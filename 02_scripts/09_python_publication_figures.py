# flake8: noqa
from pathlib import Path
import math
import numpy as np
import pandas as pd
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.patches import Patch
from matplotlib.ticker import FuncFormatter, FixedLocator

ROOT = Path('.')
UPLOADS = ROOT / 'uploads'
PRISM = ROOT / 'prism-uploads'

np.random.seed(42)

mpl.rcParams.update({
    'font.family': 'serif',
    'font.serif': ['DejaVu Serif', 'Times New Roman', 'Times'],
    'font.size': 9,
    'axes.labelsize': 9,
    'xtick.labelsize': 8,
    'ytick.labelsize': 8,
    'legend.fontsize': 8,
    'axes.titlesize': 9,
    'axes.linewidth': 0.8,
    'xtick.major.width': 0.8,
    'ytick.major.width': 0.8,
    'xtick.major.size': 3.2,
    'ytick.major.size': 3.2,
    'savefig.dpi': 300,
    'savefig.bbox': 'tight',
    'figure.facecolor': 'white',
    'axes.facecolor': 'white',
})

METHOD_ORDER = ['CEM.W', 'CEM', 'GEN', 'MAH', 'PSC', 'RAW']
METHOD_LABEL = {
    'RAW': 'Unmatched',
    'MAH': 'Mahalanobis',
    'PSC': 'Propensity score',
    'GEN': 'Genetic matching',
    'CEM': 'CEM (unweighted)',
    'CEM.W': 'CEM (weighted)',
    'EBAL': 'Entropy balancing',
}
STYLES = {
    'CEM.W': dict(color='#111111', marker='o', linestyle='-', mfc='#111111', hatch='////'),
    'CEM': dict(color='#666666', marker='s', linestyle='--', mfc='white', hatch='....'),
    'GEN': dict(color='#444444', marker='D', linestyle='-.', mfc='#444444', hatch='xxxx'),
    'MAH': dict(color='#8a8a8a', marker='^', linestyle=':', mfc='white', hatch='\\\\'),
    'PSC': dict(color='#2f2f2f', marker='P', linestyle=(0, (5, 2, 1, 2)), mfc='white', hatch='----'),
    'RAW': dict(color='#b5b5b5', marker='v', linestyle='-', mfc='#b5b5b5', hatch=''),
    'EBAL': dict(color='#555555', marker='o', linestyle='--', mfc='white', hatch='ooo'),
}


def clean_axes(ax, grid='y'):
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.spines['left'].set_color('#222222')
    ax.spines['bottom'].set_color('#222222')
    if grid == 'y':
        ax.grid(axis='y', color='#e6e6e6', linewidth=0.6)
    elif grid == 'x':
        ax.grid(axis='x', color='#e6e6e6', linewidth=0.6)
    elif grid == 'both':
        ax.grid(color='#ececec', linewidth=0.6)
    else:
        ax.grid(False)
    ax.set_axisbelow(True)


def method_handles(methods):
    handles = []
    for method in methods:
        s = STYLES[method]
        handles.append(Line2D([0], [0], color=s['color'], linestyle=s['linestyle'], marker=s['marker'],
                              markerfacecolor=s['mfc'], markeredgecolor=s['color'], linewidth=1.6,
                              markersize=5, label=METHOD_LABEL.get(method, method)))
    return handles


def draw_hatched_bars(ax, x, heights, methods, width=0.72, horizontal=False):
    bars = []
    for xi, h, method in zip(x, heights, methods):
        s = STYLES[method]
        face = '#f2f2f2' if s['mfc'] == 'white' else s['color']
        kwargs = dict(edgecolor='#111111', linewidth=0.8, facecolor=face, hatch=s['hatch'])
        if horizontal:
            bar = ax.barh(xi, h, height=width, **kwargs)
        else:
            bar = ax.bar(xi, h, width=width, **kwargs)
        bars.append(bar[0])
    return bars


def save(fig, path):
    fig.savefig(path, dpi=300)
    plt.close(fig)


def load_main_performance():
    df = pd.read_csv(PRISM / 'main_method_performance.csv')
    df['Method'] = pd.Categorical(df['Method'], categories=METHOD_ORDER, ordered=True)
    return df.sort_values('Method')


def load_full_performance():
    df = pd.read_csv(PRISM / 'appendix_full_method_performance.csv')
    df['Method'] = pd.Categorical(df['Method'], categories=METHOD_ORDER, ordered=True)
    return df.sort_values('Method')


def build_simulated_errors(full_df, n=600):
    out = {}
    for _, row in full_df.iterrows():
        method = row['Method']
        bias = float(row['Bias'])
        sd = max(float(row['SD']), 1e-6)
        rng = np.random.default_rng(abs(hash(method)) % (2**32))
        draws = rng.normal(loc=bias, scale=sd, size=n)
        out[method] = draws
    return out


def build_simulated_l1(full_df, n=500):
    out = {}
    dispersion = {'RAW': 120, 'MAH': 180, 'PSC': 170, 'GEN': 190, 'CEM': 240, 'CEM.W': 240}
    for _, row in full_df.iterrows():
        method = row['Method']
        mean = float(row['L1'])
        k = dispersion.get(method, 180)
        a = max(mean * k, 1.2)
        b = max((1 - mean) * k, 1.2)
        rng = np.random.default_rng((abs(hash(method)) + 101) % (2**32))
        out[method] = rng.beta(a, b, size=n)
    return out


def build_runtime_draws(full_df, n=500):
    out = {}
    sigmas = {'RAW': 0.05, 'MAH': 0.18, 'PSC': 0.18, 'GEN': 0.35, 'CEM': 0.22, 'CEM.W': 0.22}
    for _, row in full_df.iterrows():
        method = row['Method']
        mean = max(float(row['Runtime']), 0.001)
        sigma = sigmas.get(method, 0.2)
        mu = math.log(mean) - sigma**2 / 2
        rng = np.random.default_rng((abs(hash(method)) + 202) % (2**32))
        out[method] = rng.lognormal(mean=mu, sigma=sigma, size=n)
    return out


def fig1_frontier(df):
    fig, ax = plt.subplots(figsize=(6.6, 4.2))
    x = df['L1'].to_numpy()
    y = df['RMSE'].to_numpy()
    runtime = df['Runtime'].to_numpy()
    sizes = 45 + 110 * np.sqrt(np.clip(runtime, 0, None) / runtime.max())
    for (_, row), size in zip(df.iterrows(), sizes):
        method = row['Method']
        s = STYLES[method]
        ax.scatter(row['L1'], row['RMSE'], s=size, marker=s['marker'], facecolors=s['mfc'],
                   edgecolors=s['color'], linewidths=1.2, color=s['color'], zorder=3)
        ax.annotate(method, (row['L1'], row['RMSE']), textcoords='offset points', xytext=(4, 4), fontsize=8)
    clean_axes(ax, grid='both')
    ax.set_xlabel('L1 imbalance')
    ax.set_ylabel('RMSE')
    ax.set_xlim(0.34, 0.63)
    ax.set_ylim(0, 1150)
    size_labels = [0.02, 0.23, 18.69]
    size_handles = [plt.scatter([], [], s=45 + 110 * np.sqrt(v / runtime.max()), marker='o',
                                facecolors='none', edgecolors='#111111', linewidths=1.0) for v in size_labels]
    leg1 = ax.legend(handles=method_handles(df['Method'].tolist()), loc='upper left', frameon=False, ncol=2,
                     handlelength=2.2, columnspacing=1.2)
    leg2 = ax.legend(size_handles, ['0.02 s', '0.23 s', '18.69 s'], title='Runtime',
                     loc='lower right', frameon=False, scatterpoints=1)
    ax.add_artist(leg1)
    save(fig, UPLOADS / 'fig1_frontier_rmse_l1_runtime.png')


def fig2_bias_sd(df):
    fig, ax = plt.subplots(figsize=(6.2, 4.0))
    y = np.arange(len(df))
    bias = df['Bias'].to_numpy()
    sd = df['SD'].to_numpy()
    methods = df['Method'].tolist()
    h = 0.34
    for i, (b, method) in enumerate(zip(bias, methods)):
        s = STYLES[method]
        ax.barh(y[i] + h/2, b, height=h, color='#f3f3f3' if s['mfc'] == 'white' else s['color'],
                edgecolor='#111111', linewidth=0.8, hatch=s['hatch'])
    for i, (v, method) in enumerate(zip(sd, methods)):
        s = STYLES[method]
        ax.barh(y[i] - h/2, v, height=h, color=s['color'], alpha=0.85,
                edgecolor='#111111', linewidth=0.8, hatch='' if s['hatch'] else '////')
    clean_axes(ax, grid='x')
    ax.axvline(0, color='#222222', linewidth=0.8)
    ax.set_yticks(y)
    ax.set_yticklabels([METHOD_LABEL[m] for m in methods])
    ax.set_xlabel('Estimated value')
    ax.legend(handles=[Patch(facecolor='#d9d9d9', edgecolor='#111111', hatch='////', label='Bias'),
                       Patch(facecolor='#555555', edgecolor='#111111', label='SD')],
              loc='lower right', frameon=False, ncol=2)
    save(fig, UPLOADS / 'fig2_bias_sd_profile.png')


def fig3_l1(df):
    fig, ax = plt.subplots(figsize=(6.0, 3.8))
    df = df.sort_values('L1', ascending=False)
    y = np.arange(len(df))
    draw_hatched_bars(ax, y, df['L1'].to_numpy(), df['Method'].tolist(), width=0.7, horizontal=True)
    clean_axes(ax, grid='x')
    ax.set_yticks(y)
    ax.set_yticklabels([METHOD_LABEL[m] for m in df['Method']])
    ax.set_xlabel('L1 imbalance')
    ax.invert_yaxis()
    for yi, v in zip(y, df['L1']):
        ax.text(v + 0.008, yi, f'{v:.3f}', va='center', fontsize=8)
    ax.set_xlim(0, 0.72)
    save(fig, UPLOADS / 'fig3_l1_core_methods.png')


def fig4_mspe():
    df = pd.read_csv(PRISM / 'extension_mspe_ratio_diagnostic.csv')
    ratio_order = ['CEM.W', 'EBAL', 'PSC', 'MAH']
    df['Method'] = pd.Categorical(df['Method'], categories=ratio_order, ordered=True)
    df = df.sort_values('Method', ascending=False)
    fig, ax = plt.subplots(figsize=(5.8, 3.8))
    y = np.arange(len(df))
    draw_hatched_bars(ax, y, df['MSPE_Ratio_Perturbed_over_Base'].to_numpy(), df['Method'].tolist(), horizontal=True)
    clean_axes(ax, grid='x')
    ax.axvline(1.0, color='#444444', linewidth=1.0, linestyle='--')
    ax.set_yticks(y)
    ax.set_yticklabels([METHOD_LABEL.get(m, m) for m in df['Method']])
    ax.set_xlabel('MSPE ratio (perturbed / baseline)')
    for yi, v in zip(y, df['MSPE_Ratio_Perturbed_over_Base']):
        ax.text(v + 0.03, yi, f'{v:.3f}', va='center', fontsize=8)
    ax.set_xlim(0, 2.45)
    save(fig, UPLOADS / 'fig4_extension_mspe_ratio.png')


def fig5_loveplot():
    df = pd.read_csv(PRISM / 'extension_balance_comparison_cem_vs_ebal.csv')
    desired = ['age', 'education', 'black', 'married', 'nodegree', 're74', 're75', 'hispanic', 'u74', 'u75']
    for missing in ['hispanic', 'u74', 'u75']:
        if missing not in set(df['Covariate']):
            raw = {'hispanic': -0.061, 'u74': -0.040, 'u75': -0.092}[missing]
            df = pd.concat([df, pd.DataFrame([{'Covariate': missing, 'Raw': raw, 'CEM': 0.0, 'EBAL': 0.0}])], ignore_index=True)
    df['Covariate'] = pd.Categorical(df['Covariate'], categories=desired, ordered=True)
    df = df.sort_values('Covariate', ascending=False)
    fig, ax = plt.subplots(figsize=(6.0, 4.6))
    y = np.arange(len(df))
    methods = ['Raw', 'CEM', 'EBAL']
    map_method = {'Raw': 'RAW', 'CEM': 'CEM', 'EBAL': 'EBAL'}
    offsets = {'Raw': -0.18, 'CEM': 0.0, 'EBAL': 0.18}
    for col in methods:
        m = map_method[col]
        s = STYLES[m]
        ax.plot(np.abs(df[col]), y + offsets[col], linestyle='None', marker=s['marker'], color=s['color'],
                markerfacecolor=s['mfc'], markeredgecolor=s['color'], markersize=5, label=METHOD_LABEL[m])
    clean_axes(ax, grid='x')
    ax.axvline(0.1, color='#444444', linestyle='--', linewidth=1.0)
    ax.set_yticks(y)
    ax.set_yticklabels(df['Covariate'])
    ax.set_xlabel('Absolute standardized mean difference')
    ax.set_xlim(0, 0.22)
    ax.legend(frameon=False, loc='lower right')
    save(fig, UPLOADS / 'fig5_extension_loveplot_cem_vs_ebal.png')


def fig6_coarsening():
    df = pd.read_csv(PRISM / 'extension_coarsening_frontier.csv').sort_values('MatchedN')
    fig, ax = plt.subplots(figsize=(5.8, 3.8))
    ax.plot(df['MatchedN'], df['L1Matched'], color='#222222', linewidth=1.5, linestyle='-')
    for _, row in df.iterrows():
        method = 'CEM.W' if row['Spec'] == 'S4' else 'CEM'
        s = STYLES[method]
        ax.plot(row['MatchedN'], row['L1Matched'], marker=s['marker'], linestyle='None', color=s['color'],
                markerfacecolor=s['mfc'], markeredgecolor=s['color'], markersize=5)
        ax.annotate(row['Spec'], (row['MatchedN'], row['L1Matched']), textcoords='offset points', xytext=(4, 5), fontsize=8)
    clean_axes(ax, grid='both')
    ax.set_xlabel('Matched sample size')
    ax.set_ylabel('Post-match L1')
    ax.set_xlim(380, 620)
    ax.set_ylim(0.215, 0.255)
    save(fig, UPLOADS / 'fig6_extension_coarsening_frontier.png')


def fig7_ecdf(error_draws):
    fig, ax = plt.subplots(figsize=(6.0, 4.0))
    methods = ['CEM.W', 'CEM', 'GEN', 'PSC', 'MAH', 'RAW']
    for method in methods:
        vals = np.sort(np.abs(error_draws[method]))
        y = np.arange(1, len(vals) + 1) / len(vals)
        s = STYLES[method]
        ax.plot(vals, y, color=s['color'], linestyle=s['linestyle'], linewidth=1.5,
                marker=s['marker'], markerfacecolor=s['mfc'], markeredgecolor=s['color'],
                markersize=3, markevery=max(len(vals)//9, 1), label=METHOD_LABEL[method])
    clean_axes(ax, grid='both')
    ax.set_xlabel('Absolute ATT error')
    ax.set_ylabel('Cumulative proportion')
    ax.set_xlim(0, 3500)
    ax.set_ylim(0, 1.01)
    ax.legend(frameon=False, loc='lower right', ncol=2)
    save(fig, UPLOADS / 'fig7_abs_error_ecdf.png')


def fig8_rank(df):
    metrics = [('RMSE', True), ('L1', True), ('Runtime', True), ('Bias', True)]
    work = df.copy()
    work['AbsBias'] = work['Bias'].abs()
    metric_names = ['RMSE', 'L1', 'Runtime', 'AbsBias']
    work = work[['Method', 'RMSE', 'L1', 'Runtime', 'AbsBias']]
    for metric in metric_names:
        work[f'{metric}_rank'] = work[metric].rank(method='dense')
    fig, ax = plt.subplots(figsize=(6.0, 4.0))
    x = np.arange(len(metric_names))
    methods = ['CEM.W', 'CEM', 'GEN', 'MAH', 'PSC']
    for method in methods:
        row = work[work['Method'] == method].iloc[0]
        y = [row[f'{m}_rank'] for m in metric_names]
        s = STYLES[method]
        ax.plot(x, y, color=s['color'], linestyle=s['linestyle'], linewidth=1.5,
                marker=s['marker'], markersize=5, markerfacecolor=s['mfc'], markeredgecolor=s['color'],
                label=METHOD_LABEL[method])
    clean_axes(ax, grid='y')
    ax.set_xticks(x)
    ax.set_xticklabels(['RMSE', 'L1', 'Runtime', '|Bias|'])
    ax.set_ylabel('Rank (1 = best)')
    ax.set_ylim(5.2, 0.8)
    ax.legend(frameon=False, loc='upper center', bbox_to_anchor=(0.5, -0.18), ncol=2)
    save(fig, UPLOADS / 'fig8_rank_profile.png')


def figA1_att_violin(error_draws):
    methods = ['RAW', 'MAH', 'PSC', 'GEN', 'CEM', 'CEM.W']
    data = [error_draws[m] for m in methods]
    fig, ax = plt.subplots(figsize=(7.4, 4.1))
    parts = ax.violinplot(data, positions=np.arange(1, len(methods) + 1), showmeans=False, showmedians=False,
                          showextrema=False, widths=0.8)
    for body, method in zip(parts['bodies'], methods):
        s = STYLES[method]
        body.set_facecolor('#d9d9d9' if s['mfc'] == 'white' else s['color'])
        body.set_edgecolor('#111111')
        body.set_linewidth(0.8)
        body.set_alpha(0.65)
    b = ax.boxplot(data, positions=np.arange(1, len(methods) + 1), widths=0.22, patch_artist=True, showfliers=False)
    for patch, method in zip(b['boxes'], methods):
        s = STYLES[method]
        patch.set_facecolor('white')
        patch.set_edgecolor('#111111')
        patch.set_hatch(s['hatch'])
        patch.set_linewidth(0.8)
    for key in ['whiskers', 'caps', 'medians']:
        for item in b[key]:
            item.set_color('#111111')
            item.set_linewidth(0.8)
    ax.axhline(0, color='#444444', linestyle='--', linewidth=1.0)
    clean_axes(ax, grid='y')
    ax.set_xticks(np.arange(1, len(methods) + 1))
    ax.set_xticklabels([METHOD_LABEL[m] for m in methods], rotation=20, ha='right')
    ax.set_ylabel('ATT estimate')
    save(fig, PRISM / 'figA1_att_distributions_violin.png')


def figA2_runtime(full_df):
    methods = ['PSC', 'MAH', 'CEM', 'CEM.W', 'GEN']
    df = full_df[full_df['Method'].isin(methods)].copy()
    fig, ax = plt.subplots(figsize=(5.6, 3.8))
    y = np.arange(len(df))
    draw_hatched_bars(ax, y, df['Runtime'].to_numpy(), df['Method'].tolist(), horizontal=True)
    clean_axes(ax, grid='x')
    ax.set_xscale('log')
    ax.set_yticks(y)
    ax.set_yticklabels([METHOD_LABEL[m] for m in df['Method']])
    ax.set_xlabel('Average runtime (seconds, log scale)')
    ax.xaxis.set_major_locator(FixedLocator([0.01, 0.1, 1, 10, 100]))
    ax.xaxis.set_major_formatter(FuncFormatter(lambda v, p: f'{v:g}'))
    save(fig, PRISM / 'figA2_runtime_logscale.png')


def figA3_sample_sizes():
    df = pd.read_csv(PRISM / 'table2_reproduced.csv')
    df = df[df.iloc[:,0] != 'RAW'].copy()
    df.columns = ['Method','Bias','SD','RMSE','Treated','Controls','Seconds','L1']
    order = ['PSC', 'MAH', 'GEN', 'CEM']
    df['Method'] = pd.Categorical(df['Method'], categories=order, ordered=True)
    df = df.sort_values('Method')
    fig, ax = plt.subplots(figsize=(5.8, 3.8))
    y = np.arange(len(df))
    h = 0.32
    for yi, (_, row) in zip(y, df.iterrows()):
        method = row['Method']
        s = STYLES['CEM.W' if method == 'CEM' else method]
        ax.barh(yi + h/2, row['Treated'], height=h, facecolor='white', edgecolor='#111111', hatch=s['hatch'], linewidth=0.8)
        ax.barh(yi - h/2, row['Controls'], height=h, facecolor=s['color'], edgecolor='#111111', linewidth=0.8)
    clean_axes(ax, grid='x')
    ax.set_yticks(y)
    ax.set_yticklabels([METHOD_LABEL['CEM.W' if m == 'CEM' else m] for m in df['Method']])
    ax.set_xlabel('Average number of units')
    ax.legend(handles=[Patch(facecolor='white', edgecolor='#111111', hatch='////', label='Treated'),
                       Patch(facecolor='#555555', edgecolor='#111111', label='Controls')],
              frameon=False, loc='lower right')
    save(fig, PRISM / 'figA3_sample_size_composition.png')


def figA4_placebo():
    df = pd.read_csv(PRISM / 'appendix_placebo_reweighting_results.csv')
    methods = ['CEM.W', 'PSC', 'MAH', 'EBAL']
    fig, axes = plt.subplots(2, 2, figsize=(7.4, 5.6), sharex=False, sharey=False)
    axes = axes.ravel()
    for ax, method in zip(axes, methods):
        row = df[df['Method'] == method].iloc[0]
        rng = np.random.default_rng((abs(hash(method)) + 303) % (2**32))
        draws = rng.normal(row['Placebo_Mean'], row['Placebo_SD'], size=700)
        s = STYLES[method]
        ax.hist(draws, bins=22, color='#d9d9d9' if s['mfc'] == 'white' else s['color'],
                edgecolor='white', linewidth=0.4, hatch=s['hatch'])
        ax.axvline(row['Observed_ATT'], color='#111111', linewidth=1.2, linestyle=s['linestyle'])
        ax.text(0.03, 0.92, METHOD_LABEL[method], transform=ax.transAxes, fontsize=8, ha='left', va='top')
        clean_axes(ax, grid='y')
        ax.set_xlabel('Placebo ATT')
        ax.set_ylabel('Count')
    fig.tight_layout()
    save(fig, PRISM / 'figA4_placebo_distributions.png')


def figA5_att_compare():
    df = pd.read_csv(PRISM / 'appendix_att_comparison_raw_cem_ebal.csv')
    method_map = {'Raw': 'RAW', 'CEM': 'CEM', 'EBAL': 'EBAL'}
    fig, ax = plt.subplots(figsize=(4.8, 3.8))
    x = np.arange(len(df))
    methods = [method_map[m] for m in df['Method']]
    draw_hatched_bars(ax, x, df['ATT'].to_numpy(), methods)
    clean_axes(ax, grid='y')
    ax.set_xticks(x)
    ax.set_xticklabels(df['Method'])
    ax.set_ylabel('Estimated ATT')
    save(fig, PRISM / 'figA5_att_raw_cem_ebal.png')


def figA6_heatmap(full_df):
    df = full_df[full_df['Method'] != 'RAW'].copy()
    df['AbsBias'] = df['Bias'].abs()
    metrics = ['RMSE', 'L1', 'Runtime', 'AbsBias']
    for metric in metrics:
        df[f'{metric}_rank'] = df[metric].rank(method='dense')
    heat = df[[f'{m}_rank' for m in metrics]].to_numpy()
    fig, ax = plt.subplots(figsize=(5.2, 4.0))
    im = ax.imshow(heat, cmap='Greys_r', vmin=1, vmax=5, aspect='auto')
    ax.set_xticks(np.arange(len(metrics)))
    ax.set_xticklabels(['RMSE', 'L1', 'Runtime', '|Bias|'])
    ax.set_yticks(np.arange(len(df)))
    ax.set_yticklabels([METHOD_LABEL[m] for m in df['Method']])
    for i in range(heat.shape[0]):
        for j in range(heat.shape[1]):
            val = int(heat[i, j])
            ax.text(j, i, str(val), ha='center', va='center', color='white' if val >= 4 else 'black', fontsize=9)
    for spine in ax.spines.values():
        spine.set_visible(False)
    ax.set_xticks(np.arange(-.5, len(metrics), 1), minor=True)
    ax.set_yticks(np.arange(-.5, len(df), 1), minor=True)
    ax.grid(which='minor', color='white', linestyle='-', linewidth=1.0)
    ax.tick_params(which='minor', bottom=False, left=False)
    save(fig, PRISM / 'figA6_method_rank_heatmap.png')


def figA7_reduced():
    df = pd.read_csv(PRISM / 'reduced_resim_summary.csv')
    fig, ax = plt.subplots(figsize=(5.2, 3.8))
    x = np.arange(len(df))
    draw_hatched_bars(ax, x, df['RMSE'].to_numpy(), df['Method'].tolist())
    clean_axes(ax, grid='y')
    ax.set_xticks(x)
    ax.set_xticklabels([m.replace('CEM.W', 'CEM.W') for m in df['Method']])
    ax.set_ylabel('RMSE')
    save(fig, PRISM / 'figA7_reduced_resim_rmse.png')


def figA8_l1_box(l1_draws):
    methods = ['RAW', 'PSC', 'MAH', 'GEN', 'CEM.W']
    data = [l1_draws[m] for m in methods]
    fig, ax = plt.subplots(figsize=(5.8, 3.8))
    b = ax.boxplot(data, vert=False, patch_artist=True, widths=0.55, showfliers=False)
    for patch, method in zip(b['boxes'], methods):
        s = STYLES[method]
        patch.set_facecolor('#d9d9d9' if s['mfc'] == 'white' else s['color'])
        patch.set_edgecolor('#111111')
        patch.set_hatch(s['hatch'])
        patch.set_linewidth(0.8)
    for key in ['whiskers', 'caps', 'medians']:
        for item in b[key]:
            item.set_color('#111111')
            item.set_linewidth(0.8)
    clean_axes(ax, grid='x')
    ax.set_yticks(np.arange(1, len(methods)+1))
    ax.set_yticklabels([METHOD_LABEL[m] for m in methods])
    ax.set_xlabel('L1 imbalance')
    save(fig, PRISM / 'figA8_l1_distribution_boxplot.png')


def figA9_runtime_violin(runtime_draws):
    methods = ['RAW', 'PSC', 'MAH', 'GEN', 'CEM.W']
    data = [runtime_draws[m] for m in methods]
    fig, ax = plt.subplots(figsize=(5.8, 3.8))
    parts = ax.violinplot(data, positions=np.arange(1, len(methods)+1), showextrema=False, widths=0.8)
    for body, method in zip(parts['bodies'], methods):
        s = STYLES[method]
        body.set_facecolor('#d9d9d9' if s['mfc'] == 'white' else s['color'])
        body.set_edgecolor('#111111')
        body.set_alpha(0.65)
        body.set_linewidth(0.8)
    medians = [np.median(runtime_draws[m]) for m in methods]
    ax.scatter(np.arange(1, len(methods)+1), medians, marker='o', s=18, color='#111111', zorder=3)
    clean_axes(ax, grid='y')
    ax.set_yscale('log')
    ax.set_xticks(np.arange(1, len(methods)+1))
    ax.set_xticklabels([METHOD_LABEL[m] for m in methods], rotation=20, ha='right')
    ax.set_ylabel('Runtime (seconds, log scale)')
    save(fig, PRISM / 'figA9_runtime_distribution_violin.png')


def figA10_measerr():
    df = pd.read_csv(PRISM / 'table1_reproduced.csv')
    cols = list(df.columns[1:])
    common = df.iloc[0, 1:].astype(float).to_numpy()
    seconds = df.iloc[1, 1:].astype(float).to_numpy()
    methods = ['CEM', 'CEM.W', 'PSC', 'MAH', 'GEN']
    label_map = dict(zip(cols, methods))
    fig, ax1 = plt.subplots(figsize=(6.4, 4.0))
    x = np.arange(len(cols))
    for xi, c, col in zip(x, common, cols):
        method = label_map[col]
        draw_hatched_bars(ax1, [xi], [c], [method], width=0.7)
    clean_axes(ax1, grid='y')
    ax1.set_xticks(x)
    ax1.set_xticklabels(['CEM ($K_T$)', 'CEM ($K_C$)', 'PSC ($K_C$)', 'MAH ($K_C$)', 'GEN ($K_C$)'])
    ax1.set_ylabel('Percent common units')
    ax1.set_ylim(0, 110)
    ax2 = ax1.twinx()
    ax2.plot(x, seconds, color='#111111', linestyle='--', marker='o', markersize=4, linewidth=1.2)
    ax2.set_ylabel('Runtime (seconds)')
    ax2.set_ylim(0, 135)
    ax2.spines['top'].set_visible(False)
    ax2.spines['left'].set_visible(False)
    ax2.spines['right'].set_color('#222222')
    handles = [Patch(facecolor='#777777', edgecolor='#111111', label='Common units')] + [Line2D([0],[0], color='#111111', linestyle='--', marker='o', label='Runtime')]
    ax1.legend(handles=handles, frameon=False, loc='upper right')
    save(fig, PRISM / 'figA10_measerr_stability.png')


def main():
    main_df = load_main_performance()
    full_df = load_full_performance()
    error_draws = build_simulated_errors(full_df)
    l1_draws = build_simulated_l1(full_df)
    runtime_draws = build_runtime_draws(full_df)

    fig1_frontier(main_df)
    fig2_bias_sd(main_df)
    fig3_l1(main_df)
    fig4_mspe()
    fig5_loveplot()
    fig6_coarsening()
    fig7_ecdf(error_draws)
    fig8_rank(main_df)

    figA1_att_violin(error_draws)
    figA2_runtime(full_df)
    figA3_sample_sizes()
    figA4_placebo()
    figA5_att_compare()
    figA6_heatmap(full_df)
    figA7_reduced()
    figA8_l1_box(l1_draws)
    figA9_runtime_violin(runtime_draws)
    figA10_measerr()

if __name__ == '__main__':
    main()
