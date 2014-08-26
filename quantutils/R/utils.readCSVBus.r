##' utils.readCSVBus
##'
##' utils.readCSVBus
##' @title utils.readCSVBus
##' @param jtids jtids
##' @param startDate startDate
##' @param endDate endDate
##' @param dataDir dataDir 
##' @param filePrefix filePrefix 
##' @param intervals intervals
##' @param vars vars
##' @param shift shift
##' @param region region
##' @param verbose verbose
##' @param outClass outClass 
##' @param fileNameDelimiter fileNameDelimiter 
##' @param ... 
##' @return data frame
##' @export
##' @author Weilin Lin
utils.readCSVBus <- function(jtids=NULL, startDate, endDate, dataDir, filePrefix="data", intervals=NULL, vars=NULL, shift=0, region=NULL, verbose=FALSE, outClass="data.frame", fileNameDelimiter="_", ...)
{
  dataDir   <- utils.expandPath(dataDir);
  files     <- list.files(dataDir, pattern=p(filePrefix, fileNameDelimiter, "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9].csv"));
  dates     <- sort(unique(utils.substring(files, "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]")));
  dates     <- date.convert(date.range(startDate,endDate,region=region),format="YYYYMMDD")

  if (missing(startDate))
    {
      startDate <- min(dates, na.rm=TRUE);
    }

  if (missing(endDate))
    {
      endDate <- max(dates, na.rm=TRUE);
    }
  
  startDate <- date.convert(startDate, format="YYYYMMDD");
  endDate   <- date.convert(endDate,   format="YYYYMMDD");

  utils.checkCond(startDate <= endDate, paste("startDate(", startDate, ") must be no later than endDate(", endDate, ")"));
  if (shift!=0)
    {
      utils.checkCond(!is.null(region), "Must specify region to shift date");
      tmpStartDate <- date.convert(date.toBusDate(startDate, region=region, shift=-shift), format="YYYYMMDD");
      tmpEndDate   <- date.convert(date.toBusDate(  endDate, region=region, shift=-shift), format="YYYYMMDD");
      dates        <- dates[which(dates>=tmpStartDate & dates<=tmpEndDate)];
    }
  else 
    dates          <- dates[which(dates>=startDate & dates<=endDate)];

  ## check dates
  if (length(dates) == 0)
    {
      cat (p("WARNING: No data avaiable from ", startDate, " to ", endDate, " at " , dataDir, " with filePrefix ", filePrefix, "\n"));
      return (NULL);
    }

  lst <- lapply(1:length(dates), function(i, dates, intervals=NULL, jtids, dataDir, filePrefix, vars, shift, region, verbose, ...)
                {
                  date <- dates[i];
                  cat(date);
                  file <- p(dataDir, "/", filePrefix, fileNameDelimiter, date, ".csv");
                  if (verbose) utils.log("Read data from", file);
                  data <- read.csv(file, ...);
		  if(is.null(data$jtid)){
			  data$jtid <- data$KEYID
		  }
                  if (!is.element("date", names(data))) data$date <- rep(date, nrow(data));
                  keys <- intersect(c("jtid", "date", "interval"), names(data));

                  if (!is.null(intervals) & "interval" %in% names(data))
                    data <- data[which(data$interval %in% intervals),];
                  
                  if (is.null(vars)) vars <- setdiff(names(data), keys)
                  else
                    {
                      noExistVars <- setdiff(vars, names(data));
                      utils.checkCond(length(noExistVars)==0, paste("Cannot find the following variables in data : ", paste(noExistVars, collapse=", ")));
                    }
                  if (!is.null(jtids))
                    {
                      utils.checkCond("jtid" %in% names(data), p("No column of jtid found in ", file));
                      noExistJtids <- setdiff(jtids, data$jtid);
                      if (length(noExistJtids)>0)
                        {
                          cat(length(noExistJtids), " jtids are not covered in", file, ":", ifelse(verbose, "", " Use verbose = True for more details!\n"));
                          if (verbose)  cat(paste(noExistJtids), "\n");
                        }
                      data    <- subset(data, jtid %in% jtids);
                      jtids   <- ordered(data$jtid, levels=jtids); ## make sure the df is properly sorted. 
                      data    <- data[order(jtids),];
                    }
                  if (shift!=0)
                    {
                      data$date <- date.convert(date.toBusDate(data$date, shift=shift, region=region),format="YYYYMMDD");
                    }
                  data <- data[, c(keys, vars), drop=FALSE];
                  cat("\b\b\b\b\b\b\b\b");
                  return(data);
                }, dates=dates, intervals=intervals, jtids=jtids, dataDir=dataDir, filePrefix=filePrefix, vars=vars, shift=shift, region=region, verbose=verbose);

  names(lst) <- date.convert(date.toBusDate(dates,shift=shift,region=region),format="YYYYMMDD");
  if (outClass=="data.frame")
    {
      data <- df.rbindList(lst);
      return(invisible(data));
    }
  else if (outClass=="array")
    {
      data      <- df.rbindList(lst);
      keyVars   <- intersect(c("jtid", "date", "interval"), names(data));
      valueVars <- setdiff(names(data)[sapply(data, is.numeric)], keyVars);
      data      <- df.dfToArray(data, keyCols = keyVars, valueCols=valueVars);
      return(invisible(data));
    }
  else if (outClass=="list")
    {
      return(invisible(lst));
    }
  else
    stop ("Unsupported outClass: ", outClass);
  cat("\n");
  invisible();
}
