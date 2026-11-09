function bits = qam16_demod(r)
%QAM16_DEMOD Hard-decision (ML) demodulator for Gray-coded 16-QAM.
%   bits = QAM16_DEMOD(r) returns a column vector of bits. The received
%   symbols are scaled back by sqrt(10); each axis is then sliced to the
%   nearest 4-PAM level {-3,-1,+1,+3} (thresholds at -2, 0, +2), which is
%   the ML decision in AWGN for equally likely symbols.

    r = r(:) * sqrt(10);
    [b1, b2] = pam4_slice(real(r));
    [b3, b4] = pam4_slice(imag(r));
    bits = double(reshape([b1 b2 b3 b4].', [], 1));
end

function [b1, b2] = pam4_slice(x)
    % Inverse of the Gray map 00->-3, 01->-1, 11->+1, 10->+3
    b1 = x > 0;              % sign bit
    b2 = abs(x) < 2;         % inner level (|a| = 1) -> second bit is 1
end
