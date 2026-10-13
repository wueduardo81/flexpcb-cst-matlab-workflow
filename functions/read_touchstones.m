function [files, runIdx] = read_touchstones(folder)
%READ_TOUCHSTONES Find and sort CST Touchstone files by sweep RunID.
%
% Usage:
%   files = read_touchstones(folder);
%   [files, runIdx] = read_touchstones(folder);
%
% Inputs:
%   folder : directory containing .s4p files
%
% Outputs:
%   files  : cell array of full file paths sorted by final numeric RunID
%   runIdx : numeric RunID extracted from each filename
%
% Expected CST naming pattern, for example:
%   FlexPCB_ECSS_Coverlay_Baseline_1.s4p
%   FlexPCB_ECSS_Coverlay_Baseline_2.s4p
%   ...
%   FlexPCB_ECSS_Coverlay_Baseline_35.s4p

    if nargin < 1 || isempty(folder)
        folder = pwd;
    end

    d = dir(fullfile(folder, '*.s4p'));

    if isempty(d)
        error('No .s4p files found in folder: %s', folder);
    end

    n = numel(d);
    runIdx = NaN(n,1);

    for i = 1:n
        [~, name, ~] = fileparts(d(i).name);

        % Extract the final integer after the last underscore.
        tok = regexp(name, '_(\d+)$', 'tokens', 'once');

        if isempty(tok)
            error(['Could not extract a final numeric RunID from filename: %s\n' ...
                   'Expected a name ending in _<RunID>.s4p.'], d(i).name);
        end

        runIdx(i) = str2double(tok{1});
    end

    if numel(unique(runIdx)) ~= numel(runIdx)
        error('Duplicate RunIDs were detected in the Touchstone filenames.');
    end

    [runIdx, order] = sort(runIdx);
    d = d(order);

    files = fullfile(folder, {d.name})';

    fprintf('\nTouchstone files found in sweep order:\n');
    for i = 1:numel(files)
        [~, name, ext] = fileparts(files{i});
        fprintf('  Run %d -> %s%s\n', runIdx(i), name, ext);
    end
    fprintf('\n');
end
