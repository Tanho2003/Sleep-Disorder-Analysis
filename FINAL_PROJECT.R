# ==============================================================================
# STAT 385 - Final Project
# Date: December 8, 2025
# Title: Classification of Sleep Disorders Based on Lifestyle Metrics
# ==============================================================================

# 1. SETUP & LIBRARIES
# ------------------------------------------------------------------------------
# Install packages if missing: install.packages(c("tidyverse", "caret", "rpart", "rpart.plot", "randomForest", "nnet", "corrplot"))
library(tidyverse)    # For data manipulation and plotting
library(caret)        # For machine learning workflow (splitting, confusion matrix)
library(rpart)        # For Decision Tree model
library(rpart.plot)   # For plotting the Decision Tree
library(randomForest) # For Random Forest model
library(nnet)         # For Multinomial Logistic Regression
library(corrplot)     # For correlation heatmap

# ------------------------------------------------------------------------------
# 2. DATA LOADING AND PREPROCESSING
# ------------------------------------------------------------------------------
# Load dataset
setwd("C:/Users/TAN/Documents/STAT_385")
sleep_data <- read.csv("Sleep_health_and_lifestyle_dataset.csv")

# A. CLEANING BLOOD PRESSURE
# The 'Blood Pressure' column is a string (e.g., "126/83"). 
# We split it into two numeric columns: Systolic_BP and Diastolic_BP.
sleep_data <- sleep_data %>%
  separate(Blood.Pressure, into = c("Systolic_BP", "Diastolic_BP"), sep = "/", convert = TRUE)

# B. STANDARDIZING CATEGORIES
# 'BMI Category' has inconsistent labels ("Normal" vs "Normal Weight").
# We merge them into a single "Normal" category based on WHO standards.
sleep_data$BMI.Category[sleep_data$BMI.Category == "Normal Weight"] <- "Normal"

# C. CONVERTING TO FACTORS
# Convert categorical strings to factors for modeling.
cols_to_factor <- c("Gender", "Occupation", "BMI.Category", "Sleep.Disorder")
sleep_data[cols_to_factor] <- lapply(sleep_data[cols_to_factor], as.factor)

# Check structure to confirm cleaning
str(sleep_data)

# ------------------------------------------------------------------------------
# 3. EXPLORATORY DATA ANALYSIS (EDA)
# ------------------------------------------------------------------------------
# A. CORRELATION MATRIX & MULTICOLLINEARITY CHECK
# Select only numeric columns for correlation analysis
numeric_vars <- sleep_data %>% select_if(is.numeric) %>% select(-Person.ID)
cor_matrix <- cor(numeric_vars)

# Plot Heatmap
corrplot(cor_matrix, method = "color", type = "upper", 
         title = "Correlation Heatmap of Health Metrics", 
         mar=c(0,0,1,0), addCoef.col = "black", number.cex = 0.6)

# Explicitly check Multicollinearity between BP variables
# High correlation confirms why we might prioritize one over the other
bp_corr <- cor(sleep_data$Systolic_BP, sleep_data$Diastolic_BP)
print(paste("Correlation between Systolic and Diastolic BP:", bp_corr))

# B. DISTRIBUTION ANALYSIS (BMI vs Sleep Disorder)
ggplot(sleep_data, aes(x = BMI.Category, fill = Sleep.Disorder)) +
  geom_bar(position = "dodge") +
  theme_minimal() +
  labs(title = "Distribution of Sleep Disorders by BMI Category",
       x = "BMI Category", y = "Count") +
  scale_fill_brewer(palette = "Set1")

# ------------------------------------------------------------------------------
# 4. DATA SPLITTING
# ------------------------------------------------------------------------------
# We use the SAME train/test set for all models to ensure fair comparison.
set.seed(123) # CRITICAL for reproducibility
trainIndex <- createDataPartition(sleep_data$Sleep.Disorder, p = .7, 
                                  list = FALSE, 
                                  times = 1)
data_train <- sleep_data[ trainIndex,]
data_test  <- sleep_data[-trainIndex,]

# ------------------------------------------------------------------------------
# 5. MODELING
# ------------------------------------------------------------------------------

# --- METHOD 1: Multinomial Logistic Regression ---
# We use 'multinom' because outcome has 3 levels: None, Insomnia, Apnea.
model_log <- multinom(Sleep.Disorder ~ Age + BMI.Category + Stress.Level + Sleep.Duration, 
                      data = data_train)

print("--- Logistic Regression Coefficients (Parameter Estimations) ---")
summary(model_log) 

# Predict on Test Set
pred_log <- predict(model_log, data_test)
conf_log <- confusionMatrix(pred_log, data_test$Sleep.Disorder)
print("Logistic Regression Results:")
print(conf_log)

# --- METHOD 2: Decision Tree ---
# Tuning Parameter: cp (complexity parameter) set to 0.01
model_tree <- rpart(Sleep.Disorder ~ ., data = data_train, method = "class", cp = 0.01)

# Visualize the Tree
rpart.plot(model_tree, main="Decision Tree for Sleep Disorders")

# Predict
pred_tree <- predict(model_tree, data_test, type = "class")
conf_tree <- confusionMatrix(pred_tree, data_test$Sleep.Disorder)
print("Decision Tree Results:")
print(conf_tree)

# --- METHOD 3: Random Forest ---
# Tuning: ntree=100 (sufficient for convergence), mtry=3 (approx sqrt of predictors)
set.seed(123)
model_rf <- randomForest(Sleep.Disorder ~ ., data = data_train, ntree = 100, mtry = 3)

# Variable Importance Plot (Requested in Feedback)
varImpPlot(model_rf, main = "Random Forest: Variable Importance")

# Predict
pred_rf <- predict(model_rf, data_test)
conf_rf <- confusionMatrix(pred_rf, data_test$Sleep.Disorder)
print("Random Forest Results:")
print(conf_rf)

# ------------------------------------------------------------------------------
# 6. COMPARISON SUMMARY
# ------------------------------------------------------------------------------
results <- data.frame(
  Method = c("Logistic Regression", "Decision Tree", "Random Forest"),
  Accuracy = c(conf_log$overall['Accuracy'], 
               conf_tree$overall['Accuracy'], 
               conf_rf$overall['Accuracy'])
)
print(results)