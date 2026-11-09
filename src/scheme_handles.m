function [modf, demodf, k, sps] = scheme_handles(scheme, bfskSps)
%SCHEME_HANDLES Modulator/demodulator handles and parameters per scheme.
%   [modf, demodf, k, sps] = SCHEME_HANDLES(scheme, bfskSps)
%     modf, demodf : function handles  bits -> samples, samples -> bits
%     k            : bits per symbol
%     sps          : samples per symbol
%   Shared by BER_SIM and the GUI so every part uses the same settings.

    if nargin < 2, bfskSps = 8; end

    switch lower(scheme)
        case 'bfsk'
            k = 1; sps = bfskSps;
            modf   = @(b) bfsk_mod(b, sps);
            demodf = @(r) bfsk_demod(r, sps, 'noncoherent');
        case 'bfsk_coh'
            k = 1; sps = bfskSps;
            modf   = @(b) bfsk_mod(b, sps);
            demodf = @(r) bfsk_demod(r, sps, 'coherent');
        case 'qpsk'
            k = 2; sps = 1;
            modf = @qpsk_mod;  demodf = @qpsk_demod;
        case 'qam16'
            k = 4; sps = 1;
            modf = @qam16_mod; demodf = @qam16_demod;
        otherwise
            error('scheme_handles: unknown scheme "%s"', scheme);
    end
end
