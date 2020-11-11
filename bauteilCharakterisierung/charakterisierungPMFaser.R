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
                                        S2 = meta.polariser[c(3),"Y2"]-meta.polariser[c(4),"Y2"] ),
                       POST = data.frame(W = NA, 
                                        S0 = meta.polariser[c(5),"Y2"]+meta.polariser[c(6),"Y2"],
                                        S1 = meta.polariser[c(5),"Y2"]-meta.polariser[c(6),"Y2"],
                                        S2 = meta.polariser[c(7),"Y2"]-meta.polariser[c(8),"Y2"] ) 
                      )
  # Return result
  return(meta.stokes)
}
# Normalise data and compute stokes vectors for experimental data
getStokes.from.expData <- function(data.elab) {
  # Normalise and sort the data by the position of the waveplate
  data <- lapply(data.elab, function(table) {
    data.frame( W    = table$X,
                PRE  = table$Y2/table$Y1,
                POST = table$Y4/table$Y3 ) %>% .[order(.$W),]
  })
  
  # Compute the stokes vectors before and after the optical fiber
  # ASSUMPTION: S3 = 0
  # Make sure the stokes vectors were measured for the same positions of the wave plate
  if( !all(data[[1]]$W == data[[2]]$W) | !all(data[[1]]$W == data[[3]]$W) | !all(data[[1]]$W == data[[4]]$W) ) {
    stop("The wave plate positions don't match for all given tables.") 
  } else {
    # Calculate stokes vectors
    stokes <- list( PRE = data.frame( W = data[[1]]$W,
                                      S0 = data[[1]]$PRE + data[[2]]$PRE,
                                      S1 = data[[1]]$PRE - data[[2]]$PRE,
                                      S2 = data[[3]]$PRE - data[[4]]$PRE ),
                    POST = data.frame( W = data[[1]]$W,
                                       S0 = data[[1]]$POST + data[[2]]$POST,
                                       S1 = data[[1]]$POST - data[[2]]$POST,
                                       S2 = data[[3]]$POST - data[[4]]$POST )
                    )
  }
  
  # Return the stokes vectors
  return(stokes)
}

# Compute normalised stokes vectors
stokes      <- getStokes.from.expData(data.elab)
ssmeta.stokes <- getStokes.from.metaData(meta.elab)

# Normalise stokes vector and compute polarisation ratio and such shit
process.stokesVec <- function(stokes) {
  # Compute properties of stokes vectors and normalise -> polarisation ratio, ...
  stokes <- lapply(stokes, function(table) { 
    # Normalise stokes vectors
    table[,c("S0", "S1", "S2")] <- table[,c("S0", "S1", "S2")] / table$S0
    
    # Polarisation ratio
    table$polarisation <- sqrt(table$S1^2 + table$S2^2) / table$S0
    
    # Polar stokes angle
    table$sigma <- better.acos(table$S0, table$S1, table$S2)
    table$epsilon <- table$sigma / 2
    
    # Return result
    return(table)
  })
  
  # Change in epsilon, change in polarisation, change in laser intensity -> new table in list for all the changes?
  
  return(stokes)
  
}

# Normalise stokes vectors
#stokes[,c("PRE.S0","PRE.S1","PRE.S2")] <- stokes[,c("PRE.S0","PRE.S1","PRE.S2")]/stokes$PRE.S0
#stokes[,c("POST.S0","POST.S1","POST.S2")] <- stokes[,c("POST.S0","POST.S1","POST.S2")]/stokes$POST.S0
#meta.stokes <- meta.stokes/meta.stokes$S0

# Compute polarisation ratio
#stokes$PRE.polarisation <- sqrt(stokes$PRE.S1^2 + stokes$PRE.S2^2)/stokes$PRE.S0
#stokes$POST.polarisation <- sqrt(stokes$POST.S1^2 + stokes$POST.S2^2)/stokes$POST.S0
#meta.stokes$polarisation <- sqrt(meta.stokes$S1^2 + meta.stokes$S2^2)/meta.stokes$S0

# Compute polar stokes parameter
#stokes$PRE.sigma <- better.acos(stokes$PRE.S0, stokes$PRE.S1, stokes$PRE.S2)
#stokes$POST.sigma <- better.acos(stokes$POST.S0, stokes$POST.S1, stokes$POST.S2)
#meta.stokes$sigma <- better.acos(meta.stokes$S0, meta.stokes$S1, meta.stokes$S2)

# How does the plane of polarisation change?
mod.change.in.epsilon <- better.subtraction(stokes$POST.sigma - stokes$PRE.sigma)/2
plot(stokes$W, mod.change.in.epsilon*180/pi,
     xaxt = "n",
     type = "h",
     main = "Änderung der Polarisationsebene durch die PM-Faser",
     sub  = "minimal modular distance method",
     ylab = "Unterschied in der Polarisationsebene / °",
     xlab = "Position der Wellenplatte / °")
axis(1, at = stokes$W)
abline(h=0)

#simp.change.in.epsilon <- (stokes$POST.sigma - stokes$PRE.sigma)/2
#plot(stokes$W, simp.change.in.epsilon*180/pi,
#     xaxt = "n",
#     type = "h",
#     main = "Änderung der Polarisationsebene durch die PM-Faser",
#     sub  = "simple subtraction method",
#     ylab = "Unterschied in der Polarisationsebene / °",
#     xlab = "Position der Wellenplatte / °")
#axis(1, at = stokes$W)
#abline(h=0)

#plot(stokes$PRE.sigma*180/2/pi, simp.change.in.epsilon*180/pi,
#     xaxt = "n",
#     main = "Die Rotation der Polarisationsebene in Abängigkeit der initialen Polarisation",
#     sub  = "simple subtraction method",
#     xlab = expression("Orientierung der Polarisationsebene "*epsilon*" / °"),
#     ylab = expression("Änderung des Winkels "*epsilon*" / °") )
#axis(1, at = seq(from=0, to=180, by=10) )
#abline(h=0)

plot(stokes$PRE.sigma*180/2/pi, mod.change.in.epsilon*180/pi,
     xaxt = "n",
     main = "Die Rotation der Polarisationsebene in Abängigkeit der initialen Polarisation",
     sub  = "minimal modular distance method",
     xlab = expression("Orientierung der Polarisationsebene "~epsilon*" / °"),
     ylab = expression("Änderung des Winkels "~epsilon*" / °") )
axis(1, at = seq(from=0, to=180, by=5) )
abline(h=0)

# How is the polarisation plane initially oriented?
plot(stokes$W, stokes$PRE.sigma*180/pi/2,
     xaxt = "n",
     type = "l",
     main = "Orientierung der Polarisationsebene nach der Wellenplatte",
     xlab = "Position der Wellenplatte / °",
     ylab = expression("Orientierung der Polarisationsebene "~epsilon*" / °") )
axis(1, at = stokes$W)

# How does the polarisation ratio change?
change.in.polarisation <- stokes$POST.polarisation / stokes$PRE.polarisation - 1
plot(stokes$W, change.in.polarisation*100,
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
intensity <- data.frame(W = data.elab[[1]]$X,
                        PRE.I = data.elab[[1]]$Y1,
                        POST.I = data.elab[[1]]$Y3 )
intensity$LOSS.I <- intensity$POST.I/intensity$PRE.I

plot( intensity$W, intensity$LOSS*100,
      xaxt = "n",
      type = "h", 
      main = "Absorptionsverhalten der PM-Faser", 
      xlab = "Position Wellenplatte / °", 
      ylab = "Anteil des Lasers, der die Faser passiert / %")
axis(1, at = intensity$W)
