library(RHotStuff)
library(magrittr)

# Make sure the version of RHotStuff is compatible with the code
check.version("1.3.0")



# Get data from elab
data.elab.main <- GET.elabftw.bycaption(58, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                    func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                    header=T, skip=14, sep=";")
data.elab.nachtrag <- GET.elabftw.bycaption(67, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                                               func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                                               header=T, skip=14, sep=";")
data.elab <- lapply(seq_along(data.elab.main), function(index) {
  table1 <- data.elab.main[[index]]
  table2 <- data.elab.nachtrag[[index]]
  return( rbind.data.frame(table1, table2) )
})

meta.elab <- GET.elabftw.bycaption(67, caption="Metadaten", header=T, outputHTTP=T) %>% parseTable.elabftw(.,
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
    # !!! Keep in mind: This is bullshit, if the polarisation ratio is smaller than one!
    table$sigma <- better.acos(table$S0, table$S1, table$S2)
    
    # Polar electrical field coordinate
    # !!! Keep in mind: This is bullshit, if the polarisation ratio is smaller than one!
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

# Compute stokes vectors
stokes      <- getStokes.from.expData(data.elab)  %>% process.stokesVec
meta.stokes <- getStokes.from.metaData(meta.elab) %>% process.stokesVec

# TODO: CHECK POLARISATION RATIO <=1

#
# PLOT THAT SHIT
#

#
# How does the polarisation ratio change?
#
plot(stokes$change$W, stokes$change$change.in.polarisation*100,
     xaxt = 'n',
     type = "h",
     main = "Änderung des Polarisationsgrades durch die PM-Faser",
     xlab = "Position Wellenplatte / °",
     ylab = "realtive Änderung des Polarisationsgrades / %")
axis(1, at = stokes$W)
abline(h=0)
#
# Who much does the fiber reduce the laser intensity?
#
plot( stokes$change$W, stokes$change$change.in.intensity*100,
      xaxt = "n",
      type = "h", 
      main = "Absorptionsverhalten der PM-Faser", 
      xlab = "Position Wellenplatte / °", 
      ylab = "Anteil des Lasers, der die Faser passiert / %")
axis(1, at = stokes$change$W)

