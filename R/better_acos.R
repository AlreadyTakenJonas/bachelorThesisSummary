#' Calculate The Inverse Of Cosine
#' 
#' This function is a wrapper around the standard acos function, which returns the corresponding angle between 0 and pi for any
#' output of the cosine function. This wrapper is able to return an angle between 0 and 2pi by looking at the sides of a right
#' angled triangle. The triangle angle this function returns is placed at the origin of a cartesian coordinate system and spans
#' between the hypotenuse and the adjacent side. The sign of the opposite side enables this function to return angles between 0
#' and 2pi.
#' 
#' @param hypotenuse Length of the a triangles hypotenuse
#' @param adjacent Signed length of an angles adjacent side. The sign describes the direction the triangle is pointing in a 
#' cartesian coordinate system
#' @param oppisite Signed length of an angles oppisite side. The sign describes the direction the triangle is pointing in a 
#' cartesian coordinate system
#' @return Angle between the x-axis and the hypotenuse of an arbitrary triangle
#' @export
better.acos <- function(hypotenuse, adjacent, oppisite) {
  # Make sure all parameters have the same length
  if (length(hypotenuse) != length(adjacent) || length(hypotenuse) != length(oppisite) ) warning('All three arguments must be the same length')
  
  # Get angle via standard acos
  angle <- acos(adjacent/hypotenuse)
  
  # Flip the angle over the x-axis if the opisite side is negative to get angles between 0 and 2*pi instead of 0 and pi
  # The sign of zero will be positive
  flip <- sign(oppisite)
  flip[flip == 0] <- 1
  angle <- magrittr::mod( flip * angle, 2*pi )
  
  angle
}
