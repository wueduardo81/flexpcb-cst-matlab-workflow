function results = analyze_touchstone(file, freqs_eval_GHz)
%ANALYZE_TOUCHSTONE Extract mixed-mode SI metrics from one 4-port Touchstone file.
%
% Pointwise values are obtained by linear interpolation of the Touchstone
% frequency samples.

    Sobj = sparameters(file);
    f = Sobj.Frequencies;
    S = Sobj.Parameters;
    fGHz = f/1e9;

    Smm = s4p_to_mixedmode(S);

    Sdd21 = extract_mm_parameter(Smm,'Sdd21');
    Sdd11 = extract_mm_parameter(Smm,'Sdd11');
    Scd21 = extract_mm_parameter(Smm,'Scd21');
    Sdc21 = extract_mm_parameter(Smm,'Sdc21');

    Sdd21_dB = 20*log10(abs(Sdd21));
    Sdd11_dB = 20*log10(abs(Sdd11));
    Scd21_dB = 20*log10(abs(Scd21));
    Sdc21_dB = 20*log10(abs(Sdc21));

    results.file = file;
    results.f_Hz = f;
    results.f_GHz = fGHz;

    nEval = numel(freqs_eval_GHz);
    results.Transmission_dB = NaN(1,nEval);
    results.Reflection_dB = NaN(1,nEval);
    results.Scd_dB = NaN(1,nEval);
    results.Sdc_dB = NaN(1,nEval);

    for k = 1:nEval
        f0 = freqs_eval_GHz(k);
        results.Transmission_dB(k) = interp1(fGHz, Sdd21_dB, f0, 'linear');
        results.Reflection_dB(k)   = interp1(fGHz, Sdd11_dB, f0, 'linear');
        results.Scd_dB(k)          = interp1(fGHz, Scd21_dB, f0, 'linear');
        results.Sdc_dB(k)          = interp1(fGHz, Sdc21_dB, f0, 'linear');
    end

    [results.WorstTransmission_dB, idxTrans] = min(Sdd21_dB);
    results.WorstTransmission_freq_GHz = fGHz(idxTrans);

    results.MeanTransmission_dB = mean(Sdd21_dB, 'omitnan');

    idx_0p5_10 = fGHz >= 0.5 & fGHz <= 10;
    idx_1_10   = fGHz >= 1.0 & fGHz <= 10;

    results.MeanTransmission_0p5_10GHz_dB = ...
        mean(Sdd21_dB(idx_0p5_10), 'omitnan');

    results.MeanTransmission_1_10GHz_dB = ...
        mean(Sdd21_dB(idx_1_10), 'omitnan');

    [results.WorstReflection_dB, idxReflection] = max(Sdd11_dB);
    results.WorstReflection_freq_GHz = fGHz(idxReflection);
    results.BestReflection_dB = min(Sdd11_dB);

    MC_dB = max(Scd21_dB, Sdc21_dB);
    [results.WorstModeConversion_dB, idxMC] = max(MC_dB);
    results.WorstModeConversion_freq_GHz = fGHz(idxMC);
end
