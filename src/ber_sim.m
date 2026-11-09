function [ber, nErr, nBits] = ber_sim(scheme, EbN0_dB, opts)
%BER_SIM Monte Carlo BER vs Eb/N0 over AWGN for our own mod/demod code.
%   [ber, nErr, nBits] = BER_SIM(scheme, EbN0_dB, opts)
%     scheme  : 'bfsk', 'bfsk_coh', 'qpsk' or 'qam16'
%     EbN0_dB : vector of Eb/N0 points in dB
%     opts    : optional struct with fields
%        .minErrors  stop a point after this many bit errors (default 200)
%        .maxBits    ...or after this many bits             (default 2e6)
%        .blockBits  bits generated per loop iteration      (default 1e4)
%        .sps        samples per bit for BFSK               (default 8)
%
%   For each Eb/N0 point, random bits are modulated, passed through
%   AWGN_CHANNEL and demodulated in blocks until minErrors errors are
%   counted or maxBits bits have been sent.

    if nargin < 3, opts = struct(); end
    opts = set_default(opts, 'minErrors', 200);
    opts = set_default(opts, 'maxBits',   2e6);
    opts = set_default(opts, 'blockBits', 1e4);
    opts = set_default(opts, 'sps',       8);

    [modf, demodf, k, sps] = scheme_handles(scheme, opts.sps);
    blockBits = k * ceil(opts.blockBits / k);   % whole number of symbols

    ber   = zeros(size(EbN0_dB));
    nErr  = zeros(size(EbN0_dB));
    nBits = zeros(size(EbN0_dB));

    for i = 1:numel(EbN0_dB)
        while nErr(i) < opts.minErrors && nBits(i) < opts.maxBits
            tx = randi([0 1], blockBits, 1);
            r  = awgn_channel(modf(tx), EbN0_dB(i), k, sps);
            rx = demodf(r);
            nErr(i)  = nErr(i)  + sum(tx ~= rx);
            nBits(i) = nBits(i) + blockBits;
        end
        ber(i) = nErr(i) / nBits(i);
    end
end

function opts = set_default(opts, name, value)
    if ~isfield(opts, name) || isempty(opts.(name))
        opts.(name) = value;
    end
end
