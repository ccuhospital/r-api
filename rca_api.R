#FileName: 
# rca_ap.R
# 
#Descript: 
# backend api for fontend web interface.
# 
#Usage:
# get_rca(psql_db_info, toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, start.time, end.time)
# > rca <- get_rca(psql_db_info, 'CVDU01', 'P6|A5', 'UPAN120Q275A45|P-ANOA-A2-267X','l2tfin_uniform', 0, 0.1, '2017-09-21 23:00:00', '2017-09-24 03:00:00')
# get_single_rca(psql_db_info, glassid, toolid, chamber, recipe, ystatistics)
# > single_rca <- get_single_rca(psql_db_info, 'TL7CC0MAX', 'CVDU01', 'P2|A5', 'UPAN120Q275A45|P-ANOA-A2-267X', 'l2tfin_avg') 

# load necessary package
library(jsonlite)
library(logging)


# load necessary function
source("RCA_function.R")
source("avm.R")


get_rca <- function(psql_db_info, toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
    start.time, end.time) {
    # type: toolid: string
    # type: chamber: string
    # type: recipe: string
    # type: ystatistics: string
    # type: ysummary_value_hat_lower: float
    # type: ysummary_value_hat_upper: float
    # type: start.time: string timeformat %Y-%m-%d %H:%M:%S
    # type: end.time: string timeformat %Y-%m-%d %H:%M:%S
    # rtype: JSON: TRAINING_X, PREDICT_X_INFO, Ystat
    
    tryCatch({
        loginfo('Get local Rdata with DB')
        rdata <- get_trainingx_by_db(psql_db_info, toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
            start.time, end.time)
        if (is.null(rdata)) {
            return ()
        }

        loginfo('Get predict.x with DB')
        predict.x <- get_predictx(psql_db_info, toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
            start.time, end.time)
        if (is.null(predict.x)) {
            return ()
        }

        loginfo('Start rca main function')
        ret <- toJSON(RCA_func(rdata, predict.x))
        return (ret)
    }, error = function(e) {
        logerror(e)
        conditionMessage(e)
        return ()
    }, finally = {
        loginfo('Done')
    })
}


get_single_rca <- function(psql_db_info, glassid, toolid, chamber, recipe, ystatistics) {
    # type: glassid: string
    # type: toolid: string
    # type: chamber: string
    # type: recipe: string
    # type: ystatistics: string
    # rtype: JSON: TRAINING_X, PREDICT_X_INFO, Ystat
    
    tryCatch({
        loginfo('Get singel local Rdata with DB')
        rdata <- get_single_trainingx_by_db(psql_db_info, glassid, toolid, chamber, recipe, ystatistics)
        if (is.null(rdata)) {
            return ()
        }

        loginfo('Get single predict.x with DB')
        predict.x <- get_single_predictx(psql_db_info, glassid, toolid, chamber, recipe, ystatistics)
        if (is.null(predict.x)) {
            return ()
        }

        loginfo('Start rca main function')
        ret <- toJSON(RCA_func(rdata, predict.x))
        return (ret)
    }, error = function(e) {
        logerror(e)
        conditionMessage(e)
        return ()
    }, finally = {
        loginfo('Done')
    })
}
