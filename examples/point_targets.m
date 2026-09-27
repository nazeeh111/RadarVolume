function outputDir = point_targets(outputDir)
%POINT_TARGETS Reconstruct two independent synthetic point-scatterer scenes.
%   OUTPUTDIR = POINT_TARGETS() writes PNG, MAT, CSV, and JSON results to a
%   new timestamped directory below this repository's outputs directory.
%   OUTPUTDIR = POINT_TARGETS(DESTINATION) uses a new requested directory.
%   Existing destinations are refused. No radar hardware is used.

root = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1
    outputDir = fullfile(root,'outputs',['point-targets-' datestr(now,'yyyymmdd-HHMMSSFFF')]);
end
if ~(ischar(outputDir) || (isstring(outputDir) && isscalar(outputDir)))
    error('point_targets:InvalidOutput', 'outputDir must be a text path.');
end
outputDir = char(outputDir);
if isempty(outputDir) || exist(outputDir,'file') ~= 0
    error('point_targets:OutputExists', 'Choose a new output directory; existing paths are never overwritten.');
end

previousPath = path;
cleanup = onCleanup(@() path(previousPath)); %#ok<NASGU>
addpath(root);
c = 299792458;
frequency = [77e9,60e12,1e6,0];
f = frequency(1) + (0:63)*frequency(2)/frequency(3);
aperture_mm = (1:65)-33;
[xx,yy] = meshgrid(aperture_mm,aperture_mm);
depths_mm = 140:10:260;
targets_mm = [12 -8 200; -12 8 220];
volumes = cell(1,size(targets_mm,1));
metrics = repmat(struct('targetXmm',0,'targetYmm',0,'targetZmm',0, ...
    'peakXmm',0,'peakYmm',0,'peakZmm',0,'lateralErrorMm',0, ...
    'distantDepthRatio',0),size(targets_mm,1),1);
for q = 1:size(targets_mm,1)
    target = targets_mm(q,:);
    twoWayRange_m = sqrt(((xx-target(1))*1e-3).^2 + ...
        ((yy-target(2))*1e-3).^2 + (target(3)*1e-3)^2);
    sarData = exp(1i*(4*pi/c * twoWayRange_m .* reshape(f,1,1,[])));
    [volumes{q},x_mm,y_mm,z_mm] = radar_volume_reconstruct( ...
        sarData,frequency,1,1,depths_mm,128);
    magnitude = abs(volumes{q});
    [~,linearPeak] = max(magnitude(:));
    [iy,ix,iz] = ind2sub(size(magnitude),linearPeak);
    [~,targetX] = min(abs(x_mm-target(1)));
    [~,targetY] = min(abs(y_mm-target(2)));
    depthProfile = squeeze(magnitude(targetY,targetX,:));
    metrics(q) = struct('targetXmm',target(1),'targetYmm',target(2), ...
        'targetZmm',target(3),'peakXmm',x_mm(ix),'peakYmm',y_mm(iy), ...
        'peakZmm',z_mm(iz), ...
        'lateralErrorMm',hypot(x_mm(ix)-target(1),y_mm(iy)-target(2)), ...
        'distantDepthRatio',max(depthProfile([1 end]))/max(depthProfile));
end

[made,message] = mkdir(outputDir);
if ~made
    error('point_targets:OutputCreate', 'Could not create output directory: %s',message);
end
for q = 1:numel(volumes)
    [~,depthIndex] = min(abs(z_mm-targets_mm(q,3)));
    slice = abs(volumes{q}(:,:,depthIndex));
    png = uint8(round(255 * flipud(slice) / max(slice(:))));
    imwrite(png,fullfile(outputDir,sprintf('target-%d.png',q)));
end
save(fullfile(outputDir,'point-targets.mat'),'volumes','x_mm','y_mm','z_mm', ...
    'targets_mm','frequency','metrics','-v7');
writetable(struct2table(metrics),fullfile(outputDir,'metrics.csv'));
fid = fopen(fullfile(outputDir,'metrics.json'),'w');
if fid < 0
    error('point_targets:OutputWrite','Could not write metrics.json.');
end
fwrite(fid,jsonencode(metrics),'char');
fclose(fid);
fprintf('Synthetic point-target results: %s\n',outputDir);
end
