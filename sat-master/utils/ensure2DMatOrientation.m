%% ensure2DMatOrientation
% Macro to ensure that the direction of data is as expected.
% (Occassionally, MATLAB will represent what should be a [1xN] vector as
% [Nx1] or vice-versa, which causes issues when concatenating w/ [NxK]
% data. 

% Trevor S. Smith, 2021
% Drexel University College of Medicine

function [arr] = ensure2DMatOrientation(arr, varargin)
%// input array, ideal row count (if defined), ideal col count (if defined)
if isempty(varargin)
    disp('Ideal dimensions not defined')
    return
end
if ~isempty(varargin{1})
    ir = varargin{1}; 
    sz = size(arr); 
    if find(sz==ir) ~=1
        arr= arr';
    end
elseif ~isempty(varargin{2})
    ic = varargin{2};
    sz = size(arr);
    if find(sz==ic) ~=2
        arr = arr'; 
    end
end
    
end