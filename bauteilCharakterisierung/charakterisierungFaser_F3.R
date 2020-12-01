#
# Get some libraries and functions used for characterising optical fibers and plotting stuff
#
source("bauteilCharakterisierung/charakterisierungFaser_utilities.R")


# FIBER F3 : MULTI-MODE-FIBER

#
# FETCH data from elabftw
#
# stokes vectors
F3.data.elab <- GET.elabftw.bycaption(74, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                                         func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                                         header=T, skip=14, sep=";")
# Rotation of plane of polarisation
F3.rotation.elab <- GET.elabftw.bycaption(73, header=T)[[1]]


# Fetch the meta data of one of the experiments
F3.meta.elab <- GET.elabftw.bycaption(74, caption="Metadaten", header=T, output=T) %>% parseTable.elabftw(.,
                                                                                        func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                                        header=T, skip=14, sep=";")


# Get the measurements for the error estimation
F3.error.elab <- GET.elabftw.bycaption(75, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                                          func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                                          header=T, skip=14, sep=";")




#
# COMPUTE stokes vectors and do statistics on the error estimations
#
F3.data.stokes <- getStokes.from.expData(F3.data.elab)  %>% process.stokesVec
F3.meta.stokes <- getStokes.from.metaData(F3.meta.elab) %>% process.stokesVec
F3.error.stats <- getStokes.from.expData(F3.error.elab) %>% process.stokesVec %>% do.statistics



#
# PLOT THAT SHIT
#
# How does the polarisation ratio change relative to the initial polarisation ratio?
plot.polarisation.change(data  = F3.data.stokes, 
                         title = expression(bold("The Depolarising Behaviour Of An Optical MM-Fiber (F3)") )
)
# COMPARING POLARISATION RATIOS before and after interacting with the fiber
plot.polarisation(data       = F3.data.stokes, 
                  statistics = F3.error.stats,
                  title      = expression(bold("The Effect Of An Optical MM-Fiber (F3) On The Polarisation Ratio "*Pi))
)

# CHANGE in LASER POWER due to optical fiber
plot.intensity.change(data  = F3.data.stokes,
                      title = expression(bold("The Transmittance Of An Optical MM-Fiber (F3)"))
)
# COMPARING LASER POWER before and after interacting with the fiber
plot.intensity(data  = F3.data.stokes, 
               title = expression(bold("The Effect Of An Optical MM-Fiber (F3) On The Lasers Power "*P))
)

# How does the fiber influence the PLANE OF POLARISATIONS ORIENTATION
plot.plane.rotation(F3.rotation.elab, 
                    title = expression(bold("The Impact Of The Multi-Mode Fiber (F3) On The Orientation Of The Plane Of Polarisation"))
)



#
# TODO: REFRACTURE CODE AND APPLY TO OTHER OPTICAL FIBERS
#
#
# Calculate mueller matrix elements a bit more refined
#
# Recalculate stokes vectors
F3.mueller.stokes <- getStokes.from.expData(F3.data.elab)
# Normalise stokes vectors before and after the fiber with the first stokes parameter before the fiber
# Ensures that mueller matrix also describes the absorption behaviour of the fiber
F3.mueller.stokes$PRE[,c(2,3,4)] <- F3.mueller.stokes$PRE[,c(2,3,4)] / F3.mueller.stokes$PRE[,2]
F3.mueller.stokes$POST[,c(2,3,4)] <- F3.mueller.stokes$POST[,c(2,3,4)] / F3.mueller.stokes$PRE[,2]  
# Calculate mueller matrix by solving linear equations
F3.muellermatrix <- matrix( c( limSolve::Solve(as.matrix(F3.mueller.stokes$PRE[,c(2,3,4)]), F3.mueller.stokes$POST$S0), 0,
                               limSolve::Solve(as.matrix(F3.mueller.stokes$PRE[,c(2,3,4)]), F3.mueller.stokes$POST$S1), 0,
                               limSolve::Solve(as.matrix(F3.mueller.stokes$PRE[,c(2,3,4)]), F3.mueller.stokes$POST$S2), 0,
                               0, 0, 0, 0 ), 
                            ncol = 4, byrow = T )

# Predict stokes vector after the fiber
F3.predicted.POST <- apply(F3.mueller.stokes$PRE[,c(2,3,4)], 1, function(stokes) { 
  F3.muellermatrix %*% ( stokes %>% unlist %>% c(., 0) ) 
})
# Calculate polarisation ratio of predicted stokes vectors
F3.predicted.POST.polarisation <- data.frame( "predicted" = apply(F3.predicted.POST, 2, function(stokes) { 
                                                                  sqrt(sum(stokes[c(2,3,4)]^2)) / stokes[1] } ),
                                              "measured"  = apply(F3.mueller.stokes$POST, 1, function(stokes) { 
                                                                  sqrt(sum(stokes[c(3,4)]^2))   / stokes[2] } ) )
# Plot and compare the predicted and measured stokes parameters
# S0
plot(x = F3.mueller.stokes$POST$W, y = F3.mueller.stokes$POST$S0, col="red", type="l",
     main=expression("Predicted/Measured S"[0]))
lines(x = F3.mueller.stokes$POST$W, y = F3.predicted.POST[1,], col="blue")
# S1
plot(x = F3.mueller.stokes$POST$W, y = F3.mueller.stokes$POST$S1, col="red", type="l",
     main=expression("Predicted/Measured S"[1]))
lines(x = F3.mueller.stokes$POST$W, y = F3.predicted.POST[2,], col="blue")
# S2
plot(x = F3.mueller.stokes$POST$W, y = F3.mueller.stokes$POST$S2, col="red", type="l",
     main=expression("Predicted/Measured S"[2]))
lines(x = F3.mueller.stokes$POST$W, y = F3.predicted.POST[3,], col="blue")
# Polarisation ratio
plot(x = F3.mueller.stokes$POST$W, y = F3.predicted.POST.polarisation$predicted, col="blue", type="l",
     main=expression("Predicted/Measured "*Pi))
lines(x = F3.mueller.stokes$POST$W, y = F3.predicted.POST.polarisation$measured, col="red")


# Calculate difference between predicted and measured stokes parameters
# Mean difference and standard deviation between measurement and prediction
( t(F3.predicted.POST[-4,]) - F3.mueller.stokes$POST[,c(2,3,4)] ) %>% abs %>% colMeans
( t(F3.predicted.POST[-4,]) - F3.mueller.stokes$POST[,c(2,3,4)] ) %>% abs %>% apply(., 2, sd)
# Relative mean difference and standard deviation between measurement and prediction
( t(F3.predicted.POST[-4,]) - F3.mueller.stokes$POST[,c(2,3,4)] ) %>% `/`(., F3.mueller.stokes$POST[,c(2,3,4)]) %>% abs %>% colMeans
( t(F3.predicted.POST[-4,]) - F3.mueller.stokes$POST[,c(2,3,4)] ) %>% `/`(., F3.mueller.stokes$POST[,c(2,3,4)]) %>% abs %>% apply(., 2, sd)

# Calculate difference between predicted and measured polarisation ratio
# Mean difference and standard deviation between measurement and prediction
(F3.predicted.POST.polarisation$predicted - F3.predicted.POST.polarisation$measured) %>% abs %>% mean
(F3.predicted.POST.polarisation$predicted - F3.predicted.POST.polarisation$measured) %>% abs %>% sd
# Relative mean difference and standard deviation between measurement and prediction
(F3.predicted.POST.polarisation$predicted - F3.predicted.POST.polarisation$measured) %>% `/`(., F3.predicted.POST.polarisation$measured) %>% abs %>% mean
(F3.predicted.POST.polarisation$predicted - F3.predicted.POST.polarisation$measured) %>% `/`(., F3.predicted.POST.polarisation$measured) %>% abs %>% sd
