# thawingde

Production pipeline for constraining the thawing scalar-field dark energy model
using DES Year 6 data and external probes.

**Model:** w(a) = -1 + (1+w₀) exp(−α(1/a − 1))  
**Code:** modified CAMB (`thaw_camb`) inside CosmoSIS via `cosmosis_thaw` conda env  
**Sampler:** Nautilus (nested sampling, Bayesian evidence + posteriors)

---

## Science

The model is the quasi-universal thawing scalar field parameterization from
Shajib & Frieman (2025) [arXiv:2502.06929]. Parameters:

| Parameter | Role | Prior |
|---|---|---|
| w₀ | equation of state today | U(−1,−0.33) NEC or U(−2,−0.33) broad |
| α | scalar field shape | U(1.35, 1.55) |

All cosmological priors follow DES Y6 defaults [arXiv:2601.14559].

---

## Directory layout

```
thawingde/
├── ini/
│   ├── common/          shared config blocks (CAMB, likelihoods, paths)
│   ├── external/        9 runs: DESI DR2, Dovekie SN, DESI+SN  × {NEC, broad, ΛCDM}
│   ├── cmb/             3 runs: Planck+ACT+SPT-3G              × {NEC, broad, ΛCDM}
│   ├── 3x2/             3 runs: DES Y6 3×2pt                   × {NEC, broad, ΛCDM}
│   ├── joint/           3 runs: 3×2pt + Dovekie SN             × {NEC, broad, ΛCDM}
│   ├── cmb_joint/       6 runs: DESI+CMB, All                  × {NEC, broad, ΛCDM}
│   ├── values/          cosmology + nuisance prior/value files
│   └── priors/          Gaussian prior files (Planck/ACT/SPT calibration)
├── sbatch/              24 chain sbatch scripts + shared launcher
├── chains/              output (gitignored)
│   ├── external/        → 9 external chains
│   ├── cmb/             → 3 CMB chains
│   ├── 3x2/             → 3 3×2pt chains
│   ├── joint/           → 3 joint chains
│   ├── cmb_joint/       → 6 CMB+joint chains
│   └── logs/            → sbatch .out/.err files
├── ml/                  CosmoSIS forward-model module for ML training data
├── Y5/                  DES Y5 SN-only reproduction (reference chain)
└── thawingde2.ipynb     analysis notebook (run after chains complete)
```

---

## 24 chains

| Dataset | NEC | Broad | ΛCDM |
|---|---|---|---|
| DESI DR2 | ✓ | ✓ | ✓ |
| Dovekie SN | ✓ | ✓ | ✓ |
| DESI DR2 + Dovekie | ✓ | ✓ | ✓ |
| CMB (Planck+ACT+SPT-3G) | ✓ | ✓ | ✓ |
| DES Y6 3×2pt | ✓ | ✓ | ✓ |
| 3×2pt + Dovekie | ✓ | ✓ | ✓ |
| DESI + CMB | ✓ | ✓ | ✓ |
| All (3×2pt+DESI+Dovekie+CMB) | ✓ | ✓ | ✓ |

Priors: NEC = w₀ ∈ U(−1,−0.33), Broad = w₀ ∈ U(−2,−0.33), ΛCDM = w₀ = −1 fixed.  
Bayes evidence denominator: ΛCDM chain for each dataset combination.

---

## Submitting all chains

From `/project/sdodelso/joannjones/cosmosis-standard-library`:

```bash
# External runs (30 cores each)
sbatch thawingde/sbatch/desi_dr2_thaw.sbatch
sbatch thawingde/sbatch/desi_dr2_thaw_broad.sbatch
sbatch thawingde/sbatch/desi_dr2_lcdm.sbatch
sbatch thawingde/sbatch/dovekie_sn_thaw.sbatch
sbatch thawingde/sbatch/dovekie_sn_thaw_broad.sbatch
sbatch thawingde/sbatch/dovekie_sn_lcdm.sbatch
sbatch thawingde/sbatch/desi_dr2_dovekie_sn_thaw.sbatch
sbatch thawingde/sbatch/desi_dr2_dovekie_sn_thaw_broad.sbatch
sbatch thawingde/sbatch/desi_dr2_dovekie_sn_lcdm.sbatch

# CMB runs (30 cores each)
sbatch thawingde/sbatch/planck_act_spt_thaw.sbatch
sbatch thawingde/sbatch/planck_act_spt_thaw_broad.sbatch
sbatch thawingde/sbatch/planck_act_spt_lcdm.sbatch

# 3×2pt runs (100 cores each)
sbatch thawingde/sbatch/y6_3x2_thaw.sbatch
sbatch thawingde/sbatch/y6_3x2_thaw_broad.sbatch
sbatch thawingde/sbatch/y6_3x2_lcdm.sbatch

# Joint runs (100 cores each)
sbatch thawingde/sbatch/y6_3x2_dovekie_sn_thaw.sbatch
sbatch thawingde/sbatch/y6_3x2_dovekie_sn_thaw_broad.sbatch
sbatch thawingde/sbatch/y6_3x2_dovekie_sn_lcdm.sbatch

# CMB joint runs (30 cores each)
sbatch thawingde/sbatch/desi_dr2_planck_act_spt_thaw.sbatch
sbatch thawingde/sbatch/desi_dr2_planck_act_spt_thaw_broad.sbatch
sbatch thawingde/sbatch/desi_dr2_planck_act_spt_lcdm.sbatch

# All (100 cores each)
sbatch thawingde/sbatch/y6_3x2_desi_dr2_planck_act_spt_thaw.sbatch
sbatch thawingde/sbatch/y6_3x2_desi_dr2_planck_act_spt_thaw_broad.sbatch
sbatch thawingde/sbatch/y6_3x2_desi_dr2_planck_act_spt_lcdm.sbatch
```

Logs go to `chains/logs/`. Chains resume automatically if resubmitted.

---

## Environment

- Pipeline: `cosmosis_thaw` conda env
- Analysis notebook: `clusterarc-tools` conda env
- Modified CAMB: `/project/sdodelso/joannjones/thaw_camb`

---

## Key references

- Shajib & Frieman (2025) [arXiv:2502.06929] — thawing model definition and Y5 constraints
- DES Y6 (2026) [arXiv:2601.14559] — 3×2pt likelihood and priors
- Planck 2018 [A&A 641, A6] — CMB likelihood
