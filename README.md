# Lasso Regression on Cellphone Use Addiction

**IDC6940 — Capstone Projects in Data Science**

Richard Odgers, Melissa Bolen, Jillian Mouser, Jonathan De La Torre  
Advisor: Dr. Cohen

## Project overview

We study **problematic mobile phone use** with survey data from a Computer
Adaptive Testing (CAT) item bank collected in China (Gao et al., 2024). The
main question: **which non-SPAI scales and demographics best predict overall
smartphone-addiction severity**, measured as **SPAI total** (sum of all 20
SPAI items)?

The dataset has **1,619** respondents with complete data on six instrument
families plus demographics:

| Abbreviation | Scale |
|--------------|-------|
| NMP | Nomophobia |
| SAPS | Smartphone Addiction Proneness |
| SPAI | Smartphone Addiction Inventory |
| MPAS | Mobile Phone Addiction Scale |
| MPATS | Mobile Phone Addiction Tendency Scale |
| SAS | Smartphone Addiction Scale (SAS_C / SAS_CA items) |

SPAI items are excluded from predictors when modeling SPAI total so the
outcome is not built from its own inputs. A secondary categorical outcome,
**SPAI item 12**, captures perceived negative impact on study or work.

## Methods

With dozens of correlated survey items, ordinary least squares tends to
overfit under multicollinearity. **LASSO** adds an \(L_1\) penalty that
shrinks weak coefficients to exactly zero and performs automatic variable
selection (Tibshirani, 1996; James et al., 2013).

Models use an **80/20 train/test split** (stratified on `SPAI_12`). \(\lambda\)
is tuned with 10-fold cross-validation; we report both **`lambda.min`** and
**`lambda.1se`**.

### Iterative LASSO variable reduction

Rather than a single fit, the paper uses a **two-phase iterative refitting**
procedure:

1. **Phase 1** — Fit Gaussian LASSO at `lambda.min`, retain nonzero predictors
   (81 → 52), then refit on survivors for a stability check.
2. **Phase 2** — Escalate to `lambda.1se` and successively larger multiples of
   that penalty, refitting after each step and monitoring test RMSE, MAE,
   \(R^2\), and MAPE until further shrinkage meaningfully degrades accuracy.

Candidates across both phases are compared on held-out metrics; when scores
are near-equivalent, the more parsimonious model is preferred.

### Post-LASSO OLS

From the selected LASSO model, the **five largest-magnitude** predictors are
refit with ordinary least squares on the same split to assess a short-form
instrument.

## Key findings

- Preferred model: **33 predictors** (`lambda.1se` after Phase 2) — test
  RMSE \(= 5.16\), test \(R^2 = 0.75\) (~59% fewer predictors than the
  81-variable baseline)
- Further shrinkage to 28 / 22 / 19 predictors degraded accuracy
  (\(R^2 < 0.70\) at 19) and activated the stopping rule
- Selected items concentrate in **SAPS** and **SAS**; smaller **MPATS** role;
  **NMP** largely zeroed out
- Post-LASSO OLS on five items: test \(R^2 = 0.66\) (strong for a five-item
  screen, below the 33-item model)
- High \(R^2\) is best read as **convergent validity** among overlapping
  addiction instruments, not causation
- Sample is Chinese young adults (mean age \(= 18.8\); more female than male);
  findings should not be generalized without external validation

## Data exploration (highlights)

From `index.qmd`:

- SPAI total: mean \(\approx 41.8\) (\(SD \approx 10.2\)) on a 20–80 scale
- Strongest zero-order correlate with SPAI total: **SAS** (\(r \approx 0.81\));
  then **SAPS** / **MPATS** (\(r \approx 0.71\)), **MPAS** (\(r \approx 0.65\));
  **NMP** weakest (\(r \approx 0.55\)) despite high endorsement
- All six scales are highly intercorrelated (convergent validity +
  multicollinearity)
- **SPAI item 12** is class-imbalanced (~6% in the rarest category)

## Repository structure

```
├── index.qmd              # Capstone report (full narrative + analysis)
├── index.html             # Rendered report
├── slides.qmd             # Presentation slides
├── slides.html            # Rendered slides
├── references.bib         # Bibliography
├── data/                  # Survey CSV and item-bank documentation
├── research/              # Literature reviews and background reading
├── scripts/               # Supporting EDA and analysis notebooks
└── instructions/          # Course template files
```

## Data

- `data/DATA_Problematic Mobile Phone Use CAT.csv` — 1,619 respondents, 101
  variables (demographics + survey items)
- `data/ITEM BANK_Problematic Mobile Phone CAT.docx` — item bank documentation

Source: Gao et al. (2024), *Data in Brief* — CAT-PMPU item bank and dataset.

Rendering `index.qmd` / `slides.qmd` expects a working copy named
`cellphone.csv` in the project root (copy from the CAT CSV if needed).

## Running the analysis

**Capstone report:**

```bash
quarto render index.qmd
```

Output: `index.html`

**Presentation slides:**

```bash
quarto render slides.qmd
```

Output: `slides.html`

**Exploratory visualizations:**

```bash
quarto render scripts/jad160_visualizations.qmd
quarto render scripts/phone_use_visualizations.qmd
```

Requires R packages including: `tidyverse`, `glmnet`, `grpreg`, `caret`,
`knitr`, `kableExtra`, `patchwork`, `ggplot2`.

## Viewing the report

Published via GitHub Pages:

**https://jad160.github.io/IDC6940_Lasso-Cellphone-Use-Addiction/**

Open `slides.html` locally for the team presentation deck.
