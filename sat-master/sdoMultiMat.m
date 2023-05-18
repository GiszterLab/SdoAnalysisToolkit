%% SDO Multi-Mat
% OOP-Wrapper Class to generate ALL sdoMats within a structure; 
%
% Used to rapidly compute multiple SDOs at once. 
% Can be exported to 'sdoMat' class for analysis. 

% Trevor S. Smith, 2023
% Drexel University College of Medicine

classdef sdoMultiMat < handle
    properties
        % __ SuperSet ___
        nXtChannels {mustBeInteger}= 0; 
        nPpChannels {mustBeInteger}= 0; 
        % __ PXT PARAMS
        px0DuraMs   = -10; 
        px1DuraMs   = 10; 
        zDelay      {mustBeInteger}= 0; 
        nShift      {mustBeInteger}= 1; 
        filterWid     = 0; 
        filterStd     = 0; 
        %px_nStates  = 20;
        % __ Significance Testing
        sigPVal     = 0.05; 
        nSigValues  {mustBeInteger}= 1; 
        zScore      = false; 
        sigMat      = []; 
        %_____
        sdoMatCell  = {}; %// Reserved; 
        sdoStruct   = {}; 
        %__ MetaData
        xtProperties = []; 
        ppProperties = []; 
    end
    properties (Access = protected)
        populatedStructure = false; 
    end

    methods
        % __ Wrap the actual programmatic method; 
        function obj = compute(obj, xtdc, ppdc, useXtChannels, usePpChannels)
            arguments
                obj 
                xtdc xtDataCell
                ppdc ppDataCell
                useXtChannels {mustBeInteger} = []; 
                usePpChannels {mustBeInteger} = []; 
            end
            %___ Just run the SDO Pipeline for all combinations using common params
            %//  use the programmatic method
            %(efficient) for calculating the core code; 

            if ~isempty(useXtChannels)
                xtdc = subsample(xtdc, 1:xtdc.nTrials, useXtChannels); 
            end
            if ~isempty(usePpChannels)
                ppdc = subsample(ppdc, 1:ppdc.nTrials, usePpChannels); 
            end

            SIG_FACTOR = xtdc.fs/1000; 

            obj.sdoStruct = SAT.compute.populateSDOArray(xtdc.data(1,:), ppdc.data(1,:), ... 
                round([abs(obj.px0DuraMs), obj.px1DuraMs]*SIG_FACTOR), ... 
                'fieldName',    xtdc.dataField, ...
                'ppDataField',  ppdc.dataField, ... 
                'pxFilter',     [obj.filterWid, obj.filterStd], ... 
                'pxShift',      obj.nShift, ...
                'pxDelay',      obj.zDelay, ... 
                'nShuffles',    ppdc.nShuffles, ...
                'shuffMethod',  ppdc.shuffMethod, ...
                'verbose',     1, ... 
                'CIF_FIR',      ppdc.shuffCIF,...
                'CIF_TAU',      ppdc.shuffTau);  

            obj.nXtChannels = length(obj.sdoStruct); 
            obj.nPpChannels = length(obj.sdoStruct(1).sdos); 
            obj.populatedStructure = true; 
            %__ Append Params; 
            params.xt.xtDataName            = ''; 
            params.xt.DataFieldname         = xtdc.dataField; 
            params.xt.IDFieldname           = 'sensor'; 
            params.xt.MapMethod             = xtdc.mapMethod; 
            params.xt.MaxMode               = xtdc.maxMode; 
            params.pp.ppDataName            = ''; 
            params.pp.IDFieldname           = 'sensor';
            params.px.px0DurationMs         = obj.px0DuraMs; 
            params.px.px1DurationMs         = obj.px1DuraMs; 
            params.px.smoothingFilterWidth  = obj.filterWid; 
            params.px.smoothingFilterStd    = obj.filterStd; 
            % __ Depreciate one of these; Both here for redundancy
            params.px.x1StartShift          = obj.nShift; 
            params.px.x0x1Delay             = obj.zDelay; 
            params.px.nShift                = obj.nShift; 
            params.px.zDelay                = obj.zDelay; 
            %___
            obj.xtProperties = params.xt; 
            obj.ppProperties = params.pp; 
            %__ 
            for m=1:obj.nXtChannels
                obj.sdoStruct(m).params = params; 
            end
            %___ 
            obj.sdoStruct = SAT.compute.performStats(obj.sdoStruct); 
            obj.sdoStruct = SAT.compute.testStatSig(obj.sdoStruct, obj.sigPVal, obj.zScore); 
            %___ 
        end
        %// find sig combos at specified threshold; 
        function obj = findSigSdos(obj, SIG_THRESH)
            arguments
                obj
                SIG_THRESH {mustBeInteger} = obj.nSigValues; 
            end
            obj.sigMat = SAT.sdoUtils.findSigSdos(obj.sdoStruct, SIG_THRESH);
        end

        %// Extract an 'sdoMat' Class from multi-Mat; 
        function sdoM = extract(obj, XT_CH_NO, PP_CH_NO)
            arguments
                obj
                XT_CH_NO {mustBeInteger}
                PP_CH_NO {mustBeInteger}
            end
            if ~obj.populatedStructure
                disp("SDO Structures have not been generated. Please use the 'compute' method first"); 
                return
            end
            sdoM = sdoMat; 
            sdoM.importSdoStruct(obj.sdoStruct, XT_CH_NO, PP_CH_NO); 
        end
    end
end
