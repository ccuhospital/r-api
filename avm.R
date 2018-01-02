#FileName: 
# avm.R (RCA-apovshimben)
# 
#Author: 
# yc
#
#Descript: 
# For AVM/RCA data clean, there are some function support query predict information from db and read .Rdata 
# Normally engineer will prefer to query predict_data from db and with this information to read those nenecessary .Rdata.
# But this module support not only get those .Rdata from db's information but also can with the time interval to condition, this
# Can help you do some test on client envrionment to read .Rdata and no need db support, Good luck.
#
#Usage:
# Loading .R file.
#> source("avm.R")  
# Get .Rdata with time interval, and return list data structure.
# get_traingingx_by_local(start.time, end.time)
#> rdata <- get_trainingx_by_local('2017-12-05 00:00:00', '2017-12-05 14:00:00')
# Get .Rdata with db's information
# get_trainingx_by_db(psql_db_info, toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, start.time, end.time)
# only  ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper is *float* type, other parametr is *str* type
#> rdata <- get_trainingx_by_db(psql_db_info, 'CVDU01', 'P6|A5', 'UPAN120Q275A45|P-ANOA-A2-267X','l2tfin_uniform', 0, 0.1, '2017-09-21 23:00:00', '2017-09-24 03:00:00')
# Get predict x
# get_predictx(psql_db_info, toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, start.time, end.time)
# only  ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper is *float* type, other parametr is *str* type
#> predict.x <- get_predictx(psql_db_info, 'CVDU01', 'P6|A5', 'UPAN120Q275A45|P-ANOA-A2-267X','l2tfin_uniform', 0, 0.1, '2017-09-21 23:00:00', '2017-09-24 03:00:00')
#> single_predict.x <- get_single_predictx(psql_db_info, 'TL7CC0MAX', 'CVDU01', 'P2|A5', 'UPAN120Q275A45|P-ANOA-A2-267X', 'l2tfin_avg')

# load necessary package
library(RPostgreSQL)
library(reshape2)
library(logging)


# setting logging
logReset()
basicConfig(level = 'FINEST')


oldw <- getOption("warn")
options(warn = 1)


# load necessary function
if(file.exists("env.R")) {
    source("env.R")
    # DB connect
    psql_db_info <- list(psql.dbname=psql.dbname, psql.host=psql.host, 
        psql.port=psql.port, psql.username=psql.username, psql.password=psql.password)
} else {
    psql_db_info <- list(psql.dbname='', psql.host='', psql.port='', psql.username='', psql.password='')
    PATH <- ''
    logwarn(
    "Not exist env.R Please set both variables 'psql_db_info' and 'PATH' first.
    ex:
    psql_db_info$psql.dbname <- ''
    psql_db_info$psql.host <- ''
    psql_db_info$psql.port <- {numeric}
    psql_db_info$psql.username <- ''
    psql_db_info$psql.password <- ''
    PATH <- '.\\Batch_Output\\AVM_Model\\'

    ex:
    psql_db_info <- list(psql.dbname='', psql.host='', 
    psql.port='{numeric}', psql.username='', psql.password=''), 
    PATH <- '.\\Batch_Output\\AVM_Model\\'
    ")
}


.get_predictx <- function(psql_db_info, toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
    start.time, end.time) {
    drv_psql.avm <- dbDriver("PostgreSQL")
    con_psql.avm <- dbConnect(drv_psql.avm,
        dbname = psql_db_info$psql.dbname, host = psql_db_info$psql.host,
        port = psql_db_info$psql.port, user = psql_db_info$psql.username,
        password = psql_db_info$psql.password)

    sql <- sprintf(
        "
        WITH candidate_info AS (
            SELECT 
                glassid,
                ysummary_value_hat,
                mid,
                split_part(fdc_ind_id, '|', 1) as fdc_ind_id
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
        ),
        indicator_info AS (
            SELECT distinct indicator FROM avm_ind4model_ht t WHERE t.mid in ( SELECT distinct mid FROM candidate_info )
        )
        SELECT
            a.glassid,
            a.ysummary_value_hat,
            b.stepid,
            c.indicator,
            b.xsummary_value,
            b.fdc_ind_id,
            a.mid
        FROM    
            candidate_info a,
            %s b,
            indicator_info c
        WHERE 1=1
        AND a.fdc_ind_id::integer = b.fdc_ind_id::integer
        AND b.svid||'_'||b.stepid||'_'||b.xstatistics = c.indicator
        ORDER BY a.mid
        ",toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper,
        start.time, end.time, sprintf("%s_fdc_ind_bt", tolower(toolid))
    )
    rawdata <- dbGetQuery(con_psql.avm, sql)
    .psql_disconnectdb(con_psql.avm)
    return (rawdata)
}


.replace_glassid <- function(glassid) {
    #gids <- strsplit(glassid, ',')
    gids <- glassid
    for (index in 1:length(gids)) {
        # remove empty
        gid <- gsub("^\\s+|\\s+$", "", gids[index])
        if (index == 1) {
            glassid <- sprintf("'%s'", gid)
        } else {
            glassid <- sprintf("%s,'%s'", glassid, gid)
        }
    }
    return (glassid)
}


.get_single_predictx <- function(psql_db_info, glassid, toolid, chamber, recipe, ystatistics) {
    if (is.character(glassid)) {
        if (length(glassid) == 1) {
            glassid <- as.vector(strsplit(glassid, ',')[[1]])
        }
        glassid <- strsplit(glassid, ',')
        glassid <- .replace_glassid(glassid)
    } else if(is.list(glassid)) {
        glassid <- sapply(glassid, paste0, collapse="") # unlist(glassid), paste(glassid)??
        glassid <- strsplit(glassid, ',')
        glassid <- .replace_glassid(glassid)
    } else {
        stop(
        "glassid type error, should be vector, list or string(character)
        Input:: ", glassid, " Error type:: ", class(glassid), "\n
        ex: c('TL7CC0MAX', 'TL79M07AF'), 
             list('TL7CC0MAX', 'TL79M07AF'), 
             'TL7CC0MAX'."
        )
    }

    drv_psql.avm <- dbDriver("PostgreSQL")
    con_psql.avm <- dbConnect(drv_psql.avm,
        dbname = psql_db_info$psql.dbname, host = psql_db_info$psql.host,
        port = psql_db_info$psql.port, user = psql_db_info$psql.username,
        password = psql_db_info$psql.password)

    sql <- sprintf(
        "
        WITH candidate_info AS (
            SELECT 
                glassid,
                ysummary_value_hat,
                mid,
                split_part(fdc_ind_id, '|', 1) as fdc_ind_id
            FROM
                avm_predict_summary 
            WHERE 1=1
            AND glassid in (%s)   
            AND toolid = '%s'
            AND chamber = '%s'
            AND recipe = '%s'
            AND ystatistics = '%s'
        ),
        indicator_info AS (
            SELECT distinct indicator FROM avm_ind4model_ht t WHERE t.mid in ( SELECT distinct mid FROM candidate_info )
        )
        SELECT
            a.glassid,
            a.ysummary_value_hat,
            b.stepid,
            c.indicator,
            b.xsummary_value,
            b.fdc_ind_id,
            a.mid
        FROM    
            candidate_info a,
            %s b,
            indicator_info c
        WHERE 1=1
        AND a.fdc_ind_id::integer = b.fdc_ind_id::integer
        AND b.svid||'_'||b.stepid||'_'||b.xstatistics = c.indicator
        ORDER BY a.mid
        ",glassid, toolid, chamber, recipe, ystatistics,
        sprintf("%s_fdc_ind_bt", tolower(toolid))
    )
    rawdata <- dbGetQuery(con_psql.avm, sql)
    .psql_disconnectdb(con_psql.avm)
    return (rawdata)
}


.psql_disconnectdb <- function(con_psql.avm) {
    on.exit(dbDisconnect(con_psql.avm, force = TRUE))
}


.read_midrdata <- function(mid) {
    rdata <- sprintf("%s%s", PATH, mid)
    data <- lapply(rdata, function(x) mget(load(x)))
    return (data)
}


.save_traing_x <- function(mids) {
    mid.list <- list()
    for (i in c(1:length(mids))) {
        mid.list[sprintf("MID%s", i)] <- .read_midrdata(mids[i])
    }
    return (mid.list)
}


.get_midrdata_by_local <- function(start.time, end.time) {
    # type: string imeformat %Y-%m-%d %H:%M:%S
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


.get_rdata_list <- function(predict_X) {
    mids <- unique(predict_X$mid)
    rdata.list <- lapply(mids, function(mid) {
        mid <- sprintf('%s.Rdata', mid)
    })
    return (rdata.list)
}


.get_midrdata_by_db <- function(psql_db_info, toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
    start.time, end.time) {
    # timeformat %Y-%m-%d %H:%M:%S
    predict_X <- .get_predictx(psql_db_info, toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
        start.time, end.time)
    if (nrow(predict_X) == 0) {
        return ()
    }

    rdata.list <- .get_rdata_list(predict_X)
    return (rdata.list)
}


.get_single_midrdata_by_db <- function(psql_db_info, glassid, toolid, chamber, recipe, ystatistics) {
    # timeformat %Y-%m-%d %H:%M:%S
    predict_X <- .get_single_predictx(psql_db_info, glassid, toolid, chamber, recipe, ystatistics)
    if (nrow(predict_X) == 0) {
        return ()
    }
    
    rdata.list <- .get_rdata_list(predict_X)
    return (rdata.list)
}


get_trainingx_by_local <- function(start.time, end.time) {
    # type: start.time: string timeformat %Y-%m-%d %H:%M:%S
    # type: end.time: string timeformat %Y-%m-%d %H:%M:%S
    # rtype: list()

    mids <- .get_midrdata_by_local(start.time, end.time)
    mid.list <- .save_traing_x(mids)
    return (mid.list)
}


get_trainingx_by_db <- function(psql_db_info, toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
    start.time, end.time) {
    # type: toolid: string
    # type: chamber: string
    # type: recipe: string
    # type: ystatistics: string
    # type: ysummary_value_hat_lower: float
    # type: ysummary_value_hat_upper: float
    # type: start.time: string timeformat %Y-%m-%d %H:%M:%S
    # type: end.time: string timeformat %Y-%m-%d %H:%M:%S
    # rtype: list()

    mids <- .get_midrdata_by_db(psql_db_info, toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
        start.time, end.time)
    if (is.null(mids)) {
        loginfo('No data in this conditional.')
        return ()
    }
    mid.list <- .save_traing_x(mids)
    return (mid.list)
}


get_single_trainingx_by_db <- function(psql_db_info, glassid, toolid, chamber, recipe, ystatistics) {
    # type: glassid: string, vector or list
    # type: toolid: string
    # type: chamber: string
    # type: recipe: string
    # type: ystatistics: string
    # rtype: list()

    mids <- .get_single_midrdata_by_db(psql_db_info, glassid, toolid, chamber, recipe, ystatistics)
    if (is.null(mids)) {
        loginfo('No data in this conditional.')
        return ()
    }
    mid.list <- .save_traing_x(mids)
    return (mid.list)
}


mid_mapping <- function(mids) {
    # type mids: list()
    # rtype: list()
    mid.key <- lapply(seq(mids), function(i) {sprintf('MID%s', i)})
    dict <- c(mid.key)
    names(dict) <- c(mids)
    return (dict)
}


.predictx_to_dsind <- function(predict_X) {
    # type: predict_X: data.frame
    
    format.dcast <- formula("glassid ~ indicator")
    ds.ind.h <- dcast(predict_X, formula = format.dcast, fun.aggregate = mean, value.var = "xsummary_value")
    
    # build mid mapping table
    mids <- unique(predict_X$mid)
    mid.dict <- mid_mapping(mids)
    
    # remove duplicated and sort by predict_x
    gid.noduplicate <- predict_X[!duplicated(predict_X$glassid),]
    NAME <- c()
    ysummary_value_hat <- c()
    for (index in 1:nrow(gid.noduplicate)) {
        for (gid in ds.ind.h$glassid) {
            row <- gid.noduplicate[index,]
            if (gid == row$glassid) {
                NAME <- c(NAME, mid.dict[[row$mid]])
                ysummary_value_hat <- c(ysummary_value_hat, row$ysummary_value_hat)
            }
        }
    }
    ds.ind.h <- cbind(ysummary_value_hat, ds.ind.h)
    ds.ind.h <- cbind(NAME, ds.ind.h)
    return (ds.ind.h)
}


get_predictx <- function(psql_db_info, toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
    start.time, end.time) {
    # type: toolid: string
    # type: chamber: string
    # type: recipe: string
    # type: ystatistics: string
    # type: ysummary_value_hat_lower: float
    # type: ysummary_value_hat_upper: float
    # type: start.time: string timeformat %Y-%m-%d %H:%M:%S
    # type: end.time: string timeformat %Y-%m-%d %H:%M:%S
    # rtype: list()

    predict_X <- .get_predictx(psql_db_info, toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
        start.time, end.time)
    if (nrow(predict_X) == 0) {
        loginfo('No data in this conditional.')
        return ()
    }
    ds.ind.h <- .predictx_to_dsind(predict_X)
    return (ds.ind.h)
}


get_single_predictx <- function(psql_db_info, glassid, toolid, chamber, recipe, ystatistics) {
    # type: glassid: string, vector or list
    # type: toolid: string
    # type: chamber: string
    # type: recipe: string
    # type: ystatistics: string
    # rtype: list()

    predict_X <- .get_single_predictx(psql_db_info, glassid, toolid, chamber, recipe, ystatistics)
    if (nrow(predict_X) == 0) {
        loginfo('No data in this conditional.')
        return ()
    }
    ds.ind.h <- .predictx_to_dsind(predict_X)
    return (ds.ind.h)
}



# For test -- mutiple
# > rdata <- get_trainingx_by_db(psql_db_info, 'CVDU01', 'P6|A5', 'UPAN120Q275A45|P-ANOA-A2-267X','l2tfin_uniform', 0, 0.1, '2017-09-21 23:00:00', '2017-09-24 03:00:00')
# > predict.x <- get_predictx(psql_db_info, 'CVDU01', 'P6|A5', 'UPAN120Q275A45|P-ANOA-A2-267X','l2tfin_uniform', 0, 0.1, '2017-09-21 23:00:00', '2017-09-24 03:00:00')
# > predict.x <- get_predictx(psql_db_info, 'CVDU02', 'P2|A5', 'UPAN120Q275A45|UP-ANOA-A2-267','l2tfin_avg', 2000, 6000, '2017-12-06 10:48:21', '2017-12-06 17:23:28')

# For test -- single
# > rdata <- get_single_trainingx_by_db(psql_db_info, 'TL7CC0MAX', 'CVDU01', 'P2|A5', 'UPAN120Q275A45|P-ANOA-A2-267X', 'l2tfin_avg')

#character, mutiple character
# > single.predict.x <- get_single_predictx(psql_db_info, 'TL7CC0MAX', 'CVDU01', 'P2|A5', 'UPAN120Q275A45|P-ANOA-A2-267X', 'l2tfin_avg')
# > single.predict.x <- get_single_predictx(psql_db_info, 'TL7CC0MAX,TL79M07AF', 'CVDU01', 'P2|A5', 'UPAN120Q275A45|P-ANOA-A2-267X', 'l2tfin_avg')
# > single.predict.x <- get_single_predictx(psql_db_info, 'TL79M3FBC,TL7990DAC', 'CVDU01', 'P6|A5', 'UPAN120Q275A45|P-ANOA-A2-267X', 'l2tfin_uniform')

#list
# > single.predict.x <- get_single_predictx(psql_db_info, list('TL7CC0MAX'), 'CVDU01', 'P2|A5', 'UPAN120Q275A45|P-ANOA-A2-267X', 'l2tfin_avg')
# > single.predict.x <- get_single_predictx(psql_db_info, list('TL7CC0MAX','TL79M07AF'), 'CVDU01', 'P2|A5', 'UPAN120Q275A45|P-ANOA-A2-267X', 'l2tfin_avg')

#vector test set1
# > single.predict.x <- get_single_predictx(psql_db_info, c('TL7CC0MAX'), 'CVDU01', 'P2|A5', 'UPAN120Q275A45|P-ANOA-A2-267X', 'l2tfin_avg')
# > single.predict.x <- get_single_predictx(psql_db_info, c('TL7CC0MAX', 'TL79M07AF'), 'CVDU01', 'P2|A5', 'UPAN120Q275A45|P-ANOA-A2-267X', 'l2tfin_avg')
# > single.predict.x <- get_single_predictx(psql_db_info, c('TL7CC0MAX,TL79M07AF'), 'CVDU01', 'P2|A5', 'UPAN120Q275A45|P-ANOA-A2-267X', 'l2tfin_avg')
#vector test set2
# > single.predict.x <- get_single_predictx(psql_db_info, c('TL79M3FBC', 'TL7990DAC'), 'CVDU01', 'P6|A5', 'UPAN120Q275A45|P-ANOA-A2-267X', 'l2tfin_uniform')
# > single.predict.x <- get_single_predictx(psql_db_info, c('TL79M3FBC,TL7990DAC'), 'CVDU01', 'P6|A5', 'UPAN120Q275A45|P-ANOA-A2-267X', 'l2tfin_uniform')