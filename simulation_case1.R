### Simulation study: case 1.
### Program in a parallel way, all functions required are stored in "source_function_17.R".

### load required packages
library(snowfall)
library(parallel)
detectCores()

sfInit(parallel = TRUE, cpus = detectCores()-4)
sfLibrary(survival)
sfLibrary(JM)
sfLibrary(joineR)
sfLibrary(dplyr) # near
sfLibrary(statmod)
sfLibrary(progress)
sfLibrary(MASS)
sfLibrary(mvtnorm)
sfLibrary(tensor)
sfSource(here::here("source_function_17.R"))


SIMULATE=function(s){
  knots=mycubicbs(0,internal_knots,boundary_knots)$knots
  Q.2=matrix(0,nrow=q,ncol=q-2)
  for(l in 1:(q-2)){
    Q.2[l,l]=6/((knots[l+4]-knots[l+2])*(knots[l+4]-knots[l+1]))
    Q.2[l+2,l]=6/((knots[l+4]-knots[l+2])*(knots[l+5]-knots[l+2]))
    Q.2[l+1,l]=-(Q.2[l,l]+Q.2[l+2,l])
  }
  
  ## Generate simulation data
  data=gendat(s,obstim=seq(0,20/2,by=1/2),obsmax=10,gammatrue=-2,alpha1true=0.2,alpha2true=0.3,betatrue=c(6,3,7,1,8,5,4),D0=diag(c(3,4,4,5,4,3,4)),sigmatrue=1,knots,Q.2)
  M=as.data.frame(mycubicbs(data$time,internal_knots=c(5,10,15)/2,boundary_knots=c(0,20)/2)$mat)
  names(M)=paste0("time",c(1:7))
  data=cbind(data,M)
  data.id=data[!duplicated(data$id),]
  
  ######Get initial values (estimation results obtained from the two-stage (TS) method)
  
  initialvalue=inival(data,data.id,ctl=lmeControl (msMaxIter=100),knots,Q.2)
  beta=initialvalue$beta
  sigma2=initialvalue$sigma2
  D=initialvalue$D
  gamma=initialvalue$gamma
  cumbase=initialvalue$cumbase
  alpha1=0
  alpha2=0
  coxts=initialvalue$coxts
  res.ts=c(coxts,beta,sigma2,diag(D))
  
  ############### Estimate by the joint modelling (JM) method ###########

  res.jm=est(data,data.id,gamma,alpha1,alpha2,cumbase,beta,sigma2,D,knots,Q.2)
  
  ###Return estimation results obtained from JM and TS methods
  return(c(c(res.jm),c(res.ts)))
  
}

RES=sfLapply(1:3,SIMULATE)

sfStop()
