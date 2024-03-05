library(dplyr)
library(ggplot2)
library(reshape2)
library(summarytools)
library(tm)
library(SnowballC)
library(Matrix)
library(caret)
library(dummy)

library(glmnet)
library(rpart)

df <- read.csv("C:/Users/Vickiepedia/Desktop/combined_data.csv")
head(df, 3)

# 1. Text Cleaning and Preprocessing:
df$mda <- tolower(df$mda)

df$mda <- removePunctuation(df$mda)
df$mda <- removeNumbers(df$mda)
df$mda <- removeWords(df$mda, stopwords("en"))

df$mda <- wordStem(df$mda)

corpus <- Corpus(VectorSource(df$mda))
dtm <- DocumentTermMatrix(corpus)
dtm_df <- as.data.frame(as.matrix(dtm))

dtm_df$vol_lag <- df$vol_lag
dtm_df$date <- df$Date
dtm_df$stock <- df$stock
dtm_df$industry <- df$industry

# linear reg
# Convert date to numeric
dtm_df$date <- as.Date(paste0(dtm_df$date, "-01"), format = "%Y-%m-%d")
dtm_df$year <- format(dtm_df$date, "%Y")
dtm_df$month <- format(dtm_df$date, "%m")
dtm_df$yearNumeric = as.numeric(dtm_df$year)
dtm_df$monthNumeric = as.numeric(dtm_df$month)

# Convert factorVar to a factor
dtm_df$factorStock = as.factor(dtm_df$stock)
dtm_df$factorIndustry = as.factor(dtm_df$industry)

df1 <- dtm_df[, -which(names(dtm_df) %in% c("stock", "industry", 'date', 'year', 'month'))]



# PCA ??????????????




# Splitting data into training, validation and test sets
set.seed(42)
train_data <- subset(df1, yearNumeric >= 2013 & yearNumeric <= 2020)
test_data <- subset(df1, yearNumeric >= 2021 & yearNumeric <= 2022)

################################################################################
# Gradient Boosting
################################################################################

library(gbm)

set.seed(42)
gbm_model <- gbm(vol_lag ~ ., data=train_data, distribution = "gaussian", n.trees = 100)
gbm_pred <- predict(gbm_model, newdata = test_data, n.trees = 100)
gbm_mse <- mean((test_data$vol_lag - gbm_pred)^2)
gbm_mae <- mean(abs(test_data$vol_lag - gbm_pred))

################################################################################
# Support Vector Regression
################################################################################

library(e1071)

set.seed(42)

# Identify and remove near-zero variance predictors
nzv <- nearZeroVar(train_data)
train_data_reduced <- train_data[, -nzv]

# Scale and center numeric features
preproc <- preProcess(train_data_reduced, method = c("center", "scale"))
train_data_processed <- predict(preproc, train_data_reduced)

svr_model <- svm(vol_lag ~ ., data=train_data_processed)

# Removing near-zero variance predictors from test data
test_data_reduced <- test_data[, -nzv]

# Applying the same scaling and centering to the test data
test_data_processed <- predict(preproc, test_data_reduced)

# Predicting with the SVM model
svr_pred <- predict(svr_model, newdata = test_data_processed)

svr_mse <- mean((test_data_processed$vol_lag - svr_pred)^2)
svr_mae <- mean(abs(test_data_processed$vol_lag - svr_pred))

################################################################################
# Decision Tree Regression
################################################################################

tree_model <- rpart(vol_lag ~ ., data=train_data)
tree_pred <- predict(tree_model, newdata = test_data)
tree_mse <- mean((test_data$vol_lag - tree_pred)^2)
tree_mae <- mean(abs(test_data$vol_lag - tree_pred))


# Comparing Models
mse_df <- data.frame(
  Model = c("Decision Tree", "Gradient Boosting", "Support Vector Regression"),
  MSE = c(tree_mse, gbm_mse, svr_mse),
  MAE = c(tree_mae, gbm_mae, svr_mae)
)
