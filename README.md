# LASSO Analysis of Problematic Mobile Phone Use

**IDC6940 — Capstone Projects in Data Science**

Richard Odgers, Melissa Bolen, Jillian Mouser, Jonathan De La Torre  
Advisor: Dr. Cohen

## Project overview

We study **problematic mobile phone use** using survey data from a Computer
Adaptive Testing (CAT) item bank. The main question: **which non-SPAI scales
best predict overall smartphone-addiction severity**, measured as **SPAI total**
(the sum of all 20 SPAI items)?

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

## Methods (current workflow)

All models share one **80/20 train/test split** (stratified on `SPAI_12`).

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

## Repository structure

```
├── index.qmd              # Capstone report template (HTML)
├── slides.qmd             # Presentation slides
├── references.bib         # Bibliography
├── data/                  # Survey CSV and item-bank documentation
├── research/              # Literature reviews and background reading
├── scripts/
│   ├── jad160_CellphoneAddiction_Lasso.qmd   # Live analysis + group proposal (PDF)
│   ├── jad160_CellphoneAddiction_Lasso.pdf   # Rendered proposal
│   └── jad160_CellphoneAddiction_Lasso.R     # Standalone R script (local; gitignored)
└── instructions/        # Course template files
```

## Data

- `data/DATA_Problematic Mobile Phone Use CAT.csv` — 1,619 respondents, 101
  variables (demographics + survey items)
- `data/ITEM BANK_Problematic Mobile Phone CAT.docx` — item bank documentation

## Running the analysis

**Quarto proposal (recommended)** — reproducible tables, renders to PDF:

```bash
quarto render scripts/jad160_CellphoneAddiction_Lasso.qmd
```

Output: `scripts/jad160_CellphoneAddiction_Lasso.pdf`

Requires R packages: `glmnet`, `grpreg`, `caret`, `nnet`, `dplyr`, `knitr`.
For PDF output, a LaTeX engine is needed (`tinytex::install_tinytex()` if
rendering fails).

**Standalone R script** — from the project root:

```r
source("scripts/jad160_CellphoneAddiction_Lasso.R")
```

Run by sourcing the file (not pasting line-by-line into the console).

## Viewing the report

The course report template is published via GitHub Pages:

**https://jad160.github.io/IDC6940_Lasso-Short-Videos-Addiction/**

The LASSO methodology proposal lives in `scripts/` as the Quarto PDF above.
