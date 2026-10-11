# I use triangular WLS, CR1 block covariance and t inference with G-1 df.
PRIMARY <- c("vd_pwr_d_dom_11", "hpca11_msl_elec")
EMPLOYMENT <- c("work_p_11", "work_f_11", "work_pooled_ot_p_11", "work_pooled_ot_f_11")
PRODUCTIVE <- c("vdp_pwr_d_com_11", "vd_pwr_d_all_11")
SECONDARY <- c(EMPLOYMENT, PRODUCTIVE)
CAT <- c("Other villages", "SC majority", "ST majority")
NAMES <- c(vd_pwr_d_dom_11="Village domestic electricity availability", hpca11_msl_elec="Households using electric lighting",
 hpca01_msl_elec="Households using electric lighting, 2001", work_p_11="All work participation", work_f_11="Female work participation",
 work_pooled_ot_p_11="Other (non-agricultural) work participation", work_pooled_ot_f_11="Female other (non-agricultural) work",
 vd_pwr_d_dom_01="Village domestic electricity availability, 2001", pct_sc_01="Scheduled Caste population share, 2001",
 pct_st_01="Scheduled Tribe population share, 2001", lit_p_01="Literacy share, 2001", lights_max2001="Maximum night-time brightness, 2001",
 vdp_pwr_h_dom_avg_11="Domestic power supply (hours/day), 2011", vdp_pwr_d_com_11="Commercial electricity availability",
 vd_pwr_d_all_11="All-sector electricity availability")
SHORT <- c(vd_pwr_d_dom_11="Domestic availability", hpca11_msl_elec="Household lighting", hpca01_msl_elec="Baseline household lighting, 2001", work_p_11="All work",
 work_f_11="Female work", work_pooled_ot_p_11="Other work", work_pooled_ot_f_11="Female other work",
 vdp_pwr_d_com_11="Commercial availability", vd_pwr_d_all_11="All-sector availability")
label <- function(y, labels=NAMES) if (y %in% names(labels)) unname(labels[y]) else y
csv <- function(frame, name) write.csv(frame, file.path(T, paste0(name, ".csv")), row.names=FALSE, na="")
json <- function(object, name) jsonlite::write_json(object, file.path(V, name), pretty=TRUE, auto_unbox=TRUE, digits=16, na="null")
state_matrix <- function(z) {
  levels <- sort(unique(z$st_code))
  if (length(levels)<2) return(matrix(numeric(), nrow=nrow(z), ncol=0))
  x <- model.matrix(~factor(st_code, levels=levels), z)[, -1, drop=FALSE]
  colnames(x) <- paste0("state_", levels[-1]); x
}
fit <- function(y, h=100, sample="sample_preferred", cluster="block_id", heter=TRUE,
                donut=0, cutoff=299.5, baseline=FALSE, subgroup=NULL, state_slopes=FALSE) {
  z <- d[which(d[[sample]]==1), , drop=FALSE]
  z$x <- z$tot_p-cutoff; z$D <- as.numeric(z$tot_p>=cutoff)
  z <- z[which(abs(z$x)<h & abs(z$x)>donut), , drop=FALSE]
  if (!is.null(subgroup)) z <- z[which(z$caste_group==subgroup), , drop=FALSE]
  base <- c(vd_pwr_d_dom_11="vd_pwr_d_dom_01", hpca11_msl_elec="hpca01_msl_elec")[y]
  needed <- c(y,"x","D",cluster,"st_code", if (heter) c("sc10","st10"), if (baseline && !is.na(base)) base)
  z <- z[complete.cases(z[, needed, drop=FALSE]), , drop=FALSE]
  X <- cbind(const=1, eligible=z$D, running=z$x, D_x=z$D*z$x)
  if (heter) for (caste in c("sc10","st10")) {
    added <- cbind(z[[caste]],z$D*z[[caste]],z$x*z[[caste]],z$D*z$x*z[[caste]])
    colnames(added) <- c(caste,paste0("D_",caste),paste0("x_",caste),paste0("D_x_",caste))
    X <- cbind(X,added)
  }
  if (baseline && !is.na(base)) X <- cbind(X,baseline=z[[base]])
  states <- state_matrix(z); X <- cbind(X,states)
  if (state_slopes) for (col in colnames(states)) for (term in c("eligible","running","D_x")) {
    added <- matrix(X[,col]*X[,term],ncol=1); colnames(added)<-paste(col,term,sep="_"); X<-cbind(X,added)
  }
  w <- 1-abs(z$x)/h; model <- lm.wfit(X, as.numeric(z[[y]]), w)
  n <- nrow(X); k <- ncol(X); g <- length(unique(z[[cluster]]))
  if (model$rank!=k || g<2 || n<=k) stop("Unidentified model: ",y)
  beta <- model$coefficients
  bread <- chol2inv(chol(crossprod(X,w*X)))
  scores <- X * (w * as.numeric(model$residuals))
  grouped <- rowsum(scores,z[[cluster]],reorder=TRUE)
  vcov <- bread %*% crossprod(grouped) %*% bread * g/(g-1) * (n-1)/(n-k)
  dimnames(vcov)<-list(colnames(X),colnames(X))
  se <- sqrt(diag(vcov)); df <- g-1
  p <- 2*pt(-abs(beta/se),df); margin <- qt(.975,df)*se
  list(beta=beta,se=se,vcov=vcov,p=p,lo=beta-margin,hi=beta+margin,
       df=df,g=g,z=z,X=X,w=w,residuals=model$residuals)
}
result_row <- function(m,y,term,h=100,spec="main") data.frame(outcome=y,outcome_label=label(y),term=term,
 bandwidth=h,specification=spec,estimate=unname(m$beta[term]),se=unname(m$se[term]),p_value=unname(m$p[term]),
 ci_low=unname(m$lo[term]),ci_high=unname(m$hi[term]),n=nrow(m$z),n_left=sum(m$z$D==0),n_right=sum(m$z$D==1),clusters=m$g)
joint_p <- function(m) {
  idx <- c("D_sc10","D_st10"); b <- m$beta[idx]
  as.numeric(pf(drop(t(b)%*%solve(m$vcov[idx,idx])%*%b)/2,2,m$df,lower.tail=FALSE))
}
full_table <- function(m) data.frame(term=names(m$beta),estimate=unname(m$beta),se=unname(m$se),
 p_value=unname(m$p),ci_low=unname(m$lo),ci_high=unname(m$hi))
