## AVM/RCA-apovshimben

### Descript: 
For AVM/RCA data clean, there are some function support query predict information from db and read .Rdata 

Normally engineer will prefer to query predict_data from db and with this information to read those nenecessary .Rdata.

Buy this module support not only get those .Rdata from db's information but also can with the time interval to condition, this module can help you do some test on client envrionment to read .Rdata and no need db support, Good luck.


### Usage:

```shell
# Loading .R file.
> source("avm.R")
   
# Get .Rdata with time interval, and return list data structure.
# get_traingingx_by_local(start.time, end.time)
> rdata <- get_trainingx_by_local('2017-12-05 00:00:00', '2017-12-05 14:00:00')

# Get .Rdata with db's information
# get_trainingx_by_db(toolid, chamber, recipe, ystatistics, ysummary_value_hat, ysummary_value_hat_upper, start.time, end.time)
> rdata <- get_trainingx_by_db('CVDU01', 'P6|A5', 'UPAN120Q275A45|P-ANOA-A2-267X','l2tfin_uniform', 0, 0.1, '2017-09-21 23:00:00', '2017-09-24 03:00:00')

# Get predict x
# get_predictx(toolid, chamber, recipe, ystatistics, ysummary_value_hat, ysummary_value_hat_upper, start.time, end.time)
> predict.x <- get_predictx('CVDU01', 'P6|A5', 'UPAN120Q275A45|P-ANOA-A2-267X','l2tfin_uniform', 0, 0.1, '2017-09-21 23:00:00', '2017-09-24 03:00:00')
```