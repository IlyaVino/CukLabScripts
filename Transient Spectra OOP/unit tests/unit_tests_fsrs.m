% This file constains unit tests for the transientSpectra class and 
% overriden methods in its subclasses

%% constructor tests
% NOTE FOR TEST DATA: I've dropped the timestamp in the file name so that 
% actual data is unique and does not get confused with test data while scripting

%default constructor
myFSRS = fsrs();

% load live tweaking gs FSRS data from a fsrs object
myFSRS = fsrs('OC_sample_1sp_GSraman_slit_closed.mat');

% load acquisition gs FSRS data from a fsrs object
myFSRS = fsrs('Sample_OC_D2O.mat');

% load acquisiton gs data acquired by an older version of the acquisition
% program (todo: add git SHA)
myFSRS = fsrs('Sample_None_Methanol.mat');

% load TR data acquired as part of a FSRS data set from a fsrs object
myFSRS = fsrs('Sample_BSP_Air.mat');
% only myTR should contain data: (todo implement equal methods)
%assert(myGsFsrs == fsrs(),'myGsFsrs is not a default fsrs object');
%assert(myEsFsrs == fsrs(),'myGsFsrs is not a default fsrs object');
%assert(myTR ~= fsrs(),'myTR is empty');

% load a acquisition gs FSRS and assign a short name
myFSRS = fsrs('Sample_None_Methanol.mat','short name','methanol');

% load a acquisition gs FSRS, assign a short name, and assign the raman pump wavelength
myFSRS = fsrs('Sample_None_Methanol.mat','short name','methanol','ramanPumpNm',397.6);
assert(myFSRS.ramanPumpNm == 397.6, 'failed to assign raman pump wavelength');

% load a multi-scheme data set 
myFSRS = fsrs('Sample_None_None.mat');
assert(length(myFSRS.schemes) == 5, 'Failed to load multi-scheme data set into fsrs object');

% load a data set array
inputTable = {'spectra 1', 'Sample_None_None.mat';...
              'spectra 2', 'Sample_None_None.mat';...
              'spectra 3', 'Sample_None_None.mat'};    

myFSRS = fsrs(inputTable(:,2),'short name',inputTable(:,1),'ramanPumpNm',397.6);
assert(all(size(myFSRS)==[3,1]),'Failed to construct fsrs object array');
assert(all([myFSRS.ramanPumpNm]==397.6*ones(1,3)),'Failed to assign raman pump wavelength to fsrs object array');

%% Test working with units
myFSRS = testObjArray1();

%set fisrt unit to be different from other units
myFSRS(1) = myFSRS(1).setUnits('nm','ns','OD');

%test heterogeneous unit
[wlUnit,delayUnit,sigUnit] = myFSRS.getUnits;
assert(iscell(wlUnit),'Failed to return heterogeneous unit array');
assert(strcmp(wlUnit{1},'nm')&&strcmp(wlUnit{2},'rcm-1')&&strcmp(delayUnit{3},'ps'),'Failed to return correct units');

%% Test spectra array manipulation
myFSRS = testObjArray1();

myFSRS = myFSRS.average;
assert(all(size(myFSRS(1).spectra)==[1340,35,1,2,5]),'Failed to average repeats for object array');

myFSRS = myFSRS.stitch;
assert(all(size(myFSRS(1).spectra)==[1340,35,1,1,5]),'Failed to stitch grating positions for object array');

myFSRS = myFSRS.setUnits('nm','ps',[]);

myFSRS2 = myFSRS.subset('wavelengths',[50:5:150],'delays',[0:1e7:2e8]);
assert(all((myFSRS2(1).wavelengths-(50:5:150)')<1e-6) && all(myFSRS2(3).delays == [0, 1e7, 2e7, 3e7, 3.4e7]'), 'Failed to subset object array');

myFSRS2 = myFSRS.trim('wavelengths',[10 50],'delays',[-2, 2e8]);
assert(all((myFSRS2(1).wavelengths-(10:1:50)')<1e-6) && all(myFSRS2(3).delays == (0:1e6:34e6)'), 'Failed to trim object array');

%% Test fsrs object properties get/set
myFSRS = testObjArray2();
[myFSRS(:).ramanPumpNm] = deal(400);

%% plotSpectra tests on a FSRS acquired TR data set (probe chirp test)
%load a TR data set that contains many delays but one repeat and one grating position:
myTR = fsrs('Sample_BSP_Air.mat');

% plot all TR spectra data using the default options for plotSpectra()
figure;
myTR.plotSpectra();

% plot all TR spectra without the legend
figure;
myTR.plotSpectra('no legend');

% plot a delay subset of TR spectra in the delay vector. The option change
% uses a name-value pair
figure;
myTR.plotSpectra('delays',[0,0.5,1]+145.6);

% test if plotSpectra correctly removes non-unique delays
figure;
myTR.plotSpectra('delays',[0,0.001,0.5,1]+145.6);

% test if plotSpectra passes extra parameters to plot. '-k' is an otpional
% imput for plot() that tells to plot black solid lines
figure;
myTR.plotSpectra('delays',[0,0.5,1]+145.6,'-k');

%% test default plotSpectra behavior on data that contains multiple repeats and grating positions 
%load a test data set (live tweaking)
myFSRS = fsrs('Sample_OC_D2O.mat');

% plot all FSRS spectra from acquisition data
figure;
myFSRS.plotSpectra();
ylim([-5 5]);
xlim([-1000 3500]);

% test changing units and plot FSRS spectra
myFSRS = myFSRS.setUnits('nm',[],'mOD');

figure;
myFSRS.plotSpectra();
ylim([-2 5]);
xlim([375 465]);

%% test updating the raman pump wavelength
myFSRS = fsrs('Sample_OC_D2O.mat');
myFSRS.ramanPumpNm = 380;

figure;
myFSRS.plotSpectra();
ylim([-5 5]);
xlim([-500 4000]);

myFSRS = myFSRS.findRamanPumpNm('pump guess',400);
figure;
myFSRS.plotSpectra();
ylim([-5 5]);
xlim([-1000 3500]);

myFSRS = testObjArray2();
myFSRS = myFSRS.average;
myFSRS = myFSRS.stitch;
myFSRS = myFSRS.findRamanPumpNm;
myFSRS.plotSpectra;

%% test stiching multiple grating positions
myFSRS = fsrs('Sample_OC_D2O.mat');
myFSRS = myFSRS.findRamanPumpNm();

figure; hold on; box;
myFSRS2 = myFSRS.stitch('average');
myFSRS2.plotSpectra('no legend');

myFSRS2 = myFSRS.stitch('lower');
myFSRS2.plotSpectra('no legend');

myFSRS2 = myFSRS.stitch('upper');
myFSRS2.plotSpectra('no legend');

myFSRS2 = myFSRS.stitch('half');
myFSRS2.plotSpectra('no legend');

myFSRS2 = myFSRS.stitch('linear');
myFSRS2.plotSpectra('no legend');

%default call test
myFSRS2 = myFSRS.stitch();

legend('average','lower','upper','half','linear');

ylim([-5 10]);
xlim([-1000 3500]);

%% plotTrace tests
%load a test data set (acquisition)
myTR = fsrs('Sample_BSP_Air.mat');

figure;
myTR.plotTrace('wavelengths',[380,400,420,440]);
xlim([145 147]);

figure;
myTR.plotTrace('wavelengths',[350:5:500],'no legend');

%% Test subset data
%spectra subset
%Multi-d data dense subset
myFSRS = fsrs('Sample_OC_D2O.mat');
figure;
myFSRS = myFSRS.subset('wavelengths',-5000:1:5000);
myFSRS.plotSpectra('no legend');

%Multi-d data sparse subset
myFSRS = fsrs('Sample_OC_D2O.mat');
figure;
myFSRS = myFSRS.subset('wavelengths',-1000:100:1000);
myFSRS.plotSpectra('no legend');

%1-d data dense subset
myFSRS = fsrs('Sample_OC_D2O.mat');
figure;
myFSRS = myFSRS.stitch();
myFSRS = myFSRS.subset('wavelengths',-5000:1:5000);
myFSRS.plotSpectra('no legend');

%1-d data sparse subset
myFSRS = fsrs('Sample_OC_D2O.mat');
figure;
myFSRS = myFSRS.stitch();
myFSRS = myFSRS.subset('wavelengths',-1000:100:1000);
myFSRS.plotSpectra('no legend');
%%
%delay subset
myTR = fsrs('Sample_BSP_Air.mat');
figure;
myTR.wavelengths.unit = 'nm';
myTR = myTR.subset('delays',[90:0.15:147]);
myTR.plotTrace('wavelengths',[380,400,420,440],'no legend');

%% Test trimming data
%spectra trim
myFSRS = fsrs('Sample_OC_D2O.mat');
figure;
myFSRS = myFSRS.trim('wavelengths',[-5000 5000]);
myFSRS.plotSpectra('no legend','*');
myFSRS = myFSRS.trim('wavelengths',[-1000 1000]);
myFSRS.plotSpectra('no legend','*');

%delay trim
myTR = fsrs('Sample_BSP_Air.mat');
figure;
myTR = myTR.setUnits('nm',[],[]);
myTR.plotTrace('wavelengths',[380,400,420,440],'no legend','*');
figure;
myTR = myTR.trim('delays',[140,155]);
myTR.plotTrace('wavelengths',[380,400,420,440],'no legend','*');

%test trimming data and finding pump wavelength
myFSRS = fsrs('Sample_OC_D2O.mat');
myFSRS = myFSRS.trim('wavelengths',[-1000 3500]);
myFSRS = myFSRS.stitch();
myFSRS = myFSRS.findRamanPumpNm();

figure;
myFSRS.plotSpectra();
ylim([-0.5 1]);

%% Test interpoalting data
myFSRS = loadPath(fsrs(),'Sample_OC_D2O.mat');
myFSRS = myFSRS.findRamanPumpNm();
myFSRS = myFSRS.interp('wavelengths',-1000:1:1000);

figure;
myFSRS.plotSpectra();

%% Export tests
myTR = fsrs('Sample_BSP_Air.mat','short name','chirp 8 bounces');
myTR.wavelengths.unit = 'nm';
outputStruct = myTR.export('test.mat','kinetics',[400,425,450]);
assert(length(outputStruct)==6,'Did not generate the correct outputStruct');

myFSRS = fsrs('Sample_OC_D2O.mat','short name','STO in D2O');
myFSRS.wavelengths.unit = 'nm';
outputStruct = myFSRS.export('test.mat','append',true);
assert(length(outputStruct)==6,'Did not generate the correct outputStruct');
tmpData = load('test.mat');
assert(length(fields(tmpData))==14,'Did not correctly append export file');

%% Export tests with multiple data sets
myFSRS = testObjArray2();
myFSRS = myFSRS.average;
myFSRS = myFSRS.stitch;

myFSRS.export('test.mat');

%% All tests pass
disp('All tests passed!');

%% Test specific functions
function obj = testObjArray1()
    % load a data set array
    inputTable = {'spectra 1', 'Sample_None_None.mat';...
                  'spectra 2', 'Sample_None_None.mat';...
                  'spectra 3', 'Sample_None_None.mat'};    

    obj = fsrs(inputTable(:,2),'short name',inputTable(:,1),'ramanPumpNm',397.6);
end

function obj = testObjArray2()
    % load a data set array
    inputTable = {'spectra 1', 'Sample_None_Methanol.mat';...
                  'spectra 2', 'Sample_OC_D2O.mat'};    

    obj = fsrs(inputTable(:,2),'short name',inputTable(:,1),'ramanPumpNm',397.6);
end