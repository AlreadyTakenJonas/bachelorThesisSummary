#
# Get some libraries and functions used for characterising optical fibers and plotting stuff
#
source("bauteilCharakterisierung/charakterisierungFaser_utilities.R")



#
# FETCH data from elabftw
#
# Fiber1 (PM-Fiber)
F1.data.elab <- lapply(c(58, 67, 68), function(experimentID) {
  GET.elabftw.bycaption(experimentID, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                      func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                      header=T, skip=14, sep=";")
}) %>% better.rbind(., sort.byrow=1)
# Fiber2 (Single-Mode-Fiber)
F2.data.elab <- lapply(c(69, 70), function(experimentID) {
  GET.elabftw.bycaption(experimentID, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                   func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                   header=T, skip=14, sep=";")
}) %>% better.rbind(., sort.byrow=1)
# Fiber2 (Single-Mode-Fiber)
F2.rotation.elab <- GET.elabftw.bycaption(72, header=T)[[1]]

# Fiber3 (multi-mode-fiber)
F3.data.elab <- GET.elabftw.bycaption(74, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                        func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                        header=T, skip=14, sep=";")
# Fiber3 (multi-mode-fiber)
F3.rotation.elab <- GET.elabftw.bycaption(73, header=T)[[1]]

# Fetch the meta data of one of the experiments
# Fiber1 (PM-Fiber)
F1.meta.elab <- GET.elabftw.bycaption(67, caption="Metadaten", header=T, outputHTTP=T) %>% parseTable.elabftw(.,
                                                                                         func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                                         header=T, skip=14, sep=";")
# Fiber2 (Single-Mode-Fiber)
F2.meta.elab <- GET.elabftw.bycaption(69, caption="Metadaten", header=T, outputHTTP=T) %>% parseTable.elabftw(.,
                                                                                            func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                                            header=T, skip=14, sep=";")
# Fiber3 (multi-mode-fiber)
F3.meta.elab <- GET.elabftw.bycaption(74, caption="Metadaten", header=T, output=T) %>% parseTable.elabftw(.,
                                                                                        func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                                        header=T, skip=14, sep=";")

# Get the measurements for the error estimation
# Fiber1 (PM-Fiber)
F1.error.elab <- GET.elabftw.bycaption(66, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                        func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                        header=T, skip=14, sep=";")
# Fiber2 (Single-Mode-Fiber)
F2.error.elab <- GET.elabftw.bycaption(71, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                        func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                        header=T, skip=14, sep=";")

# Fiber3 (multi-mode-fiber)
F3.error.elab <- GET.elabftw.bycaption(75, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                        func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                        header=T, skip=14, sep=";")

#
# COMPUTE stokes vectors and do statistics on the error estimations
#
# Fiber1 (PM-Fiber)
F1.data.stokes <- getStokes.from.expData(F1.data.elab)  %>% process.stokesVec
F1.meta.stokes <- getStokes.from.metaData(F1.meta.elab) %>% process.stokesVec
F1.error.stats <- getStokes.from.expData(F1.error.elab) %>% process.stokesVec %>% do.statistics
# Fiber2 (Single-Mode-Fiber)
F2.data.stokes <- getStokes.from.expData(F2.data.elab)  %>% process.stokesVec
F2.meta.stokes <- getStokes.from.metaData(F2.meta.elab) %>% process.stokesVec
F2.error.stats <- getStokes.from.expData(F2.error.elab) %>% process.stokesVec %>% do.statistics
# Fiber3 (mulit-Mode-Fiber)
F3.data.stokes <- getStokes.from.expData(F3.data.elab)  %>% process.stokesVec
F3.meta.stokes <- getStokes.from.metaData(F3.meta.elab) %>% process.stokesVec
F3.error.stats <- getStokes.from.expData(F3.error.elab) %>% process.stokesVec %>% do.statistics

# TODO: CHECK POLARISATION RATIO <=1



#
# PLOT THAT SHIT
#
# Fiber1 (PM-Fiber)
# How does the polarisation ratio change relative to the initial polarisation ratio?
plot.polarisation.change(data  = F1.data.stokes, 
                         title = expression(bold("The Depolarising Behaviour Of An Optical PM-Fiber (F1)") )
                        )
# Fiber1 (PM-Fiber)
# COMPARING POLARISATION RATIOS before and after interacting with the fiber
plot.polarisation(data       = F1.data.stokes, 
                  statistics = F1.error.stats,
                  title      = expression(bold("The Effect Of An Optical PM-Fiber (F1) On The Polarisation Ratio "*Pi))
                  )

# Fiber1 (PM-Fiber)
# CHANGE in LASER POWER due to optical fiber
plot.intensity.change(data  = F1.data.stokes,
                      title = expression(bold("The Transmittance Of An Optical PM-Fiber (F1)"))
                      )
# Fiber1 (PM-Fiber)
# COMPARING LASER POWER before and after interacting with the fiber
plot.intensity(data  = F1.data.stokes, 
               title = expression(bold("The Effect Of An Optical PM-Fiber (F1) On The Lasers Power "*P))
               )


# Fiber2 (SM-Fiber)
# How does the polarisation ratio change relative to the initial polarisation ratio?
plot.polarisation.change(data  = F2.data.stokes, 
                         title = expression(bold("The Depolarising Behaviour Of An Optical SM-Fiber (F2)") )
)
# Fiber2 (SM-Fiber)
# COMPARING POLARISATION RATIOS before and after interacting with the fiber
plot.polarisation(data       = F2.data.stokes, 
                  statistics = F2.error.stats,
                  title      = expression(bold("The Effect Of An Optical SM-Fiber (F2) On The Polarisation Ratio "*Pi))
)

# Fiber2 (SM-Fiber)
# CHANGE in LASER POWER due to optical fiber
plot.intensity.change(data  = F2.data.stokes,
                      title = expression(bold("The Transmittance Of An Optical SM-Fiber (F2)"))
)
# Fiber2 (SM-Fiber)
# COMPARING LASER POWER before and after interacting with the fiber
plot.intensity(data  = F2.data.stokes, 
               title = expression(bold("The Effect Of An Optical SM-Fiber (F2) On The Lasers Power "*P))
)

# Fiber2 (SM-Fiber)
# How does the fiber influence the PLANE OF POLARISATIONS ORIENTATION
plot.plane.rotation(F2.rotation.elab, 
                    title = expression(bold("The Impact Of The Single-Mode Fiber (F2) On The Orientation Of The Plane Of Polarisation"))
)

# Fiber3 (MM-Fiber)
# How does the polarisation ratio change relative to the initial polarisation ratio?
plot.polarisation.change(data  = F3.data.stokes, 
                         title = expression(bold("The Depolarising Behaviour Of An Optical MM-Fiber (F3)") )
)
# Fiber3 (MM-Fiber)
# COMPARING POLARISATION RATIOS before and after interacting with the fiber
plot.polarisation(data       = F3.data.stokes, 
                  statistics = F3.error.stats,
                  title      = expression(bold("The Effect Of An Optical MM-Fiber (F3) On The Polarisation Ratio "*Pi))
)

# Fiber3 (MM-Fiber)
# CHANGE in LASER POWER due to optical fiber
plot.intensity.change(data  = F3.data.stokes,
                      title = expression(bold("The Transmittance Of An Optical MM-Fiber (F3)"))
)
# Fiber3 (MM-Fiber)
# COMPARING LASER POWER before and after interacting with the fiber
plot.intensity(data  = F3.data.stokes, 
               title = expression(bold("The Effect Of An Optical MM-Fiber (F3) On The Lasers Power "*P))
)

# Fiber3 (MM-Fiber)
# How does the fiber influence the PLANE OF POLARISATIONS ORIENTATION
plot.plane.rotation(F3.rotation.elab, 
                    title = expression(bold("The Impact Of The Multi-Mode Fiber (F3) On The Orientation Of The Plane Of Polarisation"))
)
                    