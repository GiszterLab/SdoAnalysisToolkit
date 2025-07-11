        function obj = importSdoStruct(obj, sdoStruct, XT_CH_NO, PP_CH_NO)
            arguments
                obj
                sdoStruct
                XT_CH_NO {mustBeInteger} = 1; 
                PP_CH_NO {mustBeInteger} = 1;
            end
            %// import from standard sdo multicompare Struct; 
            obj.xtChName        = sdoStruct(XT_CH_NO).signalType; 
            obj.ppChName        = sdoStruct(XT_CH_NO).neuronNames{PP_CH_NO};
            obj.pxtNames        = {'sdo'}; 
            obj.nPxtTypes       = 1; 
            %obj.nEvents         = 0; 
            obj.xtProperties    = sdoStruct(XT_CH_NO).params.xt; 
            obj.ppProperties    = sdoStruct(XT_CH_NO).params.pp; 
            obj.pxProperties    = sdoStruct(XT_CH_NO).params.px;
            obj.stateMapping    = sdoStruct(XT_CH_NO).levels; 
            obj.nStates         = length(sdoStruct(XT_CH_NO).levels) - 1; 
            obj.px0DuraMs      = sdoStruct(XT_CH_NO).params.px.px0DurationMs; 
            obj.px1DuraMs      = sdoStruct(XT_CH_NO).params.px.px1DurationMs; 
            obj.nShuffles       = size(sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}.SDOShuff, 3); 
            obj.sdo             = sdoStruct(XT_CH_NO).sdos{PP_CH_NO}; 
            obj.sdoJoint        = sdoStruct(XT_CH_NO).sdosJoint{PP_CH_NO}; 
            obj.sdoBkgrnd       = sdoStruct(XT_CH_NO).bkgrndSDO; 
            obj.sdoBkgrndJoint  = sdoStruct(XT_CH_NO).bkgrndJointSDO; 
            obj.shuffles        = sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}; 
            obj.stats           = sdoStruct(XT_CH_NO).stats{PP_CH_NO}; 
            obj.markovMatrix    = eye(obj.nStates); %This is just a DUMMY!
            try
                %// For depreciated
                obj.params      = sdoStruct(XT_CH_NO).params; 
            end
            try
                obj.stirpd      = sdoStruct(XT_CH_NO).stirpd{PP_CH_NO}; 
                obj.nEvents     = sdoStruct(XT_CH_NO).stats{PP_CH_NO}.nEvents; 
            end

            %__
            obj.generatedExactBackground = true;  
        end
