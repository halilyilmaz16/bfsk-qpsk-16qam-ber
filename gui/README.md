# gui

## `qam16_gui.m` – 16-QAM BER experiment

Run `start_qam16` from the project root, or `qam16_gui` from this folder. The GUI uses the shared modulator, receiver, theory and real-carrier experiment functions in `../src/`; preserve the folder structure. For a self-contained English version, open [`../teslim/qam16_standalone.m`](../teslim/qam16_standalone.m) in MATLAB and click **Run**, or set `teslim/` as the Current Folder and enter `qam16_standalone`. The compatibility export `qam16_tek_dosya.m` also uses English text.

- 40,000 bits and three Eb/N0 levels: 0, 6 and 12 dB. The bit count must be a multiple of 4.
- Theoretical and measured BER; received symbols and Gray decision thresholds; a BER/SER table; an error strip for the first 200 bits.
- Second tab: I/Q level distributions and the transmitter/channel waveforms for the first four symbols.
- Each dB point uses the same bits and common standard noise samples. Change the seed to run a different experiment.
- With zero observed errors, the GUI does not claim an exact BER of 0; it shows a conservative 95% upper bound calculated from independent symbols.

Default signal: Ts=1 s, fs=100 Hz, fc=4 Hz. This is an ideally synchronised simulation. `fs*Ts` must be an integer from 8 to 100,000, `fc*Ts` must be a positive integer, and `fs>2*fc` is required. Block processing limits memory use; the GUI caps the total sample count at 20 million to limit processing time.

[Technical explanation and usage](../docs/qam16/README.md) · [Result plots](../results/qam16/README.md) · [English PDF summary](../teslim/16QAM_Summary_and_Figures.pdf)

```matlab
% Reproducible automated experiment and screenshot export:
f = qam16_gui(struct('Visible','off','AutoRun',true, ...
    'ExportDir',fullfile(pwd,'..','results','qam16')));
data = getappdata(f,'QAM16Results');
close(f)
```

## `ber_gui.m` – BFSK BER experiment

```matlab
>> ber_gui
```

This file runs BFSK on its own and needs no other files. For 16-QAM, use `qam16_gui.m` above; for QPSK, use the step-by-step script.

1. **Bit count:** for example, 1000 (maximum 100,000).
2. **Three Eb/N0 values (dB):** noise levels. Higher dB means less noise. Defaults: 0, 4 and 8.
3. **Signal settings:** Tb (bit duration, default 1 s) and fs (sampling frequency, default 100 Hz). The line below shows the number of samples per bit and whether the tones are orthogonal.
4. **Run the experiment.**

At each Eb/N0, random bits pass through this chain: BFSK transmitter → AWGN channel → correlator receiver. The bits incorrectly estimated by the receiver are counted.

| Output | What it shows |
|---|---|
| BER curve | The line is theoretical BER: $Q(\sqrt{E_b/N_0})$. The points are measured simulation values, annotated with “incorrect/transmitted”. A downward triangle marks a run with no errors. |
| Why does the receiver make errors? | A histogram of the decision variable $d = z_1 - z_2$. Correctly decoded 1s cluster around $+E_b$ in blue; correctly decoded 0s cluster around $-E_b$ in orange. Bits on the wrong side of the threshold (0) are **red**: these are the receiver's errors. |
| Table | Transmitted bits, incorrect bits, measured BER and theoretical BER. The interpretation column expresses the result in plain language, such as “about 1 error in every 18 bits”. |
| Where are the errors? | The first 200 bits appear in one strip: correct decisions in green, incorrect decisions in red. |

The experiment selector chooses which Eb/N0 is shown in the histogram and bit strip.

The transmitter, channel and receiver are the same as in `docs/bfsk/bfsk_adim_adim.m` ($f_1 = 9$ Hz, $f_2 = 3$ Hz, coherent correlator). The default $f_s = 100$ Hz is lower than the script's 1000 Hz. This speeds up the simulation while remaining sufficient for the 9 Hz tone.

**Experimenting with Tb and fs:** changing Tb or fs does not change BER when orthogonality is preserved, because Eb/N0 determines the result. For example, with Tb = 0.5 s or fs = 40 Hz, the points still follow the theoretical curve. The exception is when $(f_1 \pm f_2)T_b$ is not an integer: the two tones are then nonorthogonal, and the warning displays their similarity coefficient $\rho$. The theoretical curve is not exact in this case. For example, with Tb = 0.25 s, BER is slightly worse than theory.
