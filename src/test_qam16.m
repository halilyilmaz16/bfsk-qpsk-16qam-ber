function test_qam16
%TEST_QAM16 Physical and statistical checks, not just mod/demod inversion.
    allBits=double(dec2bin(0:15,4)-'0');
    bits=reshape(allBits.',[],1); s=qam16_mod(bits);
    assert(isequal(bits,qam16_demod(s)), 'All 16 labels must round-trip.');
    assert(abs(mean(abs(s).^2)-1)<1e-12, 'Constellation Es must be 1.');
    assert(numel(unique(s))==16, 'The constellation needs 16 unique points.');
    % An independent nearest-neighbour geometry check of the Gray labels.
    for i=1:16
        for j=i+1:16
            if abs(abs(s(i)-s(j))-2/sqrt(10))<1e-12
                assert(sum(allBits(i,:)~=allBits(j,:))==1, 'Gray adjacency failed.');
            end
        end
    end
    dB=[0 4 8 12]; expected=[0.1409816351 0.05862373728 0.009247213738 0.0001386586888];
    assert(max(abs(ber_theory('qam16',dB)-expected))<2e-10, 'Exact BER regression.');
    state=rng;
    clean=qam16_experiment(4000,Inf);
    assert(clean.nErr==0 && max(abs(clean.txSymbols-clean.rxSymbols))<1e-12, ...
        'Passband correlators must recover noiseless symbols.');
    assert(isequal(rng,state), 'Experiment must preserve the caller RNG.');
    p=struct('Ts',1,'Fs',100,'Fc',4,'Seed',451);
    a=qam16_experiment(200000,4,p);
    b=qam16_experiment(200000,4,p);
    assert(isequal(a.rxSymbols,b.rxSymbols), 'Seed reproducibility failed.');
    assert(abs(a.BER-a.theory)<6*a.berStandardError, 'Passband BER disagrees with theory.');
    assert(abs(a.noisePowerMeasured/a.sigma^2-1)<0.01, 'Sample noise power scale failed.');
    e=a.rxSymbols-a.txSymbols; expectedVar=1/(8*10^(4/10));
    assert(abs(var(real(e))/expectedVar-1)<0.025, 'Correlator I variance failed.');
    assert(abs(var(imag(e))/expectedVar-1)<0.025, 'Correlator Q variance failed.');
    assert(abs(mean(real(e).*imag(e)))<0.025*expectedVar, 'I/Q noise must be uncorrelated.');
    for fs=[40 200]
        p.Fs=fs; c=qam16_experiment(200000,4,p);
        assert(isequal(a.bits,c.bits), 'Sampling must not change the input bits.');
        assert(abs(c.BER-c.theory)<6*c.berStandardError, 'BER depends on sampling rate.');
    end
    p=struct('Ts',0.5,'Fs',80,'Fc',8,'Seed',451);
    c=qam16_experiment(200000,4,p);
    assert(abs(c.BER-c.theory)<6*c.berStandardError, 'Energy scaling with Ts failed.');
    assert(c.Es==0.25 && c.Eb==0.0625, 'Physical symbol energy failed.');
    expectError(@() qam16_experiment(10,4), 'qam16_experiment:BitCount');
    expectError(@() qam16_experiment(40,4,struct('Fc',4.3)), 'qam16_experiment:Carrier');
    expectError(@() qam16_experiment(40,4,struct('Fs',7)), 'qam16_experiment:Sampling');
    fprintf('PASS: all labels, Gray neighbours, energy, exact BER, noiseless passband,\n');
    fprintf('      RNG, reproducibility, AWGN variance, Fs/Ts invariance and invalid settings.\n');
    fprintf('4 dB: %d/200000 errors, measured %.7f, theory %.7f.\n',a.nErr,a.BER,a.theory);
end

function expectError(f,identifier)
    try
        f();
    catch ME
        assert(strcmp(ME.identifier,identifier), 'Unexpected validation error.');
        return
    end
    error('test_qam16:MissingError', 'Invalid input was accepted.');
end
