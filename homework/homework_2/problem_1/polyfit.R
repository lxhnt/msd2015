library(ggplot2)
set.seed(4)
# read data
data <- read.table('polyfit.tsv', header=T)

# split into train / test data
split <- function(x){
  n = dim(x)[1]
  train_index = as.numeric(sample(rownames(x),n/2,replace=FALSE))
  train = x[train_index,]
  test = x[-train_index,]
  split = list("train"=train,"test"=test)
  return(split)  
}

prepared_data <- split(data)


# fit a model and compute train / test error for each degree
fit <- function(data,degree){
  models <- lapply(1:degree, function(n)
    lm(y ~ poly(x, n), data = data$train)
  )
  train.rmse <-lapply(1:degree, function(n)
    sqrt(mean((data$train$y - fitted(models[[n]])) ^ 2))
  )
  test.rmse<-lapply(1:degree, function(n)
    sqrt(mean((data$test$y - predict(models[[n]], newdata = data.frame(x = data$test$x))) ^ 2))
  )
  fit_list = list("train"=unlist(train.rmse),"test"=unlist(test.rmse))
  return(fit_list)
}

result <- fit(prepared_data,20)

# select best model
select_best <- function(result){
  degree = which.min(result$test)
  return(degree)
}

best_degree <- select_best(result)


# plot fit for RMSE and degree best model
max.degree=length(result$train)
x = c(1:max.degree)
optimal = which.min(result$test)
plot_data =data.frame(train=result$train,test=result$test,x=x)
ggplot(plot_data,aes(x))+
  geom_line(aes(y=train,colour="train"))+
  geom_line(aes(y=test,colour="test"))+
  geom_vline(aes(xintercept=optimal))+
  xlab("Polynomial Degree")+
  ylab("Error")+
  ggtitle("Error vs Polynomial Degree")


#Scatter plot with optimal degree overlayed
ggplot(data,aes(x,y))+
  geom_point()+
  stat_smooth(method="lm",se=TRUE,fill=NA,formula=y~poly(x,degree=6,raw=TRUE))+
  ggtitle("Scatter plot with optimal degree polynomial fit")


# report coefficients for best model
best_model <- lm(y~poly(x,6),data=data)
summary(best_model)$coefficients
