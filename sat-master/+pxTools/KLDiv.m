%% pxTools_KLDiv
% 
% Calculate the Kullback Liebler Divergence (KLD) between two input
% distributions. 
%
% varargin can be one input which determines the dimensions that form
% distributions, other dimensions are just pointing to different
% distributions in p1 and p2
% if I don't give varargin then I vectorize the p1 and p2 as single dists
%
%

% Copyright (C) 2018  Maryam Abolfath-Beygi
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


function KL=KLDiv(px1,px2,DIM)
if ~exist('DIM', 'var')
    s = 0; 
else
    s = DIM; 
end

%s=length(varargin);
eps=1e-5; % avoid divide by 0
px1=px1+eps;
px2=px2+eps;

if (s)==0
    px1=px1(:);
    px2=px2(:);
    px1=px1/sum(px1);
    px2=px2/sum(px2);
    KL=sum(px1.*log2(px1./px2));
    % KL2=sum(p2.*log2(p2./p1));
    % KL=(KL1+KL2)/2;
else
    ss = s; 
    %ss=varargin{1};
    s1=sum(px1,ss(1));
    s2=sum(px2,ss(1));
    for L =2:length(ss)
        i=ss(L);
        s1=sum(s1,i);
        s2=sum(s2,i);
    end
    px1=bsxfun(@times,px1,1./s1);
    px2=bsxfun(@times,px2,1./s2);

    KL=px1.*log2(px1./px2);
    for L =1:length(ss)
        i=ss(L);
        KL=sum(KL,i);
    end
end

end