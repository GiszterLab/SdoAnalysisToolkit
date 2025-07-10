  %% SAT.computer V2 (OOP)
  %
  % (Temporary?) Kernel class for handling SDO properties and computations.
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
  
  classdef sdoComputer < handle & matlab.mixin.Copyable
      properties
          sdoMatrix         = []; % L
          sdoMatrixNormed   = []; % Lnorm
          jointMatrix       = []; % M
          backgroundSdo     = [];  % << 'subtractive' component for background subtraction.
          %
          algorithm {mustBeMember(algorithm, {'v3', 'v5', 'v7'})} = 'v3';
          backgroundSubtraction = true; % This should be handled upstream. [or here]
          parallelCompute       = false; 
          obswise               = false; % Used for shuffles / multistacks
          lowMemory             = false; 
          verbose               = true; 
          % Trial Handling; 
          trialHandling         = 'combine' % Dummy; 
          %
          %
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
          function obj = sdoComputer(type)
              arguments
                  type = 'unit'; 
              end
              switch type
                  case 'unit'
                      % standard; 
                  case 'background'
                      % TO FILL
                  case 'shuffle'
                      obj.obswise = true; 
              end        
          end
          %-------------------------------------
          function name = get.algorithmName(obj)
              switch obj.algorithm
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
              n = length(obj.sdoMatrix); 
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
              
              % --> Need to figure out what I'm going to do w/ trials
              if px0.nTrials > 1
                    px0_flat = cellhcat(px0.data(1,:)); 
                    px1_flat = cellhcat(px1.data(1,:));
              else
                  px0_flat = px0.data{1};
                  px1_flat = px1.data{1};
              end
              
              if obj.backgroundSubtraction
                  if ~obj.importedBackground
                      disp("No background matrix defined for background subtraction!");
                      return
                  end
                  if ~ismatrix(px0_flat)
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
              
              switch obj.algorithm
                  case 'v3'
                    [L,M,Ln] = SAT.compute.sdo3(px0_flat, px1_flat, ...
                        'parallelCompute',obj.parallelCompute); 
                  case 'v5'
                    [L,M,Ln] = SAT.compute.sdo5(px0_flat, px1_flat, ...
                        'parallelCompute',obj.parallelCompute);   
                  case 'v7'
                     [L,M,Ln] = SAT.compute.sdo7(px0_flat, px1_flat, ...
                        'parallelCompute',obj.parallelCompute);         
              end
              obj.sdoMatrix         = L; 
              obj.sdoMatrixNormed   = Ln; 
              obj.jointMatrix       = M; 
              obj.nEvents           = length(px0_flat); 
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
                  f = figure; 
                  for zz = 1:1000
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