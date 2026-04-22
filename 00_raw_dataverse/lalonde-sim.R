###################################################
### chunk number 1: 
###################################################
require(cem)
require(xtable)


###################################################
### chunk number 2: 
###################################################
load(file="cemsim-penta.rda")

buf <- colMeans(tmp,na.rm=TRUE)-1000
buf <- rbind(buf, apply(tmp,2, function(x) sd(x, na.rm=TRUE)) )
buf <- rbind(buf, sqrt(colMeans((tmp-1000)^2,na.rm=TRUE)))
rownames(buf) <- c("BIAS", "SD", "RMSE")
buf <- t(buf)
tt <- colMeans(sizes,na.rm=TRUE)
tab <- cbind(buf[-5,], matrix(as.integer(tt), 5,2, byrow=TRUE) )
colnames(tab)[4:5] <- c("treated", "controls")
rownames(tab)[5] <- "CEM"
tab <- cbind(tab, c(0,colMeans(times)),colMeans(ELLE1))
colnames(tab) <- c(colnames(tab)[-(4:7)], "Treated", "Controls", "Seconds","$\\mathcal L_1$")
print(xtable(tab, display=c("s","f","f","f","d","d","f","f")), floating=FALSE, sanitize.text.function = function(x) {x})


