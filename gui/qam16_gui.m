function fig = qam16_gui(options)
%QAM16_GUI Gray 16-QAM: bits -> real channel -> correlator -> decision.
%   fig = qam16_gui() opens the experiment window.
%   fig = qam16_gui(struct('Visible','off','AutoRun',true,...
%                         'ExportDir',tempdir)) can run without showing it.
%   Results are in getappdata(fig,'QAM16Results') and fig.UserData.results.
%   All three experiments use the same bits and standard noise samples;
%   only noise amplitude changes with Eb/N0. Each sends a fixed bit count.

    if nargin < 1
        options = struct();
    end
    options = gui_options(options);
    rootDir = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(rootDir, 'src'));

    blue = [0 0.4470 0.7410];
    orange = [0.8500 0.3250 0.0980];
    red = [0.85 0.10 0.10];
    results = struct([]);

    % Project layout: 300 px settings panel on the left, results on the right.
    fig = uifigure('Name', '16-QAM BER Experiment', ...
        'Position', [60 60 1320 850], 'Visible', options.Visible, ...
        'Tag', 'QAM16Figure');
    fig.UserData = struct('results', results);
    setappdata(fig, 'QAM16Results', results);
    g = uigridlayout(fig, [1 2]);
    g.ColumnWidth = {300, '1x'};

    L = uigridlayout(g, [14 1]);
    L.RowHeight = {42, 22, 20, 28, 22, 28, 18, 22, 50, 28, 54, 42, 44, '1x'};
    L.RowSpacing = 8;
    L.Padding = [12 12 12 12];

    lb = uilabel(L, 'Text', '16-QAM BER: Send Bits, Count Errors', ...
        'FontSize', 16, 'FontWeight', 'bold', 'WordWrap', 'on');
    lb.Layout.Row = 1;
    lb = uilabel(L, 'Text', '4 bits/symbol; 16 possible I/Q points.');
    lb.Layout.Row = 2;
    lb = uilabel(L, 'Text', '1) Bits to send (multiple of 4)', ...
        'FontWeight', 'bold');
    lb.Layout.Row = 3;
    bitsEdit = uieditfield(L, 'numeric', 'Value', 40000, ...
        'Limits', [4 2e6], 'ValueDisplayFormat', '%g bit', 'Tag', 'QAM16Bits');
    bitsEdit.Layout.Row = 4;

    lb = uilabel(L, 'Text', '2) Noise: 3 Eb/N0 values (dB)', 'FontWeight', 'bold');
    lb.Layout.Row = 5;
    G3 = uigridlayout(L, [1 3]);
    G3.Padding = [0 0 0 0]; G3.Layout.Row = 6;
    dbEdit = gobjects(1, 3);
    defaultDB = [0 6 12];
    for k = 1:3
        dbEdit(k) = uieditfield(G3, 'numeric', 'Value', defaultDB(k), ...
            'Limits', [-10 30], 'ValueDisplayFormat', '%g dB', ...
            'Tag', sprintf('QAM16DB%d', k));
    end
    lb = uilabel(L, 'Text', 'higher dB = less noise; fixed bit count', ...
        'FontAngle', 'italic');
    lb.Layout.Row = 7;
    lb = uilabel(L, 'Text', '3) Signal settings', 'FontWeight', 'bold');
    lb.Layout.Row = 8;
    GS = uigridlayout(L, [2 3]);
    GS.Layout.Row = 9; GS.Padding = [0 0 0 0];
    GS.RowHeight = {18, 26}; GS.RowSpacing = 2;
    uilabel(GS, 'Text', 'Ts: duration');
    uilabel(GS, 'Text', 'fs: sample rate');
    uilabel(GS, 'Text', 'fc: carrier');
    tsEdit = uieditfield(GS, 'numeric', 'Value', 1, 'Limits', [eps Inf], ...
        'ValueDisplayFormat', '%g s', 'Tag', 'QAM16Ts', ...
        'ValueChangedFcn', @(~, ~) settings_info());
    fsEdit = uieditfield(GS, 'numeric', 'Value', 100, 'Limits', [eps Inf], ...
        'ValueDisplayFormat', '%g Hz', 'Tag', 'QAM16Fs', ...
        'ValueChangedFcn', @(~, ~) settings_info());
    fcEdit = uieditfield(GS, 'numeric', 'Value', 4, 'Limits', [eps Inf], ...
        'ValueDisplayFormat', '%g Hz', 'Tag', 'QAM16Fc', ...
        'ValueChangedFcn', @(~, ~) settings_info());
    GSeed = uigridlayout(L, [1 2]);
    GSeed.Layout.Row = 10; GSeed.Padding = [0 0 0 0];
    GSeed.ColumnWidth = {'1x', '1x'};
    uilabel(GSeed, 'Text', 'Random seed');
    seedEdit = uieditfield(GSeed, 'numeric', 'Value', 16, ...
        'Limits', [0 2^32-2], 'ValueDisplayFormat', '%g', 'Tag', 'QAM16Seed');
    settingLabel = uilabel(L, 'Text', '', 'WordWrap', 'on', 'FontSize', 11);
    settingLabel.Layout.Row = 11;

    btn = uibutton(L, 'Text', 'Run', 'FontSize', 15, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @send_bits, 'Tag', 'QAM16Send');
    btn.Layout.Row = 12;
    status = uilabel(L, 'Text', 'Choose settings, then press "Run".', ...
        'WordWrap', 'on', 'Tag', 'QAM16Status');
    status.Layout.Row = 13;
    helpText = uitextarea(L, 'Editable', 'off', 'Value', { ...
        'HOW TO READ THE RESULTS', '', ...
        '• Every 4 bits select a point on the I and Q axes. The Gray order on each axis is 00, 01, 11, 10. Adjacent points differ by one bit.', ...
        '• The transmitter sends I·cos(2πfc·t) − Q·sin(2πfc·t). The channel adds Gaussian noise. The receiver measures I and Q with two correlators and selects the nearest point.', ...
        '• BER = bit errors / transmitted bits. SER = symbol errors / transmitted symbols. Blue points are correct symbols; red points are symbol errors. Dashed lines mark decision thresholds.', ...
        '• The BER curve is exact Gray 16-QAM theory. Zero errors do not prove that the true BER is zero. The triangle marks a conservative 95% upper bound: 1−0.05^(1/Ns), where Ns is the number of symbols. For independent symbols this bounds SER; it also bounds BER because BER ≤ SER.', ...
        '• The same seed is used at each dB value: bits and standard noise samples stay the same; noise amplitude changes. More bits make small BER values easier to measure.', ...
        '• Average symbol energy is Es = Ts/2; bit energy is Eb = Ts/8. Fs·Ts and Fc·Ts must be integers, with Fs > 2·Fc, to preserve sampling and correlator orthogonality.'});
    helpText.Layout.Row = 14;

    tabs = uitabgroup(g);
    mainTab = uitab(tabs, 'Title', 'Experiment results');
    R = uigridlayout(mainTab, [4 2]);
    R.RowHeight = {'1x', 140, 28, 100};
    axBer = uiaxes(R); axBer.Layout.Row = 1; axBer.Layout.Column = 1;
    axConst = uiaxes(R); axConst.Layout.Row = 1; axConst.Layout.Column = 2;
    tbl = uitable(R, 'ColumnName', {'Eb/N0 (dB)', 'Bits sent', ...
        'Symbols', 'Bit errors', 'BER', 'SER', 'Theory BER', 'Interpretation'}, ...
        'ColumnWidth', {88, 100, 75, 78, 90, 90, 90, 'auto'}, ...
        'RowName', {}, 'Tag', 'QAM16Table');
    tbl.Layout.Row = 2; tbl.Layout.Column = [1 2];
    lb = uilabel(R, 'Text', 'Which experiment?', ...
        'FontWeight', 'bold', 'HorizontalAlignment', 'right');
    lb.Layout.Row = 3; lb.Layout.Column = 1;
    dd = uidropdown(R, 'Items', {'(press Run first)'}, 'Enable', 'off', ...
        'Tag', 'QAM16Select', 'ValueChangedFcn', @(src, ~) show_experiment(src.Value));
    dd.Layout.Row = 3; dd.Layout.Column = 2;
    axStrip = uiaxes(R); axStrip.Layout.Row = 4; axStrip.Layout.Column = [1 2];

    signalTab = uitab(tabs, 'Title', 'I/Q and waveform');
    S = uigridlayout(signalTab, [2 2]);
    S.RowHeight = {'1x', '1x'};
    axI = uiaxes(S); axI.Layout.Row = 1; axI.Layout.Column = 1;
    axQ = uiaxes(S); axQ.Layout.Row = 1; axQ.Layout.Column = 2;
    axWave = uiaxes(S); axWave.Layout.Row = 2; axWave.Layout.Column = [1 2];
    empty_plots();
    settings_info();
    if options.AutoRun
        send_bits([], []);
        drawnow;
    elseif ~isempty(options.ExportDir)
        export_snapshot();
    end

    function settings_info()
        try
            [~, ~, p] = read_settings();
            settingLabel.FontColor = [0.15 0.5 0.2];
            settingLabel.Text = sprintf(['%d samples and %g carrier cycles per symbol. ' ...
                'Es = %g, Eb = %g; orthogonal correlators.'], ...
                round(p.Fs*p.Ts), p.Fc*p.Ts, p.Ts/2, p.Ts/8);
        catch err
            settingLabel.FontColor = red;
            settingLabel.Text = err.message;
        end
    end

    function [n, dBs, p] = read_settings()
        n = bitsEdit.Value;
        dBs = sort([dbEdit.Value]);
        p = struct('Ts', tsEdit.Value, 'Fs', fsEdit.Value, ...
            'Fc', fcEdit.Value, 'Seed', seedEdit.Value);
        if ~isfinite(n) || n < 4 || n ~= fix(n) || mod(n, 4) ~= 0
            error('qam16_gui:InvalidBits', 'Bit count must be at least 4 and a multiple of 4.');
        end
        if any(~isfinite(dBs))
            error('qam16_gui:InvalidDB', 'All three Eb/N0 values must be finite.');
        end
        vals = [p.Ts p.Fs p.Fc];
        if any(~isfinite(vals)) || any(vals <= 0)
            error('qam16_gui:InvalidSignal', 'Ts, fs and fc must be positive and finite.');
        end
        sps = p.Ts*p.Fs;
        cycles = p.Ts*p.Fc;
        if ~isfinite(sps) || round(sps) < 8 || round(sps) > 1e5 || ...
                abs(sps-round(sps)) > 1e-8*max(1, round(sps))
            error('qam16_gui:InvalidSampling', 'fs·Ts must be an integer from 8 to 100000.');
        end
        if ~isfinite(cycles) || abs(cycles-round(cycles)) > 1e-9*max(1, cycles) || round(cycles) < 1
            error('qam16_gui:InvalidCarrier', 'fc·Ts must be a positive integer (orthogonal I/Q carriers).');
        end
        if p.Fs <= 2*p.Fc
            error('qam16_gui:InvalidSampling', 'Sampling requires fs > 2·fc.');
        end
        if ~isfinite(p.Seed) || p.Seed ~= fix(p.Seed) || p.Seed < 0 || p.Seed > 2^32-2
            error('qam16_gui:InvalidSeed', 'Seed must be an integer from 0 to 2^32−2.');
        end
        if n/4*round(sps) > 2e7
            error('qam16_gui:TooManySamples', ...
                'Too many samples: (bits/4)·fs·Ts must not exceed 2·10^7. Reduce the bit count or fs·Ts.');
        end
    end

    function send_bits(~, ~)
        btn.Enable = 'off';
        restoreButton = onCleanup(@enable_button); %#ok<NASGU>
        try
            [n, dBs, p] = read_settings();
            status.Text = 'Sending: transmitter → noisy channel → I/Q correlators...';
            drawnow;
            pending = cell(1, 3);
            for j = 1:3
                one = qam16_experiment(n, dBs(j), p);
                one.EbN0dB = dBs(j);
                one.label = sprintf('%d) %g dB', j, dBs(j));
                pending{j} = one;
                if ~isvalid(fig), return; end
                status.Text = sprintf('%d/3 experiments complete (%g dB).', j, dBs(j));
                drawnow;
            end
            results = [pending{:}];
            setappdata(fig, 'QAM16Results', results);
            fig.UserData = struct('results', results, 'nBits', n, ...
                'EbN0dB', dBs, 'settings', p);
            plot_ber(n, dBs);
            tableData = cell(3, 8);
            for j = 1:3
                one = results(j);
                if one.nErr == 0
                    meaning = sprintf('0 errors; 95%% upper bound %.3g (conservative)', one.zeroErrorUpper95);
                    measured = '0';
                else
                    meaning = sprintf('about 1 error per %g bits', max(1, round(n/one.nErr)));
                    measured = sprintf('%.3e', one.BER);
                end
                tableData(j, :) = {dBs(j), sprintf('%d',n), sprintf('%d',one.nSymbols), ...
                    sprintf('%d',one.nErr), measured, ...
                    sprintf('%.3e', one.SER), sprintf('%.3e', ber_theory('qam16', dBs(j))), meaning};
            end
            tbl.Data = tableData;
            dd.Items = {results.label}; dd.ItemsData = 1:3;
            dd.Value = 1; dd.Enable = 'on';
            show_experiment(1);
            settings_info();
            enable_button();
            status.Text = sprintf('Done: 3 experiments × %d bits. Same bits and shared noise samples.', n);
            drawnow;
            if ~isempty(options.ExportDir)
                try
                    export_snapshot();
                catch exportError
                    status.Text = sprintf('Experiment complete; snapshot export failed: %s', exportError.message);
                end
            end
        catch err
            if isvalid(fig)
                status.Text = ['Error: ' err.message];
                if strcmp(fig.Visible, 'on')
                    uialert(fig, err.message, 'Experiment failed');
                end
            end
        end
    end

    function enable_button()
        if isvalid(btn)
            btn.Enable = 'on';
        end
    end

    function plot_ber(n, dBs)
        cla(axBer); legend(axBer, 'off'); hold(axBer, 'on'); grid(axBer, 'on');
        xLimits = [min(-5, min(dBs)-1), max(20, max(dBs)+1)];
        theoryDB = linspace(xLimits(1), xLimits(2), 301);
        plot(axBer, theoryDB, ber_theory('qam16', theoryDB), '-', ...
            'Color', blue, 'LineWidth', 1.8, 'DisplayName', 'exact Gray 16-QAM theory');
        upper = results(1).zeroErrorUpper95;
        positiveBER = [results.BER]; positiveBER = positiveBER(positiveBER > 0);
        axBer.YScale = 'log';
        axBer.XLim = xLimits;
        axBer.YLim = [min([1e-6, upper/2, positiveBER/2]), 1];
        for j = 1:3
            one = results(j);
            if one.nErr == 0
                y = upper;
                plot(axBer, dBs(j), y, 'v', 'MarkerSize', 10, ...
                    'LineWidth', 1.5, 'MarkerEdgeColor', orange, 'HandleVisibility', 'off');
            else
                y = one.BER;
                plot(axBer, dBs(j), y, 'o', 'MarkerSize', 9, 'LineWidth', 1.5, ...
                    'MarkerFaceColor', orange, 'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
            end
            text(axBer, dBs(j), min(0.8, y*2), sprintf('%d/%d', one.nErr, n), ...
                'HorizontalAlignment', 'center', 'FontSize', 10);
            xline(axBer, dBs(j), ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
        end
        plot(axBer, NaN, NaN, 'o', 'MarkerFaceColor', orange, 'MarkerEdgeColor', 'k', ...
            'DisplayName', 'measured BER');
        plot(axBer, NaN, NaN, 'v', 'MarkerEdgeColor', orange, ...
            'DisplayName', '0 errors: 95% upper bound (conservative)');
        xlabel(axBer, 'E_b/N_0 (dB)   →   less noise');
        ylabel(axBer, 'BER (bit error rate)');
        title(axBer, {'BER: Theory and Experiment', sprintf('%d bits at each dB value', n)});
        legend(axBer, 'Location', 'southwest', 'FontSize', 10);
    end

    function show_experiment(idx)
        if isempty(results), return; end
        one = results(idx);
        symbolError = any(reshape(one.bits(:) ~= one.bits_hat(:), 4, []), 1).';
        count = min(4000, one.nSymbols);
        received = one.rxSymbols(1:count);
        wrong = symbolError(1:count);
        cla(axConst); legend(axConst, 'off'); hold(axConst, 'on'); grid(axConst, 'on');
        scatter(axConst, real(received(~wrong)), imag(received(~wrong)), 9, blue, ...
            'filled', 'MarkerFaceAlpha', 0.35, 'DisplayName', 'correct symbol');
        scatter(axConst, real(received(wrong)), imag(received(wrong)), 16, red, ...
            'filled', 'MarkerFaceAlpha', 0.65, 'DisplayName', 'symbol error');
        levels = [-3 -1 1 3]/sqrt(10);
        [ii, qq] = meshgrid(levels, levels);
        foreground = axConst.XColor;
        plot(axConst, ii(:), qq(:), '+', 'Color', foreground, 'LineWidth', 1.4, ...
            'MarkerSize', 9, 'DisplayName', 'ideal points + Gray bits');
        grayBits = {'00', '01', '11', '10'};
        for a = 1:4
            for b = 1:4
                text(axConst, levels(a)+0.04, levels(b)+0.07, ...
                    [grayBits{a} grayBits{b}], 'FontSize', 9, 'Color', foreground);
            end
        end
        for threshold = [-2 0 2]/sqrt(10)
            xline(axConst, threshold, '--', 'Color', foreground, 'HandleVisibility', 'off');
            yline(axConst, threshold, '--', 'Color', foreground, 'HandleVisibility', 'off');
        end
        lim = max(1.35, 1.05*max(abs([real(received(:)); imag(received(:))])));
        axis(axConst, 'equal');
        axConst.XLim = [-lim lim]; axConst.YLim = [-lim lim];
        xlabel(axConst, 'I (correlator output)'); ylabel(axConst, 'Q (correlator output)');
        title(axConst, {sprintf('Received Symbols: %g dB', one.EbN0dB), ...
            sprintf('first %d; SER %.3g', count, one.SER)});
        legend(axConst, 'Location', 'southoutside', 'FontSize', 10);

        m = min(200, numel(one.bits));
        correct = one.bits(1:m) == one.bits_hat(1:m);
        correct = correct(:).';
        img = zeros(1, m, 3);
        img(1, correct, 1) = 0.30; img(1, correct, 2) = 0.69; img(1, correct, 3) = 0.31;
        img(1, ~correct, 1) = red(1); img(1, ~correct, 2) = red(2); img(1, ~correct, 3) = red(3);
        cla(axStrip); image(axStrip, img);
        axStrip.XLim = [0.5 m+0.5]; axStrip.YLim = [0.5 1.5];
        axStrip.YTick = []; axStrip.XTick = unique([1 50:50:m]);
        xlabel(axStrip, 'bit index; green = correct, red = error');
        title(axStrip, sprintf('%g dB: first %d bits, %d errors; total %d bits, %d errors', ...
            one.EbN0dB, m, sum(~correct), numel(one.bits), one.nErr));
        axis_histogram(axI, sqrt(10)*real(one.rxSymbols), 'I', one.EbN0dB);
        axis_histogram(axQ, sqrt(10)*imag(one.rxSymbols), 'Q', one.EbN0dB);
        show_wave(one);
    end

    function axis_histogram(ax, values, axisName, dB)
        cla(ax); legend(ax, 'off'); hold(ax, 'on'); grid(ax, 'on');
        histogram(ax, values, 55, 'FaceColor', blue, 'FaceAlpha', 0.7, ...
            'DisplayName', 'received level');
        for threshold = [-2 0 2]
            xline(ax, threshold, '--', 'Color', ax.XColor, 'HandleVisibility', 'off');
        end
        for level = [-3 -1 1 3]
            xline(ax, level, ':', 'Color', orange, 'HandleVisibility', 'off');
        end
        xlabel(ax, [axisName ' level (scaled by √10)']);
        ylabel(ax, 'symbol count');
        title(ax, {sprintf('%s Distribution: %g dB', axisName, dB), ...
            'ideal: −3, −1, +1, +3; thresholds: −2, 0, +2'});
    end

    function show_wave(one)
        cla(axWave); legend(axWave, 'off'); hold(axWave, 'on'); grid(axWave, 'on');
        m = min([4*one.settings.sps, numel(one.wave.t), ...
            numel(one.wave.s), numel(one.wave.r)]);
        t = one.wave.t(:); s = one.wave.s(:); r = one.wave.r(:);
        plot(axWave, t(1:m), r(1:m), 'Color', orange, 'DisplayName', 'channel output r(t)');
        plot(axWave, t(1:m), s(1:m), 'Color', blue, 'LineWidth', 1.2, ...
            'DisplayName', 'transmitter s(t)');
        for boundary = one.settings.Ts*(1:3)
            if boundary <= t(m)
                xline(axWave, boundary, ':', 'Color', axWave.XColor, 'HandleVisibility', 'off');
            end
        end
        axWave.XLim = [t(1), max(t(m), t(1)+1/one.settings.Fs)];
        xlabel(axWave, 'time (s)'); ylabel(axWave, 'amplitude');
        title(axWave, sprintf('First %d Symbols: Real Passband, %g dB', ...
            min(4, one.nSymbols), one.EbN0dB));
        legend(axWave, 'Location', 'northeast');
    end

    function empty_plots()
        axBer.YScale = 'log'; axBer.YLim = [1e-6 1]; axBer.XLim = [-5 20];
        grid(axBer, 'on'); xlabel(axBer, 'E_b/N_0 (dB)'); ylabel(axBer, 'BER');
        title(axBer, 'BER: Theory and Experiment');
        grid(axConst, 'on'); xlabel(axConst, 'I'); ylabel(axConst, 'Q');
        title(axConst, 'Received Constellation');
        axStrip.XTick = []; axStrip.YTick = []; title(axStrip, 'Errors in the First 200 Bits');
        title(axI, 'I Levels'); title(axQ, 'Q Levels');
        title(axWave, 'Transmitter and Channel: First 4 Symbols');
    end

    function export_snapshot()
        if ~isfolder(options.ExportDir)
            [ok, message] = mkdir(options.ExportDir);
            if ~ok
                error('qam16_gui:ExportDirectory', 'Could not create the export folder: %s', message);
            end
        end
        drawnow;
        exportapp(fig, fullfile(options.ExportDir, 'qam16_gui.png'));
    end
end

function options = gui_options(options)
    if ~isstruct(options) || ~isscalar(options)
        error('qam16_gui:InvalidOptions', 'options must be a scalar struct.');
    end
    if ~isfield(options, 'Visible'), options.Visible = 'on'; end
    if ~isfield(options, 'AutoRun'), options.AutoRun = false; end
    if ~isfield(options, 'ExportDir'), options.ExportDir = ''; end
    if isstring(options.Visible) && isscalar(options.Visible)
        options.Visible = char(options.Visible);
    end
    if ~ischar(options.Visible) || ~isrow(options.Visible) || ...
            ~any(strcmp(options.Visible, {'on', 'off'}))
        error('qam16_gui:InvalidOptions', 'Visible must be ''on'' or ''off''.');
    end
    if ~(islogical(options.AutoRun) || isnumeric(options.AutoRun)) || ...
            ~isscalar(options.AutoRun) || ~isreal(options.AutoRun) || ...
            ~isfinite(options.AutoRun) || ~any(options.AutoRun == [0 1])
        error('qam16_gui:InvalidOptions', 'AutoRun must be true or false.');
    end
    options.AutoRun = logical(options.AutoRun);
    if isstring(options.ExportDir) && isscalar(options.ExportDir)
        options.ExportDir = char(options.ExportDir);
    end
    if ~ischar(options.ExportDir) || (~isempty(options.ExportDir) && ~isrow(options.ExportDir))
        error('qam16_gui:InvalidOptions', 'ExportDir must be a folder path or empty text.');
    end
end
