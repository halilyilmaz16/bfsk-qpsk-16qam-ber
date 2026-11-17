function summary = run_qam16_analysis(nBits)
%RUN_QAM16_ANALYSIS Reproducible passband BER and report figures.
% run_qam16_analysis         % 2e6 bits at each 0:2:14 dB point
% run_qam16_analysis(200000) % shorter demonstration
% Core implementation uses no modulation or AWGN toolbox functions.
    if nargin<1, nBits=2e6; end
    validateattributes(nBits,{'numeric'},{'real','scalar','finite', ...
        'integer','>=',4,'<=',4e6},mfilename,'nBits');
    if mod(nBits,4)~=0
        error('run_qam16_analysis:BitCount','The bit count must be a multiple of 4.');
    end
    root=fileparts(fileparts(mfilename('fullpath')));
    outDir=fullfile(root,'results','qam16');
    if ~exist(outDir,'dir'), mkdir(outDir); end
    db=0:2:14; n=numel(db); measured=zeros(1,n); errors=measured;
    theory=ber_theory('qam16',db); sem=measured; baseband=measured;
    ser=measured; zeroUpper=measured;
    p=struct('Ts',1,'Fs',100,'Fc',4,'Seed',451);
    for j=1:n
        r=qam16_experiment(nBits,db(j),p);
        measured(j)=r.BER; errors(j)=r.nErr; sem(j)=r.berStandardError;
        ser(j)=r.SER; zeroUpper(j)=r.zeroErrorUpper95;
        % Independent complex-symbol path with the same original mapper.
        stream=RandStream('mt19937ar','Seed',900+j);
        N0=1/(4*10^(db(j)/10));
        z=r.txSymbols+sqrt(N0/2)*(randn(stream,size(r.txSymbols))+ ...
            1j*randn(stream,size(r.txSymbols)));
        baseband(j)=mean(r.bits~=qam16_demod(z));
        fprintf('%2g dB: %7d/%d errors, passband %.7g, baseband %.7g, theory %.7g\n', ...
            db(j),r.nErr,nBits,r.BER,baseband(j),r.theory);
        if db(j)==0, noisy=r; end
        if db(j)==6, medium=r; end
        if db(j)==12, quiet=r; end
    end
    quality=repmat("Monte Carlo",n,1);
    quality(errors<100)="Few errors: limited precision";
    summary=table(db(:),repmat(nBits,n,1),errors(:),measured(:), ...
        theory(:),baseband(:),ser(:),sem(:),zeroUpper(:),quality, ...
        'VariableNames',{'EbN0_dB','Bits','BitErrors','BER_Passband', ...
        'BER_Theory','BER_Baseband','SER','BER_StandardError', ...
        'BER_Upper95_IfZero','Precision'});
    writetable(summary,fullfile(outDir,'qam16_ber.csv'));
    % This exact inversion avoids rounding a coarse dB sweep for the target BER.
    targetQAM=fzero(@(x)ber_theory('qam16',x)-1e-3,[0 20]);
    targetQPSK=fzero(@(x)ber_theory('qpsk',x)-1e-3,[0 20]);
    save(fullfile(outDir,'qam16_results.mat'),'summary','p','targetQAM','targetQPSK');

    f=reportFigure([100 100 1050 650]);
    cleaner=onCleanup(@()closeIfValid(f));
    dense=linspace(-2,16,400);
    semilogy(dense,ber_theory('qam16',dense),'-','LineWidth',1.8, ...
        'DisplayName','16-QAM: exact Gray BER'); hold on; grid on;
    semilogy(dense,ber_theory('qpsk',dense),'--','LineWidth',1.2, ...
        'DisplayName','QPSK: theory');
    positive=measured>0;
    enough=errors>=100;
    errorbar(db(enough),measured(enough),1.96*sem(enough),1.96*sem(enough), ...
        'o','Color',[0.85 0.33 0.10],'LineWidth',1.2, ...
        'DisplayName','Passband: approximate 95% interval (at least 100 errors)');
    few=positive & ~enough;
    if any(few)
        plot(db(few),measured(few),'s','MarkerSize',8,'LineWidth',1.5, ...
            'Color',[0.85 0.33 0.10],'DisplayName','Few errors: limited precision');
    end
    plot(db,baseband,'x','Color',[0.47 0.67 0.19],'LineWidth',1.5, ...
        'DisplayName','16-QAM: complex baseband');
    if any(~positive)
        plot(db(~positive),zeroUpper(~positive),'v','MarkerSize',9, ...
            'DisplayName','0 errors: conservative 95% BER upper bound');
    end
    for j=1:n
        text(db(j),max(measured(j),zeroUpper(j))*1.5, ...
            sprintf('%d errors',errors(j)),'FontSize',9,'HorizontalAlignment','center');
    end
    yline(1e-3,':k','BER = 10^{-3}','HandleVisibility','off');
    xlabel('E_b/N_0 (dB)'); ylabel('Bit error rate (BER)'); ylim([1e-7 1]); xlim([-2 16]);
    title({'16-QAM: theory, real-carrier experiment and baseband', ...
        sprintf('%d bits per point; T_s=1 s, F_s=100 Hz, f_c=4 Hz; ideal synchronization',nBits)});
    legend('Location','southwest');
    exportgraphics(f,fullfile(outDir,'qam16_ber.png'),'Resolution',180);
    clear cleaner

    f=reportFigure([100 100 1250 480]);
    cleaner=onCleanup(@()closeIfValid(f));
    tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
    cases={noisy,medium,quiet};
    for j=1:3
        r=cases{j}; nexttile; hold on; grid on; axis equal;
        count=min(4000,r.nSymbols);
        symbolError=any(reshape(r.bits~=r.bits_hat,4,[]),1).';
        ix=(1:count)'; wrong=symbolError(ix);
        plot(real(r.rxSymbols(ix(~wrong))),imag(r.rxSymbols(ix(~wrong))),'.', ...
            'Color',[0 0.45 0.74],'MarkerSize',3);
        plot(real(r.rxSymbols(ix(wrong))),imag(r.rxSymbols(ix(wrong))),'.', ...
            'Color',[0.85 0.10 0.10],'MarkerSize',5);
        constellation=qam16_mod(reshape((dec2bin(0:15,4)-'0').',[],1));
        plot(real(constellation),imag(constellation),'ko','MarkerSize',7,'LineWidth',1.2);
        for th=[-2 0 2]/sqrt(10)
            xline(th,':k'); yline(th,':k');
        end
        xlabel('I'); ylabel('Q'); xlim([-1.8 1.8]); ylim([-1.8 1.8]);
        title(sprintf('%g dB | BER=%.3g',r.EbN0dB,r.BER));
    end
    sgtitle('Received symbols: blue correct, red incorrect; circles mark ideal points');
    exportgraphics(f,fullfile(outDir,'qam16_constellations.png'),'Resolution',180);
    clear cleaner

    f=reportFigure([100 100 1100 650]);
    cleaner=onCleanup(@()closeIfValid(f));
    r=medium; nShow=min(4,r.nSymbols); keep=r.wave.t<nShow*p.Ts;
    tiledlayout(3,1,'TileSpacing','compact');
    nexttile; stairs((0:nShow)*p.Ts,[real(r.txSymbols(1:nShow));real(r.txSymbols(nShow))], ...
        'LineWidth',1.5); hold on;
    stairs((0:nShow)*p.Ts,[imag(r.txSymbols(1:nShow));imag(r.txSymbols(nShow))],'LineWidth',1.5);
    legend('I','Q'); grid on; ylabel('Level'); title(sprintf('%d symbols: I/Q levels',nShow));
    nexttile; plot(r.wave.t(keep),r.wave.s(keep)); grid on; ylabel('s(t)');
    title('Transmitter: s(t) = I cos(2 pi f_c t) - Q sin(2 pi f_c t)');
    nexttile; plot(r.wave.t(keep),r.wave.r(keep)); grid on; ylabel('r(t)'); xlabel('Time (s)');
    title('AWGN channel output, E_b/N_0 = 6 dB');
    exportgraphics(f,fullfile(outDir,'qam16_waveform.png'),'Resolution',180);
    clear cleaner
    fprintf('BER=1e-3: 16-QAM %.4f dB, QPSK %.4f dB; difference %.4f dB.\n', ...
        targetQAM,targetQPSK,targetQAM-targetQPSK);
    fprintf('Results: %s\n',outDir);
end

function closeIfValid(f)
    if isgraphics(f), close(f); end
end

function f=reportFigure(position)
    f=figure('Visible','off','Color','w','Position',position);
    % R2025a+ follows the desktop theme even for invisible figures. Reports
    % need a consistent light canvas so their labels also print on paper.
    if isprop(f,'Theme'), f.Theme='light'; end
end
