function bits = qpsk_demod(r)
%QPSK_DEMOD Hard-decision (ML) demodulator for Gray-coded QPSK.
%   bits = QPSK_DEMOD(r) returns a column vector of bits for the received
%   symbols r. With Gray mapping the ML decision splits into two
%   independent sign decisions on the I and Q components.

    r = r(:);
    b1 = real(r) < 0;
    b2 = imag(r) < 0;
    bits = double(reshape([b1 b2].', [], 1));
end
