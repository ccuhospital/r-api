#FileName: 
# rca_ap.R
# 
#Descript: 
# backend api for fontend web interface.
# 
#Usage:
# rca <- get_rca(toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
#    start.time, end.time)
# load necessary function
source("RCA_function.R")

oldw <- getOption("warn")
options(warn = 1)


get_rca <- function(toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
    start.time, end.time) {
    # type: toolid: string
    # type: chamber: string
    # type: recipe: string
    # type: ystatistics: string
    # type: ysummary_value_hat_lower: float
    # type: ysummary_value_hat_upper: float
    # type: start.time: string timeformat %Y-%m-%d %H:%M:%S
    # type: end.time: string timeformat %Y-%m-%d %H:%M:%S
    # rtype: list: TRAINING_X, PREDICT_X_INFO, Ystat
    
    # load necessary function
    source("avm.R")

    tryCatch({
        loginfo('Get local Rdata with DB')
        rdata <- get_trainingx_by_db(toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
            start.time, end.time)
        if (is.null(rdata)) {
            return ()
        }

        loginfo('Get predict.x with DB')
        predict.x <- get_predictx(toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
            start.time, end.time)
        if (is.null(predict.x)) {
            return ()
        }

        loginfo('Start rca main function')
        ret <- RCA_func(rdata, predict.x)
        return (ret)
    }, error = function(e) {
        logerror(e)
        conditionMessage(e)
        return ()
    }, finally = {
        loginfo('Disable dbconnect')
        .psql_disconnectdb()
    })
}