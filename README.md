# Lasso Regression on Cellphone Use Addiction

**IDC6940 — Capstone Projects in Data Science**

Richard Odgers, Melissa Bolen, Jillian Mouser, Jonathan De La Torre  
Advisor: Dr. Cohen

## Project overview

We study **problematic smartphone use (PSU)** with survey data from a Computer
Adaptive Testing (CAT) item bank collected in China (Gao et al., 2024). The
central question: **which non-SPAI scales and demographics best predict overall
smartphone-addiction severity**, measured as continuous **SPAI total** (sum of
all 20 SPAI items)?

The dataset has **1,619** complete cases across six instrument families plus
demographics:

| Abbreviation | Scale |
|--------------|-------|
| NMP | Nomophobia |
| SAPS | Smartphone Addiction Proneness |
| SPAI | Smartphone Addiction Inventory |
| MPAS | Mobile Phone Addiction Scale |
| MPATS | Mobile Phone Addiction Tendency Scale |
| SAS | Smartphone Addiction Scale (SAS_C / SAS_CA items) |

SPAI items are excluded from predictors when modeling SPAI total to avoid
circularity. Background on PSU antecedents draws on Busch and McCarthy (2021);
the SPAI instrument is Lin et al. (2014).

## Report contents (`index.qmd`)

1. **Introduction** — PSU context, multicollinearity, motivation for LASSO  
2. **Methods** — OLS vs LASSO, \(\lambda\) tuning, **iterative LASSO** reduction,
   post-LASSO OLS short form  
3. **Analysis and Results** — EDA, iterative model comparison, preferred
   33-predictor model, five-item OLS subset  
4. **Conclusion** — findings, China / young-adult generalizability, future work  
5. **References** — `references.bib`

Companion deck: `slides.qmd` → `slides.html`.

## Methods (summary)

With dozens of correlated survey items, OLS tends to overfit.
**LASSO** (\(L_1\) penalty) shrinks weak coefficients to zero and selects
variables (Tibshirani, 1996; James et al., 2013).

- **80/20** train/test split (stratified on `SPAI_12`)
- 10-fold CV for \(\lambda\); report **`lambda.min`** and **`lambda.1se`**

### Iterative LASSO

1. **Phase 1** — Gaussian LASSO at `lambda.min` (81 → 52 predictors), then a
   stability refit on survivors  
2. **Phase 2** — Escalate to `lambda.1se` and larger multiples of that penalty,
   tracking test RMSE, MAE, \(R^2\), and MAPE until further shrinkage hurts
   accuracy  

Among candidates, prefer the strongest held-out metrics; break ties toward
parsimony.

### Post-LASSO OLS

Refit OLS on the **five largest-magnitude** predictors from the preferred
LASSO model (short-form screen).

## Key findings

- Preferred model: **33 predictors** — test RMSE \(= 5.16\), test \(R^2 = 0.75\)
  (~59% fewer predictors than the 81-variable baseline)
- Further shrinkage to 28 / 22 / 19 predictors degraded accuracy
  (\(R^2 < 0.70\) at 19)
- **SAPS** and **SAS** dominate; smaller **MPATS** role; **NMP** largely zeroed out
- Five-item post-LASSO OLS: test \(R^2 = 0.66\) (strong for five items; below 0.75)
- High \(R^2\) = **convergent validity** among overlapping instruments, not causation
- Sample: Chinese young adults (mean age \(= 18.8\); more female than male) —
  do not generalize without external validation

**Future work** (as in the paper): robustness across splits/seeds, short-form
validation, more systematic **group LASSO**, and extension beyond the Chinese
young-adult cohort.

## Data exploration (highlights)

- SPAI total: mean \(\approx 41.8\) (\(SD \approx 10.2\)) on a 20–80 scale
- Strongest correlate with SPAI total: **SAS** (\(r \approx 0.81\)); then
  **SAPS** / **MPATS** (\(\approx 0.71\)), **MPAS** (\(\approx 0.65\));
  **NMP** weakest (\(\approx 0.55\))
- Scales are highly intercorrelated (convergent validity + multicollinearity)

## Repository structure

```
├── index.qmd / index.html     # Capstone report
├── slides.qmd / slides.html   # Presentation
├── references.bib             # Bibliography
├── data/                      # CAT CSV + item-bank docs
├── scripts/                   # Supporting EDA / analysis notebooks
├── research/                  # Background reading
└── instructions/              # Course templates
```

## Data

- `data/DATA_Problematic Mobile Phone Use CAT.csv` — 1,619 × 101  
- `data/ITEM BANK_Problematic Mobile Phone CAT.docx` — item documentation  

Source: Gao et al. (2024), *Data in Brief*.

Rendering expects `cellphone.csv` in the project root (copy from the CAT CSV
if needed).

## Running the analysis

```bash
quarto render index.qmd    # → index.html
quarto render slides.qmd   # → slides.html
```

Optional EDA notebooks:

```bash
quarto render scripts/jad160_visualizations.qmd
quarto render scripts/phone_use_visualizations.qmd
```

R packages used include: `tidyverse`, `glmnet`, `caret`, `knitr`,
`kableExtra`, `patchwork`, `ggplot2` (and `grpreg` if rendering older
group-LASSO slide chunks).

## Viewing the report

GitHub Pages:

**https://jad160.github.io/IDC6940_Lasso-Cellphone-Use-Addiction/**
