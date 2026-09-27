# Verification

Local checks ran with MATLAB R2026a Update 5 (26.1.0.3346908), using base MATLAB. No radar hardware or measured scans were used.

## Reproduce

From the repository root:

```matlab
run('tests/smoke_test.m');
run('tests/reconstruction_test.m');
addpath('examples');
outputDir = point_targets();
```

Assertions fail when a checked condition is not satisfied. The GitHub Actions workflow runs both scripts and exports the example in a temporary directory on Ubuntu with MATLAB R2026a.

## Passed locally

- Complex multichannel calibration matched the legacy entry point exactly and an independent phase/gain formula within 1e-12. Identity calibration returned the input exactly.
- Analytic spherical point returns focused at the requested depth. Four reconstruction cases covered signed off-axis positions, rectangular apertures, and odd/even aperture and FFT sizes. Lateral peaks were within half a sampling interval on each axis; returned axes matched the padding-derived coordinates exactly.
- At the target's lateral position, magnitudes at the two endpoint depths were below 20% of the maximum in each checked case. This is a focus check, not a depth-resolution measurement.
- Zero input produced zero output. Invalid data, frequency parameters, spacing, depths, FFT size, and excessive workloads were rejected. Reconstruction created no figures and restored the MATLAB search path.
- A separate comparison with the pre-change function found bitwise-equal legacy image and axis outputs on three complex-data grids. The permanent test also checks default versus explicit legacy routing.
- The example exported PNG, MAT, CSV, and JSON files and refused to overwrite an existing destination.

The two independent example scenes produced these results:

| Target (x, y, z), mm | Global peak, mm | Lateral error | Endpoint-depth / peak magnitude |
| --- | --- | ---: | ---: |
| (12, −8, 200) | (12, −8, 200) | 0 mm | 0.0731 |
| (−12, 8, 220) | (−12, 8, 220) | 0 mm | 0.0164 |

## Source preservation

[SOURCE-MANIFEST.json](SOURCE-MANIFEST.json) records the original nine-file snapshot. Eight files remain byte-for-byte identical. `Algorithms/imageReconstruction/reconstructSARimageFFT_3D.m` intentionally adds an opt-in physical-coordinate mode while retaining its original notice and default numerical path. The manifest remains the original baseline, not a checksum list for the modified release.

## Limits

The point model omits antenna patterns, range attenuation, noise, calibration errors, and multistatic conversion. Selecting the correct sampled depth does not establish 10 mm physical depth resolution. Measured target accuracy and the full MIMO acquisition/reconstruction pipeline remain unverified. Array utilities that call `physconst` need additional toolbox support; the new monostatic example does not.
