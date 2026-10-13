function results = analyze_weight_sensitivity(T, outDir, nMonteCarlo, deltaW, rngSeed)
%ANALYZE_WEIGHT_SENSITIVITY Evaluate ranking sensitivity to scoring weights.

    if nargin < 2 || isempty(outDir), outDir = pwd; end
    if nargin < 3 || isempty(nMonteCarlo), nMonteCarlo = 100000; end
    if nargin < 4 || isempty(deltaW), deltaW = 0.10; end
    if nargin < 5 || isempty(rngSeed), rngSeed = 42; end

    if ~exist(outDir, 'dir'), mkdir(outDir); end

    requiredVars = { ...
        'Score_MeanTrans', ...
        'Score_Trans10GHz', ...
        'Score_Reflection', ...
        'Score_ModeConversion'};

    for k = 1:numel(requiredVars)
        if ~ismember(requiredVars{k}, T.Properties.VariableNames)
            error('Required variable "%s" not found in input table.', requiredVars{k});
        end
    end

    M = [ ...
        T.Score_MeanTrans, ...
        T.Score_Trans10GHz, ...
        T.Score_Reflection, ...
        T.Score_ModeConversion];

    if any(~isfinite(M), 'all')
        error('The normalized score columns contain NaN or Inf values.');
    end

    wNominal = [0.35 0.25 0.20 0.20];

    scenarioNames = { ...
        'Nominal'; 'Equal'; 'Transmission_priority'; ...
        'Balanced_SI'; 'Reflection_MC_priority'};

    Wscenario = [ ...
        0.35 0.25 0.20 0.20; ...
        0.25 0.25 0.25 0.25; ...
        0.40 0.30 0.15 0.15; ...
        0.30 0.20 0.25 0.25; ...
        0.20 0.15 0.325 0.325];

    scenarioRows = table();
    allScenarioRankings = cell(size(Wscenario,1),1);

    for s = 1:size(Wscenario,1)
        score = M * Wscenario(s,:).';
        [sortedScore, order] = sort(score, 'descend');

        rank = zeros(height(T),1);
        rank(order) = (1:height(T)).';

        Ts = T;
        Ts.SensitivityScore = score;
        Ts.SensitivityRank = rank;
        Ts = sortrows(Ts, 'SensitivityRank', 'ascend');
        allScenarioRankings{s} = Ts;

        topIdx = order(1);

        row = table();
        row.Scenario = string(scenarioNames{s});
        row.w_MeanTrans = Wscenario(s,1);
        row.w_Trans10GHz = Wscenario(s,2);
        row.w_Reflection = Wscenario(s,3);
        row.w_ModeConversion = Wscenario(s,4);
        row.Top1_Index = topIdx;
        row.Top1_Score = sortedScore(1);

        if ismember('RunID', T.Properties.VariableNames), row.Top1_RunID = T.RunID(topIdx); end
        if ismember('Gap_mm', T.Properties.VariableNames), row.Top1_Gap_mm = T.Gap_mm(topIdx); end
        if ismember('W_mm', T.Properties.VariableNames), row.Top1_W_mm = T.W_mm(topIdx); end

        scenarioRows = [scenarioRows; row]; %#ok<AGROW>
    end

    nominalScore = M * wNominal.';
    [~, nominalBestIdx] = max(nominalScore);

    rng(rngSeed, 'twister');
    lower = max(0, wNominal - deltaW);
    upper = min(1, wNominal + deltaW);

    top1Count = zeros(height(T),1);
    top3Count = zeros(height(T),1);
    sumW = zeros(1,4);
    sumW2 = zeros(1,4);
    minW = inf(1,4);
    maxW = -inf(1,4);

    accepted = 0;
    batchAcceptedTarget = 10000;

    while accepted < nMonteCarlo
        need = min(batchAcceptedTarget, nMonteCarlo - accepted);
        candidateCount = max(ceil(need * 2.5), 1000);
        acceptedW = zeros(0,4);

        while size(acceptedW,1) < need
            W123 = lower(1:3) + rand(candidateCount,3) .* (upper(1:3) - lower(1:3));
            w4 = 1 - sum(W123,2);
            valid = (w4 >= lower(4)) & (w4 <= upper(4));
            acceptedW = [acceptedW; W123(valid,:), w4(valid)]; %#ok<AGROW>
        end

        Wbatch = acceptedW(1:need,:);
        Wbatch(:,4) = 1 - sum(Wbatch(:,1:3),2);

        scoreBatch = M * Wbatch.';

        [~, idxTop1] = max(scoreBatch, [], 1);
        top1Count = top1Count + accumarray(idxTop1(:), 1, [height(T),1]);

        [~, orderBatch] = sort(scoreBatch, 1, 'descend');
        idxTop3 = orderBatch(1:min(3,height(T)),:);
        top3Count = top3Count + accumarray(idxTop3(:), 1, [height(T),1]);

        sumW = sumW + sum(Wbatch,1);
        sumW2 = sumW2 + sum(Wbatch.^2,1);
        minW = min(minW, min(Wbatch,[],1));
        maxW = max(maxW, max(Wbatch,[],1));

        accepted = accepted + need;
    end

    top1Probability = top1Count / nMonteCarlo;
    top3Probability = top3Count / nMonteCarlo;
    meanW = sumW / nMonteCarlo;
    stdW = sqrt(max(0, sumW2 / nMonteCarlo - meanW.^2));

    MC = table();
    MC.CandidateIndex = (1:height(T)).';

    if ismember('RunID', T.Properties.VariableNames), MC.RunID = T.RunID; end
    if ismember('Gap_mm', T.Properties.VariableNames), MC.Gap_mm = T.Gap_mm; end
    if ismember('W_mm', T.Properties.VariableNames), MC.W_mm = T.W_mm; end

    MC.Top1_Count = top1Count;
    MC.Top1_Probability = top1Probability;
    MC.Top3_Count = top3Count;
    MC.Top3_Probability = top3Probability;

    MC = sortrows(MC, {'Top1_Probability','Top3_Probability'}, ...
                      {'descend','descend'});

    scenarioFile = fullfile(outDir, 'weight_sensitivity_scenarios.csv');
    mcFile = fullfile(outDir, 'weight_sensitivity_monte_carlo_summary.csv');

    writetable(scenarioRows, scenarioFile);
    writetable(MC, mcFile);

    results = struct();
    results.NominalWeights = wNominal;
    results.DeltaW = deltaW;
    results.NMonteCarlo = nMonteCarlo;
    results.RngSeed = rngSeed;
    results.ScenarioSummary = scenarioRows;
    results.ScenarioRankings = allScenarioRankings;
    results.MonteCarloSummary = MC;
    results.MonteCarloWeightMin = minW;
    results.MonteCarloWeightMax = maxW;
    results.MonteCarloWeightMean = meanW;
    results.MonteCarloWeightStd = stdW;
    results.NominalBestIndex = nominalBestIdx;

    if ismember('RunID', T.Properties.VariableNames)
        results.NominalBestRunID = T.RunID(nominalBestIdx);
    end

    results.NominalBestTop1Probability = top1Probability(nominalBestIdx);
    results.OutputFiles.ScenariosCSV = scenarioFile;
    results.OutputFiles.MonteCarloCSV = mcFile;
end
