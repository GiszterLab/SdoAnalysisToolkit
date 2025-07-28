        %// use transition matrices of SDO to predict pxt1 from an
        %input pxtDataCell
        %{
        function pxt_est = getPredictionPxt(obj, px0, duraMs)
            arguments
                obj
                px0 pxtDataCell
                duraMs double = 0; 
            end
            
            if ~obj.generatedTransitionMatrices
                disp("Transition Matrices have not Generated yet!"); 
                return
            end

            %TODO: Check for mismatch in filters/etc. 
            
            pxt_est = dataCell.adaptors.getConformedPxtDataCell(obj, 'px1'); 

            %pxt_est = pxtDataCell(); 
            pxt_est.data        = cell(1, obj.nPxtTypes); 
            pxt_est.pxtNames    = cell(1, obj.nPxtTypes);  
            if isa(px0.data, 'cell')
                ISCELL = 1; 
            else
                ISCELL = 0; 
            end
            
            for hh = 1:obj.nPxtTypes
                if ISCELL
                    pxData = px0.data{1}; 
                else
                    pxData = px0.data; 
                end
               pdPx = pxTools.predictPxtfromPx0(obj.transitionMat{hh}, pxData); 
               pxt_est.data{hh} = pdPx;  
               pxt_est.pxtNames{hh} = obj.pxtNames{hh}; 
            end
            %______ BACK COPY_________
            pxt_est.copyProperties(obj, {'xtName', 'ppName', 'xtChName', ...
                'ppChName', 'nPxtTypes', 'nEvents', 'xtProperties', ...
                'ppProperties', 'nStates', 'markovMatrix', 'stateMapping'}); 
    
            %__ Be Cautious !!
            pxt_est.markovMatrix    = obj.markovMatrix; %// this isn't exactly the same. Px of prediction  
            % __ Unique/ Differing Calls
            %{
            pxt_est.duraMs          = obj.px1DuraMs; 
            %pxt_est.stateMapping    = obj.stateMapping; 
            pxt_est.zDelay          = obj.pxProperties.zDelay; 
            pxt_est.filterWid       = obj.pxProperties.smoothingFilterWidth; 
            pxt_est.filterStd       = obj.pxProperties.smoothingFilterStd; 
            %}
            %  __ DUMMY FILL ___ 
            pxt_est.backgroundPx    = zeros(obj.nStates,1); 
            pxt_est.backgroundMkv   = zeros(obj.nStates,1); 
            %
            pxt_est.dataMatrices = obj.transitionMat; 

           % // export to a pxt;  
            
        end
        %}