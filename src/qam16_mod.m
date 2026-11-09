function s = qam16_mod(bits)
%QAM16_MOD Gray-coded square 16-QAM modulator (complex baseband).
%   s = QAM16_MOD(bits) maps a bit vector (length multiple of 4) to
%   16-QAM symbols with unit average energy (Es = 1).
%
%   Each symbol carries [b1 b2 b3 b4]: b1 b2 select the I level and
%   b3 b4 select the Q level, using a Gray-coded 4-PAM per axis:
%       00 -> -3,  01 -> -1,  11 -> +1,  10 -> +3
%   Adjacent levels differ in one bit, so adjacent constellation points
%   differ in one bit. Raw average energy is 10, so the output is
%   divided by sqrt(10).

    bits = double(bits(:));
    if mod(numel(bits), 4) ~= 0
        error('qam16_mod: number of bits must be a multiple of 4');
    end
    b = reshape(bits, 4, []).';

    % LUT indexed by 2*b1 + b2 + 1:   00   01   10   11
    lut = [-3 -1 3 1];
    I = lut(2*b(:,1) + b(:,2) + 1);
    Q = lut(2*b(:,3) + b(:,4) + 1);
    s = (I(:) + 1j*Q(:)) / sqrt(10);
end
