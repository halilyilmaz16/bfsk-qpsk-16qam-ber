function bits = bfsk_demod(r, sps, mode)
%BFSK_DEMOD BFSK demodulator using a correlator bank.
%   bits = BFSK_DEMOD(r, sps, mode) correlates each sps-sample block of r
%   with the two tone references (-df/2 and +df/2) used by BFSK_MOD.
%
%   mode = 'noncoherent' (default): compare |z1| and |z0|. Needs no
%          carrier phase, which is what we will have on the Pluto link.
%          Theory: Pb = 0.5*exp(-Eb/(2*N0)).
%   mode = 'coherent': compare real(z1) and real(z0), assuming the
%          receiver knows the phase. Theory: Pb = Q(sqrt(Eb/N0)).

    if nargin < 2 || isempty(sps), sps = 8; end
    if nargin < 3, mode = 'noncoherent'; end

    r = r(:);
    if mod(numel(r), sps) ~= 0
        error('bfsk_demod: length of r must be a multiple of sps');
    end
    R = reshape(r, sps, []);               % one column per bit
    n = (0:sps-1).';
    ref0 = exp(1j*2*pi*n*(-1/(2*sps)));    % tone for bit 0
    ref1 = exp(1j*2*pi*n*(+1/(2*sps)));    % tone for bit 1
    z0 = ref0' * R;                        % correlator outputs (row vectors)
    z1 = ref1' * R;

    switch lower(mode)
        case 'noncoherent'
            bits = abs(z1) > abs(z0);
        case 'coherent'
            bits = real(z1) > real(z0);
        otherwise
            error('bfsk_demod: mode must be ''noncoherent'' or ''coherent''');
    end
    bits = double(bits(:));
end
