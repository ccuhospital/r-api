#FileName: 
# rca_ap.R
# 
#Descript: 
# backend api for fontend web interface.
# 
#Usage:
# ret <- get_predict(toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
#    start.time, end.time)
oldw <- getOption("warn")
options(warn = 1)


get_predict <- function(toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
    start.time, end.time) {
    # rca api: get_predict
    # return list datastructure: TRAINING_X, PREDICT_X_INFO, Ystat
    
    # load necessary function
    source("avm.R")
    source("RCA_function.R")

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