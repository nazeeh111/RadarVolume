function varargout = radar_volume(varargin)
% RadarVolume: From radar aperture to 3D volume.
% Passes arguments and outputs directly to calibrateDataFunction.
root = fileparts(mfilename('fullpath'));
previousPath = path;
cleanup = onCleanup(@() path(previousPath)); %#ok<NASGU>
addpath(root);
addpath(fullfile(root, 'Algorithms', 'calibration'));
[varargout{1:nargout}] = calibrateDataFunction(varargin{:});
end
