#' Prepare list for SChnute assessment in an optimiser
#'
#' Create an object with TMB framework, including data, gradients and NLL function that can be optimised
#'
#' @param version character
#' @param catchkg numeric
#' @param indiceskg matrix
#' @param ts numeric
#' @param mwts matrix
#' @param tsp numeric
#' @param rho numeric
#' @param W numeric
#' @param start_q numeric
#' @param start_indexsigma numeric
#' @param start_B0 numeric
#' @param start_sigma numeric
#' @param start_f_calc numeric
#' @param start_catchsigma numeric
#' @param fix_sigma logical
#' @param fix_B0 logical
#' @param fix_indexsigma logical
#' @param fix_catchsigma logical
#' @return list
#' @export
#' @examples
# #' fbind(iris$Species[c(1, 51, 101)], PlantGrowth$group[c(1, 11, 21)])


schnute_peb<-function(version,catchkg,indiceskg,ts, mwts,tsp = 0, rho,W, start_q = 1e-8, start_indexsigma = 0.1 ,start_B0 = sb0, start_sigma = exp(-0.2) , start_f_calc = 0.3,start_catchsigma = 0.1, fix_sigma = TRUE, fix_B0 = FALSE, fix_indexsigma = FALSE, fix_catchsigma = TRUE){

  sb0 <- 5*max(catchkg)
  ny <- length(catchkg)
  no.survey <- length(ts)

  dat_tmb<-schnute_datprep(catchkg,indiceskg,ts,mwts,tsp)

  if(length(start_q) == 1 & no.survey > 1){
    start_q <- rep(start_q,no.survey)
    message("default start q used for each survey")
  }else start_q <-start_q


  if(length(start_indexsigma) == 1 & no.survey > 1){
    start_indexsigma <- rep(start_indexsigma,no.survey)
    message("default start_indexsigma used for each survey")
  }else start_indexsigma <-start_indexsigma

  if(length(start_f_calc) == 1){
start_f_calc <- rep(start_f_calc,ny)
  }else if(length(start_f_calc) == ny){
  start_f_calc <- start_f_calc
}else stop("mismathc in starting f_calc and number of years. Check your starting fishing mortality values")


if(version=="B0"){
  par_tmb<-schnute_parprep_v2(q = start_q, indexsigma = start_indexsigma, B0 = sb0 , sigma = start_sigma, rho, W, f_calc = start_f_calc, catchsigma = start_catchsigma)

  obj <- TMB::MakeADFun(
    data = c(model = "schnute_new_V2",dat_tmb),
    parameters = par_tmb,
    map = list(
      logB0=factor(ifelse(fix_B0==T,NA,1)),
      logindex_sigma = factor(ifelse(rep(fix_indexsigma,no.survey)==T,NA,c(seq(from=1, to=no.survey, by = 1)))),
      logW = factor(NA),
      logrho = factor(NA),
      #logf_calc= factor(rep(NA,ny)),
      logitsigma = factor(ifelse(fix_sigma==T,NA,1)),
      logcatch_sigma = factor(ifelse(fix_catchsigma==T,NA,1)),
      logrec_param = factor(rep(NA,2))
    ),
    hessian = TRUE,
    silent = TRUE,
    DLL = "sbar_TMBExports")


  }else if(version == "y1_no_f"){
    par_tmb<-schnute_parprep_v1(q = start_q, indexsigma = start_indexsigma, sigma = start_sigma, rho, W, f_calc = start_f_calc, catchsigma = start_catchsigma)


    obj <- TMB::MakeADFun(
      data = c(model = "alt_schnute",dat_tmb),
      parameters = par_tmb,
      map = list(
        logindex_sigma = factor(ifelse(rep(fix_indexsigma,no.survey)==T,NA,c(seq(from=1, to=no.survey, by = 1)))),
        logW = factor(NA),
        logrho = factor(NA),
        logrec_param = factor(rep(NA,2)),
        logf_calc= factor(c(NA,1:(ny-1))),
        logitsigma = factor(ifelse(fix_sigma==T,NA,1)),
        logcatch_sigma = factor(ifelse(fix_catchsigma==T,NA,1))
      ),
      hessian = TRUE,
      silent = TRUE,
      DLL = "sbar_TMBExports")



}

  return(obj)



}
