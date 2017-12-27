## AVM/RCA-apovshimben

### Descript: 
For AVM/RCA data clean, there are some function support query predict information from db and read .Rdata 

Normally engineer will prefer to query predict_data from db and with this information to read those nenecessary .Rdata.

But this module support not only get those .Rdata from db's information but also can with the time interval to condition, this module can help you do some test on client envrionment to read .Rdata and no need db support, Good luck.


### Usage:

First you shoud build a `env.R` file, this is a environment variable for DB and Rdata path. if not setting both variable `psql_db_info` and `PATH` is necessary.

```
# ex:
psql_db_info$psql.dbname <- ''
psql_db_info$psql.host <- ''
psql_db_info$psql.port <- {numeric}
psql_db_info$psql.username <- ''
psql_db_info$psql.password <- ''

PATH <- '.\\Batch_Output\\AVM_Model\\'


# or other ex:
psql_db_info <- list(psql.dbname='', psql.host='', psql.port={numeric}, psql.username='', psql.password='')

PATH <- '.\\{path}\\'
```


Then you can get rdata and predictx data like below:

```shell
# Loading .R file.
> source("avm.R")

psql_db_info <- list(psql.dbname='', psql.host='', psql.port='{numeric}', psql.username='', psql.password='')

PATH <- .\\{path}\\''


# Get .Rdata with time interval, and return list data structure.
# get_traingingx_by_local(start.time, end.time)
> rdata <- get_trainingx_by_local('2017-12-05 00:00:00', '2017-12-05 14:00:00')

# Get .Rdata with db's information, and return list data structure.
# get_trainingx_by_db(psql_db_info, toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, start.time, end.time)
# only  ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper is *float* type, other parametr is *str* type
> rdata <- get_trainingx_by_db(psql_db_info, 'CVDU01', 'P6|A5', 'UPAN120Q275A45|P-ANOA-A2-267X','l2tfin_uniform', 0, 0.1, '2017-09-21 23:00:00', '2017-09-24 03:00:00')

# Get predict x
# get_predictx(psql_db_info, toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, start.time, end.time)
# only  ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper is *float* type, other parametr is *str* type
> predict.x <- get_predictx(psql_db_info, 'CVDU01', 'P6|A5', 'UPAN120Q275A45|P-ANOA-A2-267X','l2tfin_uniform', 0, 0.1, '2017-09-21 23:00:00', '2017-09-24 03:00:00')
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
rdata <- get_trainingx_by_db(psql_db_info, toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, start.time, end.time)

# get predict.x with DB, if return NULL mean no data
predict.x <- get_predictx(psql_db_info, toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, start.time, end.time)

# execute the RCA_Function, handle by ma
ret <- RCA_func(rdata, predict.x)
return (ret)
```

or you can just call the api, the benefit is already do some basic error handle

```shell
# Loading .R file.
source("rca_api.R")

rca <- get_rca(psql_db_info, toolid, chamber, recipe, ystatistics, ysummary_value_hat_lower, ysummary_value_hat_upper, start.time, end.time)
```