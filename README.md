# LASSO Analysis of Problematic Mobile Phone Use

**IDC6940 — Capstone Projects in Data Science**

Richard Odgers, Melissa Bolen, Jillian Mouser, Jonathan De La Torre  
Advisor: Dr. Cohen

## Project overview

We study **problematic mobile phone use** using survey data from a Computer
Adaptive Testing (CAT) item bank [@gao2024]. The main question: **which
non-SPAI scales best predict overall smartphone-addiction severity**, measured
as **SPAI total** (the sum of all 20 SPAI items)?

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

SPAI items are excluded from predictors when modeling SPAI total so the outcome
is not built from its own inputs.

## Methods

We use **penalized linear regression** when dozens of correlated survey items
create multicollinearity [@james2013; @mcneish2015]. **LASSO** adds an $L_1$
penalty that shrinks weak coefficients to zero and performs automatic variable
selection [@tibshirani1996; @hesterberg2008]. **Group LASSO** selects entire
scales at once rather than individual items [@yuan2006; @huang2024].

All models share one **80/20 train/test split** (stratified on `SPAI_12`).
$\lambda$ is tuned with 10-fold cross-validation; we report **`lambda.min`**
and **`lambda.1se`** (parsimonious model within one SE of the best CV error).

Two independent modeling choices:

1. **Selection unit** — **Plain LASSO** (`glmnet`) keeps or drops individual
   items; **Group LASSO** (`grpreg`) keeps or drops whole scales at once.
2. **Outcome type** — **Multinomial** LASSO predicts `SPAI_12` as a 4-level
   category; **Gaussian** LASSO predicts **SPAI total** as a continuous score.

We fit **12 models** in one comparison table:

- 8 classification models (Plain/Group × variants A, B, C1, C2 on `SPAI_12`)
- 4 Gaussian regression models (Plain/Group × `lambda.min` / `lambda.1se` on
  `SPAI_total`)

**Recommended model for the paper:** plain LASSO at `lambda.1se` on SPAI total
— strong test-set R² with far fewer predictors than group LASSO at `lambda.min`.
Initial results point to **SAPS** and **SAS** as the main cross-scale predictors;
**nomophobia (NMP)** contributes little once those scales are included.

## Data exploration (highlights)

Exploratory analysis in `index.qmd` and `scripts/` visualizations shows:

- Sample: mean age ≈ 18.8 years; 991 female / 628 male respondents
- SPAI total: mean ≈ 41.8 ($SD$ ≈ 10.2) on a 20–80 scale
- **NMP** has the highest mean endorsement (~69% of scale maximum) but the
  **weakest** correlation with SPAI total ($r \approx 0.55$)
- Strongest SPAI predictors among other scales: **SAS** ($r \approx 0.81$),
  **SAPS** and **MPATS** ($r \approx 0.71$), **MPAS** ($r \approx 0.65$)
- All six scales are highly intercorrelated (convergent validity + multicollinearity)
- **SPAI item 12** is class-imbalanced (~6% in the rarest category)

## Repository structure

```
├── index.qmd              # Capstone report (Methods + Data Exploration)
├── index.html             # Rendered report
├── slides.qmd             # Presentation slides
├── slides.html            # Rendered slides
├── references.bib         # Bibliography
├── data/                  # Survey CSV and item-bank documentation
├── research/              # Literature reviews and background reading
├── scripts/
│   ├── jad160_CellphoneAddiction_Lasso.qmd   # Live analysis + group proposal (PDF)
│   ├── jad160_CellphoneAddiction_Lasso.pdf   # Rendered proposal
│   ├── jad160_visualizations.qmd             # Descriptive stats & EDA
│   ├── phone_use_visualizations.qmd          # Scale distributions & correlations
│   └── jad160_CellphoneAddiction_Lasso.R     # Standalone R script (local; gitignored)
└── instructions/          # Course template files
```

## Data

- `data/DATA_Problematic Mobile Phone Use CAT.csv` — 1,619 respondents, 101
  variables (demographics + survey items)
- `data/ITEM BANK_Problematic Mobile Phone CAT.docx` — item bank documentation

Source: Gao et al. (2024), *Data in Brief* — CAT-PMPU item bank and dataset.

## Running the analysis

**Capstone report** — Methods, EDA figures, and bibliography:

```bash
quarto render index.qmd
```

Output: `index.html`

**Presentation slides:**

```bash
quarto render slides.qmd
```

Output: `slides.html`

**Quarto proposal (detailed model comparison)** — reproducible tables, renders
to PDF:

```bash
quarto render scripts/jad160_CellphoneAddiction_Lasso.qmd
```

Output: `scripts/jad160_CellphoneAddiction_Lasso.pdf`

**Exploratory visualizations:**

```bash
quarto render scripts/jad160_visualizations.qmd
quarto render scripts/phone_use_visualizations.qmd
```

Requires R packages: `tidyverse`, `glmnet`, `grpreg`, `caret`, `nnet`, `dplyr`,
`knitr`, `patchwork`, `ggplot2`. For PDF output, a LaTeX engine is needed
(`tinytex::install_tinytex()` if rendering fails).

**Standalone R script** — from the project root:

```r
source("scripts/jad160_CellphoneAddiction_Lasso.R")
```

Run by sourcing the file (not pasting line-by-line into the console).

## Viewing the report

The course report is published via GitHub Pages:

**https://jad160.github.io/IDC6940_Lasso-Short-Videos-Addiction/**

Open `slides.html` locally for the team presentation deck.
