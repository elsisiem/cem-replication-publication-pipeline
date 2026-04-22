# run as
# R CMD BATCH --vanilla --slave cemsim.R

require(cem)
require(MatchIt)
require(Matching)

data(DW)

tsubjects <- which(DW$treated==1) # change dataset here
csubjects <- which(DW$treated==0) #
dati <- DW[,-c(1,9)]              #
outcome <- DW$re78                #


MCSim <- 5000


nt <- length(tsubjects)
nc <- length(csubjects)
n <- nt+nc
treated <- logical(n)
treated[tsubjects] <- TRUE


dati.num <- dati
for(i in 1:dim(dati)[2])
 dati.num[,i] <- as.numeric(dati[,i])


propensity  <- glm(treated~ I(age^2) + I(education^2) + black +
                   hispanic + married + nodegree + I(re74^2) + I(re75^2) +
                   u74 + u75, family=binomial, data=dati)

M <- cbind(rep(1, n),
           propensity$linear.pred,
           I(log(dati$age)^2),
           I(log(dati$education)^2),
           I(log(dati$re74+0.01)^2),
           I(log(dati$re75+0.01)^2))

propensity.coeffs <- propensity$coeff

#let's create some arbritrary weights
propensity.coeffs <- as.matrix(c(
                                 1+00,  #(Intercept)        
                                 .5,    #linear.pred
                                 .01, #age
                                 -.3,  #educ
                                 -0.01, #I(re74^2)          
                                 0.01   #I(re75^2)          
                                 ))

mu = M %*% propensity.coeffs
Tr.pred <- exp(mu)/(1+exp(mu))
print(summary(Tr.pred))

TreatmentEffect <- 1000
TreatmentReal <- matrix(nrow=n, ncol=1)




resume <- NULL

set.seed(2810192) # same seed used in GenMatch Exp 2

tmp <- matrix(NA, MCSim, 6)
times <- matrix(NA, MCSim, 4)
sizes <- matrix(NA, MCSim, 10)
ELLE1 <- matrix(NA, MCSim, 5)
colnames(times) <- c("MAH", "PSC", "GEN", "CEM")
colnames(sizes) <- c("RAW(nt)", "RAW(nc)", "MAH(nt)", "MAH(nc)", "PSC(nt)", "PSC(nc)", "GEN(nt)", "GEN(nc)", "CEM(nt)", "CEM(nc)")
colnames(tmp) <- c("RAW", "MAH", "PSC", "GEN", "CEM", "CEM.W")
colnames(ELLE1) <- c("RAW", "MAH", "PSC", "GEN", "CEM")

mybr = list(re74=hist(dati$re74,plot=FALSE)$breaks, 
			re75 = hist(dati$re75,plot=FALSE)$breaks,
			age = hist(dati$age,plot=FALSE)$breaks,
			education = hist(dati$education,plot=FALSE)$breaks)


for(MC in 1:MCSim){

	for(i in 1:n)
		TreatmentReal[i] = sample(0:1, 1, prob=c(1-Tr.pred[i],Tr.pred[i]))

    outcome <- I(TreatmentEffect*TreatmentReal) + .1*exp(.7*log(dati$re74+0.01) + .7*log(dati$re75+0.01)) + rnorm(n, 0, 10)
    treated <- TreatmentReal
	tsubjects <- which(TreatmentReal==1)
	csubjects <- which(TreatmentReal==0)
	nt <- length(tsubjects)
	nc <- length(csubjects)
    dati1 <- data.frame(treat=treated, dati)	

    L1.raw <- L1.meas(treated, dati, breaks=mybr)$L1

    system.time(cem.mat <- cem("treat", dati1))[3] -> t.cem

    cem.tr <- which(cem.mat$groups=="1" & cem.mat$matched==TRUE)
	cem.ct <- which(cem.mat$groups=="0" & cem.mat$matched==TRUE)

    cem.idx <- unique(c(cem.tr, cem.ct))
    L1.cem <- L1.meas(treated[cem.idx], dati[cem.idx,], breaks=mybr)$L1

#	system.time(mah.mat <- matchit(treat~ age+education+re74+re75+black+hispanic+nodegree+married+u74+u75, distance="mahalanobis", data=dati1))[3] ->t.mah
#	idx1 <- as.numeric(mah.mat$match.matrix)
#	idx2 <- as.numeric(rownames(mah.mat$match.matrix))
#	mah.idx <- match( c(idx1,idx2), rownames(DW))
#	mah.tr <- mah.idx[which(dati1$treat[mah.idx]==1)]
#	mah.ct <- mah.idx[which(dati1$treat[mah.idx]==0)]
	 
	system.time(mah.mat <- Match(Tr=treated, X=dati,Weight=2,M=1,replace=FALSE))[3] -> t.mah
	mah.tr <- mah.mat$index.treated
	mah.ct <- mah.mat$index.control
	 
    mah.idx <- unique(c(mah.tr, mah.ct))
    L1.mah <- L1.meas(treated[mah.idx], dati[mah.idx,], breaks=mybr)$L1

	 
#	system.time(psc.mat <- matchit(treat~ age+education+re74+re75+black+hispanic+nodegree+married+u74+u75, model="logit", data=dati1))[3] -> t.psc 
#	idx1 <- as.numeric(psc.mat$match.matrix)
#	idx2 <- as.numeric(rownames(psc.mat$match.matrix))
#	psc.idx <- match( c(idx1,idx2), rownames(DW))
#	psc.tr <- psc.idx[which(dati1$treat[psc.idx]==1)]
#	psc.ct <- psc.idx[which(dati1$treat[psc.idx]==0)]

	system.time(pscore  <- glm(treated~ age+education+re74+re75+black+hispanic+nodegree+married+u74+u75, family=binomial, data=dati1))[3] -> t.psc1
	system.time(psc.mat <- Match(Tr=treated, X=pscore$fitted,M=1,replace=FALSE))[3] -> t.psc2
	t.psc <- t.psc1+t.psc2
	psc.tr <- psc.mat$index.treated
	psc.ct <- psc.mat$index.control

    psc.idx <- unique(c(psc.tr, psc.ct))
    L1.psc <- L1.meas(treated[psc.idx], dati[psc.idx,], breaks=mybr)$L1

    system.time(gen1 <- GenMatch(X=dati, Tr=treated))[3] -> t.gen
    mgen1 <- Match(Y=outcome, Tr=treated, X=dati, Weight.matrix=gen1)

    gen.tr <- unique(gen1$matches[,1])
    gen.ct <- unique(gen1$matches[,2])

    gen.idx <- unique(c(gen.tr, gen.ct))
    L1.gen <- L1.meas(treated[gen.idx], dati[gen.idx,], breaks=mybr)$L1
	
    nt.cem <- length(unique(cem.tr))
	nc.cem <- length(unique(cem.ct))
    nt.mah <- length(unique(mah.tr))
    nc.mah <- length(unique(mah.ct))
    nt.psc <- length(unique(psc.tr))
    nc.psc <- length(unique(psc.ct))
    nt.gen <- length(unique(gen1$matches[,1]))
    nc.gen <- length(unique(gen1$matches[,2]))


	RAW <- mean(outcome[tsubjects]) - mean(outcome[csubjects])  
	CEM <- mean(outcome[cem.tr]) - mean(outcome[cem.ct])  
	CEM.W <- weighted.mean(outcome[cem.tr], cem.mat$w[cem.tr]) - weighted.mean(outcome[cem.ct], cem.mat$w[cem.ct])  
	MAH <- mean(outcome[mah.tr]) - mean(outcome[mah.ct])  
    PSC <- mean(outcome[psc.tr]) - mean(outcome[psc.ct])  
	GEN <-     mgen1$est

    cat(sprintf("sim=%.5d, RAW=%.3f, MAH=%.3f, PSC=%3.f, GEN=%.3f, CEM=%.3f, CEM.W=%.3f\n", MC, RAW, MAH, PSC, GEN,  CEM, CEM.W))
    cat(sprintf("times: MAH=%.3f, PSC=%.3f, GEN=%.3f, CEM=%.3f\n", t.mah, t.psc, t.gen, t.cem))
    cat(sprintf("L1: RAW=%.3f, MAH=%.3f, PSC=%.3f, GEN=%.3f, CEM=%.3f\n", L1.raw, L1.mah, L1.psc, L1.gen, L1.cem))

	tmp[MC,] <-  c(RAW, MAH, PSC, GEN,  CEM, CEM.W)
	ELLE1[MC,] <- c(L1.raw, L1.mah, L1.psc, L1.gen, L1.cem)
	
	times[MC,] <-  c(t.mah, t.psc, t.gen, t.cem)
	sizes[MC,] <-  c(nt, nc, nt.mah, nc.mah, nt.psc, nc.psc, nt.gen, nc.gen, nt.cem, nc.cem)
}

cat("\n\nAverage bias:\n")
colMeans(tmp,na.rm=TRUE)-1000
buf <- colMeans(tmp,na.rm=TRUE)-1000

cat("Average std.dev:\n")
apply(tmp,2, function(x) sd(x, na.rm=TRUE))
buf <- rbind(buf, apply(tmp,2, function(x) sd(x, na.rm=TRUE)) )

cat("RMSE:\n")
sqrt(colMeans((tmp-1000)^2,na.rm=TRUE))
buf <- rbind(buf, sqrt(colMeans((tmp-1000)^2,na.rm=TRUE)))

cat("Average time:\n")
colMeans(times,na.rm=TRUE)


cat("Average L1:\n")
colMeans(ELLE1,na.rm=TRUE)

rownames(buf) <- c("BIAS", "SD", "RMSE")
buf <- t(buf)

cat("Average Matched units:\n")
tt <- colMeans(sizes,na.rm=TRUE)

tab <- cbind(buf[-5,], matrix(as.integer(tt), 5,2, byrow=TRUE) )
colnames(tab)[4:5] <- c("treated", "controls")
rownames(tab)[5] <- "CEM"

tab

matplot(tmp,type="l",ylab="ATT Estimates",col=1:7,lty=1:7)
legend(MCSim/2, y=5200, legend=colnames(tmp),col=1:7,lty=1:7)
abline(h=1000,lty=3)
save.image(file="cemsim-penta.rda")




