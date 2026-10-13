function plot_parameter_sweep_heatmaps(T, outDir)
%PLOT_PARAMETER_SWEEP_HEATMAPS Generate publication-style sweep heatmaps.
%
% X axis : trace width W_mm
% Y axis : trace gap Gap_mm
%
% Heatmaps generated:
%   - Differential transmission at 10 GHz
%   - Mean differential transmission over 0.5-10 GHz
%   - Worst-case differential reflection
%   - Worst-case mode conversion

    if nargin < 2 || isempty(outDir)
        outDir = pwd;
    end

    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    requiredVars = {'W_mm', 'Gap_mm'};

    for k = 1:numel(requiredVars)
        if ~ismember(requiredVars{k}, T.Properties.VariableNames)
            error('Required variable "%s" not found in input table.', requiredVars{k});
        end
    end

    make_heatmap_if_available(T, outDir, ...
        'Transmission_10p0GHz_dB', ...
        'Differential transmission at 10 GHz', ...
        'S_{dd21} at 10 GHz (dB)', ...
        'Transmission_10GHz_heatmap.png');

    make_heatmap_if_available(T, outDir, ...
        'MeanTransmission_0p5_10GHz_dB', ...
        'Mean differential transmission, 0.5-10 GHz', ...
        'Mean S_{dd21}, 0.5-10 GHz (dB)', ...
        'MeanTransmission_heatmap.png');

    make_heatmap_if_available(T, outDir, ...
        'WorstReflection_dB', ...
        'Worst-case differential reflection', ...
        'Worst S_{dd11} (dB)', ...
        'WorstReflection_heatmap.png');

    make_heatmap_if_available(T, outDir, ...
        'WorstModeConversion_dB', ...
        'Worst-case mode conversion', ...
        'Worst mode conversion (dB)', ...
        'ModeConversion_heatmap.png');

    fprintf('Heatmaps saved in: %s\n', outDir);
end


function make_heatmap_if_available(T, outDir, metricName, plotTitle, colorbarLabel, outName)

    if ~ismember(metricName, T.Properties.VariableNames)
        warning('Metric %s not found. Skipping heatmap.', metricName);
        return;
    end

    W_values = sort(unique(T.W_mm));
    Gap_values = sort(unique(T.Gap_mm));

    Z = NaN(numel(Gap_values), numel(W_values));

    for i = 1:height(T)
        w = T.W_mm(i);
        g = T.Gap_mm(i);

        iw = find(abs(W_values - w) < 1e-12, 1);
        ig = find(abs(Gap_values - g) < 1e-12, 1);

        if ~isempty(iw) && ~isempty(ig)
            Z(ig, iw) = T.(metricName)(i);
        end
    end

    fig = figure('Color', 'w');

    imagesc(1:numel(W_values), 1:numel(Gap_values), Z);
    set(gca, 'YDir', 'normal');

    cb = colorbar;
    ylabel(cb, colorbarLabel, 'FontSize', 14);

    xticks(1:numel(W_values));
    yticks(1:numel(Gap_values));

    xticklabels(arrayfun(@(x) sprintf('%.2f', x), ...
        W_values, 'UniformOutput', false));

    yticklabels(arrayfun(@(x) sprintf('%.2f', x), ...
        Gap_values, 'UniformOutput', false));

    xlabel('Trace width, W (mm)', 'FontSize', 16);
    ylabel('Trace gap, Gap (mm)', 'FontSize', 16);
    title(plotTitle, 'FontSize', 15, 'FontWeight', 'bold');

    axis tight;
    axis square;

    set(gca, 'FontSize', 14);
    set(gca, 'LineWidth', 1.0);
    grid off;
    hold on;

    % Draw cell borders.
    for x = 0.5:1:(numel(W_values)+0.5)
        plot([x x], [0.5 numel(Gap_values)+0.5], 'k-', 'LineWidth', 0.8);
    end

    for y = 0.5:1:(numel(Gap_values)+0.5)
        plot([0.5 numel(W_values)+0.5], [y y], 'k-', 'LineWidth', 0.8);
    end

    % Add numeric cell labels.
    zMin = min(Z(:), [], 'omitnan');
    zMax = max(Z(:), [], 'omitnan');

    for ig = 1:numel(Gap_values)
        for iw = 1:numel(W_values)
            val = Z(ig, iw);

            if isnan(val)
                continue;
            end

            if zMax > zMin
                normVal = (val - zMin) / (zMax - zMin);
            else
                normVal = 0.5;
            end

            if normVal < 0.35
                txtColor = 'w';
            else
                txtColor = 'k';
            end

            text(iw, ig, sprintf('%.2f', val), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'FontSize', 11, ...
                'FontWeight', 'bold', ...
                'Color', txtColor);
        end
    end

    outFile = fullfile(outDir, outName);
    exportgraphics(fig, outFile, 'Resolution', 300);
    close(fig);
end
