# CST–MATLAB Workflow for Mixed-Mode Signal-Integrity Evaluation of Flexible PCB Differential Links

This repository contains the MATLAB post-processing workflow associated with the manuscript:

**A CST–MATLAB Workflow for Mixed-Mode Signal-Integrity Evaluation and Multi-Objective Geometry Selection in Flexible PCB Differential Links**

The workflow processes 4-port Touchstone files exported from a CST Studio Suite parameter sweep, converts the single-ended S-parameters to mixed mode, extracts signal-integrity metrics, performs a normalized multi-objective geometry ranking, evaluates ranking sensitivity to the selected weights, and generates publication-oriented result tables and figures.

## Repository structure

```text
flexpcb-cst-matlab-workflow/
│
├── README.md
├── LICENSE
├── CITATION.cff
├── run_analysis.m
├── .gitignore
│
├── analysis/
│   ├── analyze_parameter_sweep.m
│   └── analyze_weight_sensitivity.m
│
├── functions/
│   ├── read_touchstones.m
│   ├── parse_parameter_sweep_log.m
│   ├── analyze_touchstone.m
│   ├── s4p_to_mixedmode.m
│   ├── extract_mm_parameter.m
│   └── add_sweep_scores.m
│
├── plotting/
│   ├── plot_parameter_sweep_heatmaps.m
│   └── plot_parameter_sweep_grouped_curves.m
│
├── data/
│   ├── parameter_sweep_log.txt
│   └── touchstone/
│       └── *.s4p
│
└── results/
```

## Requirements

- MATLAB R2022a or later is recommended.
- RF Toolbox is required for `sparameters`.
- CST Studio Suite is only required to regenerate the electromagnetic simulations. It is not required to run the MATLAB post-processing workflow from the exported Touchstone files.

## Input data

### Touchstone files

Place the 4-port Touchstone files exported from CST in:

```text
data/touchstone/
```

The filenames are expected to end with the CST sweep run index, for example:

```text
FlexPCB_ECSS_Coverlay_Baseline_1.s4p
FlexPCB_ECSS_Coverlay_Baseline_2.s4p
...
FlexPCB_ECSS_Coverlay_Baseline_35.s4p
```

The final numeric suffix is interpreted as the `RunID`.

### CST parameter-sweep information

The parameter-sweep information is manually copied from CST into:

```text
data/parameter_sweep_log.txt
```

The parser expects blocks containing entries such as:

```text
Parameter Values:
Gap = 0.4
W = 0.14
```

After this text file has been prepared, the MATLAB workflow automatically associates the ordered Touchstone runs with the corresponding geometry parameters.

## Running the complete workflow

Set the repository root as the current MATLAB folder and execute:

```matlab
run_analysis
```

The script adds the required subfolders to the MATLAB path and runs the complete post-processing workflow.

## Mixed-mode conversion

The single-ended 4-port S-parameter matrix is transformed using the mixed-mode ordering

```text
[d1 c1 d2 c2]
```

with differential pairs

```text
Pair 1: ports 1(+) and 2(-)
Pair 2: ports 3(+) and 4(-)
```

The main quantities used in the analysis are:

- `Sdd11`: differential reflection
- `Sdd21`: differential transmission
- `Scd21`: differential-to-common forward mode conversion
- `Sdc21`: common-to-differential forward mode conversion

The conservative forward mode-conversion metric is

```text
MC(f) = max(Scd21_dB(f), Sdc21_dB(f))
```

The CST single-ended ports use a fixed 50-ohm reference impedance. Under the mixed-mode transformation this corresponds to 100-ohm differential and 25-ohm common-mode reference impedances.

## Signal-integrity metrics and ranking

The nominal multi-objective score combines four design-space-normalized metrics:

| Metric | Weight |
|---|---:|
| Mean differential transmission, 0.5–10 GHz | 0.35 |
| Differential transmission at 10 GHz | 0.25 |
| Worst-case differential reflection | 0.20 |
| Worst-case mode conversion | 0.20 |

Frequency-specific metrics are obtained by linear interpolation of the exported Touchstone frequency samples.

The weights are illustrative design preferences rather than universal values.

## Weight-sensitivity analysis

The robustness analysis uses:

- nominal weights: `[0.35 0.25 0.20 0.20]`
- maximum absolute perturbation: `±0.10`
- accepted Monte Carlo samples: `100000`
- random seed: `42`

The sampled weight vectors satisfy

```text
w_i >= 0
sum(w_i) = 1
```

## Outputs

The workflow generates files such as:

```text
results/
├── parameter_sweep_metrics.csv
├── parameter_sweep_metrics.xlsx
├── parameter_sweep_summary.mat
├── weight_sensitivity_scenarios.csv
├── weight_sensitivity_monte_carlo_summary.csv
├── grouped_curves/
└── *.png
```

Generated results are reproducible from the supplied input data and are therefore not required to be version-controlled.

## Reproducibility

The MATLAB analysis can be reproduced from the exported `.s4p` files and `parameter_sweep_log.txt`; the CST project itself is not required for post-processing.

The repository provides the code and complete sweep data associated with the methodology described in the manuscript. Release `v1.0.0` will represent the code and data state used for the manuscript, and a versioned archival copy will also be deposited in Zenodo so that the exact version cited by the paper remains permanently accessible.

## License

The MATLAB code is released under the [MIT License](LICENSE).

Any third-party software, CST models, or externally licensed material are not covered by this license.

## Citation

Citation metadata are provided in [`CITATION.cff`](CITATION.cff).

Once the associated paper and Zenodo archival release receive persistent identifiers, the repository metadata and this section will be updated with the final DOI information.
