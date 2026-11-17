function test_qam16_gui
%TEST_QAM16_GUI Exercise real callbacks, invalid settings and zero-error UI.
    root=fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(root,'gui'));
    f=qam16_gui(struct('Visible','off','AutoRun',true));
    cleanup=onCleanup(@()close(f)); %#ok<NASGU>
    data=getappdata(f,'QAM16Results');
    assert(numel(data)==3 && all(arrayfun(@(r)numel(r.bits)==40000,data)));
    assert(isequal(data(1).bits,data(3).bits));
    btn=findall(f,'Tag','QAM16Send');
    count=findall(f,'Tag','QAM16Bits');
    fc=findall(f,'Tag','QAM16Fc');
    status=findall(f,'Tag','QAM16Status');
    dd=findall(f,'Tag','QAM16Select');
    tableView=findall(f,'Tag','QAM16Table');
    callback=btn.ButtonPushedFcn;
    assert(strcmp(btn.Enable,'on') && size(tableView.Data,1)==3);
    count.Value=42; callback(btn,[]);
    assert(startsWith(status.Text,'Error:') && strcmp(btn.Enable,'on'));
    count.Value=40000; fc.Value=4.3; callback(btn,[]);
    assert(startsWith(status.Text,'Error:') && strcmp(btn.Enable,'on'));
    fc.Value=4; count.Value=400;
    for j=1:3
        edit=findall(f,'Tag',sprintf('QAM16DB%d',j)); edit.Value=30;
    end
    callback(btn,[]);
    data=getappdata(f,'QAM16Results');
    assert(numel(data)==3 && all([data.nErr]==0));
    assert(all([data.zeroErrorUpper95]>0));
    assert(contains(tableView.Data{1,8},'upper bound'));
    dd.Value=3; selectionCallback=dd.ValueChangedFcn; selectionCallback(dd,[]);
    assert(strcmp(btn.Enable,'on'));
    fprintf('PASS: real GUI callbacks, invalid bit/carrier recovery, zero-error bound,\n');
    fprintf('      duplicate dB labels, dropdown selection, results table, enabled button.\n');
end
