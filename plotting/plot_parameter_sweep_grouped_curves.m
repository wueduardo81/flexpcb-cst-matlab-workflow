function plot_parameter_sweep_grouped_curves(folder, T, outDir)
%PLOT_PARAMETER_SWEEP_GROUPED_CURVES Generate grouped mixed-mode responses.
%
% Creates curves:
%   - at fixed Gap while varying W
%   - at fixed W while varying Gap
%
% For each group:
%   - Differential transmission, Sdd21
%   - Differential reflection, Sdd11
%   - Conservative mode-conversion metric:
%         MC(f) = max(Scd21_dB, Sdc21_dB)
%
% The Touchstone file is matched to each table row using RunID rather than
% row position. This keeps the mapping correct even if T has been sorted by
% geometry after the main analysis.

    if nargin < 3 || isempty(outDir)
        outDir = pwd;
    end

    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    requiredVars = {'RunID','Gap_mm','W_mm'};
    for k = 1:numel(requiredVars)
        if ~ismember(requiredVars{k}, T.Properties.VariableNames)
            error('T must contain variable "%s".', requiredVars{k});
        end
    end

    [files, fileRunIDs] = read_touchstones(folder);

    if numel(files) ~= height(T)
        error('Number of .s4p files does not match number of rows in T.');
    end

    if ~isequal(sort(fileRunIDs(:)), sort(T.RunID(:)))
        error('RunIDs in Touchstone filenames do not match RunIDs in T.');
    end

    groupedDir = fullfile(outDir, 'grouped_curves');

    if ~exist(groupedDir, 'dir')
        mkdir(groupedDir);
    end

    Gap_values = sort(unique(T.Gap_mm));
    W_values = sort(unique(T.W_mm));

    % Fixed Gap, varying W.
    for i = 1:numel(Gap_values)

        gap = Gap_values(i);
        idx = find(abs(T.Gap_mm - gap) < 1e-12);
        idx = sort_by_variable(T, idx, 'W_mm');

        labelSuffix = sprintf('Gap = %.2f mm', gap);
        fileSuffix = sprintf('Gap_%s', number_to_tag(gap));

        plot_group(files, fileRunIDs, T, idx, 'Sdd21', ...
            ['Differential transmission - ' labelSuffix], ...
            'S_{dd21} (dB)', ...
            'W', ...
            fullfile(groupedDir, ['Sdd21_by_' fileSuffix '.png']));

        plot_group(files, fileRunIDs, T, idx, 'Sdd11', ...
            ['Differential reflection - ' labelSuffix], ...
            'S_{dd11} (dB)', ...
            'W', ...
            fullfile(groupedDir, ['Sdd11_by_' fileSuffix '.png']));

        plot_group(files, fileRunIDs, T, idx, 'MC', ...
            ['Mode conversion - ' labelSuffix], ...
            'MC(f) (dB)', ...
            'W', ...
            fullfile(groupedDir, ['ModeConversion_by_' fileSuffix '.png']));
    end

    % Fixed W, varying Gap.
    for i = 1:numel(W_values)

        w = W_values(i);
        idx = find(abs(T.W_mm - w) < 1e-12);
        idx = sort_by_variable(T, idx, 'Gap_mm');

        labelSuffix = sprintf('W = %.2f mm', w);
        fileSuffix = sprintf('W_%s', number_to_tag(w));

        plot_group(files, fileRunIDs, T, idx, 'Sdd21', ...
            ['Differential transmission - ' labelSuffix], ...
            'S_{dd21} (dB)', ...
            'Gap', ...
            fullfile(groupedDir, ['Sdd21_by_' fileSuffix '.png']));

        plot_group(files, fileRunIDs, T, idx, 'Sdd11', ...
            ['Differential reflection - ' labelSuffix], ...
            'S_{dd11} (dB)', ...
            'Gap', ...
            fullfile(groupedDir, ['Sdd11_by_' fileSuffix '.png']));

        plot_group(files, fileRunIDs, T, idx, 'MC', ...
            ['Mode conversion - ' labelSuffix], ...
            'MC(f) (dB)', ...
            'Gap', ...
            fullfile(groupedDir, ['ModeConversion_by_' fileSuffix '.png']));
    end

    fprintf('Grouped curves saved in: %s\n', groupedDir);
end


function idxSorted = sort_by_variable(T, idx, varName)

    [~, order] = sort(T.(varName)(idx));
    idxSorted = idx(order);
end


function plot_group(files, fileRunIDs, T, idx, metricType, ...
    plotTitle, yLabel, legendMode, outFile)

    fig = figure('Color', 'w');
    hold on;
    grid on;

    for k = 1:numel(idx)

        row = idx(k);
        runID = T.RunID(row);

        filePos = find(fileRunIDs == runID, 1);

        if isempty(filePos)
            error('No Touchstone file found for RunID %d.', runID);
        end

        file = files{filePos};

        [fGHz, Sdd11_dB, Sdd21_dB, Scd21_dB, Sdc21_dB] = ...
            read_mixedmode_curves_local(file);

        switch metricType
            case 'Sdd21'
                y = Sdd21_dB;

            case 'Sdd11'
                y = Sdd11_dB;

            case 'MC'
                y = max(Scd21_dB, Sdc21_dB);

            otherwise
                error('Unknown metricType: %s', metricType);
        end

        switch legendMode
            case 'W'
                label = sprintf('W = %.2f mm', T.W_mm(row));

            case 'Gap'
                label = sprintf('Gap = %.2f mm', T.Gap_mm(row));

            otherwise
                label = sprintf('Run %d', runID);
        end

        plot(fGHz, y, 'LineWidth', 1.5, 'DisplayName', label);
    end

    xlabel('Frequency (GHz)', 'FontSize', 14);
    ylabel(yLabel, 'FontSize', 14);
    title(plotTitle, 'FontSize', 16, 'FontWeight', 'bold');

    legend('Location', 'best');
    set(gca, 'FontSize', 13);
    set(gca, 'LineWidth', 1.0);

    xlim([0 10]);

    switch metricType
        case 'Sdd21'
            ylim([-18 0]);

        case 'Sdd11'
            ylim([-30 0]);

        case 'MC'
            ylim([-50 0]);
    end

    exportgraphics(fig, outFile, 'Resolution', 300);
    close(fig);
end


function [fGHz, Sdd11_dB, Sdd21_dB, Scd21_dB, Sdc21_dB] = ...
    read_mixedmode_curves_local(file)

    Sobj = sparameters(file);

    fGHz = Sobj.Frequencies / 1e9;
    S = Sobj.Parameters;

    Smm = s4p_to_mixedmode(S);

    Sdd11 = extract_mm_parameter(Smm, 'Sdd11');
    Sdd21 = extract_mm_parameter(Smm, 'Sdd21');
    Scd21 = extract_mm_parameter(Smm, 'Scd21');
    Sdc21 = extract_mm_parameter(Smm, 'Sdc21');

    Sdd11_dB = 20*log10(abs(Sdd11));
    Sdd21_dB = 20*log10(abs(Sdd21));
    Scd21_dB = 20*log10(abs(Scd21));
    Sdc21_dB = 20*log10(abs(Sdc21));
end


function tag = number_to_tag(x)

    tag = sprintf('%.2f', x);
    tag = strrep(tag, '.', 'p');
end
