# Running the 16-QAM experiment

**16-QAM contribution: Emir Dündar ([@Dundarzade](https://github.com/Dundarzade)).**

Extract the ZIP to a folder, then open [`teslim/qam16_standalone.m`](teslim/qam16_standalone.m) in MATLAB and click **Run**. Alternatively, set `teslim/` as the MATLAB Current Folder and enter:

```matlab
qam16_standalone
```

The standalone file includes the GUI and the functions it needs. The legacy `qam16_tek_dosya.m` is retained as an English-text compatibility export. To use the modular project instead, keep `src/` and `gui/` together, set the repository root as the MATLAB Current Folder, and run:

```matlab
start_qam16
```

With 40,000 bits and 0/6/12 dB, press **Run**. The GUI shows BER, received 16-QAM points, error counts and the bit strip. Select a noise level using **Which experiment?**. The **I/Q and waveform** tab shows the amplitude levels and the real carrier signal.

The Communications Toolbox is not required. The modular GUI uses the shared modulator, demodulator and experiment functions in `src/`; keep the folder structure intact.

## Explaining the topic

- [Technical explanation and system diagrams](docs/qam16/README.md)
- [A 2–3 minute presentation and instructor questions](docs/qam16/sunum_notlari.md)
- [Recorded simulation results and plots](results/qam16/README.md)
- [English PDF summary and figures](teslim/16QAM_Summary_and_Figures.pdf)
- `docs/qam16/qam16_adim_adim.m`: examine three symbols step by step.

Every four bits select one I/Q point. For example, `1011` maps to `(3+j)/sqrt(10)`. The receiver recovers I/Q with cos and −sin correlators, then selects the nearest of −3, −1, +1 and +3 on each axis. Gray labels reduce the bit-error impact of nearest-neighbour decisions.

## Validation

```matlab
addpath('src','gui')
test_mod_demod
test_qam16
test_qam16_gui
run_qam16_analysis
```

The existing core tests, 16-QAM physical/numerical tests and real GUI callback tests passed in MATLAB R2026b Prerelease Update 1. Recovery from invalid bit counts and carrier settings, experiment selection and the zero-error upper bound were checked. Dark/light theme and I/Q tab screenshots are under `results/qam16/`.

The 0:2:14 dB sweep transmitted 2 million bits at each point. At 12 dB, 279 errors / 2 million bits = 0.0001395; the exact theory gives 0.0001387. At 14 dB there are only three errors, so that point is not a precise estimate. This is an ideally synchronised simulation; no ESP32 hardware BER has been measured.
