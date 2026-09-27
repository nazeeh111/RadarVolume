# Reconstruction conventions

`radar_volume_reconstruct(data, frequency, xStep_mm, yStep_mm, zTarget_mm, nFFT)` focuses calibrated monostatic samples on a uniform planar aperture. It does not acquire signals, calibrate channels, or convert multistatic measurements.

## Inputs and output

| Argument | Meaning |
| --- | --- |
| `data` | Finite CPU single/double array, rows y × columns x × frequency. At least two samples on each axis. Complex data are supported. |
| `frequency` | `[startHz, slopeHzPerSecond, sampleRateHz, adcStartSeconds]`. First three positive; ADC start nonnegative. |
| `xStep_mm`, `yStep_mm` | Positive aperture spacing in millimeters. Columns/rows follow increasing physical x/y. |
| `zTarget_mm` | At least two positive, strictly increasing reconstruction depths in millimeters. |
| `nFFT` | Integer lateral FFT size, at least as large as each aperture dimension. |

Sample frequency is `startHz + adcStartSeconds*slope + sampleIndex*slope/sampleRateHz`, with sampleIndex starting at zero. Aperture coordinates are centered on the measurement grid, at `(index − (sampleCount−1)/2)*step` for a zero-based index.

The result is `nFFT × nFFT × depthCount` complex amplitudes and x/y/z coordinate vectors in millimeters. Display magnitude with `abs(volume)`; no absolute reflectivity calibration is applied. The function creates no figure and restores its temporary MATLAB path additions.

The work limit is `nFFT^2 * (frequencyCount + depthCount) <= 8e6`. This bounds array sizes, not total process memory: several complex arrays coexist, and MATLAB has its own overhead. Smaller FFT and depth grids reduce memory use.

## Physical coordinates

The opt-in mode uses discrete FFT bins rather than including both endpoints of the spatial-frequency interval. For an FFT of size N and spacing Δ in meters, the shifted bins are `2*pi/(N*Δ) * (j − floor(N/2))`, for j from 0 to N−1. Before the inverse transform, `ifftshift` restores the frequency ordering on the two lateral axes only.

If M measured samples are padded to N with P = floor((N−M)/2) zeros before them, output coordinate q is `(q − P − (M−1)/2)*Δ`. Each lateral axis uses its own measured length. Even-length apertures can place the origin between pixels. The physical mode does not mirror x.

The original seven-argument `reconstructSARimageFFT_3D` call keeps its previous bins, axis convention, x flip, and return units. In that legacy function the depth output is in meters despite its `_mm` variable name. The new facade converts depth to millimeters and selects physical mode explicitly. It supports volume reconstruction, not the legacy single-depth plotting branch.

## Synthetic example

`examples/point_targets.m` constructs two separate, phase-only point returns with `exp(i*4*pi*f*R/c)`, where R is the distance between each aperture location and its target. It uses a 65 × 65 aperture at 1 mm spacing, 64 frequencies from 77 to 80.78 GHz, a 128-point FFT, and depths 140:10:260 mm.

The grayscale PNG files are independently normalized magnitude slices at each target's depth, with increasing y displayed upward. Use the accompanying MAT file for coordinates and complex data, and CSV/JSON for peak measurements. The PNG intensity is not a calibrated signal strength or a cross-scene amplitude comparison.

For the observed results and remaining limits, see [verification](VERIFICATION.md).
