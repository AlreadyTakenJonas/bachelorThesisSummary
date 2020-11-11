library(RHotStuff)
library(magrittr)

# Make sure the version of RHotStuff is compatible with the code
check.version("1.2.2")



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
# CALCULATE STOKES VECTORS
#

# Normalise data and compute stokes vectors for unmanipulated stokes vector of the laser
getStokes.from.metaData <- function(meta.elab) {
  # Extract tables from list
  meta.laser     <- meta.elab[[1]]
  meta.polariser <- meta.elab[[2]]
  
  # Normalise the data
  # Not that great normalisation, because the maximal laser power (meta.laser[1,2]) 
  # is only measured without the optical fiber
  meta.polariser$Y2 <- as.numeric(as.character(meta.polariser$Y2)) / as.numeric(as.character(meta.laser[1,2]))
  
  # Compute stokes vectors
  meta.stokes <- data.frame(S0 = meta.polariser[c(1,5),"Y2"]+meta.polariser[c(2,6),"Y2"],
                            S1 = meta.polariser[c(1,5),"Y2"]-meta.polariser[c(2,6),"Y2"],
                            S2 = meta.polariser[c(3,7),"Y2"]-meta.polariser[c(4,8),"Y2"]
  )
  meta.stokes <- list( PRE = data.frame(W = NA, 
                                        S0 = meta.polariser[c(1),"Y2"]+meta.polariser[c(2),"Y2"],
                                        S1 = meta.polariser[c(1),"Y2"]-meta.polariser[c(2),"Y2"],
                                        S2 = meta.polariser[c(3),"Y2"]-meta.polariser[c(4),"Y2"],
                                        I = NA),
                       POST = data.frame(W = NA, 
                                        S0 = meta.polariser[c(5),"Y2"]+meta.polariser[c(6),"Y2"],
                                        S1 = meta.polariser[c(5),"Y2"]-meta.polariser[c(6),"Y2"],
                                        S2 = meta.polariser[c(7),"Y2"]-meta.polariser[c(8),"Y2"],
                                        I = NA) 
                      )
  # Return result
  return(meta.stokes)
}
# Normalise data and compute stokes vectors for experimental data
getStokes.from.expData <- function(data.elab) {
  # Sort data.elab by position of the waveplate
  data.elab <- lapply(data.elab, function(table) table[order(table$X),])
  
  # Normalise the data by the position of the waveplate
  data <- lapply(data.elab, function(table) {
    data.frame( W    = table$X,
                PRE  = table$Y2/table$Y1,
                POST = table$Y4/table$Y3 )
  })
  
  # Compute the stokes vectors before and after the optical fiber
  # ASSUMPTION: S3 = 0
  # Make sure the stokes vectors were measured for the same positions of the wave plate
  if( !all(data[[1]]$W == data[[2]]$W) | !all(data[[1]]$W == data[[3]]$W) | !all(data[[1]]$W == data[[4]]$W) ) {
    stop("The wave plate positions don't match for all given tables.") 
  } else {
    # Calculate stokes vectors and the total laser intensity before and after the optical fiber
    stokes <- list( PRE = data.frame( W = data[[1]]$W,
                                      S0 = data[[1]]$PRE + data[[2]]$PRE,
                                      S1 = data[[1]]$PRE - data[[2]]$PRE,
                                      S2 = data[[3]]$PRE - data[[4]]$PRE,
                                      I  = sapply(data.elab, function(table) table$Y1) %>% rowMeans ),
                    POST = data.frame( W = data[[1]]$W,
                                       S0 = data[[1]]$POST + data[[2]]$POST,
                                       S1 = data[[1]]$POST - data[[2]]$POST,
                                       S2 = data[[3]]$POST - data[[4]]$POST,
                                       I  = sapply(data.elab, function(table) table$Y3) %>% rowMeans)
                    )
  }
  
  # Return the stokes vectors
  return(stokes)
}

# Normalise stokes vector and compute polarisation ratio and such shit
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
stokes      <- getStokes.from.expData(data.elab) %>% process.stokesVec
meta.stokes <- getStokes.from.metaData(meta.elab) %>% process.stokesVec

# TODO: CHECK POLARISATION RATIO <=1


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

