#  Melissa Bolen
#  Capstone
#  This model is summing all SPAI as one continuous variable



library(glmnet)
library(dplyr)

# ===============================
# 1. LOAD DATA
# ===============================
cells_data <- read.csv("cellphone.csv", header = TRUE)

# ===============================
# 2. CLEAN GRADE and Gender
# ===============================
grade_map <- c(
  "1" = "F", "2" = "Sph", "3" = "J", "4" = "Sen", 
  "5" = "M1", "6" = "M2", "7" = "M3", "8" = "Doc", 
  "12" = "8th", "13" = "9th", "14" = "10th", "15" = "11th", "16" = "12th"
)
cells_data$grade <- factor(grade_map[as.character(cells_data$grade)])

# ADD THIS LINE TO FIX GENDER:
cells_data$gender <- factor(cells_data$gender)

# ===============================
# 3. DEFINE OUTCOME (TOTAL SPAI ADDICTION)
# ===============================
# Generate names for all 20 SPAI items
spai_all <- paste0("SPAI_", 1:20)

# Convert all 20 columns to numeric
cells_data[spai_all] <- lapply(cells_data[spai_all], function(x) as.numeric(as.character(x)))

# MODIFIED: Calculate the sum of ALL 20 SPAI variables
cells_data$sum_SPAI <- rowSums(cells_data[, spai_all], na.rm = TRUE)

# MODIFIED: Set sum_SPAI as the new dependent variable
y <- cells_data$sum_SPAI

# ===============================
# 4. PREDICTORS (NO SPAI LEAKAGE)
# ===============================
# MODIFIED: Drop the new target variable (sum_SPAI) and all individual SPAI columns 
x <- cells_data %>% select(-sum_SPAI, -all_of(spai_all))

# Safety check: Ensure no lingering SPAI or target columns exist in your predictors
stopifnot(!any(grepl("SPAI", names(x))))

# ===============================
# 5. FIXED: MODEL MATRIX BEFORE SPLIT
# ===============================
x_full_mat <- model.matrix(~ . - 1, data = x)

# ===============================
# 6. TRAIN / TEST SPLIT
# ===============================
set.seed(123)
n <- nrow(x_full_mat)
train_index <- sample(1:n, size = 0.8 * n)

x_train_mat <- x_full_mat[train_index, ]
x_test_mat  <- x_full_mat[-train_index, ]
y_train     <- y[train_index]
y_test      <- y[-train_index]

# ===============================
# 7. LASSO (TRAIN ONLY)
# ===============================
set.seed(123)
cv_lasso <- cv.glmnet(
  x = x_train_mat, y = y_train, 
  alpha = 1, family = "gaussian", nfolds = 10
)

# ===============================
# 8. TRAIN VS TEST EVALUATION
# ===============================
pred_train <- as.numeric(predict(cv_lasso, s = "lambda.min", newx = x_train_mat))
pred_test  <- as.numeric(predict(cv_lasso, s = "lambda.min", newx = x_test_mat))

rmse_train <- sqrt(mean((y_train - pred_train)^2))
mae_train  <- mean(abs(y_train - pred_train))
r2_train   <- 1 - (sum((y_train - pred_train)^2) / sum((y_train - mean(y_train))^2))

rmse_test  <- sqrt(mean((y_test - pred_test)^2))
mae_test   <- mean(abs(y_test - pred_test))
r2_test    <- 1 - (sum((y_test - pred_test)^2) / sum((y_test - mean(y_test))^2))

# FIXED: Removed the duplicate uncorrected line beneath this one
cv_rmse    <- sqrt(cv_lasso$cvm[cv_lasso$lambda == cv_lasso$lambda.min])




##########----------------------------------------------
########################################################
##########______________________________________________


# ==============================================================================
# ADDITIONAL CODE: PLOT FIT AND EXTRACT TOP PREDICTORS (TOTAL SPAI MODEL)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. VISUALIZE MODEL FIT (ACTUAL VS. PREDICTED)
# ------------------------------------------------------------------------------
plot_data <- data.frame(
  Actual = y_test,
  Predicted = pred_test
)

# Determine coordinate boundaries for a perfectly square 1:1 plot
min_val <- min(c(plot_data$Actual, plot_data$Predicted), na.rm = TRUE)
max_val <- max(c(plot_data$Actual, plot_data$Predicted), na.rm = TRUE)

plot(
  x = plot_data$Actual, 
  y = plot_data$Predicted,
  # MODIFIED: Titles updated to reflect Total SPAI instead of Sub-Addiction
  main = "Model Fit: Actual vs. Predicted Total SPAI Score (Test Set)",
  xlab = "Actual Total SPAI Score",
  ylab = "Predicted Total SPAI Score",
  pch = 16,            # Solid circles
  col = rgb(0.2, 0.4, 0.6, 0.5), # Transparent blue to see data density
  xlim = c(min_val, max_val),
  ylim = c(min_val, max_val)
)

# Add a dashed line representing a perfect 1:1 prediction match
abline(a = 0, b = 1, col = "red", lty = 2, lwd = 2)
legend("topleft", legend = "Perfect Prediction Line", col = "red", lty = 2, lwd = 2)


# ------------------------------------------------------------------------------
# 2. EXTRACT AND CLEAN TOP PREDICTORS
# ------------------------------------------------------------------------------
# Extract Lasso coefficients at the optimal lambda (lambda.min)
coef_lasso <- coef(cv_lasso, s = "lambda.min")

# Convert to a clean matrix format
coef_matrix <- as.matrix(coef_lasso)
coef_df <- data.frame(
  Dummy_Variable = rownames(coef_matrix),
  Coefficient = coef_matrix[, 1],
  Absolute_Impact = abs(coef_matrix[, 1]),
  stringsAsFactors = FALSE
)

# Remove the Intercept and filter to only selected features (non-zero)
selected_features <- coef_df %>%
  filter(Dummy_Variable != "(Intercept)", Coefficient != 0) %>%
  arrange(desc(Absolute_Impact))

# Combine everything into a clean presentation table with exact string matching
first_top_predictors <- selected_features %>%
  rowwise() %>%
  mutate(Original_Variable = {
    # Find which original column names match the start of the dummy name
    matches <- names(x)[sapply(names(x), function(orig) grepl(paste0("^", orig), Dummy_Variable))]
    # Pick the longest match to avoid sub-string confusion
    if(length(matches) > 0) matches[which.max(nchar(matches))] else Dummy_Variable
  }) %>%
  ungroup() %>%
  select(Original_Variable, Dummy_Variable, Coefficient)

cat("\n===================================\n")
cat("    TOP SELECTED PREDICTORS        \n")
cat(" (Ranked by Absolute Impact Size) \n")
cat("===================================\n")
print(first_top_predictors, n = Inf, row.names = FALSE)

# MODIFIED: Saved with a unique filename specific to this new total SPAI outcome
write.csv(first_top_predictors, "total_spai_first_predictors.csv", row.names = FALSE)




# ===============================
# 9. OUTPUT RESULTS TABLE (HORIZONTAL LAYOUT)
# ===============================
# 1. Build the base vertical results data frame
results_vertical <- data.frame(
  Metric = c("RMSE", "MAE", "R-Squared"),
  Train  = c(round(rmse_train, 4), round(mae_train, 4), round(r2_train, 4)),
  Test   = c(round(rmse_test, 4), round(mae_test, 4), round(r2_test, 4))
)

# 2. Transpose the metrics to make them columns
results_horizontal <- data.frame(
  Model = "First_Lasso_Reduction",
  OVR = length(unique(first_top_predictors$Original_Variable)),
  `Train RMSE` = results_vertical[1, "Train"],
  `Test RMSE`  = results_vertical[1, "Test"],
  `Train MAE`   = results_vertical[2, "Train"],
  `Test MAE`    = results_vertical[2, "Test"],
  `Train R-Squared` = results_vertical[3, "Train"],
  `Test R-Squared`  = results_vertical[3, "Test"],
  check.names = FALSE
)

cat("\n===============================================================================================================\n")
cat("                                         MODEL PERFORMANCE COMPARISON                                          \n")
cat("===============================================================================================================\n")
print(results_horizontal, row.names = FALSE)
cat(paste("\nInternal 10-Fold CV Training RMSE:", round(cv_rmse, 4), "\n"))


####################################################################
###############################################################################
#
#             Second Lasso
#
###############################################################################
####################################################################


# ==============================================================================
# 1. EXTRACT SELECTED VARIABLE NAMES (REMOVING DUMMY FACTOR SUFFIXES)
# ==============================================================================
# Get unique names of the original variables that survived the first round
remaining_vars <- unique(first_top_predictors$Original_Variable)

# ==============================================================================
# 2. SUBSET THE ORIGINAL X PREDICTORS
# ==============================================================================
# Create a new predictor dataframe containing only the surviving variables
x_reduced <- cells_data %>% select(all_of(remaining_vars))

# ==============================================================================
# 3. GENERATE NEW MODEL MATRIX & SPLIT DATA
# ==============================================================================
x_reduced_mat <- model.matrix(~ . - 1, data = x_reduced)

# Re-use the exact same training indexes from your first split for consistency
x_train_mat2 <- x_reduced_mat[train_index, ]
x_test_mat2  <- x_reduced_mat[-train_index, ]
# Note: y_train and y_test remain exactly the same as your sum_SPAI vectors

# ==============================================================================
# 4. RUN SECOND LASSO MODEL
# ==============================================================================
# ==============================================================================
# 4. RUN SECOND LASSO MODEL
# ==============================================================================
set.seed(123) # Reset seed for reproducibility in cross-validation folds
cv_lasso2 <- cv.glmnet(
  x = x_train_mat2, y = y_train, 
  alpha = 1, family = "gaussian", nfolds = 10
)

# ==============================================================================
# 6. EXTRACT, CLEAN, AND SAVE SECOND REDUCTION VARIABLES
#    (MOVED UP: Must create 'second_top_predictors' before evaluating performance)
# ==============================================================================
coef_lasso2  <- coef(cv_lasso2, s = "lambda.min")
coef_matrix2 <- as.matrix(coef_lasso2)

coef_df2 <- data.frame(
  Dummy_Variable = rownames(coef_matrix2),
  Coefficient = coef_matrix2[, 1],
  Absolute_Impact = abs(coef_matrix2[, 1]),
  stringsAsFactors = FALSE
)

selected_features2 <- coef_df2 %>%
  filter(Dummy_Variable != "(Intercept)", Coefficient != 0) %>%
  arrange(desc(Absolute_Impact))

second_top_predictors <- selected_features2 %>%
  rowwise() %>%
  mutate(Original_Variable = {
    matches <- names(x_reduced)[sapply(names(x_reduced), function(orig) grepl(paste0("^", orig), Dummy_Variable))]
    if(length(matches) > 0) matches[which.max(nchar(matches))] else Dummy_Variable
  }) %>%
  ungroup() %>%
  select(Original_Variable, Dummy_Variable, Coefficient)

cat("\n===================================\n")
cat("    SECOND SELECTED PREDICTORS     \n")
cat("===================================\n")
print(second_top_predictors, n = Inf, row.names = FALSE)

# Saved with a unique filename specific to this second total SPAI reduction
write.csv(second_top_predictors, "total_spai_second_predictors.csv", row.names = FALSE)

# ==============================================================================
# 5. EVALUATE SECOND MODEL PERFORMANCE (HORIZONTAL LAYOUT)
# ==============================================================================
pred_train2 <- as.numeric(predict(cv_lasso2, s = "lambda.min", newx = x_train_mat2))
pred_test2  <- as.numeric(predict(cv_lasso2, s = "lambda.min", newx = x_test_mat2))

# 1. Build the base vertical results data frame
results2_vertical <- data.frame(
  Metric = c("RMSE", "MAE", "R-Squared"),
  Train  = c(round(sqrt(mean((y_train - pred_train2)^2)), 4), round(mean(abs(y_train - pred_train2)), 4), round(1 - (sum((y_train - pred_train2)^2) / sum((y_train - mean(y_train))^2)), 4)),
  Test   = c(round(sqrt(mean((y_test - pred_test2)^2)), 4), round(mean(abs(y_test - pred_test2)), 4), round(1 - (sum((y_test - pred_test2)^2) / sum((y_test - mean(y_test))^2)), 4))
)

# 2. Transpose the metrics to make them columns with the correct OVR mapping
results2_horizontal <- data.frame(
  Model = "Second_Lasso_Reduction",
  OVR = length(unique(second_top_predictors$Original_Variable)),
  `Train RMSE` = results2_vertical[1, "Train"],
  `Test RMSE`  = results2_vertical[1, "Test"],
  `Train MAE`   = results2_vertical[2, "Train"],
  `Test MAE`    = results2_vertical[2, "Test"],
  `Train R-Squared` = results2_vertical[3, "Train"],
  `Test R-Squared`  = results2_vertical[3, "Test"],
  check.names = FALSE
)

cat("\n===============================================================================================================\n")
cat("                                         SECOND MODEL PERFORMANCE                                              \n")
cat("===============================================================================================================\n")
print(results2_horizontal, row.names = FALSE)


#------------------------------------------------------------------
#
####################
#
#   Comparison Tables Code
#
####################
#
#------------------------------------------------------------------


# ==============================================================================
# 1. CALCULATE VARIABLE COUNTS FOR EACH STAGE
# ==============================================================================
# Count original variables (excluding the outcome and ID variables)
initial_var_count <- ncol(x)

# Count unique original variables remaining after first Lasso
first_var_count   <- length(unique(first_top_predictors$Original_Variable))

# Count unique original variables remaining after second Lasso
second_var_count  <- length(unique(second_top_predictors$Original_Variable))

# ==============================================================================
# 2. RUN BASELINE MULTIPLE LINEAR REGRESSION (FOR COMPARISON PERFORMANCE)
# ==============================================================================
# Train a standard OLS model using all variables to establish a baseline
baseline_model <- lm(y_train ~ ., data = as.data.frame(x_train_mat))

pred_train_base <- predict(baseline_model, newdata = as.data.frame(x_train_mat))
pred_test_base  <- predict(baseline_model, newdata = as.data.frame(x_test_mat))

# Baseline metrics
rmse_tr_b <- sqrt(mean((y_train - pred_train_base)^2, na.rm=TRUE))
rmse_te_b <- sqrt(mean((y_test - pred_test_base)^2, na.rm=TRUE))
r2_tr_b   <- 1 - (sum((y_train - pred_train_base)^2, na.rm=TRUE) / sum((y_train - mean(y_train))^2))
r2_te_b   <- 1 - (sum((y_test - pred_test_base)^2, na.rm=TRUE) / sum((y_test - mean(y_test))^2))

# ==============================================================================
# 3. CONSTRUCT THE MASTER COMPARISON TABLE
# ==============================================================================
master_comparison <- data.frame(
  Metric = c(
    "OVR", # MODIFIED: Shorthand notation applied
    "Train RMSE", 
    "Test RMSE", 
    "Train R-Squared", 
    "Test R-Squared"
  ),
  Baseline_Full_Model = c(
    initial_var_count, 
    round(rmse_tr_b, 4), 
    round(rmse_te_b, 4), 
    round(r2_tr_b, 4), 
    round(r2_te_b, 4)
  ),
  First_Lasso_Reduction = c(
    first_var_count, 
    round(rmse_train, 4), 
    round(rmse_test, 4), 
    round(r2_train, 4), 
    round(r2_test, 4)
  ),
  Second_Lasso_Reduction = c(
    second_var_count, 
    round(sqrt(mean((y_train - pred_train2)^2)), 4), 
    round(sqrt(mean((y_test - pred_test2)^2)), 4), 
    round(1 - (sum((y_train - pred_train2)^2) / sum((y_train - mean(y_train))^2)), 4), 
    round(1 - (sum((y_test - pred_test2)^2) / sum((y_test - mean(y_test))^2)), 4)
  )
)

# ==============================================================================
# 4. TRANSPOSE, PRINT, AND SAVE THE SUMMARY TABLE
# ==============================================================================
# MODIFIED: Run transposition logic immediately within the execution sequence
transposed_comparison <- as.data.frame(t(master_comparison[, -1]))
colnames(transposed_comparison) <- master_comparison$Metric

transposed_comparison <- data.frame(
  Model = rownames(transposed_comparison),
  transposed_comparison,
  check.names = FALSE
)

cat("\n===========================================================================================\n")
cat("                         MASTER MODEL SUMMARY TABLE (TOTAL SPAI)                           \n")
cat("===========================================================================================\n")
print(transposed_comparison, row.names = FALSE)

# Save the clean wide spreadsheet to your folder
write.csv(transposed_comparison, "total_spai_master_comparison_transposed.csv", row.names = FALSE)


#______________________________________________________________________________________
#--------------------------------------------------------------------------------------
#______________________________________________________________________________________
#######################################################################################
#
#
#  New Lasso to actually do a second reduction
#
#
#######################################################################################
#______________________________________________________________________________________
#--------------------------------------------------------------------------------------
#______________________________________________________________________________________



# ==============================================================================
# 0. MEMORY RESET: TRUNCATE TABLE TO THE INITIAL 3 MODELS BEFORE APPENDING
# ==============================================================================
# CORRECTED: Ensures the matrix object clears any downstream models cleanly
master_comparison <- master_comparison[, 1:4]


# ==============================================================================
# 1. EXTRACT COEFFICIENTS AND COUNT VARIABLES FOR LAMBDA.1SE
# ==============================================================================
# Extract Lasso coefficients using the stricter 1-standard-error rule
coef_lasso_1se  <- coef(cv_lasso, s = "lambda.1se")
coef_matrix_1se <- as.matrix(coef_lasso_1se)

coef_df_1se <- data.frame(
  Dummy_Variable = rownames(coef_matrix_1se),
  Coefficient = coef_matrix_1se[, 1],
  Absolute_Impact = abs(coef_matrix_1se[, 1]),
  stringsAsFactors = FALSE
)

# Filter out the intercept and zeroed-out variables
selected_features_1se <- coef_df_1se %>%
  filter(Dummy_Variable != "(Intercept)", Coefficient != 0)

# Clean variable names to count unique original variables
top_predictors_1se <- selected_features_1se %>%
  rowwise() %>%
  mutate(Original_Variable = {
    matches <- names(x)[sapply(names(x), function(orig) grepl(paste0("^", orig), Dummy_Variable))]
    if(length(matches) > 0) matches[which.max(nchar(matches))] else Dummy_Variable
  }) %>%
  ungroup()

se1_var_count <- length(unique(top_predictors_1se$Original_Variable))

# ==============================================================================
# 2. EVALUATE LAMBDA.1SE MODEL PERFORMANCE
# ==============================================================================
# Generate predictions using the 1se penalty strength
pred_train_1se <- as.numeric(predict(cv_lasso, s = "lambda.1se", newx = x_train_mat))
pred_test_1se  <- as.numeric(predict(cv_lasso, s = "lambda.1se", newx = x_test_mat))

# Compute metrics
rmse_tr_1se <- sqrt(mean((y_train - pred_train_1se)^2))
rmse_te_1se <- sqrt(mean((y_test - pred_test_1se)^2))
r2_tr_1se   <- 1 - (sum((y_train - pred_train_1se)^2) / sum((y_train - mean(y_train))^2))
r2_te_1se   <- 1 - (sum((y_test - pred_test_1se)^2) / sum((y_test - mean(y_test))^2))

# ==============================================================================
# 3. APPEND, TRANSPOSE, AND PRINT HORIZONTAL COMPARISON
# ==============================================================================
# Append the new column to the vertical baseline metrics object
master_comparison$Lambda_1se_Parsimonious <- c(
  se1_var_count,
  round(rmse_tr_1se, 4),
  round(rmse_te_1se, 4), # Fixed: Directly applies correct 1se value
  round(r2_tr_1se, 4),
  round(r2_te_1se, 4)
)

# Run transposition logic immediately within the execution sequence
transposed_comparison <- as.data.frame(t(master_comparison[, -1]))
colnames(transposed_comparison) <- master_comparison$Metric

transposed_comparison <- data.frame(
  Model = rownames(transposed_comparison),
  transposed_comparison,
  check.names = FALSE
)

cat("\n===========================================================================================\n")
cat("                         MASTER MODEL SUMMARY TABLE (TOTAL SPAI)                           \n")
cat("===========================================================================================\n")
print(transposed_comparison, row.names = FALSE)

# Save the updated transposed spreadsheet version to your drive files
write.csv(transposed_comparison, "total_spai_master_comparison_transposed.csv", row.names = FALSE)


#-----------------------------------------------------------------------------------------------------
#
######################################################################################################
######################################################################################################
######################################################################################################
#
#      Third Lasso Reduction
#
######################################################################################################
######################################################################################################
######################################################################################################
#
#-----------------------------------------------------------------------------------------------------


# ==============================================================================
# 0. ENVIRONMENT RESET: TRUNCATE TABLE TO THE INITIAL 4 MODELS BEFORE APPENDING
# ==============================================================================
# Clears out any lingering downstream models from your active R workspace session
master_comparison <- master_comparison[, 1:5]

# ==============================================================================
# 1. EXTRACT THE SURVIVING VARIABLES FROM THE 1SE MODEL
# ==============================================================================
# Dynamically reads the variable count from your 1se total SPAI model
vars_1se <- unique(top_predictors_1se$Original_Variable)
x_strict_df <- cells_data %>% select(all_of(vars_1se))
x_strict_mat <- model.matrix(~ . - 1, data = x_strict_df)

# Align with your original training and testing splits
x_train_strict <- x_strict_mat[train_index, ]
x_test_strict  <- x_strict_mat[-train_index, ]

# ==============================================================================
# 2. RUN A HIGH-PENALTY LASSO CORRECTION
# ==============================================================================
set.seed(123)
cv_strict <- cv.glmnet(
  x = x_train_strict, y = y_train, 
  alpha = 1, family = "gaussian", nfolds = 10
)

# Manually amplify the 1se lambda by 1.75x to force aggressive variable dropping
strict_lambda <- cv_strict$lambda.1se * 1.75

# ==============================================================================
# 3. EXTRACT AND CLEAN THE ULTRA-REDUCED PREDICTORS
# ==============================================================================
coef_strict  <- coef(cv_strict, s = strict_lambda)
matrix_strict <- as.matrix(coef_strict)

df_strict <- data.frame(
  Dummy_Variable = rownames(matrix_strict),
  Coefficient = matrix_strict[, 1],
  Absolute_Impact = abs(matrix_strict[, 1]),
  stringsAsFactors = FALSE
)

selected_strict <- df_strict %>%
  filter(Dummy_Variable != "(Intercept)", Coefficient != 0) %>%
  arrange(desc(Absolute_Impact))

strict_top_predictors <- selected_strict %>%
  rowwise() %>%
  mutate(Original_Variable = {
    matches <- names(x_strict_df)[sapply(names(x_strict_df), function(orig) grepl(paste0("^", orig), Dummy_Variable))]
    if(length(matches) > 0) matches[which.max(nchar(matches))] else Dummy_Variable
  }) %>%
  ungroup() %>%
  select(Original_Variable, Dummy_Variable, Coefficient)

strict_var_count <- length(unique(strict_top_predictors$Original_Variable))

# ==============================================================================
# 4. EVALUATE STRICT MODEL PERFORMANCE
# ==============================================================================
pred_train_st <- as.numeric(predict(cv_strict, s = strict_lambda, newx = x_train_strict))
pred_test_st  <- as.numeric(predict(cv_strict, s = strict_lambda, newx = x_test_strict))

rmse_tr_st <- sqrt(mean((y_train - pred_train_st)^2))
rmse_te_st <- sqrt(mean((y_test - pred_test_st)^2))
r2_tr_st   <- 1 - (sum((y_train - pred_train_st)^2) / sum((y_train - mean(y_train))^2))
r2_te_st   <- 1 - (sum((y_test - pred_test_st)^2) / sum((y_test - mean(y_test))^2))

# ==============================================================================
# 5. APPEND, TRANSPOSE, AND PRINT HORIZONTAL COMPARISON
# ==============================================================================
# Append the new column to the vertical baseline metrics object
master_comparison$Strict_Hyper_Parsimonious <- c(
  strict_var_count,
  round(rmse_tr_st, 4),
  round(rmse_te_st, 4),
  round(r2_tr_st, 4),
  round(r2_te_st, 4)
)

# Run transposition logic immediately within the execution sequence
transposed_comparison <- as.data.frame(t(master_comparison[, -1]))
colnames(transposed_comparison) <- master_comparison$Metric

transposed_comparison <- data.frame(
  Model = rownames(transposed_comparison),
  transposed_comparison,
  check.names = FALSE
)

cat("\n===========================================================================================\n")
cat("                         MASTER MODEL SUMMARY TABLE (TOTAL SPAI)                           \n")
cat("===========================================================================================\n")
print(transposed_comparison, row.names = FALSE)

# Save the updated transposed spreadsheet version to your working files
write.csv(transposed_comparison, "total_spai_master_comparison_transposed.csv", row.names = FALSE)
write.csv(strict_top_predictors, "total_spai_strict_predictors.csv", row.names = FALSE)


#################
#########################
##################################################
######################################################################
#
#
#   I am going to do a fourth reduction
#
#
######################################################################
#################################################
#########################
#################

# ==============================================================================
# 0. MEMORY RESET: TRUNCATE TABLE TO THE INITIAL 5 MODELS BEFORE APPENDING
# ==============================================================================
# Clears out any lingering downstream terminal models from your active R session
master_comparison <- master_comparison[, 1:6]

# ==============================================================================
# 1. EXTRACT THE 28 VARIABLES FROM THE PREVIOUS STRICT MODEL
# ==============================================================================
vars_strict_28 <- unique(strict_top_predictors$Original_Variable)
x_ultra_df     <- cells_data %>% select(all_of(vars_strict_28))
x_ultra_mat    <- model.matrix(~ . - 1, data = x_ultra_df)

x_train_ultra <- x_ultra_mat[train_index, ]
x_test_ultra  <- x_ultra_mat[-train_index, ]

# ==============================================================================
# 2. RUN AN ULTRA-HIGH PENALTY LASSO CORRECTION
# ==============================================================================
set.seed(123)
cv_ultra <- cv.glmnet(
  x = x_train_ultra, y = y_train, 
  alpha = 1, family = "gaussian", nfolds = 10
)

ultra_lambda <- cv_ultra$lambda.1se * 2.50

# ==============================================================================
# 3. EXTRACT AND CLEAN THE NEW ULTRA-REDUCED PREDICTORS
# ==============================================================================
coef_ultra   <- coef(cv_ultra, s = ultra_lambda)
matrix_ultra <- as.matrix(coef_ultra)

df_ultra <- data.frame(
  Dummy_Variable = rownames(matrix_ultra),
  Coefficient = matrix_ultra[, 1],
  Absolute_Impact = abs(matrix_ultra[, 1]),
  stringsAsFactors = FALSE
)

selected_ultra <- df_ultra %>%
  filter(Dummy_Variable != "(Intercept)", Coefficient != 0) %>%
  arrange(desc(Absolute_Impact))

ultra_top_predictors <- selected_ultra %>%
  rowwise() %>%
  mutate(Original_Variable = {
    matches <- names(x_ultra_df)[sapply(names(x_ultra_df), function(orig) grepl(paste0("^", orig), Dummy_Variable))]
    if(length(matches) > 0) matches[which.max(nchar(matches))] else Dummy_Variable
  }) %>%
  ungroup() %>%
  select(Original_Variable, Dummy_Variable, Coefficient)

ultra_var_count <- length(unique(ultra_top_predictors$Original_Variable))

# ==============================================================================
# 4. EVALUATE ULTRA-STRICT MODEL PERFORMANCE
# ==============================================================================
pred_train_ultra <- as.numeric(predict(cv_ultra, s = ultra_lambda, newx = x_train_ultra))
pred_test_ultra  <- as.numeric(predict(cv_ultra, s = ultra_lambda, newx = x_test_ultra))

rmse_tr_ult <- sqrt(mean((y_train - pred_train_ultra)^2))
rmse_te_ult <- sqrt(mean((y_test - pred_test_ultra)^2))
r2_tr_ult   <- 1 - (sum((y_train - pred_train_ultra)^2) / sum((y_train - mean(y_train))^2))
r2_te_ult   <- 1 - (sum((y_test - pred_test_ultra)^2) / sum((y_test - mean(y_test))^2))

# ==============================================================================
# 5. APPEND, TRANSPOSE, AND PRINT HORIZONTAL COMPARISON
# ==============================================================================
# Append the new column to the vertical baseline metrics object
master_comparison$Ultra_Strict_Reduction <- c(
  ultra_var_count,
  round(rmse_tr_ult, 4),
  round(rmse_te_ult, 4),
  round(r2_tr_ult, 4),
  round(r2_te_ult, 4)
)

# Run transposition logic immediately within the execution sequence
transposed_comparison <- as.data.frame(t(master_comparison[, -1]))
colnames(transposed_comparison) <- master_comparison$Metric

transposed_comparison <- data.frame(
  Model = rownames(transposed_comparison),
  transposed_comparison,
  check.names = FALSE
)

cat("\n===========================================================================================\n")
cat("                         MASTER MODEL SUMMARY TABLE (TOTAL SPAI)                           \n")
cat("===========================================================================================\n")
print(transposed_comparison, row.names = FALSE)

# Save the updated transposed spreadsheet version to your working files
write.csv(transposed_comparison, "total_spai_master_comparison_transposed.csv", row.names = FALSE)
write.csv(ultra_top_predictors, "total_spai_ultra_strict_predictors.csv", row.names = FALSE)


#################----------------------#######################------------------##############
##############################################################################################
#################----------------------#######################------------------##############
#
#       Fifth Lasso 
#
#################----------------------#######################------------------##############
##############################################################################################
#################----------------------#######################------------------##############


# ==============================================================================
# 0. MEMORY RESET: TRUNCATE TABLE TO THE INITIAL 6 MODELS BEFORE APPENDING
# ==============================================================================
# CORRECTED: Safely retains your 6 foundational columns plus Ultra_Strict (7 columns total)
master_comparison <- master_comparison[, 1:7]


# ==============================================================================
# 1. EXTRACT THE 22 VARIABLES FROM THE ULTRA-STRICT MODEL
# ==============================================================================
# Extract the unique names of variables that survived the ultra-strict pass
vars_ultra_22 <- unique(ultra_top_predictors$Original_Variable)
x_term_df     <- cells_data %>% select(all_of(vars_ultra_22))
x_term_mat    <- model.matrix(~ . - 1, data = x_term_df)

# Align with your original training and testing splits for consistency
x_train_term <- x_term_mat[train_index, ]
x_test_term  <- x_term_mat[-train_index, ]

# ==============================================================================
# 2. RUN A TERMINAL MAXIMUM-PENALTY LASSO CORRECTION
# ==============================================================================
set.seed(123)
cv_term <- cv.glmnet(
  x = x_train_term, y = y_train, 
  alpha = 1, family = "gaussian", nfolds = 10
)

# Amplify the penalty multiplier to 3.5x to aggressively drop to the absolute core
term_lambda <- cv_term$lambda.1se * 3.50

# ==============================================================================
# 3. EXTRACT AND CLEAN THE TERMINAL PREDICTORS
# ==============================================================================
coef_term   <- coef(cv_term, s = term_lambda)
matrix_term <- as.matrix(coef_term)

df_term <- data.frame(
  Dummy_Variable = rownames(matrix_term),
  Coefficient = matrix_term[, 1],
  Absolute_Impact = abs(matrix_term[, 1]),
  stringsAsFactors = FALSE
)

selected_term <- df_term %>%
  filter(Dummy_Variable != "(Intercept)", Coefficient != 0) %>%
  arrange(desc(Absolute_Impact))

term_top_predictors <- selected_term %>%
  rowwise() %>%
  mutate(Original_Variable = {
    matches <- names(x_term_df)[sapply(names(x_term_df), function(orig) grepl(paste0("^", orig), Dummy_Variable))]
    if(length(matches) > 0) matches[which.max(nchar(matches))] else Dummy_Variable
  }) %>%
  ungroup() %>%
  select(Original_Variable, Dummy_Variable, Coefficient)

term_var_count <- length(unique(term_top_predictors$Original_Variable))

# ==============================================================================
# 4. EVALUATE TERMINAL MODEL PERFORMANCE
# ==============================================================================
pred_train_term <- as.numeric(predict(cv_term, s = term_lambda, newx = x_train_term))
pred_test_term  <- as.numeric(predict(cv_term, s = term_lambda, newx = x_test_term))

rmse_tr_term <- sqrt(mean((y_train - pred_train_term)^2))
rmse_te_term <- sqrt(mean((y_test - pred_test_term)^2))
r2_tr_term   <- 1 - (sum((y_train - pred_train_term)^2) / sum((y_train - mean(y_train))^2))
r2_te_term   <- 1 - (sum((y_test - pred_test_term)^2) / sum((y_test - mean(y_test))^2))

# ==============================================================================
# 5. APPEND, TRANSPOSE, AND PRINT HORIZONTAL COMPARISON
# ==============================================================================
# Append the final column calculation to the base object
master_comparison$Terminal_Core_Reduction <- c(
  term_var_count,
  round(rmse_tr_term, 4),
  round(rmse_te_term, 4),
  round(r2_tr_term, 4),
  round(r2_te_term, 4)
)

# Run transposition logic immediately within the execution sequence
transposed_comparison <- as.data.frame(t(master_comparison[, -1]))
colnames(transposed_comparison) <- master_comparison$Metric

transposed_comparison <- data.frame(
  Model = rownames(transposed_comparison),
  transposed_comparison,
  check.names = FALSE
)

cat("\n===========================================================================================\n")
cat("                         MASTER MODEL SUMMARY TABLE (TOTAL SPAI)                           \n")
cat("===========================================================================================\n")
print(transposed_comparison, row.names = FALSE)

# Save the final clean wide format summary spreadsheet and the core predictors
write.csv(transposed_comparison, "total_spai_master_comparison_transposed.csv", row.names = FALSE)
write.csv(term_top_predictors, "total_spai_terminal_core_predictors.csv", row.names = FALSE)


################################################################################################
######################################################################################
##############################################################################
####################################################################
#
#      Working with 28 variables and plots
#
####################################################################
##############################################################################
######################################################################################
################################################################################################


# Load ggplot2 for a high-quality visualization
library(ggplot2)

# ==============================================================================
# 1. ISOLATE AND RANK THE WINNING 28 PREDICTORS
# ==============================================================================
# ADJUSTED: Pulls from strict_top_predictors to capture the 28-variable model
final_ranked_predictors <- strict_top_predictors %>%
  # Recalculate absolute impact to ensure proper ranking execution
  mutate(Absolute_Impact = abs(Coefficient)) %>%
  arrange(desc(Absolute_Impact)) %>%
  select(Original_Variable, Dummy_Variable, Coefficient, Absolute_Impact)

# Print the full ranked list to your console
cat("\n==================================================================\n")
cat("       FINAL RANKED PREDICTORS (STRICT HYPER-PARSIMONIOUS)        \n")
cat("==================================================================\n")
print(final_ranked_predictors, n = Inf, row.names = FALSE)

# ADJUSTED: Saved with a unique filename specific to this final 28-variable set
write.csv(final_ranked_predictors, "total_spai_final_28_predictors.csv", row.names = FALSE)

# ==============================================================================
# 2. GENERATE A COEFFICIENT IMPACT VISUALIZATION
# ==============================================================================
# Create a clear color flag for positive vs. negative coefficients
plot_df <- final_ranked_predictors %>%
  mutate(
    Direction = ifelse(Coefficient > 0, "Increases Addiction", "Decreases Addiction"),
    # Reorder the dummy variables so the chart ranks them from largest to smallest impact
    Dummy_Variable = reorder(Dummy_Variable, Absolute_Impact)
  )

# Build the publication-ready bar chart
coef_plot <- ggplot(plot_df, aes(x = Dummy_Variable, y = Coefficient, fill = Direction)) +
  geom_bar(stat = "identity", width = 0.75, color = "black", linewidth = 0.2) +
  coord_flip() + 
  scale_fill_manual(values = c("Increases Addiction" = "#d95f02", "Decreases Addiction" = "#7570b3")) +
  labs(
    # ADJUSTED: Labels updated to specify Total SPAI Score and 28 variables
    title = "Predictor Impact on Total SPAI Score",
    subtitle = "Final Strict Hyper-Parsimonious Lasso Model (28 Variables Remaining)",
    x = "Model Predictors (Dummy Variables)",
    y = "Lasso Coefficient Value (Impact Weight)",
    fill = "Effect Direction"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 13, margin = margin(b = 5)),
    plot.subtitle = element_text(color = "gray30", size = 10, margin = margin(b = 15)),
    axis.text.y = element_text(size = 9, family = "mono"), 
    axis.title = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank() 
  )

# Display the plot in your RStudio viewer
print(coef_plot)

# ADJUSTED: Saves a unique, high-resolution PNG image for this model
ggsave("total_spai_predictor_impact_chart.png", plot = coef_plot, width = 8.5, height = 7, dpi = 300)



########################################################################
#
########################################################################
#
#         Cross Validation Plot
#
########################################################################
#
########################################################################


# ==============================================================================
# GENERATE CROSS-VALIDATION DIAGNOSTIC PLOT (TOTAL SPAI MODEL)
# ==============================================================================

# Open a high-resolution PNG device to save the plot with a unique filename
png("total_spai_cross_validation_diagnostic.png", width = 7, height = 5, units = "in", res = 300)

# Set clean margins for the plot
par(mar = c(4.5, 4.5, 3, 1))

# Generate the standard glmnet cross-validation plot using your current cv_lasso object
plot(
  cv_lasso, 
  xlab = "Lasso Penalty Strength - Log(Lambda)", 
  ylab = "10-Fold Cross-Validation Error (MSE)"
)

# Add a clean, descriptive title updated for the Total SPAI framework
title("Total SPAI Model: Lambda Selection Via 10-Fold Cross-Validation", line = 2, font.main = 1, cex.main = 1.1)

# Close the file device and save the image
dev.off()

# Display the plot directly in your RStudio viewer as well
plot(cv_lasso)


##################
##################
##################
#
#      checking grade, age and gender
#
##################
##################
##################


# ==============================================================================
# DIAGNOSTIC: INSPECT DEMOGRAPHIC VARIABLE ENCODING
# ==============================================================================

# 1. Grab all columns in your processed data matrix that mention demographics
matrix_columns <- colnames(x_full_mat)
demographic_matches <- matrix_columns[grepl("age|grade|gender|sex", matrix_columns, ignore.case = TRUE)]

# 2. Print them clearly to your console
cat("\n============================================================\n")
cat("          MATRIX ENCODING DIAGNOSTIC RESULT                 \n")
cat("============================================================\n")
if(length(demographic_matches) > 0) {
  print(demographic_matches)
} else {
  cat("WARNING: No columns matching 'age', 'grade', 'gender', or 'sex' were found.\n")
  cat("Please check the exact spelling of these column names in your CSV.\n")
}
cat("============================================================\n")


################################################################################################
######################################################################################
##############################################################################
####################################################################
#
#      Working with 33 variables and plots
#
####################################################################
##############################################################################
######################################################################################
################################################################################################


# Load ggplot2 for a high-quality visualization
library(ggplot2)

# ==============================================================================
# 1. ISOLATE AND RANK THE WINNING 33 PREDICTORS
# ==============================================================================
# MODIFIED: Pulls from top_predictors_1se to capture the 33-variable model
final_ranked_predictors <- top_predictors_1se %>%
  filter(Dummy_Variable != "(Intercept)", Coefficient != 0) %>%
  # Recalculate absolute impact to ensure proper ranking execution
  mutate(Absolute_Impact = abs(Coefficient)) %>%
  arrange(desc(Absolute_Impact)) %>%
  select(Original_Variable, Dummy_Variable, Coefficient, Absolute_Impact)

# Print the full ranked list to your console
cat("\n==================================================================\n")
cat("          FINAL RANKED PREDICTORS (LAMBDA 1SE MODEL)               \n")
cat("==================================================================\n")
print(final_ranked_predictors, n = Inf, row.names = FALSE)

# MODIFIED: Saved with a unique filename specific to this final 33-variable set
write.csv(final_ranked_predictors, "total_spai_final_33_predictors.csv", row.names = FALSE)

# ==============================================================================
# 2. GENERATE A COEFFICIENT IMPACT VISUALIZATION
# ==============================================================================
# Create a clear color flag for positive vs. negative coefficients
plot_df <- final_ranked_predictors %>%
  mutate(
    Direction = ifelse(Coefficient > 0, "Increases Addiction", "Decreases Addiction"),
    # Reorder the dummy variables so the chart ranks them from largest to smallest impact
    Dummy_Variable = reorder(Dummy_Variable, Absolute_Impact)
  )

# Build the publication-ready bar chart
coef_plot <- ggplot(plot_df, aes(x = Dummy_Variable, y = Coefficient, fill = Direction)) +
  geom_bar(stat = "identity", width = 0.75, color = "black", linewidth = 0.2) +
  coord_flip() + 
  scale_fill_manual(values = c("Increases Addiction" = "#d95f02", "Decreases Addiction" = "#7570b3")) +
  labs(
    # MODIFIED: Labels updated to specify Total SPAI Score and 33 variables
    title = "Predictor Impact on Total SPAI Score",
    subtitle = "Final Parsimonious Lasso Model (33 Variables Remaining)",
    x = "Model Predictors (Dummy Variables)",
    y = "Lasso Coefficient Value (Impact Weight)",
    fill = "Effect Direction"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 13, margin = margin(b = 5)),
    plot.subtitle = element_text(color = "gray30", size = 10, margin = margin(b = 15)),
    axis.text.y = element_text(size = 9, family = "mono"), 
    axis.title = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank() 
  )

# Display the plot in your RStudio viewer
print(coef_plot)

# MODIFIED: Saves a unique, high-resolution PNG image for this 33-variable model
ggsave("total_spai_33_predictor_chart.png", plot = coef_plot, width = 8.5, height = 7, dpi = 300)


########################################################################
#
########################################################################
#
#         Cross Validation Plot for 33 Variable Model
#
########################################################################
#
########################################################################

# ==============================================================================
# GENERATE CROSS-VALIDATION DIAGNOSTIC PLOT (FINAL 33-VARIABLE MODEL)
# ==============================================================================

# MODIFIED: Saved with a clear, specific filename for your final chosen 33-variable model
png("total_spai_33var_cross_validation_diagnostic.png", width = 7, height = 5, units = "in", res = 300)

# Set clean margins for the plot
par(mar = c(4.5, 4.5, 3, 1))

# Generate the standard glmnet cross-validation plot using your current cv_lasso object
plot(
  cv_lasso, 
  xlab = "Lasso Penalty Strength - Log(Lambda)", 
  ylab = "10-Fold Cross-Validation Error (MSE)"
)

# MODIFIED: Title updated to explicitly highlight the final 33-variable threshold selection
title("Total SPAI Model: Lambda Selection (Final 33-Variable Model Chosen)", line = 2, font.main = 1, cex.main = 1.1)

# Close the file device and save the image
dev.off()

# Display the plot directly in your RStudio viewer as well
plot(cv_lasso)












