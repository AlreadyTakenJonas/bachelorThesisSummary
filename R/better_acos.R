# Define the inverse of cosine in a way that it returns angles between 0 and 2*pi
better.acos <- function(hypotenuse, adjacent, opisite) {
  # Make sure all parameters have the same length
  if (length(hypotenuse) != length(adjacent) || length(hypotenuse) != length(opisite) ) warning('All three arguments must be the same length')
  
  # Get angle via standard acos
  angle <- acos(adjacent/hypotenuse)
  
  # Flip the angle over the x-axis if the opisite side is negative to get angles between 0 and 2*pi instead of 0 and pi
  # The sign of zero will be positive
  flip <- sign(opisite)
  flip[flip == 0] <- 1
  angle <- magrittr::mod( flip * angle, 2*pi )
  
  angle
}
