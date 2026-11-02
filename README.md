# BFSK, QPSK and 16-QAM: Modulation, Demodulation and BER Analysis

EE451 Communications term project (IYTE, Fall 2026).

We implement BFSK, QPSK and 16-QAM modulators/demodulators in MATLAB, simulate bit error rate (BER) over an AWGN channel, compare it with theoretical curves, and present everything in a MATLAB GUI. The same waveforms are then tested over the air with ADALM-Pluto SDRs.

## Repository layout

| Folder | Contents |
|---|---|
| `src/` | Modulation/demodulation functions, AWGN channel, BER simulation and theory |
| `gui/` | MATLAB App Designer GUI |
| `pluto/` | ADALM-Pluto SDR transmit/receive scripts |
| `results/` | BER plots, constellations, saved data |
| `docs/` | Proposal, report, presentation |

## Requirements

- MATLAB with Communications Toolbox
- Communications Toolbox Support Package for ADALM-PLUTO Radio (hardware part)

## Team

- Halil Yilmaz
- Emir Dündar
- Atlas Ferhan
