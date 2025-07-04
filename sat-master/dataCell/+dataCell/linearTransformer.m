%%

% Bit of a dummy class for now; 

% This is to contain the linear transforms and associated matrices for the
% V2 DataCell + SAT toolboxes


classdef linearTransformer
    properties
        weightMatrix        = 0; %// for describing the relationship between components; 
        nActivationsUsed    {mustBeInteger, mustBeNonnegative} = 0; 
        decomposeMethod     char {mustBeMember(decomposeMethod, {'pca', 'ica', 'max', 'std'})} = 'pca';
    end
    
    properties (Dependent)
        nChannels
    end
    
    
    methods 
        function nChannels = get.nChannels(obj)
            nChannels = length(obj.weightMatrix);
        end
        %---------------------------------------%
        % || Constructor || 
        function obj = linearTransformer(N_CHANNELS)
                obj.weightMatrix = eye(N_CHANNELS); 
        end
        %--------------------------------------%
        function biplot(obj, useComps) % overload
            arguments
                obj
                useComps = 1:3; 
            end
            if length(useComps) > obj.nChannels 
                useComps = intersect(useComps, 1:obj.nChannels); 
            end
            if length(useComps) > 3
                disp("Warning, only the first three component dimensions are displayed."); 
                useComps = useComps(1:3); 
            end
            N_COMPS = length(useComps); 
            figure; 
            biplot(obj.weightMatrix(useComps,:)'); %transpose due to our convention
            title(strcat("Headings for components: ", num2str(useComps))); 
            xlabel(strcat("Component ", num2str(useComps(1)))); 
            if N_COMPS > 1
                ylabel(strcat("Component ", num2str(useComps(2)))); 
            end
            if N_COMPS > 2
                zlabel(strcat("Component " , num2str(useComps(3))));
            end
        end
        %----------------------------------------%
        % Subsample 
        function obj = subsample(obj, useChannels)
            yarr = obj.weightMatrix(useChannels,:); 
            obj.weightMatrix = yarr(:,useChannels); % square subsample
        end
        %----------------------------------------%
        function obj =  calculateWeightMatrix(obj, xt, method)
            arguments
                obj
                xt 
                method = obj.decomposeMethod; 
            end
            
            % The 'weight matrix' here is a left premultiplication matrix
            % of form [Components] = [Weight]*[xtData], where xtData is a
            % 'nChannels' by 'nObservations' array
            
            % TODO Better handling for 2D vs. 3D
            [sz_x, sz_y, sz_z]= size(xt); 
            % nchannels, nTrials
            switch method
                case {'ica'}
                    % TODO: Replace this with TS_ICA plugin. 
                    [~, ~, ~, W, A, S, ~, ~] = ts_ica(xt, ...
                        'decimate', 1, 'verbose', 1); 
                    obj.weightMatrix = W*A*S; 
                case {'pca', 'max'}
                    if sz_z > 1
                        xtArr = reshape(xt, obj.nChannels, [], 1); %2D; 
                    else
                        xtArr = xt; 
                    end
                     [~, W] = iterativeVectorDecomposition(xtArr, METHOD); 
                     obj.weightMatrix = W;
                case {'std'}
                    V1 = std(xt, [], 3); 
                    V0 = mean(V1,2); 
                    obj.weightMatrix = diag(1./V0); 
            end
            obj.nActivationsUsed = obj.nChannels; 
        end
        %-----------------------------------------------------------------
        function dataOut = applyLinearTransform(obj, data)
            arguments
                obj
                data primaryData
            end
            
            dataOut = copy(data);
            
            for tr = 1:data.nTrials
                %// 2D Array; 
                xtData = data.getTensor(1:obj.nChannels, tr); 
                compData = W*xtData; 
                dataOut.importTensor(compData, "useChannels", 1:data.nChannels, "useTrials", tr); 
                % // Rename
                for ch = 1:data.nChannels
                    dataOut.data{1,tr}(ch).sensor = strcat("Comp_", num2str(ch)); 
                end
            end
        
        end
        %-----------------------------------------------------------------
        
    end
end