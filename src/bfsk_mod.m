function s = bfsk_mod(bits, sps)
%BFSK_MOD Binary FSK modulator (complex baseband, sps samples per bit).
%   s = BFSK_MOD(bits, sps) returns sps*numel(bits) samples. Bit 0 is sent
%   as a tone at -df/2 and bit 1 as a tone at +df/2, with tone spacing
%   df = 1/Tb (one cycle per bit across the pair). This spacing makes the
%   two tones orthogonal over one bit for both coherent and noncoherent
%   detection.
%
%   Frequencies are normalised to the sample rate: Tb = sps samples, so
%   the tones are at +-1/(2*sps) cycles/sample. Each bit starts at phase 0
%   (no phase continuity is enforced; this is enough for AWGN BER work).
%   Average sample power is 1, so Eb = sps (energy summed over a bit).
%
%   Default sps = 8.

    if nargin < 2, sps = 8; end
    bits = double(bits(:));
    n = (0:sps-1).';                       % sample index inside one bit
    f = (2*bits.' - 1) / (2*sps);          % -1/(2sps) for 0, +1/(2sps) for 1
    S = exp(1j*2*pi*n*f);                  % sps x Nbits, one column per bit
    s = S(:);
end
