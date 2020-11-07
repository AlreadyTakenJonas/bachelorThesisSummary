require(RHotStuff)
require(magrittr)

# Check the version of RHotStuff
designedversion <- "1.1.0"
if (packageVersion("RHotStuff")!=designedversion) {
  warning("VERSION MISMATCH RHOTSTUFF")
  warning(paste0("This script was designed for RHotStuff version ", designedversion, 
                 ", but version ", packageVersion("RHotStuff"), 
                 " is installed. Make sure the versions are compatible"))
}



# Get data from elab
data.elab <- GET.elabftw.bycaption(58, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                    func=function(x) qmean(x[,4], 0.8),
                                                                    header=T, skip=14, sep=";")

#
# CALCULATE STOKES VECTORS
#
# Normalise the data
data <- lapply(data.elab, function(table) {
  data.frame( W    = table$X,
              PRE  = table$Y2/table$Y1,
              POST = table$Y4/table$Y3 )
})

# ASSUMPTION: S3 = 0
# Make sure the stokes vectors were measured for the same positions of the wave plate
if( !all(data[[1]]$W == data[[2]]$W) | !all(data[[1]]$W == data[[3]]$W) | !all(data[[1]]$W == data[[4]]$W) ) {
  stop("The wave plate positions don't match for all given tables.") 
} else {
  # Calculate stokes vectors
  stokes <- data.frame( W = data[[1]]$W,
                        PRE.S0 = data[[1]]$PRE + data[[2]]$PRE,
                        PRE.S1 = data[[1]]$PRE - data[[2]]$PRE,
                        PRE.S2 = data[[3]]$PRE - data[[4]]$PRE,
                        POST.S0 = data[[1]]$POST + data[[2]]$POST,
                        POST.S1 = data[[1]]$POST - data[[2]]$POST,
                        POST.S2 = data[[3]]$POST - data[[4]]$POST
                        )
}

# Normalise stokes vectors
stokes[,c("PRE.S0","PRE.S1","PRE.S2")] <- stokes[,c("PRE.S0","PRE.S1","PRE.S2")]/stokes$PRE.S0
stokes[,c("POST.S0","POST.S1","POST.S2")] <- stokes[,c("POST.S0","POST.S1","POST.S2")]/stokes$POST.S0

# Compute polarisation ratio
stokes$PRE.polarisation <- (stokes$PRE.S1^2 + stokes$PRE.S2^2)/stokes$PRE.S0
stokes$POST.polarisation <- (stokes$POST.S1^2 + stokes$POST.S2^2)/stokes$POST.S0

# Compute polar stokes parameter
stokes$PRE.sigma <- better.acos(stokes$PRE.S0, stokes$PRE.S1, stokes$PRE.S2)
stokes$POST.sigma <- better.acos(stokes$POST.S0, stokes$POST.S1, stokes$POST.S2)

# How does the plane of polarisation change?
change.in.epsilon <- better.subtraction(stokes$POST.sigma - stokes$PRE.sigma)/2
plot(stokes$W, change.in.epsilon*180/pi,
     xaxt = "n",
     type = "h",
     main = "Änderung der Polarisationsebene durch die PM-Faser",
     ylab = "Unterschied in der Polarisationsebene / °",
     xlab = "Position der Wellenplatte / °")
axis(1, at = stokes$W)
abline(h=0)

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
                        PRE = data.elab[[1]]$Y1,
                        POST = data.elab[[1]]$Y3 )
intensity$LOSS <- intensity$POST/intensity$PRE

plot( intensity$W, intensity$LOSS*100,
      xaxt = "n",
      type = "h", 
      main = "Absorptionsverhalten der PM-Faser", 
      xlab = "Position Wellenplatte / °", 
      ylab = "Anteil des Lasers, der die Faser passiert / %")
axis(1, at = intensity$W)
