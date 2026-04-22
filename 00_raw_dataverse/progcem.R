###################################################
### chunk number 1: 
###################################################
require(cem)
data(LL)
mybr = list(re74=hist(LL$re74,plot=FALSE)$breaks, 
   re75 = hist(LL$re75,plot=FALSE)$breaks,
   age = hist(LL$age,plot=FALSE)$breaks,
   education = hist(LL$education,plot=FALSE)$breaks)
mat <- cem(treatment="treated",data=LL, drop="re78")
tm2 <- system.time(tab2 <- relax.cem(mat, LL, L1.breaks=mybr, depth=1, minimal=list(re74=6, age=3, education=3, re75=5),  plot=FALSE))
tm2 <- sprintf("%.1f",tm2)
iter2 <- dim(tab2$G1)[1]


###################################################
### chunk number 2: 
###################################################
pdf("coarsen1.pdf", width=9, height=6, pointsize=10,colormodel="gray")
relax.plot(tab2,unique=TRUE)
invisible(dev.off())
cat("\\includegraphics[width=1.1\\textwidth,
   viewport=0 60 700 400,clip]{coarsen1}\n\n") 


