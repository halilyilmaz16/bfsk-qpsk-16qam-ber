function s = qpsk_mod(bits)
%QPSK_MOD Gray-coded QPSK modulator (complex baseband, 1 sample/symbol).
%   s = QPSK_MOD(bits) maps a bit vector (length multiple of 2) to unit
%   average energy QPSK symbols (Es = 1).
%
%   Bit pair [b1 b2] -> I = 1-2*b1, Q = 1-2*b2, scaled by 1/sqrt(2):
%       00 -> ( 1 + 1j)/sqrt(2)     01 -> ( 1 - 1j)/sqrt(2)
%       10 -> (-1 + 1j)/sqrt(2)     11 -> (-1 - 1j)/sqrt(2)
%   Neighbouring points differ in exactly one bit (Gray mapping).

    bits = double(bits(:));
    if mod(numel(bits), 2) ~= 0
        error('qpsk_mod: number of bits must be a multiple of 2');
    end
    b = reshape(bits, 2, []).';          % one row per symbol
    I = 1 - 2*b(:,1);
    Q = 1 - 2*b(:,2);
    s = (I + 1j*Q) / sqrt(2);
end
