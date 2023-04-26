# R script for the study "An experimental approach to assessing the impact of ecosystem engineers on biodiversity and ecosystem functions" published in Ecology by Gianalberto Losapio and colleagues

# For info and requests, please contact gianalbertolosapio@gmail.com

#%#
# load R packages
library(car)
library(effects)
library(emmeans)
library(igraph)
library(lme4)
library(picante)
library(vegan)
library(sdcMicro)

# import data
diversity_3200 <- read.csv("diversity_3200.csv", head=T)
divdf <- read.csv("divdf.csv", head=T)
insect.record <- read.csv("insect.record.csv", head=T)
sndata <- read.csv("sndata.csv", head=T)
phyltree<-read.tree("phyltree.phy")

### stats for plant--plant facilitation
divdf$microh = relevel(as.factor(divdf$microh), ref = 'Open')

mod.facind <- glm(nind  ~ microh, data= divdf, family="poisson")
Anova(mod.facind)
summary(mod.facind)

emmeans(mod.facind, pairwise ~ microh)

plot(allEffects(mod.facind))

mod.facsp <- glm(nsp  ~ nind, data= divdf, family="poisson")
divdf$resmod <- mod.facsp$residuals
mod.facsp <- lm(resmod ~ microh, data=divdf)
Anova(mod.facsp)
summary(mod.facsp)

emmeans(mod.facsp, pairwise ~ microh)

plot(allEffects(mod.facsp))

###############################################
### pollinator on associated species with and without

mod.facpol2 <- lmer(y.ap2 ~ microh*fs +  (1|block), data=subset(sndata, sndata$microh!="a"), na.action=na.exclude)
Anova(mod.facpol2, test="Chisq")
summary(mod.facpol2)
plot(Effect(c("microh","fs"), mod.facpol2))

### turnover of insects across plants

insects.are <- subset(insect.record, insect.record$pl.code!="horspi" & insect.record$pl.code!="aretet" & insect.record$Fs=="h")
insects.hor<- subset(insect.record, insect.record$pl.code!="horspi" & insect.record$pl.code!="aretet" & insect.record$Fs =="s")

insects.are$microh <- as.character(insects.are$Tr)
insects.hor$microh <- as.character(insects.hor$Tr)

insects.are.o = graph.data.frame(insects.are[which(insects.are$Tr=="o"),c("in.code","Plot")], directed=FALSE)
insects.are.o = get.adjacency(insects.are.o, sparse=FALSE)
insects.are.o = insects.are.o[1:20,21:33]
ncol(insects.are.o)
nrow(insects.are.o)

insects.are.o <- cbind(insects.are.o,rep(0,nrow(insects.are.o)))
colnames(insects.are.o)[14] <- "6"

insects.are.w = graph.data.frame(insects.are[which(insects.are$Tr=="w"),c("in.code","Plot")], directed=FALSE)
insects.are.w = get.adjacency(insects.are.w, sparse=FALSE)
insects.are.w = insects.are.w[1:32,33:46]
ncol(insects.are.w)
nrow(insects.are.w)

insects.hor.o = graph.data.frame(insects.hor[which(insects.hor$Tr=="o"),c("in.code","Plot")], directed=FALSE)
insects.hor.o = get.adjacency(insects.hor.o, sparse=FALSE)
insects.hor.o = insects.hor.o[1:27,28:39]
ncol(insects.hor.o)
nrow(insects.hor.o)

insects.hor.o <- cbind(insects.hor.o,rep(0,nrow(insects.hor.o)))
insects.hor.o <- cbind(insects.hor.o,rep(0,nrow(insects.hor.o)))

colnames(insects.hor.o)[13:14] <- c("2","3")

insects.hor.w = graph.data.frame(insects.hor[which(insects.hor$Tr=="w"),c("in.code","Plot")], directed=FALSE)
insects.hor.w = get.adjacency(insects.hor.w, sparse=FALSE)
insects.hor.w = insects.hor.w[1:16,17:27]
ncol(insects.hor.w)
nrow(insects.hor.w)

insects.hor.w <- cbind(insects.hor.w,rep(0,nrow(insects.hor.w)))
insects.hor.w <- cbind(insects.hor.w,rep(0,nrow(insects.hor.w)))
insects.hor.w <- cbind(insects.hor.w,rep(0,nrow(insects.hor.w)))

colnames(insects.hor.w)[12:14] <- c("9","10","12")

insects.are.df <- data.frame(plot=0, species=NA, abundance=0)
attacca = 1:3

for(i in 1:nrow(insects.are.o)){
	for(j in 1:ncol(insects.are.o)){
		if(insects.are.o[i,j]>0){
			attacca[1] <- colnames(insects.are.o)[j]
			attacca[2] <- rownames(insects.are.o)[i]
			attacca[3] <- insects.are.o[i,j]
			insects.are.df <- rbind(insects.are.df,attacca)
		}
	}
}

insects.are.df$microh = 1
insects.are.df<-insects.are.df[-1,]

attacca = 1:4
attacca[4] = 2

for(i in 1:nrow(insects.are.w)){
	for(j in 1:ncol(insects.are.w)){
		if(insects.are.w[i,j]>0){
			attacca[1] <- colnames(insects.are.w)[j]
			attacca[2] <- rownames(insects.are.w)[i]
			attacca[3] <- insects.are.w[i,j]
			insects.are.df <- rbind(insects.are.df,attacca)
		}
	}
}

attacca[1] = 6
attacca[2] = NA
attacca[3] = 0
attacca[4] = 1
insects.are.df <- rbind(insects.are.df,attacca)

str(insects.are.df)

insects.are.df$plot <- as.numeric(insects.are.df$plot)
insects.are.df$abundance <- as.numeric(insects.are.df$abundance)
insects.are.df$microh <- as.numeric(insects.are.df$microh)
insects.are.df$species <- as.factor(insects.are.df$species)

turn.df <- data.frame(microh = gl(2,14,56),
					  fs=gl(2,28,56),
					  plot=c(rep(1:14,4)),
					  gain = 0,
					  lost = 0)	  

for(i in 1:14){
# are
	spo = names(which(insects.are.o[,which(colnames(insects.are.o)==i)]>0))
	spw = names(which(insects.are.w[,which(colnames(insects.are.w)==i)]>0))
	sptot = unique(c(spo,spw))
	nsp = length(sptot)
# o
	spgain = length(spo)-length(which(spo%in%spw))
	splost = nsp-length(which(spo%in%sptot))
	turn.df$gain[i] = spgain/nsp
	turn.df$lost[i] = splost/nsp
# w
	spgain = length(spw)-length(which(spw%in%spo))
	splost = nsp-length(which(spw%in%sptot))
	turn.df$gain[i+14] = spgain/nsp
	turn.df$lost[i+14] = splost/nsp
# hor
	spo = names(which(insects.hor.o[,which(colnames(insects.hor.o)==i)]>0))
	spw = names(which(insects.hor.w[,which(colnames(insects.hor.w)==i)]>0))
	sptot = unique(c(spo,spw))
	nsp = length(sptot)
# o
	spgain = length(spo)-length(which(spo%in%spw))
	splost = nsp-length(which(spo%in%sptot))
	turn.df$gain[i+28] = spgain/nsp
	turn.df$lost[i+28] = splost/nsp
# w
	spgain = length(spw)-length(which(spw%in%spo))
	splost = nsp-length(which(spw%in%sptot))
	turn.df$gain[i+42] = spgain/nsp
	turn.df$lost[i+42] = splost/nsp
}

mod.turn <- lm(cbind(gain,lost) ~ microh*fs, data=turn.df)
Anova(mod.turn)
summary(mod.turn)

mod.gain <- lm(gain ~ microh*fs, data=turn.df)
Anova(mod.gain)
summary(mod.gain)
emmeans(mod.gain, pairwise ~ fs * microh)

plot(allEffects(mod.gain))

mod.loss <- lm(lost ~ microh*fs, data=turn.df)
Anova(mod.loss)
summary(mod.loss)
emmeans(mod.loss, pairwise ~ fs * microh)
plot(allEffects(mod.loss))

plot(allEffects(mod.turn))

turn.df2 <- rbind(turn.df, turn.df)
turn.df2$turn <- gl(2,112/2, 112)
turn.df2$value <- c(turn.df$gain,turn.df$lost)

mod.turn2 <- lm(value ~ microh * fs * turn, data=turn.df2)
Anova(mod.turn2, type=3)
summary(mod.turn2)
plot(allEffects(mod.turn2))

emmeans(mod.turn2, pairwise ~ turn * fs * microh)

#####
mod.pol = glmer.nb(pollinator ~ scale(fl) + microh*fs +  (1|block), data=sndata, na.action=na.exclude)
Anova(mod.pol)
summary(mod.pol)
plot(Effect(c('microh', 'fs'), mod.pol))

#####
mod.her = glmer.nb(herbivore ~ scale(fl) + microh*fs +  (1|block), data=sndata, na.action=na.exclude)
Anova(mod.her)
summary(mod.her)
plot(Effect(c('microh', 'fs'), mod.her))

#####
mod.par = glmer.nb(parasitoid ~ scale(fl) + microh*fs +  (1|block), data=sndata, na.action=na.exclude)
Anova(mod.par)
summary(mod.par)
plot(Effect(c('microh', 'fs'), mod.par))

##### func and phylo insect div
# data operations
ntaxa<- length(phyltree$tip.label)

g_phyl = graph.data.frame(insect.record[,c("Phylogenetic.taxon","site.label")], directed=FALSE)
phylcom <- get.adjacency(g_phyl, sparse=FALSE)
phylcom <- phylcom[(ntaxa+1):ncol(phylcom),1:ntaxa]
head(phylcom)

phyldist<-cophenetic(phyltree)

# phylo distance
sesmpd<-ses.mpd(phylcom, phyldist, null.model="independentswap", abundance.weighted=TRUE, runs=99)

sndata$mpdz<-NA

for(i in 1:nrow(sndata)){
	if(sndata$site.label[i]%in%rownames(sesmpd))
	sndata$mpdz[i]<-sesmpd$mpd.obs.z[which(rownames(sesmpd)==sndata$site.label[i])]
}

##### stat model

mod.mpd<-lmer(mpdz ~plsp + fl+ microh*fs +  (1|block), data=sndata, na.action=na.exclude)

Anova(mod.mpd, test="Chisq")

summary(mod.mpd)

emmeans(mod.mpd, pairwise ~ fs*microh)
emmeans(mod.mpd, pairwise ~ microh)

mod.mpd.s <- emmeans(mod.mpd, c("fs", "microh"))
pairs(mod.mpd.s)

eff_size(mod.mpd.s, sigma = sigma(mod.mpd), edf=60)

##
mod.fdiv<-lmer(wdiv.func ~ plsp + fl + microh*fs +  (1|block), data=sndata)

Anova(mod.fdiv, test="Chisq")

summary(mod.fdiv)
emmeans(mod.fdiv, pairwise ~ fs*microh)

mod.fdiv.s <- emmeans(mod.fdiv, c("fs", "microh"))

eff_size(mod.fdiv.s, sigma = sigma(mod.fdiv), edf=76)
 
###### biodiversitty effect: selection and complementarity

y.aretet<-ifelse(sndata$aretet>0, sndata$aretet, 0)
y.aretet[which(is.na(y.aretet))]<-0
y.horspi<-sndata$horspi
y.horspi[which(is.na(y.horspi))]<-0
sndata$y.fs<-y.aretet+y.horspi

biodiveff <- data.frame(block=1:28, fs=gl(2,14,28), poll.ce=0, poll.se=0, herb.ce=0, herb.se=0, scav.ce=0, cav.se=0, pred.ce=0, pred.se=0, paras.ce=0, paras.se=0, fdiv.ce=0, fdiv.se=0, fric.ce=0, fric.se=0, insab.ce=0, insab.se=0)

m.fs<-rep(0,28)
m.ap<-rep(0,28)
y.fs<-rep(0,28)
y.ap<-rep(0,28)

m.fs2<-rep(0,28)
m.ap2<-rep(0,28)
y.fs2<-rep(0,28)
y.ap2<-rep(0,28)

for(i in 1:28){
	m.fs[i]<-sndata$ins.ab[sndata$microh=="a"&sndata$block==i]
	m.ap[i]<-sndata$ins.ab[sndata$microh=="o"&sndata$block==i]
	y.fs[i]<-sndata$y.fs[sndata$microh=="w"&sndata$block==i]
	y.ap[i]<-sndata$ins.ab[sndata$microh=="w"&sndata$block==i]-sndata$y.fs[sndata$microh=="w"&sndata$block==i]

sndata$y.ap=sndata$ins.ab-sndata$y.fs
# complementarity effect
	biodiveff$insab.ce[i]<-2*mean(c(y.fs[i]/m.fs[i]-1,y.ap[i]/m.ap[i]-1))*mean(m.fs[i],m.ap[i])
	
# selection effect
	biodiveff$insab.se[i]<-2*cov(c(y.fs[i]/m.fs[i]-1,y.ap[i]/m.ap[i]-1),c(m.fs[i],m.ap[i]))

	if(y.fs[i]/m.fs[i]=="Inf"|y.ap[i]/m.ap[i]=="Inf"){ biodiveff$insab.ce[i]<-60; biodiveff$insab.se[i]<-12}
	if(y.fs[i]/m.fs[i]=="NaN"|y.ap[i]/m.ap[i]=="NaN"){ biodiveff$insab.ce[i]<-0; biodiveff$insab.se[i]<-0}
	
}

biodiveff$insab.bioef<-biodiveff$insab.ce +biodiveff$insab.se

mod.ce <- lm(insab.ce~ fs , data= biodiveff)
mod.se <- lm(insab.se~ fs , data= biodiveff)

summary(mod.ce)
Anova(mod.ce, test="Chisq")

summary(mod.se)
Anova(mod.se, test="Chisq")

##
# with infl standardize by number of flowers

for(i in 1:11){sndata[,120+i][which(is.na(sndata[,120+i]))]<-0}
sndata$fl.fs<-c(sndata$aretet.fl[1:42],sndata$horspi.fl[43:84])
sndata$fl.ap<-sndata$fl-sndata$fl.fs

sndata$ins.ab2<-sndata$ins.ab/sndata$fl

sndata$y.fs2<-sndata$y.fs/sndata$fl.fs
sndata$y.ap2<-sndata$y.ap/sndata$fl.ap

sndata$y.fs2[which(is.na(sndata$y.fs2))]<-0
sndata$y.ap2[which(is.na(sndata$y.ap2))]<-0

for(i in 1:28){
	m.fs2[i]<-sndata$ins.ab2[sndata$microh=="a"&sndata$block==i]
	m.ap2[i]<-sndata$ins.ab2[sndata$microh=="o"&sndata$block==i]
	y.fs2[i]<-sndata$y.fs2[sndata$microh=="w"&sndata$block==i]
	y.ap2[i]<-sndata$y.ap2[sndata$microh=="w"&sndata$block==i]

# complementarity effect
	biodiveff$insab.ce2[i]<-2*mean(c(y.fs2[i]/m.fs2[i]-1,y.ap2[i]/m.ap2[i]-1))*mean(m.fs2[i],m.ap2[i])
	
# selection effect
	biodiveff$insab.se2[i]<-2*cov(c(y.fs2[i]/m.fs2[i]-1,y.ap2[i]/m.ap2[i]-1),c(m.fs2[i],m.ap2[i]))

}

biodiveff2<-biodiveff[-c(4,6,16,17),]

biodiveff$insab.ce2[c(4,6,16,17)]<-2*max(biodiveff2$insab.ce2)
biodiveff$insab.se2[c(4,6,16,17)]<-2*max(biodiveff2$insab.se2)

mod.ce2 <- lm(insab.ce2~ fs, data= biodiveff)
mod.se2 <- lm(insab.se2~ fs, data= biodiveff)

summary(mod.ce2)
Anova(mod.ce2, type=3)

summary(mod.se2)
Anova(mod.se2, type=3)

########## %%%%%%%%%% ################
## plots

ci1 <- summary(emmeans(mod.fdiv, pairwise ~ microh))$emmeans

par(mfrow=c(2,1), mar=c(2,3,0,0))
plot(0,0,type="n",xlim=c(1,3), ylim=c(min(ci1$emmean - ci1$SE),max(ci1$emmean + ci1$SE)), xaxt="n",xlab="",ylab="",yaxt="n")
axis(2,at=c(.1,.2,.3,.4,.5,.6,.7), las=1)

segments(1, ci1$emmean[2]-ci1$SE[2], 1, ci1$emmean[2]+ci1$SE[2])
segments(2, ci1$emmean[3]-ci1$SE[3], 2, ci1$emmean[3]+ci1$SE[3])
segments(3, ci1$emmean[1]-ci1$SE[1], 3, ci1$emmean[1]+ci1$SE[1])

segments(1, ci1$emmean[2], 3, ci1$emmean[1], lty=2)
segments(2, ci1$emmean[3], 3, ci1$emmean[1], lty=2)

points(1, ci1$emmean[2], cex=1.5, pch=15, col="black", bg="white")
points(2, ci1$emmean[3], cex=1.5, pch=19, col="black", bg="white")
points(3, ci1$emmean[1], cex=1.5, pch=17, col="black", bg="white")

##
ci1 <- summary(emmeans(mod.mpd, pairwise ~ microh))$emmeans

plot(0,0,type="n",xlim=c(1,3), ylim=c(min(ci1$emmean - ci1$SE),max(ci1$emmean + ci1$SE)), xaxt="n",xlab="",ylab="",yaxt="n")
axis(2,at=c(-0.75, -0.50, -0.25, 0, 0.25, 0.5, 0.75, 1), las=1)

segments(1, ci1$emmean[2]-ci1$SE[2], 1, ci1$emmean[2]+ci1$SE[2])
segments(2, ci1$emmean[3]-ci1$SE[3], 2, ci1$emmean[3]+ci1$SE[3])
segments(3, ci1$emmean[1]-ci1$SE[1], 3, ci1$emmean[1]+ci1$SE[1])

segments(1, ci1$emmean[2], 3, ci1$emmean[1], lty=2)
segments(2, ci1$emmean[3], 3, ci1$emmean[1], lty=2)

points(1, ci1$emmean[2], cex=1.5, pch=15, col="black", bg="white")
points(2, ci1$emmean[3], cex=1.5, pch=19, col="black", bg="white")
points(3, ci1$emmean[1], cex=1.5, pch=17, col="black", bg="white")

######

ci1.ce<-coef(summary(mod.ce2))[1,1:2]
ci1.se<-coef(summary(mod.se2))[1,1:2]

plot(0,0,type="n",xlim=c(1,3), ylim=c(min(min(ci1.ce[1] - ci1.ce[2]),min(ci1.se[1] - ci1.se[2]),min(ci1.be[1] - ci1.be[2])),max(max(ci1.ce[1] + ci1.ce[2]),min(ci1.se[1] + ci1.se[2]),min(ci1.be[1] + ci1.be[2]))), xaxt="n",xlab="",ylab="",yaxt="n")

axis(2,at=c(-0.05,0,0.05,0.10,0.15,0.2), las=1)

abline(h=0, lty=2)

segments(1, ci1.ce[1]-ci1.ce[2], 1, ci1.ce[1]+ci1.ce[2], col="red")
segments(2, ci1.se[1]-ci1.se[2], 2, ci1.se[1]+ci1.se[2], col="blue")
segments(3, ci1.be[1]-ci1.be[2], 3, ci1.be[1]+ci1.be[2], col="green")

points(1, ci1.ce[1], col="red", cex=1.5, pch=19)
points(2, ci1.se[1], col="blue", cex=1.5, pch=19)
points(3, ci1.be[1], col="green", cex=1.5, pch=19)

dev.off()

## insect functional groups separately

sndata$res.modfdiv <- residuals(mod.fdiv)
sndata$res.modmpd <- residuals(mod.mpd)

mod.resfdiv<-lm(res.modfdiv ~ herbivore + parasitoid + pollinator + predator + scavenger, data=sndata)
Anova(mod.resfdiv)
summary(mod.resfdiv)

plot(allEffects(mod.resfdiv))

mod.resmpd<-lm(res.modmpd ~ herbivore + parasitoid + pollinator + predator + scavenger, data=sndata)
Anova(mod.resmpd)
summary(mod.resmpd)

plot(allEffects(mod.resmpd))

#%#
save.image('losapio_ecology20.RData')
