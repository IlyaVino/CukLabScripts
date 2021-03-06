function [valsOut, indOut] = nearestVal(valsIn,targetVals,varargin)
% Find the nearest values targetVals in array valsInd.
% This function supports multi-dim arrays valsIn. If valsIn is a vector,
% the output size will be a column vector with the same length as
% targetVals. If the valsIn is a matrix, the function will search each
% column for targetVals and return a matrix with the length of targetVals
% number of rows and the same number of columns as valsIn. This pattern
% continues for multi-dim arrays in valsIn.
% 
% By default, this function removes duplicate values form valsOut. Extra
% indicies in valsOut or indOut are set to NaN. If all elements for a
% targetVal are NaN, then the function also trims the first dim. Note
% that if trim is overriden, the 1st dim of valsOut and indOut
% correspond to the entries in targetVals.
%
% [valsOut, ind] = nearestVal(valsIn,targetVals)
%   Find elements of targetVals valsIn by searching the 1st non-unit
%   dimension in valsIn and returning the value in valsOut and index in
%   ind. This search is performed for all elements in the other dimensions.
%   The output size of valsOut and ind are:
%   [nTargetVals, size(valsIn,2), size(valsIn,3), ...]
%
% [valsOut, ind] = nearestVal(__,name1,value1,name2,value2,...)
%   Executes above syntax with additional name-value pair options
%       'unique' (true) removes any duplicate values found by targetValues
%           and replaces them with NaN
%       'trim' (true)   trims any targetValues that were all duplicate
%       'threshold' (0, no threshold) excludes found targetVals that are 
%           greater than the threshold away from the actual value and 
%           replaces them with NaN. A threshold of 0 is a flag for no 
%           threshold.
%       'forceMat' (false) forces vector search to be treated as a matrix.
%           This is useful if you want to search columns of a matrix but
%           your column length happens to be 1 (i.e. a row vector).
%           Multi-dim (>2 dims) vectors are always treated as matricies.
    
    %default values for removing duplicates and trimming NaN
    removeDups = true;
    trimNaN = true;
    threshold = 0;  %0 is a flag for any value. If the threshold is non zero values away from targetVal are dropped
    forceMat = false;
    
    %parse varargin
    if nargin > 2
       for ii = 1:2:(nargin-2)
           assert(ischar(varargin{ii}),...
               ['Invalid argument class for name-value pair. Expected class char for name, got ' class(varargin{ii}) '.']);
           switch varargin{ii}
               case 'unique'    %flags duplicate values in valsOut in the 1st dim as NaN
                   removeDups = varargin{ii+1};
               case 'trim'  %type logical, trim NaN values in the 1st dim of valsOut that are NaN for all other dims
                   trimNaN = varargin{ii+1};
               case 'threshold' %type double, treat found targetVals as NaN if threshold away from valsIn (flag 0 as no threshold)
                   threshold = varargin{ii+1};
               case 'forceMat' %type logical, force treat valsIn is a matrix if a vector
                   forceMat = varargin{ii+1};
               otherwise
                   error([varargin{ii} ' is not a valid argument name.']);
           end             
       end
    end
    
    %check if any of the double inputs are empty. If not proceed to finding
    %the nearest vals. If they are empty, return empty arrays.
    if ~isempty(valsIn) || ~isempty(targetVals)
    
        %if input is a vector, ensure it is a column
        if isvector(valsIn) && ~forceMat
            valsIn = valsIn(:);
        end
        
        %ensure targetVals and threshold is a column vector
        targetVals = targetVals(:);
        threshold = threshold(:);
        
        %check threshold is a scalar or the same size as targetVals
        assert(isscalar(threshold),'Threshold must be a scalar'); 

        %convert valsIn into a 2d matrix, where the 2nd dim contains all extra
        %dims. This makes it easy to loop over and store entries in ind
        nTargetVals = length(targetVals);
        nValsIn = size(valsIn);
        valsIn = reshape(valsIn,nValsIn(1),prod(nValsIn(2:end)));

        %Initialize ind as a 2d matrix to make it easy to loop over targetVals
        ind = zeros(nTargetVals,prod(nValsIn(2:end))); 

        %find nearest value to user specified target value and record the index
        for ii = 1:nTargetVals
            [~,ind(ii,:)] = min(abs(valsIn - targetVals(ii)));
        end
        
        % Lookup actual values for the found nearest indicies
        valsOut = zeros(size(ind));
        for ii = 1:prod(nValsIn(2:end))
            valsOut(:,ii) = valsIn(ind(:,ii),ii);
        end
        
        %drop values and indicies that are outside of the threshold
        indOut = ind;
        if threshold > 0
            indOut(abs(valsOut-targetVals(:))>threshold) = NaN;
            valsOut(abs(valsOut-targetVals(:))>threshold) = NaN;
        end
        
        %loop over other dim's and lookup actual values
        if removeDups %in addition, keep only unique values
            %initialze output matricies as NaN and write unique values to them
            tmpValsOut = valsOut;
            tmpIndOut = indOut;
            indOut = NaN(size(ind));    
            valsOut = indOut;

            %loop over elements created by extra dims
            for ii = 1:prod(nValsIn(2:end))
                %update delay values based on index and remove any duplicate values
                [uniqueValsOut, ia] = unique(tmpValsOut(:,ii),'stable');
                
                %remove any indicies that are already NaN from threshold
                ia = ia(~isnan(ia));
                uniqueValsOut = uniqueValsOut(~isnan(ia));
                
                %Assign unique values and indicies
                valsOut(ia,ii) = uniqueValsOut;
                indOut(ia,ii) = tmpIndOut(ia,ii);
            end
        end

        %remove any rows from valsOut and indOut that are all NaN
        if trimNaN
            keepRow = any(~isnan(valsOut),2);
            valsOut = valsOut(keepRow,:);
            indOut = indOut(keepRow,:);
            nTargetVals = size(valsOut,1);
        end

        %reshape the final values and indices to match the size of valsIn
        indOut = reshape(indOut,[nTargetVals,nValsIn(2:end)]);
        valsOut = reshape(valsOut,[nTargetVals,nValsIn(2:end)]);
        
    else %if valsIn or targetVals are empty, return empty arrays
        indOut = zeros(0);
        valsOut = zeros(0);
    end
end