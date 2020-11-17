library(RHotStuff)
library(magrittr)

# Make sure the version of RHotStuff is compatible with the code
check.version("1.4.0")


#
# CALCULATE STOKES VECTORS AND THEIR PROPERTIES
#
# Normalise stokes vector and compute polarisation ratio and such shit
# ASSUMPTION: S3 = 0
process.stokesVec <- function(stokes) {
  # Compute properties of stokes vectors and normalise -> polarisation ratio, ...
  stokes <- lapply(stokes, function(table) { 
    # Normalise stokes vectors
    table[,c("S0", "S1", "S2")] <- table[,c("S0", "S1", "S2")] / table$S0
    
    # Polarisation ratio
    table$polarisation <- sqrt(table$S1^2 + table$S2^2) / table$S0
    
    # Polar stokes angle
    table$sigma <- better.acos( table$polarisation*table$S0, table$S1, table$S2)
    
    # Polar electrical field coordinate
    # !!! Keep in mind: This may be bullshit, if the polarisation ratio is smaller than one!
    # I'm to 90% sure that this conversion is also valid for partially polarised light
    table$epsilon <- table$sigma / 2
    
    # Return result
    return(table)
  })
  
  # CALCULATE CHANGE OF THE STOKES VECTORS PROPERTIES
  # Change in epsilon, change in polarisation, change in laser intensity
  stokes[["change"]]   <- data.frame("W"                      = stokes$PRE$W,
                                     # How much gets the plane of polarisation rotated?
                                     # Calculate the difference as smallest signed distance between two modular numbers
                                     # !!! Keep in mind: This is bullshit, if the polarisation ratio is smaller than one!
                                     "mod.change.in.epsilon"  = better.subtraction(stokes$POST$epsilon - stokes$PRE$epsilon, base=  pi),
                                     "mod.change.in.sigma"    = better.subtraction(stokes$POST$sigma   - stokes$PRE$sigma  , base=2*pi),
                                     # How much does the polarisation ratio change?
                                     "change.in.polarisation" = stokes$POST$polarisation / stokes$PRE$polarisation - 1,
                                     # How much does the intensity of the light change?
                                     "change.in.intensity"    = stokes$POST$I / stokes$PRE$I
  )
  
  return(stokes)
  
}
#
# DO THE STATISTICS
#
# error.stokes contains the data for several identical measurements
# following function will therefore compute statistical properties 
# like sd or mean for every column of the tables
# !!! Keep in mind: The statistics for the angles sigma and epsilon are not done with modular functions
#                   The modular numbers sigma and epsilon will therefore have the wrong mean, variance, sd, ...
#                   In this case only the modular calculated difference can be trusted.
do.statistics <- function(error.stokes) {
  lapply(error.stokes, function(table) {
    stats.table <- data.frame( var  = sapply(table, var ),
                               sd   = sapply(table, sd  ),
                               mean = sapply(table, mean)
    )
    return(stats.table)
  }) %>% return
  
  
  # TODO: t-Test, Kruskal-Wallis-Test
}