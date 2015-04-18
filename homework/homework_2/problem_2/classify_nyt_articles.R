library(tm)
library(Matrix)
library(glmnet)
library(ROCR)
library(ggplot2)


set.seed(4)
# read business and world articles into one data frame
data_combined <- rbind(business,world)
# create a Corpus from the article snippets
snippet_corpus <- VCorpus(VectorSource(data_combined$snippet))
# create a DocumentTermMatrix from the snippet Corpus
clean_corpus <- tm_map(snippet_corpus,content_transformer(tolower))
clean_corpus <- tm_map(clean_corpus, removePunctuation)
clean_corpus <- tm_map(clean_corpus, removeNumbers)
dtm <- DocumentTermMatrix(clean_corpus)
# convert the DocumentTermMatrix to a sparseMatrix, required by cv.glmnet
sparse_dtm <- dtm_to_sparse(dtm)
# helper function
dtm_to_sparse <- function(dtm) {
 sparseMatrix(i=dtm$i, j=dtm$j, x=dtm$v, dims=c(dtm$nrow, dtm$ncol), dimnames=dtm$dimnames)
}

# create a train / test split
train.idx = sample(c(1:2000),0.8*2000,replace=FALSE)
# 1 represent business 0 represent world
y = c(rep(1,1000),rep(0,1000))

train_x <- sparse_dtm[train.idx,]
train_y <- y[train.idx]
test_x <- sparse_dtm[-train.idx,]
test_y <- y[-train.idx]
# cross-validate logistic regression with cv.glmnet, measuring auc
model = cv.glmnet(train_x,train_y,type.measure='auc',family='binomial')
plot(model)

# evaluate performance for the best-fit model
lambda <- model$lambda.min
lambda

test_pred <- predict(model,newx=test_x,s='lambda.min',type='class')
table(test_pred,test_y)

# plot ROC curve and output accuracy and AUC
probs <- predict(model, newx = test_x, s = 'lambda.min', type = 'response')
pred <- prediction(probs, test_y)
perf <- performance(pred, measure='tpr', x.measure='fpr')
plot(perf)
abline(a=0,b=1)
auc.perf=performance(pred, 'auc')
auc.perf@y.values

acc.perf = performance(pred, measure = "acc")
plot(acc.perf)
ind = which.max( slot(acc.perf, "y.values")[[1]] )
acc = slot(acc.perf,"y.values")[[1]][ind]
cutoff = slot(acc.perf, "x.values")[[1]][ind]
print(c(accuracy= acc, cutoff = cutoff))



# extract coefficients for words with non-zero weight
# helper function
get_informative_words <- function(crossval) {
  coefs <- coef(crossval, s="lambda.min")
  coefs <- as.data.frame(as.matrix(coefs))
  names(coefs) <- "weight"
  coefs$word <- row.names(coefs)
  row.names(coefs) <- NULL
  subset(coefs, weight != 0)
}

top_words_all <- get_informative_words(model)
#clean the work field
# show weights on words with top 10 weights for business
business_corpus <- VCorpus(VectorSource(business$snippet))
clean_corpus <- tm_map(business_corpus,content_transformer(tolower))
clean_corpus <- tm_map(clean_corpus, removePunctuation)
clean_corpus <- tm_map(clean_corpus, removeNumbers)
business_dtm <- DocumentTermMatrix(clean_corpus)
business_words <- colnames(business_dtm)
business_subset <- top_words_all[top_words_all$word %in% business_words,]
head(business_subset[order(-business_subset$weight),],n=10)
rm(list=c("business_corpus","clean_corpus","business_dtm","business_words","business_subset"))

# show weights on words with top 10 weights for world
world_corpus <- VCorpus(VectorSource(world$snippet))
clean_corpus <- tm_map(world_corpus,content_transformer(tolower))
clean_corpus <- tm_map(clean_corpus, removePunctuation)
clean_corpus <- tm_map(clean_corpus, removeNumbers)
world_dtm <- DocumentTermMatrix(clean_corpus)
world_words <- colnames(world_dtm)
world_subset <- top_words_all[top_words_all$word %in% world_words,]
head(world_subset[order(-world_subset$weight),],n=10)
#clean the work filed
rm(list=c("world_corpus","clean_corpus","world_dtm","world_words","world_subset"))
