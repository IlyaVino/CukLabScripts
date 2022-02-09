%export the object data to file
function [outputStruct, filePath] = export(obj,filePath,varargin)
    
    %set default export options for data. By default either a contour is
    %saved along with its wavelengths and delays or a spectra (wave) is
    %saved along with its wavelengths. The user can override these options.
    saveFlag = struct('delays',   obj.sizes.nDelays > 1,...  %true if multiple delays
                      'wavelengths', true,...                %by default always save wavelengths
                      'traces',   false,...                  %by default to not export traces
                      'spectra',  obj.sizes.nDelays == 1,... %by default false if there are multiple delays
                      'contours', obj.sizes.nDelays > 1);    %true if multiple delays
    
    %set default naming options for exported data when there are multiple schemes and grating positions
    nameFlag = struct('shortName', true,...
                      'scheme', false,...
                      'gPos', false,...
                      'rpts', false,...
                      'delay', false,...
                      'wl', false,...
                      'spectraUnit', true);
    
    %define subsets
    wlSub = [];
    delaySub = [];  
    
    %parse varargin
    if nargin > 2
        for ii = 1:2:(nargin-2)
            assert(ischar(varargin{ii}),...
                ['Invalid argument class for name-value pair. Expected class char for name, got ' class(varargin{ii}) '.']);
            switch varargin{ii}
                case 'wavelengths'  %User wants a subset of wavelengths to plot traces
                    wlSub = varargin{ii+1}; %update wavelength subset
                    saveFlag.traces = true; %set save traces flag to true
                    nameFlag.wl = true;
                case 'delays' %User wants a subset of delays to plot spectra
                    delaySub = varargin{ii+1}; %update delay subset
                    saveFlag.spectra = true;   %set save spectra flag to true
                    nameFlag.delay = true;
                case 'contours'
                    saveFlag.contours = varargin{ii+1}; %update contour save flag
                otherwise
                    error([varargin{ii} ' is not a valid argument name.']); 
            end
        end
    end
    
    nSubWls = length(wlSub);
    nSubDelays = length(delaySub);
    
    %get actual indicies and wavelengths from object data. These may be
    %multi-dim if there are multiple repeats and grating positions
    [wlSubVal, wlSubInds] = nearestVal(obj.wavelengths,wlSub,'trim',false,'threshold',0.01*mean(obj.wavelengths,'all'));
    [delaySubVal, delaySubInds] = nearestVal(obj.delays,delaySub,'trim',false);    
    
    %define unit strings
    unitStr = struct('spectra',obj.spectra.unit,...
                     'wl',obj.wavelengths.unit,...
                     'delay',obj.delays.unit);
    
    %generate naming rules for data. These may be further modified for
    %contours, traces, and spectra below
    %todo: figure out how to select subsets of schemes, delays, etc.
    dataName = nameRule({'shortName',  {obj.desc.shortName},                                                     0, nameFlag.shortName && ~isempty(obj.desc.shortName);...
                         'label',      {''},                                                                     0, true;...
                         'dataUnit',   {['in ' unitStr.spectra]},                                                0, nameFlag.spectraUnit;...
                         'scheme',     obj.schemes,                                                              1, (obj.sizes.nSchemes>1) || nameFlag.scheme;...
                         'gPos',       strcat({'gPos: '},strcat(strtrim(cellstr(num2str(obj.gPos(:))))), ' nm'), 2, (obj.sizes.nGPos>1) || nameFlag.gPos;...
                         'rpts',       strcat({'rpt '}, strtrim(cellstr(num2str((1:obj.sizes.nRpts)')))),        3, (obj.sizes.nRpts>1) || nameFlag.rpts;...
                         'wl',         strcat(strtrim(cellstr(num2str(wlSub(:)))), {' '}, unitStr.wl),           4, (length(wlSub)>1) || nameFlag.wl;...
                         'delay',      strcat(strtrim(cellstr(num2str(delaySub(:)))), {' '}, unitStr.delay),     4, (length(delaySub)>1) || nameFlag.delay});
    
    outputStruct = struct('name',{},'data',{});
    
    %decide what type of data to export depending on sizes
    %generate contours
    if saveFlag.contours
        %remove wavelengths and delay labels from naming rule and copy into contourName
        contourName = dataName.modify('label.values',{'Matrix'},...
                                      'wl.flag',false,...
                                      'delay.flag',false);
        
        %setup autoindexing levels for multiple name generation
        contourName = contourName.buildLevels(); 
        
        %Loop over data groups to do name conversion
        nContours = obj.sizes.nRpts*obj.sizes.nGPos*obj.sizes.nSchemes;
        contours = repmat(struct('name','','data',[]),nContours,1);
        
        %Populate countours structure with matrix and matrix name
        cc = 1;    
        for ii = 1:obj.sizes.nSchemes
            for jj = 1:obj.sizes.nGPos
                for kk = 1:obj.sizes.nRpts                   
                    %assign name and data with name autoindexing
                    [contours(cc).name, contourName] = contourName.buildName('autoIncrement',true,'delimiter',', '); 
                    contours(cc).data = obj.spectra.data(:,:,kk,jj,ii);

                    %increment contour counter
                    cc = cc + 1;
                end
            end
        end
        
        %add contour data to output structure
        outputStruct = [outputStruct; contours(~strcmp({contours.name},''))]; 
    end
    
    %generate spectra
    if saveFlag.spectra
        %remove wavelengths labels from naming rule and copy into contourName
        spectraName = dataName.modify('label.values',{'Spectra'},...
                                      'wl.flag',false);
        %setup autoindexing levels for multiple name generation
        spectraName = spectraName.buildLevels(); 
        
        %Loop over data groups to do name conversion
        nWaves = obj.sizes.nRpts*obj.sizes.nGPos*obj.sizes.nSchemes*nSubDelays;
        waves = repmat(struct('name','','data',[]),nWaves,1);

        %Populate countours structure with matrix and matrix name
        cc = 1;    
        for schemeInd = 1:obj.sizes.nSchemes
            for gPosInd = 1:obj.sizes.nGPos
                for rptInd = 1:obj.sizes.nRpts
                    %update the delay name values to the actual delay values for this repeat and grating position
                    spectraName = spectraName.modify('delay.values',strcat(strtrim(cellstr(num2str(delaySubVal(:,rptInd,gPosInd),3))), ' ', unitStr.wl));
                    for delayInd = delaySubInds(:,rptInd,gPosInd)'
                        if ~isnan(delayInd)
                            %assign name and data with name autoindexing
                            [waves(cc).name, spectraName] = spectraName.buildName('autoIncrement',true,'delimiter',', '); 
                            waves(cc).data = obj.spectra.data(:,delayInd,rptInd,gPosInd,schemeInd);
                            waves(cc).data = waves(cc).data(~isnan(waves(cc).data));
                            
                            %increment contour counter
                            cc = cc + 1;
                        else
                            spectraName = spectraName.increment();
                        end
                    end
                end
            end
        end
        
        %add spectra waves to output structure
        outputStruct = [outputStruct; waves(~strcmp({waves.name},''))]; 
    end
    
    %generate traces
    if saveFlag.traces
        %remove wavelengths labels from naming rule and copy into contourName
        traceName = dataName.modify('label.values',{'Traces'},...
                                    'delay.flag',false);
        %setup autoindexing levels for multiple name generation
        traceName = traceName.buildLevels(); 
        
        %Loop over data groups to do name conversion
        nWaves = obj.sizes.nRpts*obj.sizes.nGPos*obj.sizes.nSchemes*nSubWls;
        waves = repmat(struct('name','','data',[]),nWaves,1);

        %Populate countrous structure with matrix and matrix name
        cc = 1;    
        for schemeInd = 1:obj.sizes.nSchemes
            for gPosInd = 1:obj.sizes.nGPos
                %Update the wavelength name values for the actual available wavelengths for the grating position
                traceName = traceName.modify('wl.values',strcat(strtrim(cellstr(num2str(wlSubVal(:,gPosInd),3))), unitStr.wl));
                for rptInd = 1:obj.sizes.nRpts
                    for wlInd = wlSubInds(:,gPosInd)'
                        if ~isnan(wlInd)    %If the wavelength is outside the grating position it is flagged with NaN
                            %assign name and data with name autoindexing
                            [waves(cc).name, traceName] = traceName.buildName('autoIncrement',true,'delimiter',', '); 
                            waves(cc).data = obj.spectra.data(wlInd,:,rptInd,gPosInd,schemeInd).';

                            %increment contour counter
                            cc = cc + 1;
                        else
                            traceName = traceName.increment();
                        end
                    end
                end
            end
        end
        
        %add trace waves to output structure
        outputStruct = [outputStruct; waves(~strcmp({waves.name},''))]; 
    end
    
    %save delays
    if saveFlag.delays
        %remove wavelengths labels from naming rule and copy into contourName
        delayName = dataName.modify('label.values',strcat({'Delays in '},unitStr.delay),...
                                    'scheme.flag',false,...
                                    'wl.flag',false,...
                                    'delay.flag',false,...
                                    'dataUnit.flag',false);
        %setup autoindexing levels for multiple name generation
        delayName = delayName.buildLevels(); 
        
        %Loop over data groups to do name conversion
        nWaves = obj.sizes.nRpts*obj.sizes.nGPos;
        waves = repmat(struct('name','','data',[]),nWaves,1);

        %Populate countrous structure with matrix and matrix name
        cc = 1;    
        for gPosInd = 1:obj.sizes.nGPos
            for rptInd = 1:obj.sizes.nRpts
                %assign name and data with name autoindexing
                [waves(cc).name, delayName] = delayName.buildName('autoIncrement',true,'delimiter',', '); 
                waves(cc).data = obj.delays.data(:,rptInd,gPosInd);

                %increment contour counter
                cc = cc + 1;
            end
            
        end
        
        %add trace waves to output structure
        outputStruct = [outputStruct; waves(~strcmp({waves.name},''))]; 
    end    
    
    %save wavelengths
    if saveFlag.wavelengths
        %remove wavelengths labels from naming rule and copy into contourName
        wlName = dataName.modify('label.values',strcat({'Wavelengths in '},unitStr.wl),...
                                    'scheme.flag',false,...
                                    'rpts.flag',false,...
                                    'wl.flag',false,...
                                    'delay.flag',false,...
                                    'dataUnit.flag',false);
        %setup autoindexing levels for multiple name generation
        wlName = wlName.buildLevels(); 
        
        %Loop over data groups to do name conversion
        nWaves = obj.sizes.nGPos;
        waves = repmat(struct('name','','data',[]),nWaves,1);

        %Populate countrous structure with matrix and matrix name
        cc = 1;    
        for gPosInd = 1:obj.sizes.nGPos
                %assign name and data with name autoindexing
                [waves(cc).name, wlName] = wlName.buildName('autoIncrement',true,'delimiter',', '); 
                waves(cc).data = obj.wavelengths.data(:,gPosInd);

                %increment contour counter
                cc = cc + 1;            
        end
        
        %add trace waves to output structure
        outputStruct = [outputStruct; waves(~strcmp({waves.name},''))]; 
    end
    
    %Convert outputStruct name to structure with field names and save as a
    %file
    fullNames = {outputStruct.name}';
    validNames = matlab.lang.makeValidName(fullNames);
    validNames = matlab.lang.makeUniqueStrings(validNames);
    
    %build save structure with field names and save to file
    saveCell = [validNames, {outputStruct.data}']';
    saveStruct = struct(saveCell{:});
    saveStruct.validNames = strjoin(validNames,';');
    saveStruct.fullNames = strjoin(fullNames,';');
    save(filePath,'-struct','saveStruct');
    
end