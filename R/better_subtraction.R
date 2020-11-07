#' Calculates the smallest distance between two modular numbers
#' 
#' This function subtracts a from b (b-a) and returns the signed difference with the smallest absolute value in modulus base. The function will compute
#' b mod base and a mod base before subtracting.
#' 
#' @param b minuend
#' @param a subtrahend
#' @param base base of the modulus numbers a and b.
#' @return signed difference of b and a with the smallest possible absolute value in modulus base
#'
#' @export
better.subtraction <- function(b, a, base=2*pi) {
  # Get the difference of a mod base and b mod base
  diff <- b%%base - a%%base
  # Check for smaller distances for every element in vector
  diff <- sapply(diff, function(elem) {
    if      (elem > +base/2) elem <- base-elem
    else if (elem < -base/2) elem <- base+elem
    return(elem)
  })
  # Return result
  return(diff)
} 
