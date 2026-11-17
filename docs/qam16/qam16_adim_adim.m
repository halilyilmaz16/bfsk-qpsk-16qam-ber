%% 16-QAM: STEP BY STEP FROM TRANSMITTER TO RECEIVER
% EE451 term project - 16-QAM modulation, AWGN channel and correlation receiver
%
% Chain:   bits -> (1) S/P + Gray 4-PAM mapping + I/Q carriers -> (2) AWGN channel
%          -> (3-4) two correlators -> (5) 4-level slicer + P/S -> (6) result
%
% Each section (%%) can be run separately (Ctrl+Enter). Run sections in order,
% because each section uses variables defined by the preceding sections.
% Diagram: docs/qam16/qam16_sistem.svg

clear; clc; close all;

%% 0) PARAMETERS
Nbits   = 12;       % In 16-QAM, 4 bits = 1 symbol; the bit count must be a multiple of 4.
                    % 10 bits do not divide by 4 (2.5 symbols), so use 12 bits = 3 symbols.
k       = 4;        % bits per symbol
Nsym    = Nbits/k;  % symbol count -> 3
Ts      = 1;        % symbol duration [s]  (bit duration Tb = Ts/k = 0.25 s)
fs      = 1000;     % sampling frequency [Hz]
fc      = 4;        % carrier frequency [Hz]; integer fc*Ts -> orthogonal cos and sin
EbN0_dB = 12;       % 16-QAM points are close together; QPSK's 5 dB produces many errors.
                    % Reduce this to 5 and compare the constellation diagram.

% rng(1);           % uncomment to reproduce the same bits and noise on every run
bits = randi([0 1], 1, Nbits);

%% 1) TRANSMITTER
% 1a) S/P: group bits in fours, [b1 b2 b3 b4]
%     b1 b2 -> I-axis LEVEL,  b3 b4 -> Q-axis level
bp = reshape(bits, k, Nsym);     % 4 x 3: each column is one symbol

% 1b) Gray-coded 4-PAM, independently for each axis:
%     G(00) = -3,  G(01) = -1,  G(11) = +1,  G(10) = +3
%     Adjacent levels differ by one bit (for example, 01 and 11).
%     Index lut with 2*bA + bB + 1:  00 -> 1, 01 -> 2, 10 -> 3, 11 -> 4
lut = [-3 -1 3 1];
I_raw = lut(2*bp(1,:) + bp(2,:) + 1);    % -3, -1, +1, +3
Q_raw = lut(2*bp(3,:) + bp(4,:) + 1);

% Mean energy of the raw points: E[I^2] + E[Q^2] = 5 + 5 = 10
% (because (1 + 9)/2 = 5). Divide by sqrt(10) to obtain mean |a|^2 = 1.
aI = I_raw/sqrt(10);
aQ = Q_raw/sqrt(10);

% 1c) Carriers:  s(t) = aI*cos(2*pi*fc*t) - aQ*sin(2*pi*fc*t)
t_sym = 0:1/fs:Ts-1/fs;
N     = length(t_sym);
cI    =  cos(2*pi*fc*t_sym);
cQ    = -sin(2*pi*fc*t_sym);

s = zeros(1, Nsym*N);
for m = 1:Nsym
    idx    = (m-1)*N + (1:N);
    s(idx) = aI(m)*cI + aQ(m)*cQ;
end
t = (0:length(s)-1)/fs;

% ---- Figure 1a: bits -> levels ----
figure('Name', '1a - S/P and Gray 4-PAM');
ax = gobjects(3,1);
Tb = Ts/k;
ax(1) = subplot(3,1,1);
stem((0:Nbits-1)*Tb + Tb/2, bits, 'filled', 'LineWidth', 1.5);
for m = 1:Nsym
    text((m-1)*Ts + Ts/2, 1.35, sprintf('[%d%d | %d%d]', bp(:,m)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end
ylim([-0.2 1.6]); grid on; ylabel('bit');
title('Bits grouped in fours: [I bits | Q bits]');

ax(2) = subplot(3,1,2);
stairs([(0:Nsym-1)*Ts, Nsym*Ts], [I_raw I_raw(end)], 'LineWidth', 2);
ylim([-4 4]); yticks(-3:2:3); yline(0, 'k-', 'HandleVisibility', 'off'); grid on;
ylabel('\surd10 a_I'); title('I level: G(b_1b_2) \in \{-3, -1, +1, +3\}');

ax(3) = subplot(3,1,3);
stairs([(0:Nsym-1)*Ts, Nsym*Ts], [Q_raw Q_raw(end)], 'LineWidth', 2);
ylim([-4 4]); yticks(-3:2:3); yline(0, 'k-', 'HandleVisibility', 'off'); grid on;
ylabel('\surd10 a_Q'); xlabel('t (s)'); title('Q level: G(b_3b_4)');

for i = 1:3
    for m = 1:Nsym-1
        xline(ax(i), m*Ts, ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
    end
end
linkaxes(ax, 'x'); xlim([0 Nsym*Ts]);

% ---- Figure 1b: 16-QAM signal ----
figure('Name', '1b - 16-QAM signal');
plot(t, s, 'r'); grid on;
for m = 1:Nsym-1
    xline(m*Ts, ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
end
xlabel('t (s)'); ylabel('Amplitude');
title('s(t) = a_I cos - a_Q sin   (amplitude and phase change with each symbol)');

% ---- Figure 1c: constellation diagram ----
figure('Name', '1c - 16-QAM constellation');
hold on; grid on; axis equal;
gray2 = {'00', '01', '10', '11'};
for gI = 0:3                     % 16 ideal points and their 4-bit labels
    for gQ = 0:3
        px = lut(gI+1)/sqrt(10);  py = lut(gQ+1)/sqrt(10);
        plot(px, py, 'o', 'MarkerSize', 8, 'Color', [0.6 0.6 0.6], 'HandleVisibility', 'off');
        text(px, py+0.1, [gray2{gI+1} gray2{gQ+1}], 'HorizontalAlignment', 'center', 'FontSize', 8);
    end
end
plot(aI, aQ, 'r.', 'MarkerSize', 25);
for m = 1:Nsym
    text(aI(m)+0.05, aQ(m)-0.08, sprintf('s%d', m), 'Color', 'r');
end
xline(0, 'k-', 'HandleVisibility', 'off'); yline(0, 'k-', 'HandleVisibility', 'off');
xlim([-1.3 1.3]); ylim([-1.3 1.3]);
xlabel('I'); ylabel('Q'); title('Transmitted symbols (red) and Gray labels (b_1b_2b_3b_4)');

%% 2) CHANNEL: AWGN
% Es = mean |a|^2 * Ts/2 = Ts/2,  Eb = Es/k = Es/4
% N0 = Eb/10^(EbN0_dB/10),  per-sample sigma = sqrt(N0*fs/2)
Es    = sum(cI.^2)/fs;           % = Ts/2 = 0.5
Eb    = Es/k;
N0    = Eb / 10^(EbN0_dB/10);
sigma = sqrt(N0*fs/2);

n = sigma * randn(1, length(s));
r = s + n;

figure('Name', '2 - Channel');
subplot(2,1,1); plot(t, s); grid on; title('Transmitted s(t)');
subplot(2,1,2); plot(t, r); grid on; xlabel('t (s)');
title(sprintf('Received r(t) = s(t) + n(t),   E_b/N_0 = %g dB', EbN0_dB));

%% 3) RECEIVER - inspect one symbol closely
% The correlators are identical to those used for QPSK:
%     zI = (2/Ts) * integral r*cos dt  = aI + nI
%     zQ = (2/Ts) * integral r*(-sin) dt = aQ + nQ
% The decision stage differs: there are 4 levels here instead of 2.
m_incele = 1;
idx  = (m_incele-1)*N + (1:N);
r_m  = r(idx);
intI = (2/Ts) * cumsum(r_m .* cI)/fs;
intQ = (2/Ts) * cumsum(r_m .* cQ)/fs;

figure('Name', sprintf('3 - Correlators, symbol %d', m_incele));
subplot(2,1,1);
plot(t_sym, r_m); hold on; plot(t_sym, cI, '--'); plot(t_sym, cQ, ':');
legend('r(t)', 'cos', '-sin', 'Location', 'eastoutside'); grid on;
title(sprintf('Symbol %d, bits [%d%d | %d%d]', m_incele, bp(:,m_incele)));

subplot(2,1,2);
plot(t_sym, sqrt(10)*intI, 'LineWidth', 1.5); hold on;
plot(t_sym, sqrt(10)*intQ, 'LineWidth', 1.5);
for lv = [-2 0 2]                % decision thresholds
    yline(lv, 'k:', 'HandleVisibility', 'off');
end
legend('\surd10 z_I', '\surd10 z_Q', 'Location', 'eastoutside');
title(sprintf('Running integral (\\surd10 scale): final %.2f (target %d) and %.2f (target %d)', ...
    sqrt(10)*intI(end), I_raw(m_incele), sqrt(10)*intQ(end), Q_raw(m_incele)));
xlabel('t (s)'); grid on; ylim([-4.5 4.5]);

%% 4) RECEIVER - all symbols
zI = zeros(1, Nsym);
zQ = zeros(1, Nsym);
for m = 1:Nsym
    idx   = (m-1)*N + (1:N);
    r_m   = r(idx);
    zI(m) = (2/Ts) * sum(r_m .* cI)/fs;
    zQ(m) = (2/Ts) * sum(r_m .* cQ)/fs;
end

figure('Name', '4 - Received symbols');
hold on; grid on; axis equal;
[GI, GQ] = meshgrid(lut/sqrt(10));
plot(GI(:), GQ(:), 'ko', 'MarkerSize', 8, 'LineWidth', 1.2);
plot(zI, zQ, 'r.', 'MarkerSize', 25);
for m = 1:Nsym
    plot([aI(m) zI(m)], [aQ(m) zQ(m)], 'r:', 'HandleVisibility', 'off');
    text(zI(m)+0.05, zQ(m), sprintf('%d', m), 'Color', 'r');
end
for th = [-2 0 2]/sqrt(10)       % decision boundaries: -2, 0, +2 on each axis (scaled)
    xline(th, 'b-', 'HandleVisibility', 'off');
    yline(th, 'b-', 'HandleVisibility', 'off');
end
legend('Ideal points', 'Received (z_I, z_Q)', 'Location', 'eastoutside');
xlabel('z_I'); ylabel('z_Q');
title('Received symbols; blue lines mark decision boundaries (16 squares)');

%% 5) DECISION (4-PAM slicer) + P/S
% Undo the scaling: x = sqrt(10)*z -> one of -3, -1, +1, +3 in the noiseless case.
% Nearest-level decisions use thresholds -2, 0, +2. Invert the Gray table:
%     1st bit (b1 or b3) = x > 0          (right half -> 1)
%     2nd bit (b2 or b4) = |x| < 2        (inner levels +/-1 -> 1)
xI = sqrt(10)*zI;
xQ = sqrt(10)*zQ;
b_hat = [xI > 0; abs(xI) < 2; xQ > 0; abs(xQ) < 2];   % 4 x Nsym
bits_hat = double(reshape(b_hat, 1, []));              % P/S

%% 6) RESULT
hata_idx = find(bits_hat ~= bits);
hata     = numel(hata_idx);

fprintf('\nEb/N0 = %g dB,  Es = %.3f,  Eb = %.3f,  N0 = %.4f\n\n', EbN0_dB, Es, Eb, N0);
fprintf(' symbol | transmitted| I  Q (raw) |  xI     xQ   | decision\n');
fprintf('--------+------------+------------+--------------+------\n');
for m = 1:Nsym
    isaret = ' ';   % keep one space: fprintf skips an empty argument and drops the newline
    if any(b_hat(:,m)' ~= bp(:,m)'), isaret = '  <- ERROR'; end
    fprintf('   %2d   |    %d%d%d%d    |  %+d  %+d   | %5.2f  %5.2f |  %d%d%d%d%s\n', ...
        m, bp(:,m), I_raw(m), Q_raw(m), xI(m), xQ(m), b_hat(:,m), isaret);
end
fprintf('\nBit errors: %d / %d\n', hata, Nbits);

figure('Name', '6 - Result');
stem(1:Nbits, bits, 'filled', 'LineWidth', 1.5); hold on;
stem(1:Nbits, bits_hat, 'r--');
if hata > 0
    plot(hata_idx, bits_hat(hata_idx), 'ro', 'MarkerSize', 12, 'LineWidth', 1.5);
end
ylim([-0.2 1.3]); xlim([0.5 Nbits+0.5]); grid on;
xlabel('Bit index'); ylabel('bit');
legend('Transmitted', 'Estimated', 'Location', 'eastoutside');
title(sprintf('Transmitted and estimated bits: %d errors', hata));

% Next step: BER curve. Theory (Gray, exact):
%     u  = sqrt(4/5 * Eb/N0)
%     Pb = 1/4 * (3*Q(u) + 2*Q(3u) - Q(5u)),   Q(x) = 0.5*erfc(x/sqrt(2))
