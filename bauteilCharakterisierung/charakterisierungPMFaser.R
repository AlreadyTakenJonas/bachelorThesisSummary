library(RHotStuff)
library(magrittr)

# Make sure the version of RHotStuff is compatible with the code
check.version("1.4.0")



# Get experimental data from elab
# The experimental data will be combined from three different experiments
data.elab <- lapply(c(58, 67, 68), function(experimentID) {
  GET.elabftw.bycaption(experimentID, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                           func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                           header=T, skip=14, sep=";")
}) %>% better.rbind(., sort.byrow=1)

# Fetch the meta data of one of the experiments
meta.67.elab <- GET.elabftw.bycaption(67, caption="Metadaten", header=T, outputHTTP=T) %>% parseTable.elabftw(.,
                        func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                        header=T, skip=14, sep=";")

# Get the measurements for the error estimation
error.elab <- GET.elabftw.bycaption(66, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                           func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                           header=T, skip=14, sep=";")


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
  print(stokes)
  
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
# Compute stokes vectors
data.stokes    <- getStokes.from.expData(data.elab)     %>% process.stokesVec
meta.67.stokes <- getStokes.from.metaData(meta.67.elab) %>% process.stokesVec
error.stokes   <- getStokes.from.expData(error.elab)    %>% process.stokesVec

# TODO: CHECK POLARISATION RATIO <=1

#
# DO THE STATISTICS
#
# error.stokes contains the data for several identical measurements
# following function will therefore compute statistical properties 
# like sd or mean for every column of the tables
# !!! Keep in mind: The statistics for the angles sigma and epsilon are not done with modular functions
#                   The modular numbers sigma and epsilon will therefore have the wrong mean, variance, sd, ...
#                   In this case only the modular calculated difference can be trusted.
error.stats <- lapply(error.stokes, function(table) {
  stats.table <- data.frame( var  = sapply(table, var ),
                             sd   = sapply(table, sd  ),
                             mean = sapply(table, mean)
                            )
  return(stats.table)
})

# TODO: t-Test, Kruskal-Wallis-Test

#
# PLOT THAT SHIT
#
# How does the polarisation ratio change?
plot(stokes$change$W, stokes$change$change.in.polarisation*100,
     xaxt = 'n',
     type = "h",
     main = "Änderung des Polarisationsgrades durch die PM-Faser",
     xlab = "Position Wellenplatte / °",
     ylab = "realtive Änderung des Polarisationsgrades / %")
axis(1, at = stokes$W)
abline(h=0)

# Who much does the fiber reduce the laser intensity?
plot( stokes$change$W, stokes$change$change.in.intensity*100,
      xaxt = "n",
      type = "h", 
      main = "Absorptionsverhalten der PM-Faser", 
      xlab = "Position Wellenplatte / °", 
      ylab = "Anteil des Lasers, der die Faser passiert / %")
axis(1, at = stokes$change$W)

