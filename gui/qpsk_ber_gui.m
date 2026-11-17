function qpsk_ber_gui
%QPSK_BER_GUI Standalone Gray-coded QPSK experiment. Run: qpsk_ber_gui
% Complex baseband, one sample per symbol, coherent receiver, AWGN.
% Uses base MATLAB UI components; no Communications Toolbox required.
    fig = uifigure('Name','QPSK BER Experiment','Position',[40 60 1150 690]);
    layout = uigridlayout(fig,[1 2]);
    layout.ColumnWidth = {235,'1x'};
    controls = uigridlayout(layout,[9 1]);
    controls.RowHeight = {32,22,32,22,105,36,25,32,'1x'};
    uilabel(controls,'Text','Gray-coded QPSK','FontWeight','bold','FontSize',18);
    uilabel(controls,'Text','Number of bits (even)');
    count = uieditfield(controls,'numeric','Value',100000,'Limits',[2 2000000], ...
        'RoundFractionalValues','on');
    uilabel(controls,'Text','Three Eb/N0 levels (dB)');
    fields = uigridlayout(controls,[3 1]);
    fields.Padding = [0 0 0 0];
    levels = gobjects(1,3);
    for k = 1:3
        levels(k) = uieditfield(fields,'numeric','Value',4*(k-1),'Limits',[-5 20]);
    end
    uibutton(controls,'Text','Run experiment','ButtonPushedFcn',@runExperiment);
    uilabel(controls,'Text','Inspect experiment');
    choice = uidropdown(controls,'Items',{'Run first'},'Enable','off', ...
        'ValueChangedFcn',@showSelection);
    uitextarea(controls,'Editable','off','Value',{ ...
        'Each pair of bits selects one symbol. The first bit controls I, the second Q.', ...
        'The receiver reads each sign: negative gives 1, otherwise 0.', ...
        'Red points show symbol errors. A symbol error can affect one or both bits.', ...
        'A triangle marks zero observed errors at 1/N for display only.'});
    plots = uigridlayout(layout,[3 2]);
    plots.RowHeight = {'1x',125,110};
    berAxes = uiaxes(plots);
    iqAxes = uiaxes(plots);
    results = uitable(plots,'ColumnName',{'Eb/N0 (dB)','Bits','Bit errors', ...
        'Measured BER','Theory BER'},'RowName',{});
    results.Layout.Row = 2;
    results.Layout.Column = [1 2];
    strip = uiaxes(plots);
    strip.Layout.Row = 3;
    strip.Layout.Column = [1 2];
    samples = cell(1,3);
    symbolErrors = cell(1,3);
    bitErrors = cell(1,3);
    runExperiment([],[]);

    function runExperiment(~,~)
        N = count.Value;
        if mod(N,2)
            uialert(fig,'Choose an even bit count. Each symbol needs two bits.','Bit count');
            return
        end
        db = [levels.Value];
        bits = randi([0 1],N,1);
        s = qpsk_mod(bits);
        errors = zeros(3,1);
        for j = 1:3
            % Es = 1, Eb = 1/2. Each real noise component has variance N0/2.
            gamma = 10^(db(j)/10);
            sigma = 1/(2*sqrt(gamma));
            r = s + sigma*(randn(size(s)) + 1j*randn(size(s)));
            wrong = qpsk_demod(r) ~= bits;
            errors(j) = nnz(wrong);
            m = min(2000,numel(r));
            samples{j} = r(1:m);
            symbolErrors{j} = any(reshape(wrong(1:2*m),2,[]),1).';
            bitErrors{j} = wrong(1:min(200,N));
        end
        theory = @(d) 0.5*erfc(sqrt(10.^(d/10)));
        results.Data = [db(:),repmat(N,3,1),errors,errors/N,theory(db(:))];
        d = linspace(min(db)-1,max(db)+1,200);
        cla(berAxes,'reset');
        semilogy(berAxes,d,theory(d),'LineWidth',1.6,'DisplayName','Theory');
        hold(berAxes,'on');
        hit = errors > 0;
        semilogy(berAxes,db(hit),errors(hit)/N,'o','DisplayName','Measured');
        semilogy(berAxes,db(~hit),ones(nnz(~hit),1)/N,'v','DisplayName','Zero errors');
        grid(berAxes,'on');
        ylim(berAxes,[0.1/N 1]);
        xlabel(berAxes,'E_b/N_0 (dB)');
        ylabel(berAxes,'Bit error rate');
        title(berAxes,'Theory and simulation');
        legend(berAxes,'Location','best');
        choice.Items = arrayfun(@(j) sprintf('Run %d: %g dB',j,db(j)),1:3,'UniformOutput',false);
        choice.ItemsData = 1:3;
        choice.Value = 1;
        choice.Enable = 'on';
        showSelection([],[]);
    end

    function showSelection(~,~)
        j = choice.Value;
        r = samples{j};
        e = symbolErrors{j};
        cla(iqAxes,'reset');
        plot(iqAxes,real(r(~e)),imag(r(~e)),'.','Color',[0.1 0.52 0.52]);
        hold(iqAxes,'on');
        plot(iqAxes,real(r(e)),imag(r(e)),'r.');
        ideal = qpsk_mod([0 0 0 1 1 0 1 1]);
        plot(iqAxes,real(ideal),imag(ideal),'kx','MarkerSize',9,'LineWidth',2);
        xline(iqAxes,0,':');
        yline(iqAxes,0,':');
        span = 1.1*max([1;abs(real(r));abs(imag(r))]);
        axis(iqAxes,'equal');
        xlim(iqAxes,[-span span]);
        ylim(iqAxes,[-span span]);
        xlabel(iqAxes,'In-phase (I)');
        ylabel(iqAxes,'Quadrature (Q)');
        title(iqAxes,{'Received constellation',sprintf('%d of first %d symbols incorrect',nnz(e),numel(e))});
        e = bitErrors{j};
        imagesc(strip, double(e.'),[0 1]);
        colormap(strip,[0.22 0.65 0.45;0.85 0.18 0.15]);
        strip.YTick = [];
        xlabel(strip,'Bit index');
        title(strip,sprintf('First %d bits: %d errors (red)',numel(e),nnz(e)));
    end
end

function s = qpsk_mod(bits)
    bits = double(bits(:));
    if mod(numel(bits),2) ~= 0
        error('qpsk_mod: number of bits must be a multiple of 2');
    end
    b = reshape(bits,2,[]).';
    I = 1 - 2*b(:,1);
    Q = 1 - 2*b(:,2);
    s = (I + 1j*Q)/sqrt(2);
end

function bits = qpsk_demod(r)
    r = r(:);
    b1 = real(r) < 0;
    b2 = imag(r) < 0;
    bits = double(reshape([b1 b2].',[],1));
end
