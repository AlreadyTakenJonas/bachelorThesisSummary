#' Compute The Mean Of Data Not Considering Outliners
#' 
#' This function subsets a given vector of numbers according to the quantiles specified with intervalsize
#' and computes the mean of the subset. The intervalsize specifies the percentage of the data that should
#' be used to compute the mean. The quantiles are defined as half the intervalsize left and right of 50%.
#' Therefore the distribution of the subset will be centered at the median of the data vector. The interval
#' can be also centered at other points of the distribution.
#' 
#' For example: The intervalsize 0.5 will cause the function to compute the 25%- and the 75%-quantile and
#' get the mean of all the values in the data vector, that are between these quantiles.
#' 
#' @param vector Some vector with numbers.
#' @param intervalsize The amount of the original data that should be passed to mean. It may take values
#' between 0 and 1.
#' @param intervalcenter The center point of the interval specified by intervalsize. The default is the
#' median at 0.5. It may take values between 0 and 1.
#' @return The mean of the data without considering the outliner.
#'  
#' @importFrom magrittr %>%
#' @export
qmean <- function(vector, intervalsize=0.95, intervalcenter=0.5) {
  # Calculate the quantiles for the area covering intervalsize part of the data centered at the median
  interval <- quantile(vector, intervalcenter+c(-intervalsize, +intervalsize)/2, names=F, na.rm=T) %>% sort(.)
  # Subset the data vector with the quantiles and compute the mean
  vector[vector >= interval[1] & vector <= interval[2]] %>% mean(., rm.na=T) %>% return(.)
}