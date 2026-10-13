%% run_analysis.m
% Reproduce the CST-MATLAB mixed-mode signal-integrity analysis.
%
% Expected inputs:
%   data/parameter_sweep_log.txt
%   data/touchstone/*.s4p
%
% The script adds the repository folders to the MATLAB path, executes the
% complete parameter-sweep analysis, exports metrics/ranking results, runs
% the ranking-weight sensitivity study, and generates the main figures.

clear;
clc;

repoRoot = fileparts(mfilename('fullpath'));

analysisDir  = fullfile(repoRoot, 'analysis');
functionsDir = fullfile(repoRoot, 'functions');
plottingDir  = fullfile(repoRoot, 'plotting');
dataDir      = fullfile(repoRoot, 'data');
touchstoneDir = fullfile(dataDir, 'touchstone');
logFile      = fullfile(dataDir, 'parameter_sweep_log.txt');
resultsDir   = fullfile(repoRoot, 'results');

addpath(analysisDir);
addpath(functionsDir);
addpath(plottingDir);

if ~isfolder(touchstoneDir)
    error('Touchstone folder not found: %s', touchstoneDir);
end

if ~isfile(logFile)
    error(['CST parameter-sweep text file not found:\n  %s\n\n' ...
           'Copy the CST parameter-sweep information into this file before running.'], ...
           logFile);
end

if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

fprintf('\n=========================================\n');
fprintf('FLEX PCB CST-MATLAB WORKFLOW\n');
fprintf('=========================================\n');
fprintf('Repository root : %s\n', repoRoot);
fprintf('Touchstone data : %s\n', touchstoneDir);
fprintf('Sweep log       : %s\n', logFile);
fprintf('Results folder  : %s\n', resultsDir);
fprintf('=========================================\n\n');

T = analyze_parameter_sweep(touchstoneDir, resultsDir, logFile);

plot_parameter_sweep_heatmaps(T, resultsDir);
plot_parameter_sweep_grouped_curves(touchstoneDir, T, resultsDir);

fprintf('\nWorkflow completed successfully.\n');
fprintf('Results are available in:\n  %s\n\n', resultsDir);
