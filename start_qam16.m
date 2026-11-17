function fig = start_qam16(varargin)
%START_QAM16 Open the 16-QAM lab from the project root.
    root=fileparts(mfilename('fullpath'));
    addpath(fullfile(root,'src'),fullfile(root,'gui'));
    fig=qam16_gui(varargin{:});
end
