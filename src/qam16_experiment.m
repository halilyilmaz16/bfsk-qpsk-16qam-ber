function out = qam16_experiment(nBits, EbN0dB, opts)
%QAM16_EXPERIMENT Real passband 16-QAM -> AWGN -> coherent I/Q receiver.
% out = qam16_experiment(nBits, EbN0dB, opts)
% opts: Ts [s], Fs [Hz], Fc [Hz], Seed (defaults: 1, 100, 4, 16).
% No Communications Toolbox. Uses the project's qam16_mod/qam16_demod.
% Perfect symbol/carrier synchronisation; rectangular symbol pulses.
%
% s(t) = I*cos(2*pi*Fc*t) - Q*sin(2*pi*Fc*t), E|I+jQ|^2=1.
% Ensemble Es=Ts/2, Eb=Ts/8; real sample noise variance=N0*Fs/2.
% The 2/Ts correlator restores the original constellation scale.
% Only the first eight symbols' waveforms are retained; processing is blocked.
% RandStream is local: calling this function does not reset MATLAB's RNG.

    if nargin < 3, opts = struct(); end
    validateattributes(nBits, {'numeric'}, {'real','scalar','finite', ...
        'integer','>=',4,'<=',4e6}, mfilename, 'nBits');
    if mod(nBits,4) ~= 0
        error('qam16_experiment:BitCount', 'Bit count must be a multiple of 4.');
    end
    validateattributes(EbN0dB, {'numeric'}, {'real','scalar','nonnan'}, ...
        mfilename, 'EbN0dB');
    if EbN0dB == -Inf
        error('qam16_experiment:EbN0', 'Eb/N0 must be a finite dB value or +Inf.');
    end
    if ~isstruct(opts) || ~isscalar(opts)
        error('qam16_experiment:Options', 'opts must be a scalar struct.');
    end
    names = {'Ts','Fs','Fc','Seed'};
    defaults = {1,100,4,16};
    for j=1:numel(names)
        if ~isfield(opts,names{j}), opts.(names{j})=defaults{j}; end
    end
    for name={'Ts','Fs','Fc'}
        validateattributes(opts.(name{1}), {'numeric'}, ...
            {'real','scalar','finite','positive'}, mfilename, name{1});
    end
    validateattributes(opts.Seed, {'numeric'}, {'real','scalar','finite', ...
        'integer','>=',0,'<=',2^32-2}, mfilename, 'Seed');
    Ts=double(opts.Ts); Fs=double(opts.Fs); Fc=double(opts.Fc);
    L=round(Fs*Ts);
    if L<8 || L>1e5 || abs(Fs*Ts-L)>1e-8*max(1,L)
        error('qam16_experiment:Sampling', ...
            'Fs*Ts must be an integer from 8 to 100000.');
    end
    if Fc>=Fs/2 || abs(Fc*Ts-round(Fc*Ts))>1e-9
        error('qam16_experiment:Carrier', ...
            'Fc must be less than Fs/2 and Fc*Ts must be an integer (orthogonal I/Q carriers).');
    end
    t=(0:L-1)'/Fs;
    cI=cos(2*pi*Fc*t); cQ=-sin(2*pi*Fc*t);
    gram=[cI cQ]'*[cI cQ]/L;
    if max(abs(gram(:)-reshape(eye(2)/2,[],1)))>1e-9
        error('qam16_experiment:Orthogonality', ...
            'The sampled carriers are not orthogonal.');
    end
    bitStream=RandStream('mt19937ar','Seed',double(opts.Seed));
    noiseStream=RandStream('mt19937ar','Seed',double(opts.Seed)+1);
    bits=randi(bitStream,[0 1],nBits,1);
    tx=qam16_mod(bits); nSym=numel(tx);
    Es=Ts/2; Eb=Es/4; N0=Eb/10^(EbN0dB/10);
    sigma=sqrt(N0*Fs/2);
    if ~isfinite(sigma)
        error('qam16_experiment:NoiseRange', 'Eb/N0 is outside the numeric range.');
    end
    rx=complex(zeros(nSym,1));
    blockSymbols=max(1,floor(1e6/L));
    nPreview=min(8,nSym); sPreview=zeros(L,nPreview); rPreview=sPreview;
    noisePower=0;
    for first=1:blockSymbols:nSym
        ix=first:min(first+blockSymbols-1,nSym);
        S=cI*real(tx(ix)).'+cQ*imag(tx(ix)).';
        noise=sigma*randn(noiseStream,size(S));
        R=S+noise;
        rx(ix)=(2/(Ts*Fs))*(cI.'*R+1j*(cQ.'*R)).';
        noisePower=noisePower+sum(noise(:).^2);
        previewIx=ix(ix<=nPreview);
        if ~isempty(previewIx)
            sPreview(:,previewIx)=S(:,1:numel(previewIx));
            rPreview(:,previewIx)=R(:,1:numel(previewIx));
        end
    end
    bitsHat=qam16_demod(rx);
    perSymbol=sum(reshape(bits~=bitsHat,4,[]),1).';
    out=struct('bits',bits,'bits_hat',bitsHat,'txSymbols',tx, ...
        'rxSymbols',rx,'rawI',sqrt(10)*real(tx),'rawQ',sqrt(10)*imag(tx), ...
        'nErr',sum(perSymbol),'BER',mean(perSymbol)/4, ...
        'SER',mean(perSymbol>0),'nSymbols',nSym, ...
        'Es',Es,'Eb',Eb,'N0',N0,'sigma',sigma, ...
        'EsMeasured',Es*mean(abs(tx).^2), ...
        'noisePowerMeasured',noisePower/(nSym*L), ...
        'berStandardError',std(perSymbol/4)/sqrt(nSym), ...
        'zeroErrorUpper95',-expm1(log(0.05)/nSym), ...
        'EbN0dB',EbN0dB,'theory',ber_theory('qam16',EbN0dB));
    out.wave=struct('t',(0:L*nPreview-1)'/Fs, ...
        's',sPreview(:),'r',rPreview(:));
    out.settings=struct('Ts',Ts,'Fs',Fs,'Fc',Fc,'sps',L,'Seed',opts.Seed);
end
