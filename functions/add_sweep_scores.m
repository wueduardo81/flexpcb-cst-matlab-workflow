function T = add_sweep_scores(T)
%ADD_SWEEP_SCORES Add normalized scores, total score, rank and recommendation.

    requiredVars = { ...
        'MeanTransmission_0p5_10GHz_dB', ...
        'Transmission_10p0GHz_dB', ...
        'WorstReflection_dB', ...
        'WorstModeConversion_dB'};

    for k = 1:numel(requiredVars)
        if ~ismember(requiredVars{k}, T.Properties.VariableNames)
            error('Required variable "%s" not found in table.', requiredVars{k});
        end
    end

    T.Score_MeanTrans = normalize_metric( ...
        T.MeanTransmission_0p5_10GHz_dB, 'higher');

    T.Score_Trans10GHz = normalize_metric( ...
        T.Transmission_10p0GHz_dB, 'higher');

    T.Score_Reflection = normalize_metric( ...
        T.WorstReflection_dB, 'lower');

    T.Score_ModeConversion = normalize_metric( ...
        T.WorstModeConversion_dB, 'lower');

    wMeanTrans = 0.35;
    wTrans10 = 0.25;
    wReflection = 0.20;
    wMC = 0.20;

    T.Score_Total = ...
        wMeanTrans * T.Score_MeanTrans + ...
        wTrans10 * T.Score_Trans10GHz + ...
        wReflection * T.Score_Reflection + ...
        wMC * T.Score_ModeConversion;

    [~, order] = sort(T.Score_Total, 'descend');

    rank = NaN(height(T), 1);
    rank(order) = (1:height(T)).';

    T.Rank_Total = rank;
    T.Recommended = false(height(T), 1);
    T.Recommended(order(1)) = true;

    T.Properties.UserData.Scoring.Description = ...
        ['Score_Total = 0.35 Score_MeanTrans + ' ...
         '0.25 Score_Trans10GHz + ' ...
         '0.20 Score_Reflection + ' ...
         '0.20 Score_ModeConversion'];
end

function score = normalize_metric(x, mode)
    x = double(x);

    if any(~isfinite(x))
        error('Metric contains NaN or Inf values and cannot be normalized.');
    end

    xmin = min(x);
    xmax = max(x);
    span = xmax - xmin;

    if abs(span) <= eps(max(abs([xmin xmax 1])))
        score = ones(size(x));
        return;
    end

    switch mode
        case 'higher'
            score = (x - xmin) ./ span;
        case 'lower'
            score = (xmax - x) ./ span;
        otherwise
            error('Unknown normalization mode: %s', mode);
    end
end
