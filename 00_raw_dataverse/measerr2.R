rm(list=ls())

library(cem)
library(Matching)

set.seed(123)

data(LL)
tr <- which(LL$treated==1)
ct <- which(LL$treated==0)
ntr <- length(tr)
nct <- length(ct)
n <- nct+ntr

n.sims <- 1000

com <- matrix(NA, n.sims, 5)
times <- matrix(NA, n.sims, 4)
colnames(com) <- c("CEM(T)", "CEM(C)", "PSC(C)", "MAH(C)", "GEN(C)")
colnames(times) <- c("CEM", "PSC", "MAH", "GEN")

for(sim in 1:n.sims){

LL2 <- LL
LL2$re75 <- LL$re75 + rnorm(n, mean=1000, sd=1000)
LL2$re75[which(LL2$re75<0)] <- 0
#summary(LL$re75)
#summary(LL2$re75)

#plot(density(LL$re75))
#lines(density(LL2$re75),col="red")


system.time(cem.mat <- cem(treatment="treated",data=LL, drop="re78"))[3] -> t1.cem
cem.mat$tab

cem.tr <- which(cem.mat$groups=="1" & cem.mat$matched==TRUE)
cem.ct <- which(cem.mat$groups=="0" & cem.mat$matched==TRUE)

nt.cem <- length(unique(cem.tr))
nc.cem <- length(unique(cem.ct))


system.time(cem2.mat <- cem(treatment="treated",data=LL2, drop="re78"))[3] -> t2.cem
t.cem <- t1.cem+t2.cem

cem2.tr <- which(cem2.mat$groups=="1" & cem2.mat$matched==TRUE)
cem2.ct <- which(cem2.mat$groups=="0" & cem2.mat$matched==TRUE)
nt.cem2 <- length(unique(cem2.tr))
nc.cem2 <- length(unique(cem2.ct))

comC.cem <- length(intersect(unique(cem.ct), unique(cem2.ct)))
comT.cem <- length(intersect(unique(cem.tr), unique(cem2.tr)))


COMC.CEM <- comC.cem/min(nc.cem,nc.cem2)
COMT.CEM <- comT.cem/min(nt.cem,nt.cem2)




# PSCORE MATCHING
system.time(pscore  <- glm(treated~ . -re78, family=binomial, data=LL))[3] -> t1.psc
system.time(psc.mat <- Match(Tr=LL$treated, X=pscore$fitted))[3] -> t2.psc
psc.tr <- psc.mat$index.treated
psc.ct <- psc.mat$index.control
nt.psc <- length(unique(psc.tr))
nc.psc <- length(unique(psc.ct))

system.time(pscore2  <- glm(treated~ . -re78, family=binomial, data=LL2))[3] -> t3.psc
system.time(psc2.mat <- Match(Tr=LL2$treated, X=pscore2$fitted))[3] -> t4.psc
t.psc <- t1.psc+t2.psc+t3.psc+t4.psc
psc2.tr <- psc2.mat$index.treated
psc2.ct <- psc2.mat$index.control
nt.psc2 <- length(unique(psc2.tr))
nc.psc2 <- length(unique(psc2.ct))

comC.psc <- length(intersect(unique(psc2.ct), unique(psc.ct)))
COMC.PSC <- comC.psc/min(nc.psc,nc.psc2)

 

# MAHALANOBIS MATCHING

system.time(mah.mat <- Match(Tr=LL$treated, X=LL[,-c(1,9)], Weight=2))[3]-> t1.mah
mah.tr <- mah.mat$index.treated
mah.ct <- mah.mat$index.control
nt.mah <- length(unique(mah.tr))
nc.mah <- length(unique(mah.ct))

system.time(mah2.mat <- Match(Tr=LL2$treated, X=LL2[,-c(1,9)], Weight=2))[3]-> t2.mah
t.mah <- t1.mah+t2.mah
mah2.tr <- mah2.mat$index.treated
mah2.ct <- mah2.mat$index.control
nt.mah2 <- length(unique(mah2.tr))
nc.mah2 <- length(unique(mah2.ct))

comC.mah <- length(intersect(unique(mah2.ct), unique(mah.ct)))
COMC.MAH <- comC.mah/min(nc.mah,nc.mah2)



# GENETIC MATCHING
system.time(gen1 <- GenMatch(X=LL[,-c(1,9)], Tr=LL$treated))[3] -> t1.gen
system.time(gen.mat <- Match(Tr=LL$treated, X=LL[,-c(1,9)], Weight.matrix=gen1))[3] -> t2.gen
gen.tr <- gen.mat$index.treated
gen.ct <- gen.mat$index.control
nt.gen <- length(unique(gen.tr))
nc.gen <- length(unique(gen.ct))

system.time(gen2 <- GenMatch(X=LL[,-c(1,9)], Tr=LL$treated))[3] -> t3.gen
system.time(gen2.mat <- Match(Tr=LL2$treated, X=LL2[,-c(1,9)], Weight.matrix=gen2))[3]->t4.gen
t.gen <- t1.gen+t2.gen+t3.gen+t4.gen
gen2.tr <- gen2.mat$index.treated
gen2.ct <- gen2.mat$index.control
nt.gen2 <- length(unique(gen2.tr))
nc.gen2 <- length(unique(gen2.ct))

comC.gen <- length(intersect(unique(gen2.ct), unique(gen.ct)))
COMC.GEN <- comC.gen/min(nc.gen,nc.gen2)

com[sim,] <- c(COMT.CEM, COMC.CEM, COMC.PSC, COMC.MAH, COMC.GEN)
times[sim,] <- c(t.cem, t.psc, t.mah, t.gen)
cat(sprintf("sim=%.5d\n",sim))
print(colMeans(com,na.rm=TRUE))
}



colMeans(com)
colMeans(times)


save.image("measerr2.rda")



