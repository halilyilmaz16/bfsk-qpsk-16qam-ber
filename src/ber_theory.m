function Pb = ber_theory(scheme, EbN0_dB)
%BER_THEORY Closed-form BER in AWGN (Proakis & Salehi, Haykin).
%   Pb = BER_THEORY(scheme, EbN0_dB), scheme is one of:
%     'bfsk'      noncoherent BFSK        Pb = 0.5*exp(-g/2)
%     'bfsk_coh'  coherent orthogonal BFSK Pb = Q(sqrt(g))
%     'qpsk'      Gray QPSK               Pb = Q(sqrt(2g))
%     'qam16'     Gray 16-QAM (exact)     Pb = 1/4*[3Q(x) + 2Q(3x) - Q(5x)],
%                                         x = sqrt(4g/5)
%   where g = Eb/N0 (linear). Q(x) = 0.5*erfc(x/sqrt(2)) is used instead of
%   qfunc so that the file runs without the Communications Toolbox.

    g = 10.^(EbN0_dB/10);
    Q = @(x) 0.5*erfc(x/sqrt(2));

    switch lower(scheme)
        case 'bfsk'
            Pb = 0.5*exp(-g/2);
        case 'bfsk_coh'
            Pb = Q(sqrt(g));
        case 'qpsk'
            Pb = Q(sqrt(2*g));
        case 'qam16'
            x = sqrt(4*g/5);
            Pb = (3*Q(x) + 2*Q(3*x) - Q(5*x)) / 4;
        otherwise
            error('ber_theory: unknown scheme "%s"', scheme);
    end
end
