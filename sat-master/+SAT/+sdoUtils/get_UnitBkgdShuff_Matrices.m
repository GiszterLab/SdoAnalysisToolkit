
% // Function for getting the often-repeated operations of querying the SDO
% structure for the unit, background, and shuffled matrices; compensating
% for the fact that the individual shuffles may no longer be present. 
%
% Here, the 'dSdo' and 'jSdo' are structures, which contain the entirety of
% the 'Unit', 'Bkgd', 'Shuff', and 'MeanShuff'

%_______________________________________
% Copyright (C) 2024 Trevor S. Smith
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

function [dSdo, jSdo, rdSdo, rjSdo] = get_UnitBkgdShuff_Matrices(sdoStruct, XT_CH_NO, PP_CH_NO, varargin)

p = inputParser; 
addParameter(p, 'reparameterize', 1); 
addParameter(p, 'nShuffles', 1000); 
parse(p, varargin{:}); 
pR = p.Results; 

sFields = {'Unit', 'Bkgd', 'Shuff', 'MeanShuff'}; 
nFields = 4; 
dSdo = cell2struct(cell(4,1), sFields); 
jSdo = cell2struct(cell(4,1), sFields); 
%________________________
dSdo.Unit = sdoStruct(XT_CH_NO).sdos{PP_CH_NO}; 
jSdo.Unit = sdoStruct(XT_CH_NO).sdosJoint{PP_CH_NO}; 
dSdo.Bkgd = sdoStruct(XT_CH_NO).bkgrndSDO; 
jSdo.Bkgd = sdoStruct(XT_CH_NO).bkgrndJointSDO; 
%
if ~isempty(sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}.SDOJointShuff)
    %
    dSdo.Shuff = sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}.SDOShuff; 
    jSdo.Shuff = sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}.SDOJointShuff;
    dSdo.MeanShuff = mean(dSdo.Shuff,3); 
    jSdo.MeanShuff = mean(jSdo.Shuff,3); 
   %
elseif ~isempty(sdoStruct(XT_CH_NO).shuffles{1,PP_CH_NO}.SDOJointShuff_mean)
    %// For normalized means + std, without raw shuffles; 
    dSdo.MeanShuff = sdoStruct(XT_CH_NO).shuffles{1,PP_CH_NO}.SDOShuff_mean; 
    jSdo.MeanShuff = sdoStruct(XT_CH_NO).shuffles{1,PP_CH_NO}.SDOJointShuff_mean; 
    dSdo_shuff_std = sdoStruct(XT_CH_NO).shuffles{1,PP_CH_NO}.SDOShuff_std; 
    jSdo_shuff_std = sdoStruct(XT_CH_NO).shuffles{1,PP_CH_NO}.SDOJointShuff_std;
    %__ Simulate draws; 
    % WARNING: This assumes the underlying distribution was normal (which
    % is usually true towards the center, but may deviate towards the
    % tails)
    N_SHUFF = pR.nShuffles; 
    dSdo.Shuff = SAT.sdoUtils.generateShuffleMatrices(...
        dSdo.MeanShuff, dSdo_shuff_std, N_SHUFF, 'conform', 'L'); 
    jSdo.Shuff = SAT.sdoUtils.generateShuffleMatrices(...
        jSdo.MeanShuff, jSdo_shuff_std, N_SHUFF, 'conform', 'M'); 
else
    %/ Skip Shuffles :: Override For-loops
    sFields = sFields(1:2);  
    nFields = 2; 
end    
%||__ ::NEW:: Reparameterize ________
%// ensure all priors match unit before testing for differences
%in significance; 

rjSdo = jSdo; 
rdSdo = dSdo; 

if pR.reparameterize
    for f = 1:nFields-1 
        sField = sFields{f}; 
        % __ Norm to unit p(x,0)
        rjSdo.(sField) = SAT.sdoUtils.reparameterizeSdo(...
            jSdo.(sField), jSdo.(sField), jSdo.(sFields{1})); 
        rdSdo.(sField) = SAT.sdoUtils.reparameterizeSdo(...
            dSdo.(sField), jSdo.(sField), jSdo.(sFields{1})); 
    end
    % __ If reparameterizing shuffles, should take the mean of the
    % reparameterized shuffles rather than reparameterize the mean
    sField = sFields{4}; 
    rjSdo.(sField) = mean(rjSdo.(sFields{3}),3); 
    rdSdo.(sField) = mean(rdSdo.(sFields{3}),3);

end

% __ Back to default 
if (nargout == 2) && (pR.reparameterize == 1)
    dSdo = rdSdo; 
    jSdo = rjSdo; 
    rdSdo = []; 
    rjSdo = []; 
end


end