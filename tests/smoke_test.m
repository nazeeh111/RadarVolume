% Offline checks; run from repository root.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
addpath(fullfile(root,'Algorithms','calibration'));
rng(7); raw=complex(rand(4,2,3,16),rand(4,2,3,16));
params=struct('Slope_MHzperus',60,'Sampling_Rate_ksps',5000,'Samples_per_Chirp',16);
gain=complex([1;2;3;4],[.1;.2;.3;.4]); offset=[0;1;2;3]*1e-10;
actual=radar_volume(raw,params,gain,offset);
expected=calibrateDataFunction(raw,params,gain,offset);
assert(isequaln(actual,expected));
frequency=reshape((0:15)*60e12/5e6,1,1,1,16);
reference=raw.*gain.*exp(-1i*2*pi*offset.*frequency);
assert(max(abs(actual(:)-reference(:)))<1e-12);
assert(isequal(radar_volume(raw,params,ones(4,1),zeros(4,1)),raw));
disp('PASS RadarVolume: complex calibration, exact facade parity, phase reference, identity');
