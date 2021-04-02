# linear model fit
cv.err= rep(NA, 10)
for (i in 1:10) {
  fit = glm(y ~ poly(x, i), data = Data)
  cv.err[i] = cv.glm(Data, fit, K=10)$delta[1]
}
plot(1:10, cv.err, xlab="Degree", ylab="Test MSE")
deg.min = which.min(cv.err)
points(deg.min, cv.err[deg.min], col = 'red')

# splines
library(splines)
deltas=rep(NA,10)
for (i in 3:10) {
  fit = glm(y ~ ns(x, df = i), data = Data)
  deltas[i] = cv.glm(Data, fit, K = 10)$delta[1]
}
plot(3:10, deltas[-c(1, 2)], xlab = "degree", ylab = "Test MSE")
d.min = which.min(deltas)
points(d.min, deltas[d.min], col = "red")

# gam
library(gam)
deltas=rep(NA,10)
for (i in 1:10) {
  fit = gam(y ~ s(x1, i)+s(x2, i), data = Data)
  deltas[i] = cv.glm(Data, fit, K = 10)$delta[1]
}
plot(3:10, deltas[-c(1, 2)], xlab = "degree", ylab = "Test MSE")
d.min = which.min(deltas)
points(d.min, deltas[d.min], col = "red")

# ridge
library(glmnet)
r.fit=cv.glmnet(train.x, train.y, alpha=0)
r.lambda = r.fit$lambda.min
r.pred=predict(r.fit, s=r.lambda, newx = test.x)
mean((r.pred-test.y)^2)

# lasso
l.fit=cv.glmnet(train.x, train.y, alpha=1)
l.lambda = l.fit$lambda.min
l.pred=predict(l.fit, s=l.lambda, newx = test.x)
mean((l.pred-test.y)^2)
predict(l.fit, type="coefficients", s=l.lambda)

# lda
lda_model = lda(y~x, family=binomial, data=train_set)
lda_pred = predict(lda_model, test_set, type = "response")
confusion_matrix = table(lda_pred$class, test_set$y)
print(confusion_matrix)
mean(lda_pred$class == test_set$y)

# qda
qda_model = qda(y~x, family=binomial, data=train_set)
qda_pred = predict(qda_model, test_set, type="response")
confusion_matrix = table(qda_pred$class, test_set$y)
print(confusion_matrix)
mean(qda_pred$class == test_set$y)

# knn
set.seed(1)
knn_pred=knn(train, test, y[train_year],k=50)
table(knn_pred,y[!train_year])
mean(knn_pred == y[!train_year])