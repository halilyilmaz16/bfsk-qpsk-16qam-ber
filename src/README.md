# src

## 16-QAM real-carrier experiment

`qam16_experiment.m` uses the existing `qam16_mod`/`qam16_demod` functions to generate a real cos/−sin waveform, add AWGN and decode it with two correlators. `test_qam16` checks the mapping, energy, noise variance, theoretical BER and invariance to sampling rate. `run_qam16_analysis` generates 0:2:14 dB results as CSV/MAT/PNG files under `../results/qam16/`. From the project root, `start_qam16` opens the interactive GUI. For its self-contained English version, open [`../teslim/qam16_standalone.m`](../teslim/qam16_standalone.m) in MATLAB and click **Run**, or enter `qam16_standalone` with `teslim/` as the Current Folder. See the [English PDF summary and figures](../teslim/16QAM_Summary_and_Figures.pdf).

MATLAB core functions (WP2 mod/demod + WP3 AWGN BER). Written from first principles: no Communications Toolbox functions are needed to run them (the toolbox is only used, if present, to cross-check the theory in `test_mod_demod.m`).

| File | What it does |
|---|---|
| `bfsk_mod.m`, `bfsk_demod.m` | BFSK, complex baseband, `sps` samples/bit, tones at ±1/(2T) (orthogonal). Demod: correlator bank, noncoherent (default) or coherent |
| `qpsk_mod.m`, `qpsk_demod.m` | Gray QPSK, Es = 1, sign decisions on I and Q |
| `qam16_mod.m`, `qam16_demod.m` | Gray square 16-QAM, Es = 1, per-axis 4-PAM slicing (thresholds −2, 0, +2 before scaling) |
| `awgn_channel.m` | Adds complex AWGN for a given Eb/N0, k and samples per symbol |
| `scheme_handles.m` | Returns mod/demod handles, bits/symbol and sps for a scheme name (shared by sim and GUI) |
| `ber_sim.m` | Monte Carlo BER vs Eb/N0 (stops at `minErrors` errors or `maxBits` bits) |
| `ber_theory.m` | Closed-form BER: noncoherent/coherent BFSK, QPSK, 16-QAM (exact Gray) |
| `test_mod_demod.m` | Sanity tests: noiseless round trip, Es = 1, Gray mapping, BFSK orthogonality |
| `run_ber_awgn.m` | Main script: BER plot (sim vs theory), constellations, Eb/N0 needed for BER = 1e-3 |

## Usage

```matlab
cd src
test_mod_demod     % all tests should PASS
run_ber_awgn       % writes ../results/ber_awgn.png, constellations.png, ber_awgn.mat
```

Scheme names: `'bfsk'` (noncoherent), `'bfsk_coh'`, `'qpsk'`, `'qam16'`.

## Theory used

With γ = Eb/N0 and Q(x) = ½·erfc(x/√2):

- BFSK noncoherent: Pb = ½·exp(−γ/2)
- BFSK coherent (orthogonal): Pb = Q(√γ)
- QPSK (Gray): Pb = Q(√(2γ))
- 16-QAM (Gray, exact): Pb = ¼·[3Q(x) + 2Q(3x) − Q(5x)], x = √(4γ/5)

## Week 1 result

Eb/N0 needed for BER = 10⁻³ (theory, matches simulation):

| Scheme | Eb/N0 | bits/symbol |
|---|---|---|
| QPSK | 6.8 dB | 2 |
| BFSK coherent | 9.8 dB | 1 |
| 16-QAM | 10.5224 dB (exact inversion) | 4 |
| BFSK noncoherent | 11.0 dB | 1 |
