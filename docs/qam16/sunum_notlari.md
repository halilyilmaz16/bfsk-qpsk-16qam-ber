# 16-QAM presentation notes

## A 2–3 minute explanation

**0:00–0:25 — Aim and constellation.** “In 16-QAM, every four bits select one symbol. The first two bits determine the I level and the last two determine the Q level. Four levels on each axis give 16 points. This lets us carry twice as many bits per symbol as QPSK.” Show the system diagram or the ideal points in the GUI.

**0:25–0:55 — One example.** “For `1011`, the I pair is `10` → +3 and the Q pair is `11` → +1. Our normalised point is $(3+j)/\sqrt{10}$, with amplitude 1 and phase about 18.4 degrees. The transmitter combines cos and −sin carriers using these coefficients. The analog wave changes in amplitude and phase.” Explain that the 16 points do not each have a distinct amplitude: there are three amplitude radii.

**0:55–1:25 — Channel and receiver.** “The AWGN channel adds Gaussian noise to the signal. The receiver recovers I and Q by correlating with cos and −sin over each symbol. On each axis we select the nearest of four levels; the raw thresholds are −2, 0 and +2. With Gray coding, horizontal and vertical neighbours differ in only one bit.”

**1:25–2:05 — Live demonstration.** Open [`../../teslim/qam16_standalone.m`](../../teslim/qam16_standalone.m) in MATLAB and click **Run** (or use `start_qam16` from the repository root with the modular files) and compare 0, 6 and 12 dB at the same bit count. “As noise decreases, the cloud tightens; points that cross a decision boundary cause errors.” Show the incorrect points, the error count in the table and the bit-error strip. Read BER as **incorrect bits / total bits**. For a run with no observed errors, say “We observed no errors in this run.”

**2:05–2:40 — Result and limitations.** Compare simulation with theory on the BER plot. “At the same bit rate, we halve the symbol rate compared with QPSK. The cost is a higher required $E_b/N_0$: at a theoretical BER of $10^{-3}$, the gap is about 3.7 dB. Phase and timing are known ideally here. The ESP32 part is still a plan; amplitude calibration and synchronisation must be implemented separately in hardware.”

Before presenting, run `addpath('src'); run_qam16_analysis`. Figures and numerical results are under [`../../results/qam16/`](../../results/qam16/); take the simulation counts from [`qam16_ber.csv`](../../results/qam16/qam16_ber.csv). Do not describe a result that has not been generated or inspected as a completed measurement. A printable English summary is available in [`16QAM_Summary_and_Figures.pdf`](../../teslim/16QAM_Summary_and_Figures.pdf).

## What do the code blocks do?

The teaching script [`qam16_adim_adim.m`](qam16_adim_adim.m) provides a detailed view of three symbols. Twelve bits are insufficient for a reliable BER estimate. The GUI experiment [`qam16_experiment.m`](../../src/qam16_experiment.m) uses the shared [`qam16_mod.m`](../../src/qam16_mod.m) and [`qam16_demod.m`](../../src/qam16_demod.m) functions.

### 1. Grouping four bits and Gray mapping

```matlab
bp = reshape(bits, 4, []);
lut = [-3 -1 3 1];
I_raw = lut(2*bp(1,:) + bp(2,:) + 1);
Q_raw = lut(2*bp(3,:) + bp(4,:) + 1);
```

Each column is one symbol. The index order is `00, 01, 10, 11`, which is why the LUT is `[-3 -1 3 1]`. When the levels are arranged from left to right, their Gray labels are `00, 01, 11, 10`. Dividing I and Q by $\sqrt{10}$ makes the average complex symbol energy 1.

### 2. Real carrier and noise

```matlab
s = aI*cos(2*pi*fc*t) - aQ*sin(2*pi*fc*t);
Es = Ts/2;
Eb = Es/4;
N0 = Eb/10^(EbN0_dB/10);
sigma = sqrt(N0*fs/2);
r = s + sigma*randn(size(s));
```

This block summarises the carrier model for one symbol. Having $\mathbb{E}|a|^2=1$ for complex symbols does not mean the physical waveform here has $E_s=1$: the cos/sin carrier energy gives an average of $E_s=T_s/2$. `sigma` is the noise standard deviation of a real carrier sample; its variance is `N0*fs/2`.

### 3. Correlators and decisions

```matlab
zI = (2/Ts)*sum(r_m.*cI)/fs;
zQ = (2/Ts)*sum(r_m.*cQ)/fs;
xI = sqrt(10)*zI;
xQ = sqrt(10)*zQ;
b_hat = [xI > 0; abs(xI) < 2; xQ > 0; abs(xQ) < 2];
```

`sum(...)/fs` approximates the integral. `2/Ts` compensates for the carrier energy; `sqrt(10)` restores the raw 4-PAM levels. The first bit comes from the sign, and the second from the inner/outer level. The Q branch does the same for the other two bits. These rules assume ideal knowledge of phase and symbol boundaries.

### 4. Counting errors

```matlab
BER = sum(bits_hat ~= bits)/numel(bits);
symbolErrors = any(reshape(bits_hat ~= bits, 4, []), 1);
SER = mean(symbolErrors);
```

BER counts bits; SER counts symbols. If three bits are wrong in one symbol, add 3 to the BER numerator and 1 to the SER numerator. The two vectors must have the same orientation and ordering; the teaching script uses row vectors, while the shared modem functions use column vectors.

## Questions the instructor may ask

| Question | Short answer |
|---|---|
| Why $\sqrt{10}$? | Each raw axis has mean square 5; I and Q together give 10. Dividing the amplitude by $\sqrt{10}$ makes the average squared magnitude 1. The points do not all have the same energy. |
| Are there 16 distinct amplitudes? | No. The 4×4 combinations of I and Q create 16 points; three radii combine with different phases. |
| Why does the Q branch use −sin? | $\operatorname{Re}\{(a_I+ja_Q)e^{j2\pi f_ct}\}=a_I\cos-a_Q\sin$. The receiver uses the same sign convention. |
| Does Gray coding reduce noise? | It changes neither the noise nor the point spacing. A nearest-neighbour symbol error usually becomes a single bit error. At low SNR, errors to more distant points also occur. |
| Is BER equal to SER/4? | Not in general. One symbol error can cause 1–4 bit errors. At high SNR, if single-bit nearest-neighbour errors dominate with Gray mapping, BER ≈ SER/4. |
| What is the exact BER formula? | For $u=\sqrt{0{,}8E_b/N_0}$, it is $[3Q(u)+2Q(3u)-Q(5u)]/4$. $0{,}75Q(u)$ is only the high-SNR approximation. |
| Why does the noise variance contain $F_s/2$? | Real AWGN has two-sided density $N_0/2$. The sample variance is $N_0F_s/2$; the receiver's $1/F_s$ integration scaling balances the sampling-rate effect. |
| If $E_s=1$, why does the code use 0.5? | The value 1 is the average squared magnitude of the complex symbols. With the real cos/sin carriers used here, waveform energy is $T_s/2$, or 0.5 for $T_s=1$. |
| Why must $f_cT_s$ be an integer? | The experiment uses complete carrier periods in every symbol to make the sampled cos and −sin carriers orthogonal. $F_sT_s$ must also be an integer. |
| What if phase or timing drifts? | The I/Q points may rotate or neighbouring symbols may mix, causing incorrect decisions at fixed thresholds. Carrier and timing are known ideally in this experiment; there is no recovery algorithm. |
| What is the advantage over QPSK? | 16-QAM carries 4 bits/symbol; QPSK carries 2. At the same bit rate, 16-QAM halves the symbol rate. With the same pulse shaping, this narrows the bandwidth, but a higher $E_b/N_0$ is needed for the same BER. |
| Is the gap always 4 dB? | No. At a theoretical BER of $10^{-3}$, the requirements are about 6.8 and 10.5 dB, a gap of about 3.7 dB. The gap depends on the target BER. |
| We saw zero errors at 12 dB; is BER zero? | No errors were observed in this bit sequence. This does not prove a zero true error probability; a longer run is needed. For zero errors in $N_s$ independent symbols, the 95% SER upper bound is $1-0{,}05^{1/N_s}$. Since BER ≤ SER, it can also serve as a conservative BER bound. |
| Have you measured it on ESP32 too? | Not yet; the hardware is a draft plan. Amplitude/DC calibration, phase/timing and the ADC sampling method need separate validation. The classic ESP32's IDF v5.5.1 continuous ADC has a 20 kHz lower limit, so the planned 8 kHz cannot be treated as directly implemented. |

The assumptions behind the formulas and the official sources are explained in the [technical README](README.md): [MathWorks analytical BER](https://www.mathworks.com/help/comm/ug/analytical-expressions-used-in-berawgn-function-and-bit-error-rate-analysis-app.html), [MathWorks AWGN scaling](https://www.mathworks.com/help/comm/ref/awgnchannel.html), and [Espressif ESP32 IDF v5.5.1 ADC limit](https://github.com/espressif/esp-idf/blob/v5.5.1/components/soc/esp32/include/soc/soc_caps.h).
