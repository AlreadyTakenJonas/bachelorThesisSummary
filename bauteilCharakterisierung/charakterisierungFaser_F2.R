#
# Get some libraries and functions used for characterising optical fibers and plotting stuff
#
source("bauteilCharakterisierung/charakterisierungFaser_utilities.R")

# F2 : SINGLE-MODE-FIBER

#
# FETCH data from elabftw
#
# stokes vectors
F2.data.elab <- lapply(c(69, 70), function(experimentID) {
  GET.elabftw.bycaption(experimentID, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                   func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                   header=T, skip=14, sep=";")
}) %>% better.rbind(., sort.byrow=1)
# Rotation of plane of polarisation
F2.rotation.elab <- GET.elabftw.bycaption(72, header=T)[[1]]


# Fetch the meta data of one of the experiments
F2.meta.elab <- GET.elabftw.bycaption(69, caption="Metadaten", header=T, outputHTTP=T) %>% parseTable.elabftw(.,
                                                                                            func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                                            header=T, skip=14, sep=";")

# Get the measurements for the error estimation
F2.error.elab <- GET.elabftw.bycaption(71, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                        func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                        header=T, skip=14, sep=";")


#
# COMPUTE stokes vectors and do statistics on the error estimations
#
F2.data.stokes <- getStokes.from.expData(F2.data.elab)  %>% process.stokesVec
F2.meta.stokes <- getStokes.from.metaData(F2.meta.elab) %>% process.stokesVec
F2.error.stats <- getStokes.from.expData(F2.error.elab) %>% process.stokesVec %>% do.statistics


#
# PLOT THAT SHIT
#
# How does the polarisation ratio change relative to the initial polarisation ratio?
plot.polarisation.change(data  = F2.data.stokes, 
                         title = expression(bold("The Depolarising Behaviour Of An Optical SM-Fiber (F2)") )
)
# COMPARING POLARISATION RATIOS before and after interacting with the fiber
plot.polarisation(data       = F2.data.stokes, 
                  statistics = F2.error.stats,
                  title      = expression(bold("The Effect Of An Optical SM-Fiber (F2) On The Polarisation Ratio "*Pi))
)

# CHANGE in LASER POWER due to optical fiber
plot.intensity.change(data  = F2.data.stokes,
                      title = expression(bold("The Transmittance Of An Optical SM-Fiber (F2)"))
)
# COMPARING LASER POWER before and after interacting with the fiber
plot.intensity(data  = F2.data.stokes, 
               title = expression(bold("The Effect Of An Optical SM-Fiber (F2) On The Lasers Power "*P))
)

# How does the fiber influence the PLANE OF POLARISATIONS ORIENTATION
plot.plane.rotation(F2.rotation.elab, 
                    title = expression(bold("The Impact Of The Single-Mode Fiber (F2) On The Orientation Of The Plane Of Polarisation"))
)


# Thoughts on deriving a mueller matrix for the fiber
plot(x = F2.data.stokes$PRE$W, y = F2.data.stokes$PRE$S1, col="red", type="l")
lines(x = F2.data.stokes$POST$W, y = F2.data.stokes$POST$S1, col="blue")

plot(x = F2.data.stokes$PRE$W, y = F2.data.stokes$PRE$polarisation, col="red", type="l", ylim=c(-1,1.05))
lines(x = F2.data.stokes$POST$W, y = F2.data.stokes$POST$polarisation, col="blue")
lines(x = F2.data.stokes$change$W, y = F2.data.stokes$change$change.in.polarisation, col="green")

plot(x = F2.data.stokes$PRE$W, y = F2.data.stokes$PRE$S2, col="red", type="l")
lines(x = F2.data.stokes$POST$W, y = F2.data.stokes$POST$S2, col="blue")
lines(x = F2.data.stokes$POST$W, y = F2.data.stokes$POST$S2*(-2), col="green")
