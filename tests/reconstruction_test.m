% Offline physical-coordinate reconstruction checks; run from any folder.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
testPath = path;
initialFigures = numel(findall(0,'Type','figure'));
c = 299792458;
frequency = [77e9,60e12,1e6,0];
f = frequency(1) + (0:63)*frequency(2)/frequency(3);
z_mm = 140:10:260;
cases = [65 65 128  0   0 200; ...
         65 49 128 12  -8 200; ...
         47 64 129 -12  8 220; ...
         64 65 129  12 -8 200];
for q = 1:size(cases,1)
    ny = cases(q,1); nx = cases(q,2); nFFT = cases(q,3);
    xyz = cases(q,4:6);
    [xx,yy] = meshgrid((1:nx)-(nx+1)/2,(1:ny)-(ny+1)/2);
    range_m = sqrt(((xx-xyz(1))*1e-3).^2 + ...
        ((yy-xyz(2))*1e-3).^2 + (xyz(3)*1e-3)^2);
    data = exp(1i*(4*pi/c * range_m .* reshape(f,1,1,[])));
    [volume,xAxis,yAxis,zAxis] = radar_volume_reconstruct(data,frequency,1,1,z_mm,nFFT);
    assert(isequal(size(volume),[nFFT,nFFT,numel(z_mm)]));
    assert(numel(xAxis)==nFFT && numel(yAxis)==nFFT);
    expectedX = (0:nFFT-1) - (floor((nFFT-nx)/2) + (nx-1)/2);
    expectedY = (0:nFFT-1) - (floor((nFFT-ny)/2) + (ny-1)/2);
    assert(isequal(xAxis,expectedX) && isequal(yAxis,expectedY));
    assert(max(abs(zAxis(:)-z_mm(:)))<1e-10);
    [~,linearPeak] = max(abs(volume(:)));
    [iy,ix,iz] = ind2sub(size(volume),linearPeak);
    assert(abs(xAxis(ix)-xyz(1))<=0.5 && abs(yAxis(iy)-xyz(2))<=0.5);
    assert(zAxis(iz)==xyz(3));
    [~,targetX] = min(abs(xAxis-xyz(1)));
    [~,targetY] = min(abs(yAxis-xyz(2)));
    profile = squeeze(abs(volume(targetY,targetX,:)));
    [focused,focusedIndex] = max(profile);
    assert(zAxis(focusedIndex)==xyz(3));
    assert(max(profile([1 end])) < 0.2*focused);
    assert(strcmp(path,testPath));
end

zeroData = complex(zeros(5,7,4));
[zeroVolume,zeroX,zeroY,zeroZ] = radar_volume_reconstruct( ...
    zeroData,frequency,1,1,[100 150],8);
assert(isequal(size(zeroVolume),[8,8,2]) && all(zeroVolume(:)==0));
assert(numel(zeroX)==8 && numel(zeroY)==8 && isequal(zeroZ,[100 150]));

% The optional physical mode must leave the original seven-argument route.
addpath(fullfile(root,'Algorithms','imageReconstruction'));
legacyData = reshape(complex(1:140,141:280),5,7,4);
[defaultVolume,defaultX,defaultY,defaultZ] = reconstructSARimageFFT_3D( ...
    legacyData,frequency,1,1,-1,[100 150],8);
[explicitVolume,explicitX,explicitY,explicitZ] = reconstructSARimageFFT_3D( ...
    legacyData,frequency,1,1,-1,[100 150],8,'legacy');
assert(isequaln(defaultVolume,explicitVolume) && isequaln(defaultX,explicitX) ...
    && isequaln(defaultY,explicitY) && isequaln(defaultZ,explicitZ));
path(testPath);

badCalls = { ...
    @() radar_volume_reconstruct(NaN(5,7,4),frequency,1,1,[100 150],8), ...
    @() radar_volume_reconstruct(zeroData,frequency(1:3),1,1,[100 150],8), ...
    @() radar_volume_reconstruct(zeroData,[0 60e12 1e6 0],1,1,[100 150],8), ...
    @() radar_volume_reconstruct(zeroData,frequency,0,1,[100 150],8), ...
    @() radar_volume_reconstruct(zeroData,frequency,1,1,[150 100],8), ...
    @() radar_volume_reconstruct(zeroData,frequency,1,1,[100 150],6), ...
    @() radar_volume_reconstruct(zeroData,frequency,1,1,[100 150],2048)};
for q = 1:numel(badCalls)
    caught = false;
    try
        badCalls{q}();
    catch err
        caught = startsWith(err.identifier,'radar_volume_reconstruct:');
    end
    assert(caught);
end
assert(strcmp(path,testPath));
assert(numel(findall(0,'Type','figure'))==initialFigures);
disp('PASS RadarVolume physical reconstruction: off-axis focus, shape, mm axes, depth contrast, zeros, validation, no figure/path leak');
