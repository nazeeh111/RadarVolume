function [volume,x_mm,y_mm,z_mm] = radar_volume_reconstruct(sarData,frequency,xStep_mm,yStep_mm,zTarget_mm,nFFT)
%RADAR_VOLUME_RECONSTRUCT Focus a calibrated monostatic uniform SAR grid.
%   [VOLUME,X_MM,Y_MM,Z_MM] = RADAR_VOLUME_RECONSTRUCT(DATA,FREQUENCY,
%   XSTEP_MM,YSTEP_MM,ZTARGET_MM,NFFT) reconstructs a 3-D volume from
%   DATA ordered as vertical positions x horizontal positions x frequencies.
%   Columns and rows must follow increasing physical x and y, respectively.
%   FREQUENCY is [startHz,slopeHzPerSecond,sampleRateHz,adcStartSeconds].
%   All returned coordinate axes are in millimeters. This function does not
%   calibrate, convert multistatic data, acquire signals, or create figures.
%
%   To bound peak memory and CPU work, NFFT^2*(frequencyCount+depthCount)
%   must not exceed 8 million complex elements. Use the original function
%   directly for legacy coordinates or larger manually managed workloads.

if ~(isa(sarData,'single') || isa(sarData,'double')) || ndims(sarData) ~= 3 || ...
        size(sarData,1) < 2 || size(sarData,2) < 2 || size(sarData,3) < 2 || ...
        ~all(isfinite(sarData(:)))
    error('radar_volume_reconstruct:InvalidData', ...
        'sarData must be a finite CPU single/double 3-D array with at least two samples on each axis.');
end

if ~isnumeric(frequency) || ~isreal(frequency) || ~isvector(frequency) || ...
        numel(frequency) ~= 4 || ~all(isfinite(frequency(:))) || ...
        frequency(1) <= 0 || frequency(2) <= 0 || frequency(3) <= 0 || frequency(4) < 0
    error('radar_volume_reconstruct:InvalidFrequency', ...
        'frequency must be finite [positive startHz, slopeHzPerSecond, sampleRateHz, nonnegative adcStartSeconds].');
end
firstHz = double(frequency(1)) + double(frequency(4))*double(frequency(2));
lastHz = firstHz + (size(sarData,3)-1)*double(frequency(2))/double(frequency(3));
if ~isfinite(firstHz) || ~isfinite(lastHz) || firstHz <= 0 || lastHz <= 0
    error('radar_volume_reconstruct:InvalidFrequency', 'Sampled frequencies must be finite and positive.');
end

if ~isnumeric(xStep_mm) || ~isreal(xStep_mm) || ~isscalar(xStep_mm) || ...
        ~isfinite(xStep_mm) || xStep_mm <= 0 || ...
        ~isnumeric(yStep_mm) || ~isreal(yStep_mm) || ~isscalar(yStep_mm) || ...
        ~isfinite(yStep_mm) || yStep_mm <= 0
    error('radar_volume_reconstruct:InvalidStep', 'Both aperture steps must be finite positive millimeters.');
end

if ~isnumeric(zTarget_mm) || ~isreal(zTarget_mm) || ~isvector(zTarget_mm) || ...
        numel(zTarget_mm) < 2 || ~all(isfinite(zTarget_mm(:))) || ...
        ~all(zTarget_mm(:) > 0) || ~all(diff(zTarget_mm(:)) > 0)
    error('radar_volume_reconstruct:InvalidDepth', ...
        'zTarget_mm must contain at least two finite, positive, increasing depths in millimeters.');
end

if ~isnumeric(nFFT) || ~isreal(nFFT) || ~isscalar(nFFT) || ...
        ~isfinite(nFFT) || nFFT ~= floor(nFFT) || ...
        nFFT < max(size(sarData,1),size(sarData,2))
    error('radar_volume_reconstruct:InvalidFFT', ...
        'nFFT must be a finite integer at least as large as both aperture dimensions.');
end
if double(nFFT)^2 * (double(size(sarData,3)) + double(numel(zTarget_mm))) > 8e6
    error('radar_volume_reconstruct:WorkBudget', ...
        'Requested FFT, frequency, and depth sizes exceed the 8-million-element work budget.');
end

frequency = double(frequency(:).');
xStep_mm = double(xStep_mm);
yStep_mm = double(yStep_mm);
zTarget_mm = double(zTarget_mm(:).');
nFFT = double(nFFT);
root = fileparts(mfilename('fullpath'));
previousPath = path;
cleanup = onCleanup(@() path(previousPath)); %#ok<NASGU>
addpath(fullfile(root,'Algorithms','imageReconstruction'));
[volume,x_mm,y_mm,z_m] = reconstructSARimageFFT_3D( ...
    sarData,frequency,xStep_mm,yStep_mm,-1,zTarget_mm,nFFT,'physical');
z_mm = z_m * 1e3;
end
