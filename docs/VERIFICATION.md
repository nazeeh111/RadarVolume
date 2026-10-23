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

## Retained example figure, 2026-10-23

A fresh run at source revision `2b6b8f90aaa37e6b295a25b28b9293a971ff430c` used MATLAB R2026a Update 5 (26.1.0.3346908). Both supplied test scripts passed, and the unchanged `point_targets` example exported two scenes. [Retained metrics](figures/metrics.json) are copied directly from that run. The initial sandboxed MATLAB launch failed its processor-feature check; the approved native run completed.

[PNG figure](figures/focus.png) · [SVG figure](figures/focus.svg) · [Plotting source](figures/render_point_targets.m)

To recreate the figure from a new result directory:

```matlab
addpath('examples');
outputDir = point_targets();
addpath('docs/figures');
render_point_targets(outputDir);
```

The plotting function reads `point-targets.mat` from that directory, writes new `focus.png` and `focus.svg` beside it, and refuses existing figure paths. It does not run reconstruction or change its outputs. The top panels divide magnitude slices by their own maxima at the target depths. The lower curves sample each target's lateral position and divide by their own maxima. PNG and SVG contain the same figure; the SVG includes raster heatmaps with vector labels and curves. The underlying MAT output can be regenerated with the example; it is not duplicated in the repository.

All quantities are synthetic. There are no repeated trials or uncertainty bars. Lateral axes in the figure are limited to −32…32 mm, the measurement aperture's extent, while the reconstruction spans the full padded grid. No normalization permits amplitude comparison between the two scenes.
