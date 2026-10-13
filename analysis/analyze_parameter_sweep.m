function T = analyze_parameter_sweep(folder, outDir, logFile)
%ANALYZE_PARAMETER_SWEEP Analyze a CST parameter sweep of 4-port interconnects.

    if nargin < 1 || isempty(folder), folder = pwd; end
    if nargin < 2 || isempty(outDir), outDir = fullfile(folder, 'analysis_results'); end
    if nargin < 3 || isempty(logFile)
        error('A CST parameter-sweep text file must be provided.');
    end

    if ~exist(outDir, 'dir'), mkdir(outDir); end

    freqs_eval_GHz = [2.5 5 7.5 10];

    files = read_touchstones(folder);
    nFiles = numel(files);

    if nFiles == 0
        error('No .s4p files found in folder: %s', folder);
    end

    runs = parse_parameter_sweep_log(logFile);
    nRuns = height(runs);

    if nRuns == 0
        error('No runs were found in logfile: %s', logFile);
    end

    if nFiles ~= nRuns
        error(['Number of .s4p files and logfile runs do not match.\n' ...
               '  .s4p files found : %d\n' ...
               '  logfile runs     : %d'], nFiles, nRuns);
    end

    Case = cell(nFiles, 1);
    Transmission = NaN(nFiles, numel(freqs_eval_GHz));
    Reflection = NaN(nFiles, numel(freqs_eval_GHz));
    Scd = NaN(nFiles, numel(freqs_eval_GHz));
    Sdc = NaN(nFiles, numel(freqs_eval_GHz));

    WorstTransmission = NaN(nFiles, 1);
    MeanTransmission = NaN(nFiles, 1);
    MeanTransmission_0p5_10 = NaN(nFiles, 1);
    MeanTransmission_1_10 = NaN(nFiles, 1);
    WorstReflection = NaN(nFiles, 1);
    BestReflection = NaN(nFiles, 1);
    WorstMC = NaN(nFiles, 1);
    WorstTransmissionFreq = NaN(nFiles, 1);
    WorstReflectionFreq = NaN(nFiles, 1);
    WorstMCFreq = NaN(nFiles, 1);

    for i = 1:nFiles
        [~, name, ext] = fileparts(files{i});
        Case{i} = [name ext];

        r = analyze_touchstone(files{i}, freqs_eval_GHz);

        Transmission(i,:) = r.Transmission_dB;
        Reflection(i,:) = r.Reflection_dB;
        Scd(i,:) = r.Scd_dB;
        Sdc(i,:) = r.Sdc_dB;

        WorstTransmission(i) = r.WorstTransmission_dB;
        MeanTransmission(i) = r.MeanTransmission_dB;
        MeanTransmission_0p5_10(i) = r.MeanTransmission_0p5_10GHz_dB;
        MeanTransmission_1_10(i) = r.MeanTransmission_1_10GHz_dB;

        WorstReflection(i) = r.WorstReflection_dB;
        BestReflection(i) = r.BestReflection_dB;
        WorstMC(i) = r.WorstModeConversion_dB;

        WorstTransmissionFreq(i) = r.WorstTransmission_freq_GHz;
        WorstReflectionFreq(i) = r.WorstReflection_freq_GHz;
        WorstMCFreq(i) = r.WorstModeConversion_freq_GHz;
    end

    T = table(Case);
    T.RunID = runs.RunID;

    runVarNames = runs.Properties.VariableNames;
    for k = 1:numel(runVarNames)
        varName = runVarNames{k};
        if strcmp(varName, 'RunID'), continue; end
        T.(varName) = runs.(varName);
    end

    for k = 1:numel(freqs_eval_GHz)
        f0 = freqs_eval_GHz(k);
        T.(make_freq_varname('Transmission', f0)) = Transmission(:,k);
        T.(make_freq_varname('Reflection', f0)) = Reflection(:,k);
        T.(make_freq_varname('Scd', f0)) = Scd(:,k);
        T.(make_freq_varname('Sdc', f0)) = Sdc(:,k);
    end

    T.WorstTransmission_dB = WorstTransmission;
    T.WorstTransmission_freq_GHz = WorstTransmissionFreq;
    T.MeanTransmission_dB = MeanTransmission;
    T.MeanTransmission_0p5_10GHz_dB = MeanTransmission_0p5_10;
    T.MeanTransmission_1_10GHz_dB = MeanTransmission_1_10;

    T.WorstReflection_dB = WorstReflection;
    T.WorstReflection_freq_GHz = WorstReflectionFreq;
    T.BestReflection_dB = BestReflection;

    T.WorstModeConversion_dB = WorstMC;
    T.WorstModeConversion_freq_GHz = WorstMCFreq;

    T = add_sweep_scores(T);

    if all(ismember({'Gap_mm','W_mm'}, T.Properties.VariableNames))
        T = sortrows(T, {'Gap_mm','W_mm'});
    end

    csvFile = fullfile(outDir, 'parameter_sweep_metrics.csv');
    xlsxFile = fullfile(outDir, 'parameter_sweep_metrics.xlsx');
    matFile = fullfile(outDir, 'parameter_sweep_summary.mat');

    writetable(T, csvFile);

    try
        writetable(T, xlsxFile);
    catch ME
        warning('Could not write Excel file. CSV was still generated. Error: %s', ME.message);
    end

    save(matFile, 'T', 'runs', 'files', 'freqs_eval_GHz', 'logFile');

    analyze_weight_sensitivity(T, outDir);
end

function varName = make_freq_varname(prefix, fGHz)
    fStr = sprintf('%.1f', fGHz);
    fStr = strrep(fStr, '.', 'p');
    varName = sprintf('%s_%sGHz_dB', prefix, fStr);
end
