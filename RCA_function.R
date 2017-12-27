#Example:
#> out = RCA_func( rdata, predict.x)
# 
#Return a list of three objects
# TRAINING_X
# PREDICT_X_INFO
# Ystat
#
##Author: Ma (2017/12/25)
#
library(pls)
library(dplyr)


RCA_func <- function(rdata, predict.x)
{
  predict.x$NAME = as.character(predict.x$NAME)
  MODEL_NAME = unique(predict.x$NAME)
  out <- list()
  for(i in 1:length(MODEL_NAME))
  {
    TEMP1 =  rdata[[MODEL_NAME[i]]]
    MODEL.PLS = TEMP1$model.pls
    IND.USED = TEMP1$ind.used
    FINAL.COMP = TEMP1$final.comp
    IND.MEDIAN = TEMP1$trainig_x_Information[3,]
    Ystat =  TEMP1$ystat.used
    
    DATA = matrix(IND.MEDIAN, nrow = 1)
    colnames(DATA) = names(IND.MEDIAN)
    Y_MEDIAN = predict(MODEL.PLS, ncomp = FINAL.COMP, newdata= DATA)[,,1]
    
    I = which(predict.x$NAME == MODEL_NAME[i])
    TEMP2 = predict.x[I,]
    GLASSID = TEMP2$glassid
    OLDPRE.X = TEMP2[,IND.USED]
    ORIGIN.Y = matrix(TEMP2$ysummary_value_hat, nrow = 1)
    rownames(ORIGIN.Y) = Ystat
    colnames(ORIGIN.Y) = GLASSID
    Ymedian = rep(Y_MEDIAN,length(GLASSID))
    ORIGIN.Y = rbind(ORIGIN.Y, Ymedian )
    
    PRE.X = as.matrix(OLDPRE.X)
    PRE.X = matrix(PRE.X, nrow=nrow(PRE.X),byrow=F)
    colnames(PRE.X) = IND.USED
    
    sub_out = rep(0,dim(PRE.X)[2])
    for(j in 1:dim(PRE.X)[1])
    {
      TEMP3 = which( is.na(PRE.X[j,]) )
      if(length(TEMP3)>0)
      {
        PRE.X[j,TEMP3] = IND.MEDIAN [TEMP3]
      }
      TEMP4 = matrix(PRE.X[j,],length(PRE.X[j,]),length(PRE.X[j,]),byrow = TRUE)
      
      diag(TEMP4) <- IND.MEDIAN
      colnames(TEMP4) = IND.USED 
      pre.value = predict(MODEL.PLS, ncomp = FINAL.COMP, newdata = TEMP4)[,,1]
      sub_out = cbind(sub_out,pre.value) 
    }
    sub_out = sub_out[,-1,drop=F]
    rownames(sub_out) = IND.USED
    colnames(sub_out) = GLASSID
    sub_out = rbind(ORIGIN.Y,sub_out)
    out[[i]] = sub_out
  }
  if(length(out)>1)
  {
    RN = as.character(  rownames(out[[1]]) )
    out1 = data.frame(RN,out[[1]])
    for(i in 2:length(out))
    {
      RN = as.character(rownames(out[[i]]))
      TEMP5 = data.frame(RN,out[[i]])
      out1 = full_join(out1, TEMP5)
    }
    RN = out1$RN
    out1 = out1[,-1]
    rownames(out1) = RN
  }
  if(length(out) == 1) {out1= out[[1]]}    
  
  out2 = out1
  
  for(j in 1:dim(out2)[2])
  {
    for(i in 1:dim(out2)[1])
    {
      if( !is.na(out2[i,j]) )
      {
        out2[i,j] = abs(out2[i,j] - out1[2,j])/(out1[2,j])*100
      }
    }
  }
  
  return1 = out1[c(1:2),,drop=F]
  
  
  for(j in 1:dim(out2)[2])
  {
    for(i in  3:dim(out2)[1])
    {
      if( !is.na(out2[i,j]) )
      {
        out2[i,j] = (out2[1,j]-out2[i,j])/out2[1,j]
      }
    }
  }
  out3 = out2[-c(1:2),,drop=F]
  diffva=rep(0,dim(out3)[1])
  for(i in 1:dim(out3)[1])
  {
    I=which(out3[i,]!="NA")
    temp= out3[i,I]
    temp= as.numeric(temp)
    diffva[i]=mean(temp)
  }
  out3=cbind(out3,diffva)
  out3=as.data.frame(out3)
  out3=out3[order(out3$diffva,decreasing = TRUE),]
  
  PREDICT_X_INFO = predict.x[,rownames(out3)]
  PREDICT_X_INFO = t(PREDICT_X_INFO)
  colnames(PREDICT_X_INFO) = colnames(out2)
  BIAS_RATIO = out3$diffva
  PREDICT_X_INFO = cbind(PREDICT_X_INFO,BIAS_RATIO)
  
  #########################################################
  RCANEAME = rownames(PREDICT_X_INFO)
  TRAINING_X_INFO = matrix(0,length(RCANEAME),5)
  for(i in 1:length(RCANEAME))
  {
    for(k in 1:length(MODEL_NAME) )
    {
      I=which(colnames(rdata[[MODEL_NAME[k]]]$trainig_x_Information) == RCANEAME[i] )
      if(length(I)>0){TRAINING_X_INFO[i,] = rdata[[MODEL_NAME[k]]]$trainig_x_Information[,I] }
    }
  }
  colnames(TRAINING_X_INFO) = c("MIN","Q1","MEDIAN","Q3","MAX")
  rownames(TRAINING_X_INFO) = RCANEAME
  all_out = list(TRAINING_X = TRAINING_X_INFO, PREDICT_X_INFO = PREDICT_X_INFO, Ystat = return1)
  return(all_out)
}
