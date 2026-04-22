###################################################
### chunk number 1: 
###################################################
library(xtable)
load("measerr2.rda")
tm <- colMeans(times)
cm <- sprintf("%.1f",colMeans(com)*100)
tab <- rbind(cm, sprintf("%.2f",c(tm[1],tm)))
colnames(tab) <- colnames(com)
colnames(tab) <- c("CEM($K_T$)", "CEM($K_C$)", "PSC($K_C$)", "MAH($K_C$)","GEN($K_C$)")  
rownames(tab) <- c("\\% Common Units", "Seconds")
ctimes <- sprintf("%.2f",colMeans(times))


###################################################
### chunk number 2: measerrT1
###################################################
print(xtable(tab), floating=FALSE,  sanitize.text.function = function(x) {x})


