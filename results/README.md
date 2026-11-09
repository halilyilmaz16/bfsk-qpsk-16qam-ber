# results

BER plots, constellation figures and saved `.mat` data. Large raw SDR captures go in `results/captures/` and are git-ignored.

## Week 1 (AWGN simulation)

- `ber_awgn.png`: simulated BER (markers) vs theory (lines) for BFSK (noncoherent and coherent), QPSK and 16-QAM, Eb/N0 = 0 to 14 dB, at least 300 errors or 2·10⁶ bits per point.
- `constellations.png`: received QPSK and 16-QAM constellations and BFSK correlator outputs at Eb/N0 = 10 dB.

Running `src/run_ber_awgn.m` in MATLAB regenerates both figures and also saves `ber_awgn.mat`.
