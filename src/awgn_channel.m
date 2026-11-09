function [r, N0] = awgn_channel(s, EbN0_dB, k, sps)
%AWGN_CHANNEL Add complex white Gaussian noise for a given Eb/N0.
%   [r, N0] = AWGN_CHANNEL(s, EbN0_dB, k, sps)
%     s       : transmitted complex baseband samples
%     EbN0_dB : Eb/N0 in dB
%     k       : bits per symbol (1 for BFSK, 2 for QPSK, 4 for 16-QAM)
%     sps     : samples per symbol (1 for QPSK/16-QAM here, e.g. 8 for BFSK)
%
%   Symbol energy is measured from the signal, Es = mean(|s|^2) * sps,
%   so Eb = Es/k and N0 = Eb / 10^(EbN0_dB/10). Each complex noise sample
%   has variance N0 (N0/2 per real dimension). With this convention a
%   correlator summed over sps samples sees the textbook Eb/N0.

    if nargin < 4, sps = 1; end
    Es = mean(abs(s(:)).^2) * sps;
    Eb = Es / k;
    N0 = Eb / 10^(EbN0_dB/10);
    noise = sqrt(N0/2) * (randn(size(s)) + 1j*randn(size(s)));
    r = s + noise;
end
