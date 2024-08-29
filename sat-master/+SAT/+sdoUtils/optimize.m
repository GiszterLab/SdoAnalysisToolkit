%% SDO Optimization Wrapper
% Ad-hoc re-optimization of the SDO matrices, using the current SDOs as the
% initial values for optimization (sdo7).

%_______________________________________
% Copyright (C) 2023 Trevor S. Smith
% Drexel University College of Medicine
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%__________________________________________

% This will run into an error when the SDOs were generated from subsets of 
% xtdc and ppdc

function obj = optimize(obj, xtdc, ppdc, SDO_XT_CH_NO, SDO_PP_CH_NO, vars)%, XTDC_CH_NO, PPDC_CH_NO, vars)
    arguments
        obj
        xtdc
        ppdc
        SDO_XT_CH_NO = 1:obj.nXtChannels; 
        SDO_PP_CH_NO = 1:obj.nPpChannels; 
        %XTDC_CH_NO   = 1:obj.nXtChannels; 
        %PPDC_CH_NO   = 1:obj.nPpChannels; 
        vars.errorOrder {mustBeMember(vars.errorOrder, [2,4])} = 4; 
    end

   n_xt = length(SDO_XT_CH_NO); 
   n_pp = length(SDO_PP_CH_NO); 

    % __> We can have an issue here if we take a subset;

    for m = 1:n_xt
        for u = 1:n_pp
            pxt0_dc = pxtDataCell; 
            pxt0_dc.copyProperties(obj, {'zDelay', 'nShift', 'filterWid', 'filterStd'}); 
            pxt1_dc = pxt0_dc.copy; 
            pxt0_dc.duraMs = obj.px0DuraMs; 
            pxt1_dc.duraMs = obj.px1DuraMs; 
            pxt0_dc.import(xtdc, ppdc, m, u); 
            pxt1_dc.import(xtdc, ppdc, m, u); 
            %
            px0 = pxt0_dc.data; 
            px1 = pxt1_dc.data; 
            %_____________________
            L0 = obj.sdoStruct(m).sdos{u}; 
    
            [L7, M7, ~] = SAT.compute.sdo7(px0, px1, ...
                'customMatrix',L0, ...
                'initialization','custom', ...
                'errorOrder', 4); 
            %_____________________
            %|| Writeout / Replace
            obj.sdoStruct(m).sdos{u}        = L7; 
            obj.sdoStruct(m).sdosJoint{u}   = M7; 
            %_______________________

        end
    end

end