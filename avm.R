#FileName: 
# avm.R (RCA-apovshimben)
# 
#Descript: 
# For AVM/RCA data clean, there are some function support query predict information from db and read .Rdata 
# Normally engineer will prefer to query predict_data from db and with this information to read those nenecessary .Rdata.
# Buy this module support not only get those .Rdata from db's information but also can with the time interval to condition, this
# Can help you do some test on client envrionment to read .Rdata and no need db support, Good luck.
#
#Usage:
# Loading .R file.
#> source("avm.R")  
# Get .Rdata with time interval, and return list data structure.
# get_traingingx_by_local(start.time, end.time)
#> rdata <- get_trainingx_by_local('2017-12-05 00:00:00', '2017-12-05 14:00:00')
# Get .Rdata with db's information
# get_trainingx_by_db(toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, start.time, end.time)
#> rdata <- get_trainingx_by_db('CVDU01', 'P6|A5', 'UPAN120Q275A45|P-ANOA-A2-267X','l2tfin_uniform', 0, 0.1, '2017-09-21 23:00:00', '2017-09-24 03:00:00')
# Get predict x
# get_predictx(toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, start.time, end.time)
#> predict.x <- get_predictx('CVDU01', 'P6|A5', 'UPAN120Q275A45|P-ANOA-A2-267X','l2tfin_uniform', 0, 0.1, '2017-09-21 23:00:00', '2017-09-24 03:00:00')


# load necessary package
library(RPostgreSQL)
library(reshape2)
library(logging)


# load necessary function
source("env.R")


# setting logging
logReset()
basicConfig(level = 'FINEST')


# DB connect
drv_psql.avm <- dbDriver("PostgreSQL")
con_psql.avm <- dbConnect(drv_psql.avm,
    dbname = psql.dbname, host = psql.host,
    port = psql.port, user = psql.username,
    password = psql.password)


.get_predictx <- function(toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
    start.time, end.time) {
    sql <- sprintf(
        "
        WITH candidate_info AS (
            SELECT 
                glassid,
                mid,
                regexp_split_to_table(fdc_ind_id, \'\\|')::integer as fdc_ind_id
            FROM
                avm_predict_summary 
            WHERE 1=1
            AND toolid = '%s'
            AND chamber = '%s'
            AND recipe = '%s'
            AND ystatistics = '%s'
            AND ysummary_value_hat NOT BETWEEN '%f' AND '%f'
            AND proc_end_time >= '%s'
            AND proc_end_time < '%s'
        )
        SELECT 
            a.glassid,
            a.mid,
            b.stepid,
            b.svid||'_'||b.stepid||'_'||b.xstatistics as indicator,
            b.xsummary_value,
            b.fdc_ind_id
        FROM    
            candidate_info a,
            %s b
        WHERE 1=1
        AND a.fdc_ind_id = b.fdc_ind_id
        AND exists ( SELECT 1 FROM avm_ind4model_ht c WHERE c.mid = a.mid AND c.indicator = b.svid||'_'||b.stepid||'_'||b.xstatistics)
        ",toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper,
        start.time, end.time, sprintf("%s_fdc_ind_bt", tolower(toolid))
    )
    rawdata <- dbGetQuery(con_psql.avm, sql)
    return (rawdata)
}


.psql_disconnectdb <- function() {
    on.exit(dbDisconnect(con_psql.avm, force = TRUE))
}


.read_midrdata <- function(mid) {
    # internal
    rdata <- sprintf("%s%s", PATH, mid)
    data <- lapply(rdata, function(x) mget(load(x)))
    return (data) 
}


.save_traing_x <- function(mids) {
    # internal
    mid.list <- list()
    for (i in c(1:length(mids))) {
        mid.list[sprintf("MID%s", i)] <- .read_midrdata(mids[i])
    }
    return (mid.list)
}


.get_midrdata_by_local <- function(start.time, end.time) {
    # timeformat %Y-%m-%d %H:%M:%S
    rdata.list <- list()
    start.time <- as.POSIXct(strptime(start.time, "%Y-%m-%d %H:%M:%S"))
    end.time <- as.POSIXct(strptime(end.time, "%Y-%m-%d %H:%M:%S"))

    for (f in list.files(PATH)) {
        file <- unlist(strsplit(f, '_', fixed= TRUE))[2]
        file <- unlist(strsplit(file, '.', fixed= TRUE))[1]
        f.time <- as.POSIXct(strptime(file, "%Y%m%d%H%M%S"))
        st.diff <- as.numeric(difftime(start.time, f.time, units='secs'))
        et.diff <- as.numeric(difftime(end.time, f.time, units='secs'))
        if (st.diff <= 0 & et.diff >= 0) {
            rdata.list <- c(rdata.list, f)
        }
    }
    return (rdata.list)
}


.get_midrdata_by_db <- function(toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
    start.time, end.time) {
    # timeformat %Y-%m-%d %H:%M:%S
    predict_X <- .get_predictx(toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
        start.time, end.time)
    mids <- unique(predict_X$mid)
    rdata.list <- lapply(mids, function(mid) {
        mid <- sprintf('%s.Rdata', mid)
    })
    return (rdata.list)
}


get_trainingx_by_local <- function(start.time, end.time) {
    mids <- .get_midrdata_by_local(start.time, end.time)
    mid.list <- .save_traing_x(mids)
    return (mid.list)
}


get_trainingx_by_db <- function(toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
    start.time, end.time) {
    mids <- .get_midrdata_by_db(toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
        start.time, end.time)
    mid.list <- .save_traing_x(mids)
    return (mid.list)
}


mid_mapping <- function(mids) {
    mid.key <- lapply(seq(mids), function(i) {sprintf('MID%s', i)})
    dict <- c(mid.key)
    names(dict) <- c(mids)
    return (dict)
}


get_predictx <- function(toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
    start.time, end.time) {
    predict_X <- .get_predictx(toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
        start.time, end.time)
    format.dcast <- formula("glassid ~ indicator")
    ds.ind.h <- dcast(predict_X, formula = format.dcast, fun.aggregate = mean, value.var = "xsummary_value")
    
    # build mid mapping table
    mids <- unique(predict_X$mid)
    mid.dict <- mid_mapping(mids)
    
    # remove duplicated and sort by predict_x
    gid.noduplicate <- predict_X[!duplicated(predict_X$glassid),] 
    NAME <- c()
    for (gid in ds.ind.h$glassid) {
        for (index in 1:nrow(gid.noduplicate)) {
            row <- gid.noduplicate[index,]
            if (gid == row$glassid) {
                NAME <- c(NAME, mid.dict[[row$mid]])
            }
        }
    }
    ds.ind.h <- cbind(NAME, ds.ind.h)
    return (ds.ind.h)
}


main <- function() {
    tryCatch({
        local <- get_trainingx_by_local('2017-09-21 23:00:00', '2017-09-24 03:00:00')
        db <- get_trainingx_by_db('CVDU01', 'P6|A5', 'UPAN120Q275A45|P-ANOA-A2-267X',
                                  'l2tfin_uniform', 0.1, 1000.0, '2017-09-21 23:00:00', '2017-09-24 03:00:00')
        predict.x <- get_predictx('CVDU01', 'P6|A5', 'UPAN120Q275A45|P-ANOA-A2-267X',
                                  'l2tfin_uniform', 0.1, '2017-09-21 23:00:00', '2017-09-24 03:00:00')
        ret <- list(predict = predict.x, local = local, db = db)
        return (ret)
    }, error <- function(e) {
        conditionMessage(e)
    }, finally <- {
        loginfo('Disable dbconnect')
        .psql_disconnectdb
    })
}

# For test
#predict.x <- get_predictx('CVDU01', 'P6|A5', 'UPAN120Q275A45|P-ANOA-A2-267X','l2tfin_uniform', 0, 0.1, '2017-09-21 23:00:00', '2017-09-24 03:00:00')

