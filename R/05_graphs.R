# I recreate all eighteen designs from the R estimates, with PNG/SVG/PDF output.
COLORS<-c("#0072B2","#D55E00","#009E73")
manifest<-jsonlite::fromJSON(file.path(PROJECT,"docs/figure_manifest.json"))
draw_graph<-function(index,width,height,draw) {
  stem<-tools::file_path_sans_ext(basename(manifest$file[index]))
  caption<-manifest$caption[index]
  for(ext in c("png","svg","pdf")) {
    path<-if(ext=="pdf") file.path(OUT,"report/assets",paste0(stem,".pdf")) else file.path(F,paste0(stem,".",ext))
    if(ext=="png") png(path,width=width,height=height,units="in",res=250,type="cairo",bg="white")
    if(ext=="svg") svg(path,width=width,height=height,bg="white",family="sans")
    if(ext=="pdf") pdf(path,width=width,height=height,bg="white",family="Helvetica",useDingbats=FALSE)
    par(family="sans",cex=.9,col.axis="#344054",col.lab="#17242C",col.main="#17242C",
        las=1,bty="l",mar=c(4.2,4.8,3.1,1.2),oma=c(3.4,0,0,0),mgp=c(2.8,.7,0))
    tryCatch({draw(); mtext(paste(strwrap(caption,width=round(width*12)),collapse="\n"),side=1,outer=TRUE,line=1,cex=.67,adj=.025,col="#475467")},
             finally=dev.off())
  }
}
guide<-function(horizontal=TRUE) {
  if(horizontal) abline(h=axTicks(2),col="#DDE3E8",lwd=.6) else abline(v=axTicks(1),col="#DDE3E8",lwd=.6)
}
rd_panel<-function(y,title=label(y,SHORT),scale=100) {
  z<-d[which(d$sample_preferred==1 & d$local_200==1 & !is.na(d[[y]])),]
  bin<-floor(z$running/20)*20+10
  groups<-split(seq_len(nrow(z)),interaction(z$eligible,bin,drop=TRUE))
  bins<-do.call(rbind,lapply(groups,function(i) data.frame(side=z$eligible[i[1]],population=mean(z$tot_p[i]),mean=mean(z[[y]][i])*scale)))
  lines_data<-lapply(0:1,function(side) {
    q<-z[z$eligible==side & abs(z$running)<100,]
    m<-lm.wfit(cbind(1,q$running),as.numeric(q[[y]]),1-abs(q$running)/100)
    x<-seq(if(side==0)-99.5 else 0,if(side==0)0 else 99.5,length.out=100)
    list(x=x+299.5,y=drop(cbind(1,x)%*%m$coefficients)*scale)
  })
  yrange<-range(c(bins$mean,unlist(lapply(lines_data,`[[`,"y"))),finite=TRUE)
  span<-max(diff(yrange),.5); yrange<-yrange+c(-.12,.24)*span
  plot(NA,xlim=c(99.5,499.5),ylim=yrange,xlab="Village population, 2001 (persons)",
       ylab=if(scale==100)"Percent" else "Brightness units (0-63)",main=title,xaxt="n")
  rect(199.5,par("usr")[3],399.5,par("usr")[4],col="#F2F4F7",border=NA); guide()
  axis(1,at=c(100,200,300,400,500))
  for(side in 0:1) {
    q<-bins[bins$side==side,]; points(q$population,q$mean,pch=21,bg=COLORS[side+1],col="white",cex=1.1)
    lines(lines_data[[side+1]]$x,lines_data[[side+1]]$y,col=COLORS[side+1],lwd=2)
  }
  abline(v=299.5,lty=2,col="#667085")
  text(304,yrange[2]-.03*diff(yrange),"Eligibility cutoff",adj=c(0,1),cex=.7,col="#475467")
  legend("bottomright",c("Below 300","300 or more"),pch=16,col=COLORS[1:2],bty="n",cex=.75)
}
forest<-function(q,title,xlabel="Effect difference (pp per +10 pp baseline caste share)") {
  q<-q[order(match(q$outcome,c(PRIMARY,SECONDARY)),match(q$term,c("D_sc10","D_st10"))),]
  lo<-min(0,q$ci_low*100); hi<-max(0,q$ci_high*100); span<-max(hi-lo,.5); y<-rev(seq_len(nrow(q)))
  par(mar=c(4.2,10.2,3.1,1.1),cex=.84)
  plot(NA,xlim=c(lo-.1*span,hi+.72*span),ylim=c(.4,nrow(q)+.6),yaxt="n",xlab=xlabel,ylab="",main=title)
  for(i in seq_len(nrow(q))) if(i%%2==1) rect(par("usr")[1],y[i]-.45,par("usr")[2],y[i]+.45,col="#F2F4F7",border=NA)
  guide(FALSE); abline(v=0,lty=2,col="#667085")
  labs<-vapply(q$outcome,label,character(1),labels=SHORT)
  labs<-paste0(labs,ifelse(q$term=="D_sc10"," / SC"," / ST")); axis(2,at=y,labels=labs,tick=FALSE,cex.axis=.87)
  for(i in seq_len(nrow(q))) {
    color<-COLORS[if(q$term[i]=="D_sc10")1 else 2]
    arrows(q$ci_low[i]*100,y[i],q$ci_high[i]*100,y[i],angle=90,code=3,length=.045,col=color,lwd=1.7)
    points(q$estimate[i]*100,y[i],pch=if(q$term[i]=="D_sc10")16 else 15,col=color,cex=1)
    text(hi+.06*span,y[i],sprintf("%+.2f [%+.2f, %+.2f]",q$estimate[i]*100,q$ci_low[i]*100,q$ci_high[i]*100),adj=0,cex=.72)
  }
}
draw_graph(1,10,4.8,function() {
  counts<-table(d$tot_p[d$sample_preferred==1 & d$local_200==1]); x<-as.numeric(names(counts))
  plot(x,as.numeric(counts),type="n",ylim=c(0,max(counts)*1.1),xlab="2001 Census population (persons)",ylab="Number of villages",main="Population frequencies around the eligibility threshold")
  guide(); segments(x,0,x,as.numeric(counts),col=COLORS[1],lwd=1.1); abline(v=299.5,col=COLORS[2],lty=2,lwd=2)
  legend("topright","Eligibility boundary (>=300)",lty=2,col=COLORS[2],bty="n",cex=.8)
})
draw_graph(2,11,5,function() {
  par(mfrow=c(1,2))
  for(caste in c("pct_sc_01","pct_st_01")) {hist(local[[caste]]*100,breaks=seq(0,100,5),col=COLORS[1],border="white",main=label(caste),xlab="2001 population share (%)",ylab="Number of villages")}
})
draw_graph(3,12,5,function() {par(mfrow=c(1,2)); rd_panel("pct_sc_01",label("pct_sc_01")); rd_panel("pct_st_01",label("pct_st_01"))})
for(i in 4:6) local({index<-i; y<-c("vd_pwr_d_dom_11","hpca11_msl_elec","hpca01_msl_elec")[i-3]
 draw_graph(index,10,5,function() rd_panel(y))})
draw_graph(7,12,5,function() {
  par(mfrow=c(1,2))
  for(y in PRIMARY) {
    base<-if(y==PRIMARY[1])"vd_pwr_d_dom_01" else "hpca01_msl_elec"
    vals<-vapply(CAT,function(group) colMeans(local[local$caste_group==group,c(base,y)],na.rm=TRUE)*100,numeric(2))
    barplot(vals,beside=TRUE,names.arg=c("Other","SC majority","ST majority"),col=COLORS[1:2],border=NA,ylim=c(0,100),ylab="Percent",main=label(y,SHORT))
    legend("topleft",c("2001","2011"),fill=COLORS[1:2],bty="n",cex=.8)
  }
})
draw_graph(8,12,5,function() forest(res[res$outcome %in% PRIMARY & res$bandwidth==100,],"Does caste composition change the eligibility effect?"))
draw_graph(9,12,6.5,function() forest(res[res$outcome %in% EMPLOYMENT & res$bandwidth==100,],"Employment heterogeneity: exploratory outcomes"))
draw_graph(10,12,8,function() {
  par(mfrow=c(2,2),mar=c(4.3,5.8,2.6,1),cex=.82)
  for(y in PRIMARY) for(term in c("D_sc10","D_st10")) {
    q<-res[res$outcome==y & res$term==term,]; q<-q[order(q$bandwidth),]; col<-COLORS[if(term=="D_sc10")1 else 2]
    plot(q$bandwidth,q$estimate*100,type="n",ylim=range(c(0,q$ci_low*100,q$ci_high*100)),xaxt="n",xlab="Bandwidth each side (persons)",ylab="Effect difference (pp per +10 pp share)",main=paste(label(y,SHORT),if(term=="D_sc10")"/ SC" else "/ ST"))
    guide(); axis(1,at=c(50,100,150,200)); abline(h=0,lty=2,col="#667085")
    arrows(q$bandwidth,q$ci_low*100,q$bandwidth,q$ci_high*100,angle=90,code=3,length=.045,col=col)
    lines(q$bandwidth,q$estimate*100,type="b",pch=16,col=col,lwd=1.8)
  }
})
draw_graph(11,14,9,function() {
  par(mfrow=c(2,2),mar=c(4.2,11,2.6,1),cex=.82)
  labels<-c("Main model","No post-policy light filter","District clustering","Exclude +/-5 persons","Baseline adjustment","State-specific RD")
  for(y in PRIMARY) for(term in c("D_sc10","D_st10")) {
    q<-sens[sens$outcome==y & sens$term==term,]; pos<-rev(seq_len(nrow(q))); col<-COLORS[if(term=="D_sc10")1 else 2]
    plot(NA,xlim=range(c(0,q$ci_low*100,q$ci_high*100)),ylim=c(.5,6.5),yaxt="n",xlab="Effect difference (pp per +10 pp share)",ylab="",main=paste(label(y,SHORT),if(term=="D_sc10")"/ SC" else "/ ST"))
    guide(FALSE); axis(2,at=pos,labels=labels,tick=FALSE,cex.axis=.85); abline(v=0,lty=2,col="#667085")
    arrows(q$ci_low*100,pos,q$ci_high*100,pos,angle=90,code=3,length=.04,col=col,lwd=1.5); points(q$estimate*100,pos,pch=16,col=col)
  }
})
draw_graph(12,12,6,function() {
  par(mar=c(4.2,18,3,1),cex=.82); scale<-ifelse(bal$outcome=="lights_max2001",1,100); pos<-rev(seq_len(nrow(bal)))
  plot(NA,xlim=range(c(0,bal$ci_low*scale,bal$ci_high*scale)),ylim=c(.5,6.5),yaxt="n",ylab="",xlab="Eligibility-boundary difference (pp; brightness in native units)",main="Pre-policy balance checks")
  guide(FALSE); axis(2,at=pos,labels=vapply(bal$outcome,label,character(1)),tick=FALSE,cex.axis=.85); abline(v=0,lty=2,col="#667085")
  arrows(bal$ci_low*scale,pos,bal$ci_high*scale,pos,angle=90,code=3,length=.05,col=COLORS[1]); points(bal$estimate*scale,pos,pch=16,col=COLORS[1])
})
draw_graph(13,12,5,function() {
  par(mfrow=c(1,2),mar=c(4.3,8,3,1),cex=.85)
  for(y in PRIMARY) {
    q<-sg[sg$outcome==y & sg$status=="Estimated",]; q<-q[match(CAT,q$group),]; pos<-3:1
    plot(NA,xlim=range(c(0,q$ci_low*100,q$ci_high*100)),ylim=c(.5,3.5),yaxt="n",ylab="",xlab="Eligibility effect (percentage points)",main=label(y,SHORT))
    guide(FALSE); axis(2,at=pos,labels=q$group,tick=FALSE,cex.axis=.8); abline(v=0,lty=2,col="#667085")
    arrows(q$ci_low*100,pos,q$ci_high*100,pos,angle=90,code=3,length=.04,col=COLORS); points(q$estimate*100,pos,pch=16,col=COLORS)
  }
})
draw_graph(14,11,6,function() {
  counts<-sort(table(local$state)); par(mar=c(4.2,12,3,1),cex=.85)
  pos<-barplot(counts,horiz=TRUE,names.arg=tools::toTitleCase(tolower(names(counts))),col=COLORS[1],border=NA,xlim=c(0,max(counts)*1.2),xlab="Number of villages",main="State coverage of the local estimation sample")
  text(as.numeric(counts)+max(counts)*.02,pos,as.numeric(counts),adj=0,cex=.8)
})
draw_graph(15,10,5,function() {
  q<-pretrends; year<-1998:2004
  plot(year,q$estimate,type="n",ylim=range(c(0,q$ci_low,q$ci_high)),xaxt="n",xlab="Year (pre-policy)",ylab="Brightness difference (0-63 scale)",main="Night-light discontinuities before RGGVY")
  guide(); axis(1,at=year); abline(h=0,lty=2,col="#667085")
  arrows(year,q$ci_low,year,q$ci_high,angle=90,code=3,length=.05,col=COLORS[1]); lines(year,q$estimate,type="b",pch=16,col=COLORS[1],lwd=2)
})
draw_graph(16,10,5,function() {
  vals<-vapply(CAT,function(group) mean(local$access_adoption_gap[local$caste_group==group],na.rm=TRUE)*100,numeric(1))
  barplot(vals,names.arg=CAT,col=COLORS,border=NA,ylim=c(0,max(vals)*1.2),xlab="Village composition in 2001",ylab="Mean availability minus lighting share (pp)",main="Availability and adoption are different margins")
})
draw_graph(17,12,5,function() {par(mfrow=c(1,2)); for(y in PRODUCTIVE) rd_panel(y)})
draw_graph(18,12,5,function() forest(res[res$outcome %in% PRODUCTIVE & res$bandwidth==100,],"Productive electricity: exploratory caste heterogeneity"))
json(manifest,"R_figure_manifest.json")
