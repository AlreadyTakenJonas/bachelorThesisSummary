#
# Get some libraries and functions used for characterising optical fibers and plotting stuff
#
source("bauteilCharakterisierung/charakterisierungFaser_utilities.R")


# F1 : POLARISATION-MAINTAING-FIBER


#
# FETCH data from elabftw
#
F1.data.elab <- lapply(c(58, 67, 68), function(experimentID) {
  GET.elabftw.bycaption(experimentID, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                                     func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                                     header=T, skip=14, sep=";")
}) %>% better.rbind(., sort.byrow=1)


# Fetch the meta data of one of the experiments
F1.meta.elab <- GET.elabftw.bycaption(67, caption="Metadaten", header=T, outputHTTP=T) %>% parseTable.elabftw(.,
                                                                                            func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                                            header=T, skip=14, sep=";")

# Get the measurements for the error estimation
F1.error.elab <- GET.elabftw.bycaption(66, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                                          func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                                          header=T, skip=14, sep=";")

#
# COMPUTE stokes vectors and do statistics on the error estimations
#
F1.data.stokes <- getStokes.from.expData(F1.data.elab)  %>% process.stokesVec
F1.meta.stokes <- getStokes.from.metaData(F1.meta.elab) %>% process.stokesVec
F1.error.stats <- getStokes.from.expData(F1.error.elab) %>% process.stokesVec %>% do.statistics

# COMPUTE the mueller matrix of the fiber, using the stokes vectors measured before and after the fiber
F1.muellermatrix <- muellermatrix(F1.data.stokes)
# PREDICT the stokes vectors after the fiber from the mueller matrix and the stokes vectors measured before the fiber
F1.data.stokes   <- predict.stokesVec(F1.data.stokes, F1.muellermatrix)

#
# PLOT THAT SHIT
#
# How does the polarisation ratio change relative to the initial polarisation ratio?
plot.polarisation.change(data  = F1.data.stokes, 
                         title = expression(bold("The Depolarising Behaviour Of An Optical PM-Fiber (F1)") )
)
# COMPARING POLARISATION RATIOS before and after interacting with the fiber
plot.polarisation(data       = F1.data.stokes, 
                  statistics = F1.error.stats,
                  title      = expression(bold("The Effect Of An Optical PM-Fiber (F1) On The Polarisation Ratio "*Pi))
)

# CHANGE in LASER POWER due to optical fiber
plot.intensity.change(data  = F1.data.stokes,
                      title = expression(bold("The Transmittance Of An Optical PM-Fiber (F1)"))
)
# COMPARING LASER POWER before and after interacting with the fiber
plot.intensity(data  = F1.data.stokes, 
               title = expression(bold("The Effect Of An Optical PM-Fiber (F1) On The Lasers Power "*P))
)


# Plot and compare the PREDICTED and MEASURED STOKES parameters
# S0
plot(x = F1.data.stokes$POST$W, y = F1.data.stokes$POST$S0, col="red", type="l",
     main = expression("F1: Predicted/Measured S"[0]*" (blue/red)"),
     xlab = "wave plate position / °",
     ylab = expression("stokes parameter S"[0]))
lines(x = F1.data.stokes$POST$W, y = F1.data.stokes$POST.PREDICT$S0, col="blue")
# S1
plot(x = F1.data.stokes$POST$W, y = F1.data.stokes$POST$S1, col="red", type="l",
     main = expression("F1: Predicted/Measured S"[1]*" (blue/red)"),
     xlab = "wave plate position / °",
     ylab = expression("stokes parameter S"[1]))
lines(x = F1.data.stokes$POST$W, y = F1.data.stokes$POST.PREDICT$S1, col="blue")
# S2
plot(x = F1.data.stokes$POST$W, y = F1.data.stokes$POST$S2, col="red", type="l",
     main = expression("F1: Predicted/Measured S"[2]*" (blue/red)"),
     xlab = "wave plate position / °",
     ylab = expression("stokes parameter S"[2]))
lines(x = F1.data.stokes$POST$W, y = F1.data.stokes$POST.PREDICT$S2, col="blue")
# Polarisation ratio
plot(x = F1.data.stokes$POST$W, y = F1.data.stokes$POST.PREDICT$polarisation, col="blue", type="l",
     main = expression("F1: Predicted/Measured "*Pi*" (blue/red)"),
     xlab = "wave plate position / °",
     ylab = expression("grade of polarisation "*Pi),
     ylim = c(0.3, 1.1))
lines(x = F1.data.stokes$POST$W, y = F1.data.stokes$POST$polarisation, col="red")
