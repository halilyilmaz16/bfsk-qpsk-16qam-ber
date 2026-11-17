function verify_english_materials
%VERIFY_ENGLISH_MATERIALS Check unchanged results and refresh English figures.
    root=fileparts(fileparts(mfilename('fullpath')));
    output=fullfile(root,'results','qam16');
    originalFolder=pwd; originalPath=path;
    restore=onCleanup(@()restoreEnvironment(originalFolder,originalPath)); %#ok<NASGU>
    cd(root); addpath('src','gui');
    before=readtable(fullfile(output,'qam16_ber.csv'));
    test_qam16;
    test_qam16_gui;
    run_qam16_analysis;
    after=readtable(fullfile(output,'qam16_ber.csv'));
    assert(isequal(before.BitErrors,after.BitErrors),'Translation changed measured errors.');
    assert(isequal(before.BER_Passband,after.BER_Passband),'Translation changed BER.');
    f=qam16_gui(struct('Visible','off','AutoRun',true));
    figCleanup=onCleanup(@()closeIfValid(f));
    data=getappdata(f,'QAM16Results');
    assert(isequal([data.nErr],[5629 1105 4]));
    button=findall(f,'Tag','QAM16Send'); run=button.ButtonPushedFcn;
    f.Theme='light'; run(button,[]); drawnow; pause(0.5);
    exportapp(f,fullfile(output,'qam16_gui.png'));
    exportapp(f,fullfile(output,'qam16_gui_light.png'));
    f.Theme='dark'; run(button,[]); drawnow; pause(0.5);
    exportapp(f,fullfile(output,'qam16_gui_dark.png'));
    f.Theme='light'; run(button,[]);
    group=findall(f,'Type','uitabgroup');
    group.SelectedTab=findall(f,'Type','uitab','Title','I/Q and waveform');
    drawnow; pause(0.5); exportapp(f,fullfile(output,'qam16_gui_iq.png'));
    group.SelectedTab=findall(f,'Type','uitab','Title','Experiment results');
    f.Position=[60 60 1050 720]; drawnow; pause(1);
    run(button,[]); drawnow; pause(0.5);
    exportapp(f,fullfile(output,'qam16_gui_compact.png'));
    clear figCleanup

    % Copy only the standalone file; the maintained src/gui paths are removed.
    isolated=fullfile(root,'tmp','english_standalone_check');
    if ~isfolder(isolated), mkdir(isolated); end
    copyfile(fullfile(root,'teslim','qam16_standalone.m'),isolated);
    rmpath(fullfile(root,'src'),fullfile(root,'gui'));
    cd(isolated);
    assert(isempty(which('qam16_gui')) && isempty(which('qam16_experiment')));
    f=qam16_standalone(struct('Visible','off','AutoRun',true));
    figCleanup=onCleanup(@()closeIfValid(f)); %#ok<NASGU>
    data=getappdata(f,'QAM16Results');
    assert(isequal([data.nErr],[5629 1105 4]));
    assert(strcmp(findall(f,'Tag','QAM16Send').Text,'Run'));
    [files,products]=matlab.codetools.requiredFilesAndProducts( ...
        fullfile(isolated,'qam16_standalone.m'));
    assert(numel(files)==1 && numel(products)==1 && strcmp(products.Name,'MATLAB'));
    fprintf('PASS: English GUI, unchanged BER/error counts, standalone file and MATLAB-only dependency.\n');
end

function closeIfValid(f)
    if isgraphics(f), close(f); end
end

function restoreEnvironment(folder,oldPath)
    cd(folder); path(oldPath);
end
