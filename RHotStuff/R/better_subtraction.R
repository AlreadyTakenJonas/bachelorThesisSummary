#' Calculates the smallest distance between two modular numbers
#' 
#' This function takes the difference b-a and returns the signed difference with the smallest absolute value in modulus base. 
#' The function will compute b mod base and a mod base before subtracting.
#' 
#' @param diff difference: (b mod base)-(a mod base)
#' @param base base of the modulus numbers a and b.
#' @return signed difference of b and a with the smallest possible absolute value in modulus base
#'
#' @export
better.subtraction <- function(diff, base=2*pi) {
  # Check for smaller distances for every element in vector
  diff <- sapply(diff, function(elem) {
    if      (elem > +base/2) elem <- elem-base
    else if (elem < -base/2) elem <- elem+base
    return(elem)
  })
  # Return result
  return(diff)
} 
