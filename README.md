# CEM Replication Project

![R](https://img.shields.io/badge/R-4.5%2B-276DC3?logo=R&logoColor=white)
![Python](https://img.shields.io/badge/Python-optional-3776AB?logo=python&logoColor=white)
![Reproducible Pipeline](https://img.shields.io/badge/Reproducible-pipeline-2ea44f)
![Release](https://img.shields.io/github/v/release/elsisiem/cem-replication-publication-pipeline?display_name=tag)
![Last Commit](https://img.shields.io/github/last-commit/elsisiem/cem-replication-publication-pipeline)

A reproducible R pipeline for replicating core CEM simulation results and producing publication-ready extension figures, tables, and long-form output data.

Final paper (PDF): [View Final Paper](06_manuscript/final_paper.pdf)

## What This Repository Contains

- Replication and extension analysis scripts written in R.
- Pre-generated manuscript assets (figures, tables, and long-format CSV outputs).
- Source/reference paper files and raw Dataverse materials.
- Manuscript sources and the final paper PDF.

## Project Structure

```text
cem_replication_project/
  00_raw_dataverse/          # Original replication materials (.rda and source scripts)
  01_source_paper/           # Reference article files (PDF/text)
  02_scripts/                # End-to-end build and extension scripts
  03_outputs/
    figures/
      main/                  # Main-text figures (8)
      appendix/              # Appendix figures (10)
    tables/
      main/                  # Main-text tables
      appendix/              # Appendix tables
    data/                    # Long-form/exported intermediate data
  06_manuscript/             # Submission manuscript source draft
  uploads/
    prism-uploads/           # Upload-ready mirror of all final PNG figures
```

## Quick Start

### 1) Prerequisites

- R installed (tested with R 4.5.3 on Windows).
- Internet access for first-time package installation.

### 2) Run Full Build

From the repository root:

```powershell
Set-Location 02_scripts
Rscript run_all.R
```

This runs the complete R-first pipeline and refreshes all outputs in `03_outputs/`.

## Script Guide (`02_scripts/`)

- `00_install_packages.R`: Installs/verifies required R packages.
- `01_build_from_provided_rda.R`: Rebuilds baseline outputs from provided replication data.
- `02_run_reduced_resim_validation.R`: Reduced re-simulation robustness exercise and appendix figure/table.
- `03_extension_balance_tradeoff.R`: Coarsening-sensitivity frontier extension.
- `04_polished_replication_visuals.R`: Core replication visual package (main + appendix).
- `05_extension_mspe_placebo.R`: MSPE perturbation and placebo reassignment diagnostics.
- `06_extension_entropy_balance.R`: CEM vs entropy balancing extension.
- `08_export_detailed_data.R`: Export of detailed long-format datasets.
- `09_additional_r_figures.R`: Additional main/appendix figures from exported data.
- `09_python_publication_figures.py`: Optional Python-based publication figure transformation script used for manuscript assets.
- `99_figure_style.R`: Shared publication figure styling and save helpers.
- `run_all.R`: One-click pipeline runner.

## Optional Python Figure Workflow

If you are using the author-provided Python transformation workflow for paper-ready figures:

```powershell
python 02_scripts/09_python_publication_figures.py
```

Note: this script is preserved as provided and uses its own internal path conventions.

## Output Inventory

### Main Figures

- `fig1_frontier_rmse_l1_runtime.png`
- `fig2_bias_sd_profile.png`
- `fig3_l1_core_methods.png`
- `fig4_extension_mspe_ratio.png`
- `fig5_extension_loveplot_cem_vs_ebal.png`
- `fig6_extension_coarsening_frontier.png`
- `fig7_abs_error_ecdf.png`
- `fig8_rank_profile.png`

### Appendix Figures

- `figA1_att_distributions_violin.png`
- `figA2_runtime_logscale.png`
- `figA3_sample_size_composition.png`
- `figA4_placebo_distributions.png`
- `figA5_att_raw_cem_ebal.png`
- `figA6_method_rank_heatmap.png`
- `figA7_reduced_resim_rmse.png`
- `figA8_l1_distribution_boxplot.png`
- `figA9_runtime_distribution_violin.png`
- `figA10_measerr_stability.png`

## Reproducibility Notes

- The project is intentionally R-first and script-driven.
- Figure styling is centralized in `99_figure_style.R` to keep all visuals consistent.
- Upload-ready figure files are mirrored in `uploads/prism-uploads/` with unchanged filenames.

## Manuscript

- Draft source: `06_manuscript/response_article_submission_ready.md`
- Final paper PDF: `06_manuscript/final_paper.pdf`
- Browser link: [View Final Paper](06_manuscript/final_paper.pdf)
