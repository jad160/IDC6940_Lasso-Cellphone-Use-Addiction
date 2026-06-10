# Lasso Regression on Cellphone Use Addiction

**IDC6940 — Capstone Projects in Data Science**

Richard Odgers, Melissa Bolen, Jillian Mouser, Jonathan De La Torre  
Advisor: Dr. Cohen

## Project overview

This capstone project studies **problematic mobile phone use** using survey data
from a Computer Adaptive Testing (CAT) item bank. The goal is to identify which
psychological and behavioral measures are most strongly associated with a key
smartphone addiction outcome, while managing high-dimensional predictors and
multicollinearity among related survey subscales.

The primary outcome is **SPAI_12**, an item from the Smartphone Physical
Addiction Inventory (SPAI). Predictors include demographic variables and items
from related instruments:

| Prefix | Scale |
|--------|-------|
| NMP | Nomophobia |
| SAPS | Smartphone Application-Based Addiction Scale |
| SPAI | Smartphone Physical Addiction Inventory |
| MPAS | Mobile Phone Addiction Scale |
| MPATS | Mobile Phone Addiction Tendency Scale |
| SAS_C / SAS_CA | Smartphone Addiction Scale (core and companion items) |

## Methods

The analysis workflow includes:

1. **Exploratory analysis** — data summaries, correlations, and visualization
2. **Multicollinearity diagnostics** — variance inflation factor (VIF) checks
3. **LASSO regression** — penalized multinomial models to select predictors of
   `SPAI_12`
4. **Group LASSO** — the same outcome modeled with predictors grouped by survey
   subscale (e.g., all NMP items together, all SAPS items together)
5. **Post-selection refit** — multinomial logistic regression on variables
   retained by LASSO / Group LASSO
6. **Model comparison** — accuracy, kappa, and confusion matrices for
   `lambda.min` vs `lambda.1se`

## Repository structure

```
├── index.qmd          # Main Quarto report (rendered to index.html)
├── slides.qmd         # Presentation slides
├── references.bib     # Bibliography
├── data/              # Survey data and item bank documentation
├── research/          # Literature reviews and background reading
├── scripts/           # R analysis scripts (local use)
└── instructions/      # Course template files
```

## Data

- `data/DATA_Problematic Mobile Phone Use CAT.csv` — 1,619 respondents, 101
  variables (demographics + survey items)
- `data/ITEM BANK_Problematic Mobile Phone CAT.docx` — item bank documentation

## Viewing the report

The rendered report is published via GitHub Pages:

**https://jad160.github.io/IDC6940_Lasso-Short-Videos-Addiction/**
