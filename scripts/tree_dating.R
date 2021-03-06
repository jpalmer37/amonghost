#DATING TREES USING ASSOCIATED TIP DATES


#----FUNCTIONS----
n.days <- function(year, month) {
  # @param year: string (number) or integer for full year, e.g., '1997'
  # @param month: string (number) or integer for month
  
  start <- as.Date(paste(year, month, '01', sep='-'))
  if (month == '12') {
    # increment to start of next year
    end <- as.Date(paste(as.integer(year)+1, '01', '01', sep='-'))
  } else {
    end <- as.Date(paste(year, as.integer(month)+1, '01', sep='-'))
  }
  return(as.integer(difftime(end, start)))
}
mid.date <- function(lo, hi){
  mid <- as.integer(as.Date(lo,origin = "1970-01-01")) + as.integer(as.Date(hi,origin = "1970-01-01")-as.Date(lo,origin = "1970-01-01"))/2
  return (mid)
}

date.to.decimal <- function(dt) {
  return (as.double(dt) / 365.25 + 1970)
}


root.to.tip <- function(tre, vect, x){
  rtdtree <- tryCatch(
    {rtdtree <- rtt(tre, vect, ncpu=x)} ,
    error = function(c){
      message("Faulty rtt error, still running")
      return (NULL)
    }
  )
  return (rtdtree)
}

get.range <- function(x) {
  x = as.character(x)
  items <- strsplit(x, '-')[[1]]
  year <- items[1]
  if (length(items) == 1) {
    ## year only
    low <- as.Date(paste(year, '01', '01', sep='-'))
    high <- as.Date(paste(year, '12', '31', sep='-'))
  } 
  else if (length(items) == 2) {
    ## year and month
    month <- items[2]
    
    # determine number of days in this month
    days <- n.days(year, month)
    low <- as.Date(paste(year, month, '01', sep='-'))
    high <- as.Date(paste(year, month, days, sep='-'))
  } 
  else {
    # year, month, day
    days <- items[3]
    month <- items[2]
    low <- as.Date(paste(year, month, days, sep='-'))
    high <- low
  }
  return (c(low, high))
}

require(ape)
dfolder <- list.files(path="~/PycharmProjects/hiv-evolution-master/Dates/edit",full.names=TRUE)
tfolder <- list.files(path="~/PycharmProjects/hiv-evolution-master/6Trees", full.names=TRUE)
afolder <- list.files(path="~/PycharmProjects/hiv-evolution-master/5_1_final", full.names=TRUE)


branch.lengths <- data.frame()
genetic.dists <- data.frame()
big.df <- data.frame(stringsAsFactors = F)
setwd("~/PycharmProjects/hiv-evolution-master/8_Dated_Trees")
for (n in 1:length(tfolder)){
  tre <- read.tree(tfolder[n])
  csv <- read.csv(dfolder[n], header=FALSE,stringsAsFactors = F)
  names(csv) <- c('accno', 'date')
  
  filename <- strsplit(strsplit(tfolder[n], "/")[[1]][7], "_CR")[[1]][1]
  print(filename)
  
  # ROOTING THE TREES WITH RTT ----------------------------------
  tre <- multi2di(tre) 
  
  #rearranges the temp file to be in the same order as the tree
  index <- match(tre$tip.label, csv$accno)
  csv <- csv[index,]
  
  #loading a temporary data frame of mid dates
  
  temp <- NULL
  for (x in 1:nrow(csv)){
    dtx <- get.range(csv$date[x])
    temp <- rbind(temp, data.frame(accno=csv$accno[x],
                                   acc.date=csv$date[x], min.date=dtx[1], max.date=dtx[2],
                                   min.ord=date.to.decimal(dtx[1]), max.ord=date.to.decimal(dtx[2])))
   
  }
  sample.times <- date.to.decimal(mid.date(temp$min.date, temp$max.date))
  sample.times <- sample.times - 1970
  
  
  #ROOTING THE TREE
  rtdtree <- root.to.tip(tre, sample.times, 5)
  if (is.null(rtdtree)){
    print(filename)
    print("TREE PROBLEM")
  }
  
  #ROOTED (UNDATED) TREE ANALYSIS 
  # --------------------------------------------
  ntips <- Ntip(tre)
  
  # count the number of instances that first column (node) corresponds to a second column number which is <= n (meaning it is a tip)
  numtips <- tabulate(tre$edge[,1][which(tre$edge[,2] <= ntips)])
  
  #determines which nodes contain cherries (returns vector with their integer positions)
  is.cherry <- which(numtips == 2)
  
  # construct data frame where each row corresponds to a cherry
  m <- sapply(is.cherry, function(a) { #will input the numbers of nodes containing 2 tips?
    edge.idx <- tre$edge[,1]==a  # FINDS THE EDGES (row #) corresponding with the parent node ; ap: select rows in edge matrix with parent node index
    
    c(a,   # index of the parent node
      which(edge.idx),
      t(     # transpose so we can concatenate this vector to i
        tre$edge[edge.idx, 2]    # column of tip indices
      )
    )
  })
  df <- data.frame(node.index=m[1,], edge1=m[2,], edge2=m[3,], tip1=m[4,], tip2=m[5,])
  
  df$tip1.label <- tre$tip.label[df$tip1]
  df$tip2.label <- tre$tip.label[df$tip2]
  df$tip1.len <- tre$edge.length[df$edge1]
  df$tip2.len <- tre$edge.length[df$edge2]
  
  indels <- df[,c(6:9)]
  indels$total.length <- indels$tip1.len + indels$tip2.len
  
  #TERMINAL BRANCH LENGTHS PLOT 
  branch.lengths <- rbind(branch.lengths, data.frame(subtype=rep(filename,nrow(indels)), length=indels$total.length))
  
  #CHERRY GENETIC DISTANCES PLOT
  genetic.dists <- rbind(genetic.dists, data.frame(subtype=rep(filename,nrow(indels)), indels))
  
  #ROOT TO TIP DISTANCE PLOT
  sample.times <- sample.times + 1970
  lens <- node.depth.edgelength(rtdtree)[1:Ntip(rtdtree)]
  
  
  # STUFF USED FOR TEMPEST
  #rtdtree2 <- rtdtree
  #rtdtree2$tip.label <- paste(rtdtree2$tip.label, sample.times, sep="-")
  #setwd("~/PycharmProjects/hiv-evolution-master/7_Tempest")
  #write.tree(rtdtree2, file=paste0(filename,".tree"))
  
  big.df <- rbind(big.df,data.frame(subtype=rep(filename,Ntip(rtdtree)), dates=sample.times, lengths=lens))
  
  # DATING TREES USING LSD 
  # -----------------------------------
  write.tree(rtdtree, file="rtt2lsd.nwk")

  #The following is written in accordance with the LSD format

  write(nrow(temp), file='date_file.txt')

  for (i in 1:nrow(temp)) {
    if (temp$min.ord[i] == temp$max.ord[i]) {
       write(paste(temp$accno[i], temp$min.ord[i]), file='date_file.txt', append=TRUE)
     } else {
       write(paste(temp$accno[i], paste0("b(", temp$min.ord[i], ",", temp$max.ord[i], ")")),
             file='date_file.txt', append=TRUE)
     }
   }

  paths <- nodepath(rtdtree)
  distances <- c()
  for (p in 1:length(paths))  distances <- c(distances, sum(rtdtree$edge.length[paths[[p]]]))
  
  aLen <- length(read.FASTA(afolder[n])[1][[1]])
  
  #system(paste0('lsd -i rtt2lsd.nwk -d date_file.txt -o ', filename ,' -c -f 1000 -s ',aLen))
  
}
#setwd("~/PycharmProjects/hiv-evolution-master/8_Dated_Trees")
file.remove('date_file.txt')
file.remove('rtt2lsd.nwk')

#genetic.dists <- cbind(genetic.dists, filtered.indels3[,7:21])
# BRANCH LENGTHS PLOT --------------------------------
#par(mar=c(6,7,2,2))
#branch.len2 <- split(branch.lengths$length, branch.lengths$subtype)
#boxplot(branch.len2, xlab="Subtype",cex.lab=1.3,las=1)
#par(las=3)
#mtext(side = 2, text = "Terminal Branch Lengths (Expected Substitutions)", line = 4, cex=1.3)

write.csv(genetic.dists, "~/vindels/Pipeline_2_Within/genetic-dists.csv")

# GENETIC DISTANCES PLOTS --------------

# qcquire the order of means 
new.df <- split(genetic.dists, genetic.dists$subtype)
means <- sapply(new.df, function (x) mean(x$GD) )
means <- means[order(means)]
ordered <- names(means)


gd.order <- genetic.dists
# this applies the properly ordered factor to the subtype column 
gd.order$subtype <- factor(gd.order$subtype, levels=ordered)
# this sorts the entire data frame by the properly ordered 'levels' in the subtype column
gd.order <- gd.order[order(gd.order$subtype),]


# A) Standard plot 
par(mar=c(5,5,1,1))
plot(gd.order$subtype, gd.order$GD, xlab="Group M Clade", ylab="Genetic Distance (Cherries)", cex.axis=1.2, cex.lab=1.5)

# perform a wilcoxon test on this 


# B) Only GDs under 0.05 
gd.05 <- genetic.dists[which(genetic.dists$GD <= 0.05),]
par(mar=c(5,5,1,1))
plot(gd.05$subtype, gd.05$GD, xlab="Group M Clade", ylab="Genetic Distance (Cherries)", cex.axis=1.2, cex.lab=1.5)


# C) Staggered density plot of the seven subtypes  
require(ggplot2)
require(ggridges)
gd.15 <- genetic.dists[which(genetic.dists$GD <= 0.15),]
ggplot(gd.15, aes(x=GD, y=subtype, group=subtype)) + 
  geom_density_ridges(colour="white", fill="blue3", scale=1, bandwidth=0.002) + 
  labs(x="Genetic Distance", y="Subtype") + 
  theme(axis.title.x=element_text(size=15,margin=margin(t = 15, r = 0, b = 0, l = 0)),
        axis.title.y=element_text(size=15,margin=margin(t = 15, r = 0, b = 0, l = 0)),
        #strip.text.x = element_text(size=16),
        axis.text=element_text(size=13))


big.df <- big.df[which(big.df$dates>1960),]
new.df <- split(big.df[,2:3],big.df[,1])

require(survey)
require(scales)
par(mar=c(5,5,4,3))

require(xtable)
require(RColorBrewer)
cols <- brewer.pal(7,"Dark2")
par(mfrow=c(4,2),las=1)
names <- c("AE", "AG","A1","B","C","D","F1")
letters <- c("a","b","c","d","e","f","g")
lims <- c()
treedata <- data.frame(stringsAsFactors = F)

for (m in 1:7){
  
  par(mar=c(4.5,6,1,1))
  xval <- new.df[m][[1]][,1]
  yval <- new.df[m][[1]][,2]
  
  #buffer <- 0.01*(range(xval)[2] - range(new.df[m][[1]][,1])[1])
  #newx <- min(new.df[m][[1]][,1])-buffer
  plot(x=jitter(xval,amount=0.45), y=yval, col=alpha(cols[m],0.35), xlim=c(1979,2016),
       ylim=c(0,0.30), cex=1,pch=20, 
       xlab="Collection Date",ylab="Root-to-Tip Branch Length", cex.lab=1.1)
  lreg <- lm(lengths~dates ,data=new.df[m][[1]])
  
  #compute the 95% conf ints for slope
  cislope <- c(strsplit(formatC(confint(lreg)[2],format="e",digits=2),"e")[[1]][1],
               strsplit(formatC(confint(lreg)[4],format="e",digits=2),"e")[[1]][1])
  rsqr <- signif(summary(lreg)$adj.r.squared,2)
  slope <- strsplit(formatC(lreg$coefficients[2][[1]],format="e",digits=2),"e")[[1]]
  
  
  #calculation of the xintercept
  xest <- svycontrast(lreg, quote(-`(Intercept)`/dates))
  xint <- coef(xest)[[1]]
  se <- SE(xest)[[1]]
  
  xlo <- format(round((xint-se),2),nsmall=2)
  xup <- format(round((xint+se),2),nsmall=2)
  treedata <- rbind(treedata, data.frame(Clade=names[m],
                                         Estimate= toString(sprintf("%s (%s,%s) %s",slope[1],cislope[1],cislope[2],slope[2])),
                                         xint=sprintf("%s (%s,%s)",format(round(xint,2),nsmall=2), xlo, xup),
                                         rsqr=rsqr,stringsAsFactors = F))
  
  
  
  abline(lreg,lwd=1.5)
  #print(summary(lreg))
  text(1979.7,0.285,labels=names[m], cex=1.6)
  eqn <- paste0("y = ", signif(lreg$coefficients[2][[1]],2), "x ", signif(lreg$coefficients[1][[1]],2))
  #text(1998,0.275,labels=eqn, cex=1.1)
  #rsqr <- paste0(txt, get(signif(summary(lreg)$adj.r.squared,2)))
  #text(2012,0.29,labels=expression(paste(R^2,"= ")), cex=1.1)
  #text(2015,0.286,labels=rsqr,cex=1.1)
  par(xpd=NA)
  text(1970,0.31,labels=paste0(letters[m],")"), cex=1.5)
  par(xpd=F)
  
  
}

#colnames(treedata) <- c("Clade","Estimate", "$x$-Intercept (Year)", "$R^2$")

#lxtable <- xtable(treedata)
#toLatex.xtable(lxtable)


#setwd("~/vindels/Indel_Analysis")
#write.csv(treedata,file="tree_data.csv")

# for (m in 1:7){
#   par(mar=c(4.5,6,1,1))
#   buffer <- 0.01*(range(new.df[m][[1]][,1])[2] - range(new.df[m][[1]][,1])[1])
#   newx <- min(new.df[m][[1]][,1])-buffer
#   plot(x=jitter(new.df[m][[1]][,1],amount=0.45), y=new.df[m][[1]][,2], col=alpha(cols[m],0.35), xlim=c(1980,2016),
#        ylim=c(0,0.30), cex=1,pch=20, 
#        xlab="Collection Date",ylab="Root-to-Tip Branch Length", cex.lab=1.1)
#   abline(lm(new.df[m][[1]][,2]~new.df[m][[1]][,1]),lwd=1.5)
#   text(newx+buffer*2,0.285,labels=names[m], cex=1.4)
#   par(xpd=NA)
#   text(newx-buffer*25,0.31,labels=paste0(letters[m],")"), cex=1.5)
#   par(xpd=F)
# }





#plot(x=jitter(dfAE$dates,amount=0.3), y=dfAE$lengths, col=alpha(cols[1],0.7), xlim=c(1982,2016),ylim=c(0.05,0.25), cex=0.8,pch=20,
#     xlab="Collection Date",ylab="Root-to-Tip Branch Length\n", main="Tree Branch Lengths vs. Collection Dates -- AE", cex.lab=1.4,cex.main=1.6)
#abline(lm(dfAE[,2]~dfAE[,1]),lwd=1.5)


#par(mar=c(6,6,4,4))
#plot(x=jitter(dfB$dates,amount=0.5), y=dfB$lengths, col=alpha(as.character(dfB$color),0.5), cex=0.8,pch=20,
#     xlab="Collection Date",ylab="Root-to-Tip Branch Length", main="Tree Branch Lengths vs. Collection Dates -- Subtype B",cex.lab=1.3,cex.main=1.6)
#abline(lm(dfB[,2]~dfB[,1]))

#par(mar=c(6,6,4,4))
#plot(x=jitter(dfC$dates,amount=0.5), y=dfC$lengths, col=alpha(cols[1],0.5),cex=1,pch=20, 
#     xlab="Collection Date",ylab="Root-to-Tip Branch Length", main="Tree Branch Lengths vs. Collection Dates -- Subtype C",cex.lab=1.3,cex.main=1.6)
#abline(lm(dfC[,2]~dfC[,1]))
