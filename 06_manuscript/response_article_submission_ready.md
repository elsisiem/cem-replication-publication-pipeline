# Title Page

## Causal Inference Without Ex Post Balance Tuning:
## A Replication and Extension Response to Iacus, King, and Porro (2012)

Author: [Your Name]

Course: [Course Number and Title]

Instructor: [Instructor Name]

Date: April 21, 2026

---

# Executive Summary

This response article is written for the authors of Iacus, King, and Porro (2012), "Causal Inference without Balance Checking: Coarsened Exact Matching." I reproduce one central empirical result from the paper: the method comparison in Table 2 and the associated L1 balance pattern from the Monte Carlo design based on the LaLonde setting. I then extend the analysis in three directions: a coarsening-sensitivity frontier for CEM, perturbation and placebo diagnostics, and a comparison against entropy balancing (EBAL).

The replication supports the main claim. In the reproduced output, CEM has lower L1 imbalance than Mahalanobis, propensity score, and genetic matching (0.382 vs 0.539, 0.615, and 0.562). In the same run, CEM weighted also has the lowest RMSE. The extensions generally reinforce the design-first message while adding useful nuance: under perturbation, CEM weighted has the highest MSPE ratio, but it still has the lowest absolute MSPE in both baseline and perturbed settings.

Taken together, the results support the paper's argument that balance decisions should be made transparently at the design stage. They also suggest a practical update for applied work: report both ratio-based and level-based robustness metrics so method rankings are interpreted in context.

---

# 1. Introduction and Response Objective

Dear Professors Iacus, King, and Porro,

This paper responds directly to your CEM article by reproducing one of its key empirical findings and extending that comparison with diagnostics commonly used in current causal inference workflows. The target is causal inference, not prediction: the focus is how matching design affects bias, imbalance, and treatment-effect estimation quality under observational confounding.

The core causal question carried into this response is straightforward: how does the choice of matching algorithm change the quality of causal effect estimates in realistic observational conditions? I focus on your simulation-based comparison and then test whether the main conclusions remain stable under coarsening changes, perturbation diagnostics, placebo reassignment, and EBAL comparison.

---

# 2. Summary of the Original Paper

Iacus, King, and Porro, "Causal Inference without Balance Checking: Coarsened Exact Matching" (Oxford University Press on behalf of the Society for Political Methodology, advance access August 23, 2011; Political Analysis 20(1), 2012), argues that standard matching workflows often guarantee what is less important (sample retention or variance control) while leaving balance improvement uncertain. You state this clearly: "the less important criterion is guaranteed by the procedure, and any success at achieving the most important criterion is uncertain and must be checked ex post."

The paper is explicitly causal, not predictive. The problem is credibility of counterfactual comparisons in observational data. The article frames the practical challenge as "information, information everywhere, nor a datum to trust." Your proposed solution is CEM within the MIB class, where users choose acceptable imbalance ex ante through substantively meaningful coarsening choices. As the paper notes, "if you understand the trade-offs in drawing a histogram, you will understand how to use this method."

The central contribution is the connection between theory and workflow: CEM can bound imbalance by design, reduce dependence on iterative ex post tuning, and perform strongly against common alternatives. This response tests those claims using your public replication archive.

---

# 3. Data, Code, and Access

All data and code used in this project are publicly available via Harvard Dataverse:

https://doi.org/10.7910/DVN/NMMYYW

The project uses the LaLonde-based simulation objects and scripts included in that archive (including cemsim-penta and measurement-error components) and executes the full workflow in R.

Public submission repository link (to be filled before submission):

[INSERT PUBLIC GITHUB OR DRIVE LINK HERE]

---

# 4. Replication Focus and Methods

The replication centers on the paper's multi-method simulation comparison (Table 2) and its L1 imbalance result, rather than reproducing only descriptive summaries. The methods compared are Mahalanobis (MAH), propensity score matching (PSC), genetic matching (GEN), and CEM (unweighted and weighted variants).

The evaluation metrics are bias, standard deviation, RMSE, runtime, and L1 imbalance. For readers outside matching methods, the practical interpretation is simple: L1 tells us how similar treated and control covariate distributions are after matching (lower is better), while RMSE summarizes estimation quality by combining bias and variance (lower is better).

---

# 5. Replication Results

The replication succeeds and supports your core empirical claim. In the reproduced output, CEM has much lower L1 imbalance than MAH, PSC, and GEN (0.382 vs 0.539, 0.615, and 0.562). CEM weighted also has the strongest RMSE in this run (111.4 vs 1077.2, 1058.3, and 508.3 for MAH, PSC, and GEN).

[TABLE PLACEHOLDER - MAIN] table2_reproduced.csv

Caption: Reproduction of the core simulation comparison from the original study. The table reports bias, SD, RMSE, matched sample composition, runtime, and L1 by method, and is the main numerical basis for the replication claim.

[TABLE PLACEHOLDER - MAIN] main_method_performance.csv

Caption: Consolidated method performance table used to construct the main visual diagnostics. This version keeps method labels standardized for manuscript reporting and includes the CEM weighted variant.

[FIGURE PLACEHOLDER - MAIN] fig1_frontier_rmse_l1_runtime.png

Caption: Balance-accuracy-runtime frontier. Each point is a method, the x-axis is L1 imbalance, the y-axis is RMSE, and point size reflects runtime. The figure helps readers see trade-offs among statistical quality and computation in one panel.

[FIGURE PLACEHOLDER - MAIN] fig2_bias_sd_profile.png

Caption: Joint profile of bias and sampling variability across methods. This figure separates directional error (bias) from spread (SD) so readers can see why methods with similar RMSE may still differ in error composition.

[FIGURE PLACEHOLDER - MAIN] fig3_l1_core_methods.png

Caption: Direct L1 comparison among core matching methods. This figure visualizes the central balance claim and makes the rank ordering of post-match imbalance immediately interpretable.

---

# 6. Extension 1: Coarsening-Sensitivity Frontier

To study how design choices affect results, I varied CEM coarsening granularity across four specifications and traced the relationship between retained matched sample size and post-match L1. This extension is methodologically important because CEM's central tuning decision is the coarsening level itself; reporting one default setting alone would hide that trade-off. The results show a clear frontier: matched sample size increases from 398 to 608 as designs become coarser, while post-match L1 ranges from roughly 0.248 to 0.223. In practice, this gives analysts a transparent way to defend where they place the balance-retention compromise.

[TABLE PLACEHOLDER - MAIN] extension_coarsening_frontier.csv

Caption: Coarsening sensitivity table with one row per specification. It records bin choices, matched counts, and pre/post L1, allowing direct audit of how each coarsening decision changes data retention and imbalance.

[FIGURE PLACEHOLDER - MAIN] fig6_extension_coarsening_frontier.png

Caption: Coarsening frontier plot of matched N against post-match L1. Labels identify each specification so the reader can map design settings to outcomes and see the practical trade-off curve.

---

# 7. Extension 2: MSPE-Ratio Diagnostics and Placebo Reweighting

I implemented perturbation-based MSPE diagnostics and placebo treatment reassignment checks to evaluate ranking stability under stress. This matters because method rankings can change when data-generating details shift, and robust conclusions should survive those shifts. MSPE ratio results are CEM.W 2.191, PSC 1.185, MAH 1.124, and EBAL 1.236. The key nuance is that CEM.W has the largest relative deterioration under perturbation, but still has the lowest absolute MSPE in both baseline and perturbed settings. Placebo tests show valid and interpretable two-sided p-values between 0.044 and 0.428, indicating real heterogeneity in method behavior under pseudo-treatment assignment. The practical implication is to report relative robustness and absolute error together.

[TABLE PLACEHOLDER - MAIN] extension_mspe_ratio_diagnostic.csv

Caption: Method-by-method perturbation summary with baseline MSPE, perturbed MSPE, and their ratio. This table supports statements about stability in both level and relative terms.

[TABLE PLACEHOLDER - APPENDIX] appendix_placebo_reweighting_results.csv

Caption: Placebo reweighting summary with observed ATT, placebo mean/SD, and two-sided placebo p-values for each method. The table quantifies whether observed estimates are unusual under randomized reassignment.

[FIGURE PLACEHOLDER - MAIN] fig4_extension_mspe_ratio.png

Caption: Bar chart of MSPE ratios across methods. Ratios above 1 indicate increased error under perturbation; relative heights show sensitivity ranking.

[FIGURE PLACEHOLDER - APPENDIX] figA4_placebo_distributions.png

Caption: Method-specific placebo ATT distributions with observed ATT reference lines. The panel view lets readers compare where each observed estimate falls in its placebo null distribution.

---

# 8. Extension 3: CEM Versus Entropy Balancing (EBAL)

I compared CEM and EBAL on balance and ATT estimates using the same observational setup. This extension is important because it checks whether a classic CEM result remains strong against a later baseline that many applied researchers now use. Both methods improve covariate balance substantially relative to raw data. Mean absolute standardized mean differences are 0.0590 (Raw), 0.0055 (CEM), and approximately 0.0000 (EBAL). ATT estimates differ across approaches (Raw 886.3, CEM 551.0, EBAL 872.9), which reinforces a central causal-design lesson: balancing strategy can materially change substantive conclusions when assignment is nonrandom.

[TABLE PLACEHOLDER - MAIN] extension_balance_comparison_cem_vs_ebal.csv

Caption: Covariate-level balance table showing Raw, CEM, and EBAL standardized mean differences. It is the primary source for the mean absolute SMD comparison discussed in the text.

[TABLE PLACEHOLDER - APPENDIX] appendix_att_comparison_raw_cem_ebal.csv

Caption: ATT point estimates from the raw sample, CEM, and EBAL. The table highlights how estimands derived from different balancing designs can shift in magnitude.

[FIGURE PLACEHOLDER - MAIN] fig5_extension_loveplot_cem_vs_ebal.png

Caption: Love plot comparing absolute standardized mean differences by covariate and method. The dashed threshold line provides a visual benchmark for practical imbalance.

---

# 9. Additional Diagnostic Visuals

To improve interpretability, I include two additional main-text diagnostics. The first is an ECDF of absolute ATT error, which compares full error distributions rather than means alone. The second is a rank-profile figure across RMSE, L1, runtime, and absolute bias, showing where each method is consistently strong or weak across criteria.

[FIGURE PLACEHOLDER - MAIN] fig7_abs_error_ecdf.png

Caption: ECDF of absolute ATT error by method. Curves farther left indicate better accuracy across the full distribution of simulation draws.

[FIGURE PLACEHOLDER - MAIN] fig8_rank_profile.png

Caption: Multi-criterion rank profile across RMSE, L1, runtime, and absolute bias. This figure summarizes method performance stability when no single metric is treated as definitive.

---

# 10. Integrated Discussion for the Authors

The replication strongly supports your practical argument that choosing balance ex ante through CEM can produce strong finite-sample behavior while avoiding repeated balance-tuning cycles. The extensions suggest two updates for contemporary reporting: first, CEM remains highly competitive in this benchmark even against newer alternatives; second, robustness reporting should separate relative sensitivity from absolute performance, because those may not point in the same direction.

The central takeaway from this response is therefore supportive rather than revisionist: your design-first framework still travels well. The main refinement is procedural transparency, not a change in principle.

---

# 11. Conclusion

This response article replicated a central empirical result from Iacus, King, and Porro (2012) and extended it with coarsening sensitivity analysis, perturbation/placebo diagnostics, and an EBAL comparison. The replication target was achieved, the core claim is supported, and the extensions provide substantive added evidence rather than cosmetic variation. Overall, the evidence remains consistent with the view that design-stage balance control is a first-order requirement for credible causal inference in observational data.

---

# Contribution Statement

This project was completed by one author. I selected the replication target, organized the public data and code, implemented all replication and extension scripts, generated and validated all outputs, and wrote the manuscript.

---

# References

Iacus, Stefano M., Gary King, and Giuseppe Porro. 2012. "Causal Inference without Balance Checking: Coarsened Exact Matching." Political Analysis 20(1): 1-24. https://doi.org/10.1093/pan/mpr013

Iacus, Stefano M., Gary King, and Giuseppe Porro. 2011b. Replication data and code for CEM article. Harvard Dataverse. https://doi.org/10.7910/DVN/NMMYYW

LaLonde, Robert J. 1986. "Evaluating the Econometric Evaluations of Training Programs with Experimental Data." American Economic Review 76(4): 604-620.

Ho, Daniel E., Kosuke Imai, Gary King, and Elizabeth A. Stuart. 2007. "Matching as Nonparametric Preprocessing for Reducing Model Dependence in Parametric Causal Inference." Political Analysis 15(3): 199-236.

---

# Appendix A. Figure Placeholders and Captions

## A.1 Main Figures

[FIGURE PLACEHOLDER - MAIN] fig1_frontier_rmse_l1_runtime.png

Caption: Balance-accuracy-runtime frontier with L1 on x-axis, RMSE on y-axis, and runtime encoded by point size.

[FIGURE PLACEHOLDER - MAIN] fig2_bias_sd_profile.png

Caption: Method comparison of bias and standard deviation to separate directional error from sampling spread.

[FIGURE PLACEHOLDER - MAIN] fig3_l1_core_methods.png

Caption: Core-method L1 imbalance comparison used to evaluate post-match covariate distribution overlap.

[FIGURE PLACEHOLDER - MAIN] fig4_extension_mspe_ratio.png

Caption: Relative perturbation sensitivity by method, shown as perturbed-to-baseline MSPE ratios.

[FIGURE PLACEHOLDER - MAIN] fig5_extension_loveplot_cem_vs_ebal.png

Caption: Absolute standardized mean differences by covariate for Raw, CEM, and EBAL.

[FIGURE PLACEHOLDER - MAIN] fig6_extension_coarsening_frontier.png

Caption: Coarsening trade-off frontier linking retained matched N to residual post-match imbalance.

[FIGURE PLACEHOLDER - MAIN] fig7_abs_error_ecdf.png

Caption: Distributional accuracy comparison using ECDFs of absolute ATT error.

[FIGURE PLACEHOLDER - MAIN] fig8_rank_profile.png

Caption: Cross-metric rank profile showing each method's relative position on RMSE, L1, runtime, and absolute bias.

## A.2 Appendix Figures

[FIGURE PLACEHOLDER - APPENDIX] figA1_att_distributions_violin.png

Caption: Violin-and-box distribution of ATT estimates by method with true ATT reference line.

[FIGURE PLACEHOLDER - APPENDIX] figA2_runtime_logscale.png

Caption: Runtime comparison on a log scale to accommodate large differences across algorithms.

[FIGURE PLACEHOLDER - APPENDIX] figA3_sample_size_composition.png

Caption: Average treated/control matched counts by method to show composition effects of pruning.

[FIGURE PLACEHOLDER - APPENDIX] figA4_placebo_distributions.png

Caption: Placebo ATT histograms by method with observed ATT overlays for inferential context.

[FIGURE PLACEHOLDER - APPENDIX] figA5_att_raw_cem_ebal.png

Caption: ATT point estimate comparison among raw data, CEM, and EBAL designs.

[FIGURE PLACEHOLDER - APPENDIX] figA6_method_rank_heatmap.png

Caption: Heatmap of metric-by-method ranks for quick visual comparison of multidimensional performance.

[FIGURE PLACEHOLDER - APPENDIX] figA7_reduced_resim_rmse.png

Caption: RMSE comparison from reduced re-simulation used as a pipeline robustness check.

[FIGURE PLACEHOLDER - APPENDIX] figA8_l1_distribution_boxplot.png

Caption: Distribution of L1 values across simulation draws to show variability in balance outcomes.

[FIGURE PLACEHOLDER - APPENDIX] figA9_runtime_distribution_violin.png

Caption: Distributional view of runtime across simulations for methods with meaningful compute cost.

[FIGURE PLACEHOLDER - APPENDIX] figA10_measerr_stability.png

Caption: Measurement-error stability diagnostic showing common-unit retention with uncertainty intervals.

---

# Appendix B. Table Placeholders and Captions

## B.1 Main Tables

[TABLE PLACEHOLDER - MAIN] table2_reproduced.csv

Caption: Core replicated simulation table with bias, SD, RMSE, matched counts, runtime, and L1 by method.

[TABLE PLACEHOLDER - MAIN] main_method_performance.csv

Caption: Harmonized performance summary used for main manuscript visuals and direct method ranking.

[TABLE PLACEHOLDER - MAIN] extension_coarsening_frontier.csv

Caption: Specification-level sensitivity table for CEM coarsening choices and resulting balance/retention outcomes.

[TABLE PLACEHOLDER - MAIN] extension_mspe_ratio_diagnostic.csv

Caption: Baseline and perturbed MSPE with method-level perturbation ratios.

[TABLE PLACEHOLDER - MAIN] extension_balance_comparison_cem_vs_ebal.csv

Caption: Covariate-level standardized mean difference comparison among Raw, CEM, and EBAL.

## B.2 Appendix Tables

[TABLE PLACEHOLDER - APPENDIX] table1_reproduced.csv

Caption: Measurement-error replication table reporting common-unit retention and computational time.

[TABLE PLACEHOLDER - APPENDIX] appendix_full_method_performance.csv

Caption: Full method performance table including unmatched baseline and both CEM variants.

[TABLE PLACEHOLDER - APPENDIX] appendix_placebo_reweighting_results.csv

Caption: Placebo reassignment summary with observed ATT, placebo moments, and two-sided p-values.

[TABLE PLACEHOLDER - APPENDIX] appendix_att_comparison_raw_cem_ebal.csv

Caption: ATT point estimates under three design choices to illustrate estimator sensitivity to balancing strategy.

[TABLE PLACEHOLDER - APPENDIX] reduced_resim_summary.csv

Caption: Reduced Monte Carlo validation summary used to verify consistency of performance ordering.
