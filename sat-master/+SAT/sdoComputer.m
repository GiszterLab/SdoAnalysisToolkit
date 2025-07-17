  %% SAT.computer V2 (OOP)
  %
  % Kernel class for handling SDO properties and computations.
  % 
  % This alone likely isn't sufficient for SDO Analysis; it only handles
  % the parameterization of the functions, and the core-compute
  % capabilities
  %
  % --> I should have a spin-out class for statistics.
  % --> This is a lightweight matrix class. If we want to do background
  % subtraction, etc, this should be handled upstream. --> px0--px0* -->
  % sdoComputer. 
  
  % Maybe also a method for how we handle classes; shuffles; etc. 
  
  % --> use constructor to select for 'unit', 'background' 'shuffle' 
  
  % >> This class should also handle all of the plotters and direct
  % operations on the matrix + import/export
  
  % -->> It will also need to be the one to handle prediction + background
  
  % Trevor S. Smith, 2025
  % 
  
  classdef sdoComputer < handle & matlab.mixin.Copyable
      properties
          % _____ Data ____ 
          sdoMatrix         = []; % L
          sdoMatrixNormed   = []; % Lnorm
          jointMatrix       = []; % M
          backgroundSdo     = [];  % << 'subtractive' component for background subtraction.
          % ___ Meta________
          config    SAT.properties.computerProperties
          nEvents = 0;
      end
      properties (Dependent)
          px0
          px1
          algorithmName
          nSDOs
          nStates
      end          
      properties (Dependent, Hidden)
          importedBackground
          computedSdo
      end
      methods
          function obj = sdoComputer(type, config)
              arguments
                  type = 'unit'; 
                  config = SAT.properties.computerProperties(); 
              end
              obj.config = config; % slave to 'config' as passed, if passed.
              switch type
                  case 'unit'
                      % standard; 
                  case 'background'
                      % TO FILL
                  case 'shuffle'
                      %obj.obswise = true; 
                      obj.config.obswise = true; 
              end        
          end
          %-------------------------------------
          function name = get.algorithmName(obj)
              switch obj.config.algorithm
                  case 'v3'
                      name = 'linearEstimate'; 
                  case 'v5'            
                      name = 'asymmetricResidual';
                  case 'v7'
                      name = 'directOptimization';
              end
          end
          %---------------------------------------
          function n = get.nStates(obj)
              n = size(obj.sdoMatrix,1); 
          end
          %-----------
          function px0 = get.px0(obj)
              px0 = sum(obj.jointMatrix,1); 
          end
          %-------------
          function px1 = get.px1(obj)
              px1 = sum(obj.jointMatrix,2); 
          end
          function LI = get.computedSdo(obj)
             LI = ~isempty(obj.sdoMatrix);
          end
          function LI = get.importedBackground(obj)
              LI = ~isempty(obj.backgroundSdo); 
          end
          
          %---------------------------------------
          function obj = compute(obj, px0, px1)
              arguments
                  obj
                  px0   dataCell.pxAssigner
                  px1   dataCell.pxAssigner
              end
              
              if ~px0.isCompatible(px1)
                  print("pxAssigners are not compatible")
                  return
              end
              
              % NOTE: IT is possible that px0/px1 contains 3D data [N_XT,
              % N_TR, N_PP
              
              N_SHUFF = size(obj.px0,3); 
              N_STATES = px0.nStates(1); % obj inherits nStates downstream from this
              
              L_buff = zeros(N_STATES, N_STATES, N_SHUFF); 
              M_buff = zeros(N_STATES, N_STATES, N_SHUFF);  
              Ln_buff= zeros(N_STATES, N_STATES, N_SHUFF); 
              
              spkCount = 0; 
              for tr = 1:px0.nTrials
                  
                  % --> Need to figure out what I'm going to do w/ trials
                  px0_flat = px0.data{1,tr}; 
                  px1_flat = px1.data{1,tr}; 

                  if obj.config.backgroundSubtraction
                      if ~obj.importedBackground
                          disp("No background matrix defined for background subtraction!");
                          return
                      end
                      if ~ismatrix(px0_flat)
                          % Flatten shuffles for speed; 
                          [sz_x, sz_y, sz_z] = size(px0_flat); 
                          px0_flat_2 = reshape(px0_flat, sz_x, []); 
                          pdpx1_flat = obj.backgroundSdo*px0_flat_2+px0_flat_2; 
                          pd_px1 = reshape(pdpx1_flat, sz_x, sz_y, sz_z); 
                      else
                          pd_px1 = obj.backgroundSdo * px0_flat + px0_flat; 
                      end
                      %
                      px0_flat = pd_px1; % Override 
                  end

                  switch obj.config.algorithm
                      case 'v3'
                        [L,M] = SAT.compute.sdo3(px0_flat, px1_flat, ...
                            'parallelCompute',obj.config.parallelCompute, ...
                            'rescale', 0); 
                      case 'v5'
                        [L,M] = SAT.compute.sdo5(px0_flat, px1_flat, ...
                            'parallelCompute',obj.config.parallelCompute, ...
                            'rescale', 0);   
                      case 'v7'
                         [L,M] = SAT.compute.sdo7(px0_flat, px1_flat, ...
                            'parallelCompute',obj.config.parallelCompute, ...
                            'rescale', 0);         
                  end
                  L_buff = L_buff + L; 
                  %Ln_buff= Ln_buff+ Ln; 
                  M_buff = M_buff + M; 
                  %
                  spkCount = spkCount + size(px0_flat,2);
              end
              spkCount = max(spkCount,1);
              L     = L_buff / spkCount; 
              %Ln    = Ln_buff/ spkCount; 
              M     = M_buff / spkCount;
              Ln    = SAT.sdoUtils.normsdo(L,M); 
              %
              obj.sdoMatrix         = L; 
              obj.sdoMatrixNormed   = Ln; 
              obj.jointMatrix       = M; 
              obj.nEvents           = spkCount; %length(px0_flat); 
          end
          %--------------------------------------
          function obj = setBackgroundMatrix(obj, VAR)
              if ~isnumeric(VAR)
                  if strcmp(VAR, 'zero')
                      obj.backgroundSDO = zeros(obj.nStates); 
                  end
              else
                % __ otherwise , set; 
                obj.backgroundSDO = VAR; 
              end
          end
          %--------------- Prediction ----------
          % // Write to output prediction; 
          function px1_est = predictPx(obj, px0)
              arguments
                  obj
                  px0 dataCell.pxAssigner
              end
              Ln = obj.sdoMatrixNormed; 
              
              px1_dat = cell(px0.nChannels, px0.nTrials);
              
              px1_est = copy(px0); 
              for tr = 1:px0.nTrials
                  for ch = 1:px0.nChannels
                      % simple linear update; 
                      px1_dat{ch,tr} = Ln*px0.data{ch,tr}+px0.data{ch,tr}; 
                      %
                  end
              end
              px1_est.data = px1_dat; 
              %
              for ch = 1:px0.nChannels
                  px1_est.sensor{ch} = strcat(px1_est.sensor{ch}, "-Predict."); 
              end     
          end
          %----------
          function implay(obj, TARGET)
              arguments
                  obj
                  TARGET = 'sdoMatrix'; 
              end
              FPS = 100; 
              try 
                  implay(obj.(TARGET));
              catch
                  % hack around for people w/o toolbox; 
                  figure; 
                  for zz = 1:obj.nEvents
                      imagesc(obj.(TARGET)(:,:,zz)); 
                      cMap = SAT.sdoUtils.getSdoColormap(obj.(TARGET)(:,:,zz));
                      colormap(cMap); 
                      pause(1/FPS); 
                  end
              end
          end
          %----------------- 
      end
  end