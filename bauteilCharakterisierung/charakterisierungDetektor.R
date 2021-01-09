#
# CHARACTERISING THE WITEC DETECTOR
#
# How does the detector response changes when changing the orientation of the lasers plane of polarisation?

#
# Get some libraries and functions used for characterising the detector and plotting stuff
#
source("bauteilCharakterisierung/charakterisierungDetektor_utilities.R")



# Fetch experimental data from elabFTW
# First try
detector.spectra1 <- GET.elabftw.bycaption(76, header=T, outputHTTP=T) %>% parseTimeSeries.elab(., header=F, sep="")
# Second try
detector.spectra2 <- GET.elabftw.bycaption(81, header=T, outputHTTP=T) %>% parseTimeSeries.elab(., header=F, sep="")
# Select one data set for evaluation
detector.spectra <- detector.spectra2

# Get the ideal white lamp spectrum
detector.whitelamp <- read.table(file = "./Weisslichtspektrum_Julian.txt", header = T)

#
# PREPROCESS SPECTRA
# Vector normalisation and wavenumber conversion and mean calculation
#
# Wavelength of the WiTecs laser
laser.wavelength <- 514.624
detector.spectra <- lapply(detector.spectra, function(spec) {
  
  # Convert raman shift in wavenumbers into absolute wavelength
  spec$wavelength <- 1/( 1/laser.wavelength - spec$wavenumber*1e-7 )
  
  # Cut out rayleigh filter
  spec <- spec[spec$wavenumber>200,]
  
  # Which columns contain the measured white lamp spectra?
  data.selector <- which(colnames(spec) %in% c("wavenumber", "wavelength", "mean") == F)
  
  # Weißlichtkorrektur
  # Berechne eine gemeinsame Wellenlängenachse für gemessenes und ideales Weißlicht
  idealWhiteLamp <- approx(detector.whitelamp$Wavelength, detector.whitelamp$Intensity, 
                           xout=spec$wavelength)
  # Teile das gemessene Weißlicht durch das ideale Weißlicht
  spec[, data.selector] <- apply(spec[, data.selector], 2, function(spec) {
    spec / idealWhiteLamp$y
  })
  
  # Compute mean spectrum and add it to the data.frame
  spec$mean <- rowMeans(spec[, data.selector])
  
  # Which columns contain the measured white lamp spectra?
  data.selector <- which(colnames(spec) %in% c("wavenumber", "wavelength", "mean") == F)
  
  # Reorder data.frame
  spec <- spec[,c( which(colnames(spec) == "wavenumber"),
                   which(colnames(spec) == "wavelength"),
                   which(colnames(spec) == "mean"),
                   data.selector )]

  
  # Return
  return(spec)
})

#
# HOW DOES THE INFLUENCE OF THE POLARISATION CHANGE WITH THE WAVENUMBER?
#
detector.absDifference <- lapply(detector.spectra, function(spectra) {
  # Copy white lamp spectrum
  diffSpectra <- spectra
  # Compute the absolute difference between white lamp spectra and their mean spectrum
  diffSpectra[, -(1:3)] <- apply(diffSpectra[, -(1:3)], 2, function(spec) {spec - diffSpectra$mean})
  # Return result
  return(diffSpectra)
})
detector.relDifference <- lapply(detector.spectra, function(spectra) {
  # Copy white lamp spectrum
  diffSpectra <- spectra
  # Compute the relative difference between white lamp spectra and their mean spectrum
  diffSpectra[, -(1:3)] <- apply(diffSpectra[, -(1:3)], 2, function(spec) {(spec/diffSpectra$mean)-1})
  # Return result
  return(diffSpectra)
})



# Which spectra have the largest and smallest values
lapply(detector.absDifference, function(spectra) {
  specMean <- colMeans(spectra[, -(1:3)])
  list("max" = (which(max(specMean) == specMean)+3) %>% unname,
       "min" = (which(min(specMean) == specMean)+3) %>% unname)
})

#
# PLOT THAT SHIT
#

# # Plot the white lamp spectra for the detector without the microscope
# plot.detector.whitelamp(data=makeSpectraPlotable(detector.spectra[[1]][, -c(2:3)], 
#                                                  colorFunc=function(polariserRotation) {mod(polariserRotation+45, 180) %>% `-`(.,90) %>% abs(.)} ), 
#                         title="The Changing Detector Response For Different Linear Polarised White Light Of The WiTecs Detector")
# 
# 
# # Plot the white lamp spectra for the detector with the microscope
# plot.detector.whitelamp(data=makeSpectraPlotable(detector.spectra[[2]][, -c(2:3)], 
#                                                  colorFunc=function(polariserRotation) {mod(polariserRotation, 180) %>% `-`(.,90) %>% abs(.)} ), 
#                         title="The Changing Detector Response For Different Linear Polarised White Light Of The WiTecs Detector And Microscope") #+
# 
# Plot the WHITE LAMP SPECTRA in one 3d plot as 3D SURFACE
# plot.detector.allSpectra.interactable(detector.spectra[[1]][, -c(2:3)])
# plot.detector.allSpectra.interactable(detector.spectra[[2]][, -c(2:3)])
# plot.detector.allSpectra(detector.spectra[[1]][,-c(2:3,21:24)], theta=240)
# plot.detector.allSpectra(detector.spectra[[2]][,-c(2:3,21:24)], theta=240)
# 
# 
# # Plot the ABSOLUTE DIFFERENCE between the white lamp spectra and their mean
# # with microscope
# plot.detector.whitelamp(data=makeSpectraPlotable(detector.absDifference[[1]][, -c(2:3)],
#                                                  colorFunc=function(polariserRotation) {mod(polariserRotation+45, 180) %>% `-`(.,90) %>% abs(.)} ),
#                         title="Absolute Difference between Polarised White Lamp Spectra and Their Mean (with detector)",
#                         ylab="abs. count difference")
# # with microscope, only the extrema
# plot.detector.whitelamp(data=makeSpectraPlotable(detector.absDifference[[1]][, c(1, 7, 16)],
#                                                  colorFunc=function(polariserRotation) {mod(polariserRotation+45, 180) %>% `-`(.,90) %>% abs(.)} ),
#                         title="Relative Difference between Polarised White Lamp Spectra and Their Mean (with detector)",
#                         ylab="rel. count difference")
# # without microscope
# plot.detector.whitelamp(data=makeSpectraPlotable(detector.absDifference[[2]][, -c(2:3)],
#                                                  colorFunc=function(polariserRotation) {mod(polariserRotation, 180) %>% `-`(.,90) %>% abs(.)} ),
#                         title="Absolute Difference between Polarised White Lamp Spectra and Their Mean (without detector)",
#                         ylab="abs. count difference")
# 
# # Plot the RELATIVE DIFFERENCE between the white lamp spectra and their mean
# # with microscope
# plot.detector.whitelamp(data=makeSpectraPlotable(detector.relDifference[[1]][, -c(2:3)],
#                                                  colorFunc=function(polariserRotation) {mod(polariserRotation+45, 180) %>% `-`(.,90) %>% abs(.)} ),
#                         title="Relative Difference between Polarised White Lamp Spectra and Their Mean (with detector)",
#                         ylab="rel. count difference") +
#   coord_cartesian(ylim = c(-0.3, 0.3))
# 
# # with microscope, only the extrema
# plot.detector.whitelamp(data=makeSpectraPlotable(detector.relDifference[[1]][, c(1, 7, 16)],
#                                                  colorFunc=function(polariserRotation) {mod(polariserRotation+45, 180) %>% `-`(.,90) %>% abs(.)} ),
#                         title="Relative Difference between Polarised White Lamp Spectra and Their Mean (with detector)",
#                         ylab="rel. count difference")  +
#   coord_cartesian(ylim = c(-0.3, 0.3))
# # without microscope
# plot.detector.whitelamp(data=makeSpectraPlotable(detector.relDifference[[2]][, -c(2:3)],
#                                                  colorFunc=function(polariserRotation) {mod(polariserRotation, 180) %>% `-`(.,90) %>% abs(.)} ),
#                         title="Relative Difference between Polarised White Lamp Spectra and Their Mean (without detector)",
#                         ylab="rel. count difference")


#
# PLOTS FOR OVERLEAF
#
# Restructure data to make it easier to plot that shit
# Relative deviation form the mean spectrum
detector.plotable.relDifference <- 
  list( "Mit Mikroskop" = makeSpectraPlotable(detector.relDifference[[1]][, -c(2:3)], 
                                              colorFunc=function(polariserRotation) {
                                                mod(polariserRotation-45, 180) %>% 
                                                `-`(.,90) %>% abs(.)
                                              }),
        "Ohne Mikroskop" = makeSpectraPlotable(detector.relDifference[[2]][, -c(2:3)], 
                                               colorFunc=function(polariserRotation) {
                                                  mod(polariserRotation+90, 180) %>% 
                                                  `-`(.,90) %>% abs(.)
                                                }) 
      )  %>% dplyr::bind_rows(.id="exp")
# Bring white lamp spectra in plottable form
detector.plotable.spectra <-
  list( "Mit Mikroskop" = makeSpectraPlotable(detector.spectra[[1]][, -c(2:3)],
                                              colorFunc=function(polariserRotation) {
                                                mod(polariserRotation-45, 180) %>% 
                                                  `-`(.,90) %>% abs(.)
                                              }),
        "Ohne Mikroskop" = makeSpectraPlotable(detector.spectra[[2]][, -c(2:3)],
                                               colorFunc=function(polariserRotation) {
                                                 mod(polariserRotation+90, 180) %>% 
                                                   `-`(.,90) %>% abs(.)
                                              })
        ) %>% dplyr::bind_rows(.id="exp")

# Write table to file -> Upload to overleaf
write.table(detector.plotable.relDifference, file="../overleaf/externalFilesForUpload/data/detector_relDiff.csv", row.names = F)
write.table(detector.plotable.spectra, file="../overleaf/externalFilesForUpload/data/detector_spectra.csv", row.names = F)

# Create plots
# Relative difference
ggplot(detector.plotable.relDifference,
       mapping = aes(x=wavenumber, y=signal, color=color, group=P) ) +
  geom_line() +
  facet_wrap(facets=vars(exp)) +
  theme_hot() + 
  theme(strip.text = element_text(face="bold"), 
        legend.position = "right") +
  scale_color_gradient(low    = "blue",
                       high   = "red", 
                       breaks = seq(from=0, to=90, by=45) ) +
  scale_x_continuous(breaks = seq(from=500, to=4000, by=1000)) +
  labs(x = expression(bold("Wellenzahl "*nu*" / cm"^"-1")),
       y = expression(bold("Abweichung "*Delta["rel"])),
       title = "Anisotropie des Ramanspektrometes",
       color = expression(bold(delta*" / °")))

# All spectra
ggplot(detector.plotable.spectra,
       mapping = aes(x=wavenumber, y=signal, color=color, group=P) ) +
  geom_line() +
  facet_wrap(facets=vars(exp), scales = "free_y") +
  theme_hot() + 
  theme(strip.text = element_text(face="bold"), 
        legend.position = "right") +
  scale_color_gradient(low    = "blue",
                       high   = "red", 
                       breaks = seq(from=0, to=90, by=45) ) +
  scale_x_continuous(breaks = seq(from=500, to=4000, by=1000)) +
  labs(x = expression(bold("Wellenzahl "*nu*" / cm"^"-1")),
       y = expression(bold("normierte Intensität")),
       title = "Polarisationsabhängige Weißlichtspektren",
       color = expression(bold(delta*" / °")))

