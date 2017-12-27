## AVM/RCA-apovshimben

### Descript: 
For AVM/RCA data clean, there are some function support query predict information from db and read .Rdata 

Normally engineer will prefer to query predict_data from db and with this information to read those nenecessary .Rdata.

But this module support not only get those .Rdata from db's information but also can with the time interval to condition, this module can help you do some test on client envrionment to read .Rdata and no need db support, Good luck.


### Usage:

First you shoud build a `env.R` file, this is a environment variable for DB and Rdata path.

```
# env.R

# Postgresql DB config.
psql.type <- "PostgreSQL"
psql.dbname <- "FDC"
psql.host <- ""
psql.port <- 5432
psql.username <- ""
psql.password <- ""

# Global var
PATH <- ".\\Batch_Output\\AVM_Model\\"
```


Then you can get rdata and predictx data like below:

```shell
# Loading .R file.
> source("avm.R")
   
# Get .Rdata with time interval, and return list data structure.
# get_traingingx_by_local(start.time, end.time)
> rdata <- get_trainingx_by_local('2017-12-05 00:00:00', '2017-12-05 14:00:00')

# Get .Rdata with db's information, and return list data structure.
# get_trainingx_by_db(toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, start.time, end.time)
# only  ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper is *float* type, other parametr is *str* type
> rdata <- get_trainingx_by_db('CVDU01', 'P6|A5', 'UPAN120Q275A45|P-ANOA-A2-267X','l2tfin_uniform', 0, 0.1, '2017-09-21 23:00:00', '2017-09-24 03:00:00')

# Get predict x
# get_predictx(toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, start.time, end.time)
# only  ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper is *float* type, other parametr is *str* type
> predict.x <- get_predictx('CVDU01', 'P6|A5', 'UPAN120Q275A45|P-ANOA-A2-267X','l2tfin_uniform', 0, 0.1, '2017-09-21 23:00:00', '2017-09-24 03:00:00')
```


### RCA Function

This is `root cause analysis` scheme for AVM, below will descript how to combine with RCA-apovshimben.
Which simply means, the `RCA_Functiom.R` need the data source get from RCA-apovshimben.


### Usage:

```shell
# Loading .R file.
source("avm.R")
source("RCA_function.R")

# get rdata with DB, if return NULL mean no data
rdata <- get_trainingx_by_db(toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, start.time, end.time)

# get predict.x with DB, if return NULL mean no data
predict.x <- get_predictx(toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, start.time, end.time)

# execute the RCA_Function, handle by ma
ret <- RCA_func(rdata, predict.x)
return (ret)
```

or you can just call the api, the benefit is already do some basic error handle

```shell
# Loading .R file.
source("rca_api.R")

rca <- get_rca(toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, 
    start.time, end.time)
```