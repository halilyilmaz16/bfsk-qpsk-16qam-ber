%RUN_BER_AWGN Week 1 main script: simulated vs theoretical BER over AWGN.
%   Run from the src folder:  >> run_ber_awgn
%   - Monte Carlo BER for BFSK (noncoherent and coherent), QPSK, 16-QAM
%   - Theoretical curves from ber_theory.m on the same axes
%   - Received constellations at a fixed Eb/N0
%   - Required Eb/N0 for BER = 1e-3 (power-bandwidth trade-off table)
%   Figures and data are saved to ../results/.

clear; clc; close all;
rng(2026);

EbN0_dB  = 0:1:14;
EbN0_fine = 0:0.1:16;
opts = struct('minErrors', 300, 'maxBits', 2e6, 'blockBits', 2e4, 'sps', 8);

schemes = {'bfsk',             'bfsk_coh',        'qpsk',  'qam16'};
names   = {'BFSK (noncoherent)', 'BFSK (coherent)', 'QPSK', '16-QAM'};
colors  = [0.85 0.33 0.10; 0.93 0.69 0.13; 0.00 0.45 0.74; 0.47 0.67 0.19];

resultsDir = fullfile('..', 'results');
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end

%% BER simulation
ber = zeros(numel(schemes), numel(EbN0_dB));
tic;
for i = 1:numel(schemes)
    ber(i,:) = ber_sim(schemes{i}, EbN0_dB, opts);
    fprintf('%-20s done (%.1f s)\n', names{i}, toc);
end

%% BER plot: simulation (markers) vs theory (lines)
f1 = figure('Name', 'BER vs Eb/N0', 'Color', 'w');
for i = 1:numel(schemes)
    semilogy(EbN0_fine, ber_theory(schemes{i}, EbN0_fine), '-', ...
             'Color', colors(i,:), 'LineWidth', 1.4); hold on;
end
for i = 1:numel(schemes)
    v = ber(i,:) > 0;                       % log axis: skip zero-error points
    semilogy(EbN0_dB(v), ber(i,v), 'o', 'Color', colors(i,:), ...
             'MarkerFaceColor', colors(i,:), 'MarkerSize', 5);
end
grid on; ylim([1e-6 1]); xlim([EbN0_dB(1) EbN0_dB(end)]);
xlabel('E_b/N_0 (dB)'); ylabel('Bit error rate');
title('BER over AWGN: simulation (markers) vs theory (lines)');
legend(names, 'Location', 'southwest');
print(f1, fullfile(resultsDir, 'ber_awgn.png'), '-dpng', '-r150');

%% Constellations at a fixed Eb/N0
EbN0_const = 10;
nSym = 2000;
f2 = figure('Name', 'Constellations', 'Color', 'w');
plotSchemes = {'qpsk', 'qam16'};
plotNames   = {'QPSK', '16-QAM'};
for i = 1:2
    [modf, ~, k, sps] = scheme_handles(plotSchemes{i});
    s = modf(randi([0 1], k*nSym, 1));
    r = awgn_channel(s, EbN0_const, k, sps);
    subplot(1, 3, i);
    plot(real(r), imag(r), '.', 'Color', [0.6 0.6 0.6], 'MarkerSize', 3); hold on;
    plot(real(s), imag(s), 'r+', 'MarkerSize', 10, 'LineWidth', 1.5);
    axis equal; grid on; xlim([-1.6 1.6]); ylim([-1.6 1.6]);
    title(sprintf('%s, E_b/N_0 = %d dB', plotNames{i}, EbN0_const));
    xlabel('I'); ylabel('Q');
end
% BFSK: correlator outputs (|z0|, |z1|) instead of an I/Q constellation
sps = opts.sps;
b = randi([0 1], nSym, 1);
r = awgn_channel(bfsk_mod(b, sps), EbN0_const, 1, sps);
R = reshape(r, sps, []);
n = (0:sps-1).';
z0 = abs(exp(-1j*pi*n/sps)' * R) / sps;
z1 = abs(exp( 1j*pi*n/sps)' * R) / sps;
subplot(1, 3, 3);
plot(z0(b==0), z1(b==0), '.', 'MarkerSize', 4); hold on;
plot(z0(b==1), z1(b==1), '.', 'MarkerSize', 4);
plot([0 2], [0 2], 'k--');
axis equal; grid on; xlim([0 2]); ylim([0 2]);
xlabel('|z_0|'); ylabel('|z_1|');
title(sprintf('BFSK correlators, E_b/N_0 = %d dB', EbN0_const));
legend('bit 0', 'bit 1', 'decision line', 'Location', 'northeast');
print(f2, fullfile(resultsDir, 'constellations.png'), '-dpng', '-r150');

%% Required Eb/N0 for BER = 1e-3 (from theory) and spectral efficiency
target = 1e-3;
bitsPerSym = [1 1 2 4];
fprintf('\nEb/N0 needed for BER = %.0e (theory) and bits/symbol:\n', target);
req = zeros(1, numel(schemes));
for i = 1:numel(schemes)
    pb = ber_theory(schemes{i}, EbN0_fine);
    req(i) = EbN0_fine(find(pb <= target, 1, 'first'));
    fprintf('  %-20s %5.1f dB   %d bit/symbol\n', names{i}, req(i), bitsPerSym(i));
end

%% Save data
save(fullfile(resultsDir, 'ber_awgn.mat'), 'EbN0_dB', 'ber', 'schemes', 'names', 'opts', 'req');
fprintf('\nSaved figures and data to %s\n', resultsDir);
