# Digital Communication System Simulation Using MATLAB

A complex-baseband simulation of BPSK and Gray-coded QPSK
transmission over an Additive White Gaussian Noise (AWGN) channel.

## Features

- BPSK modulation and demodulation
- Gray-coded QPSK modulation and demodulation
- Complex AWGN channel
- BER estimation across Eb/N0 values
- Comparison with theoretical BER
- Transmitted and received constellation diagrams
- Separate theoretical comparison at equal Es/N0
- CSV and MAT result exports
- Reproducible random seed
- Built-in noiseless round-trip and energy checks

## Requirements

- MATLAB
- No Communications Toolbox calls are used

Tested MATLAB version: Not yet recorded.

## Quick Start

From the repository root:

```matlab
addpath('src');
results = digital_communication_simulation();
```

Inspect the summary:

```matlab
disp(results.summary);
```

## Default Configuration

| Parameter | Value |
|---|---|
| Eb/N0 range | 0 to 10 dB |
| Symbol energy | 1 |
| Target errors per point | 400 |
| Maximum bits per point | 2,000,000 |
| Batch size | 100,000 bits |
| Constellation Eb/N0 | 6 dB |
| Random seed | 42 |

Edit the configuration section of the main function to change
these settings.

## Outputs

Generated files are stored in `results/`:

- `ber_summary.csv`
- `simulation_results.mat`
- `ber_comparison.png`
- `constellations.png`
- `equal_symbol_energy_theory.png`

## Comparison Convention

The simulated BER comparison uses equal Eb/N0.

A separate theory-only plot uses equal Es/N0.

Do not describe these quantities interchangeably as “SNR.”

## Statistical Interpretation

The simulator stops each BER point after reaching the target
error count or maximum bit count.

Sample counts can differ between modulation schemes and between
Eb/N0 values.

Zero observed errors do not establish zero true BER.

For zero-error points, the CSV includes a one-sided 95% upper
limit, and the BER plot shows that limit with a downward triangle.

The upper-limit columns are NaN when errors were observed.
They are not general confidence intervals for every point.

## Validation

Before simulation, the program checks:

- Noiseless bit recovery for both modulation schemes
- Unit-energy symbol normalization

These checks do not replace an independent validation test suite.

## Limitations

- Perfect carrier phase and timing
- One complex sample per symbol
- No pulse shaping or oversampling
- No channel coding
- No fading or multipath
- No synchronization errors
- No RF hardware impairments
- Finite Monte Carlo sample size
- Adaptive error-count stopping; reported BER is an estimate

## Results Status
<img width="791" height="537" alt="WhatsApp Image 2026-11-22 at 6 23 12 AM" src="https://github.com/user-attachments/assets/1b1ec016-64e2-44f5-b747-9bba6fb77099" />
<img width="799" height="537" alt="WhatsApp Image 2026-11-22 at 6 23 12 AM (5)" src="https://github.com/user-attachments/assets/1aa761b2-1652-4894-98e2-9cf0913b1b93" />
<img width="312" height="261" alt="WhatsApp Image 2026-11-22 at 6 23 12 AM (4)" src="https://github.com/user-attachments/assets/7288200a-6c9d-48bb-baee-9f884aee4aa1" />
<img width="278" height="256" alt="WhatsApp Image 2026-11-22 at 6 23 12 AM (3)" src="https://github.com/user-attachments/assets/4c6e84ed-54e6-4c79-83f5-411fcc2c647c" />
<img width="311" height="261" alt="WhatsApp Image 2026-11-22 at 6 23 12 AM (2)" src="https://github.com/user-attachments/assets/8551b68d-901a-4ea9-a013-d3c778ec4bac" />
<img width="278" height="256" alt="WhatsApp Image 2026-11-22 at 6 23 12 AM (1)" src="https://github.com/user-attachments/assets/898810f9-738d-4848-8b15-462dd8a0022d" />

## Reference

MathWorks, “Analytical Expressions Used in berawgn Function and
Bit Error Rate Analysis App,” BPSK and QPSK sections.
