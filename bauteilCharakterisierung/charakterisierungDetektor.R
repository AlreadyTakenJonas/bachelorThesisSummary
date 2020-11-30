#
# CHARACTERISING THE WITEC DETECTOR
#
# How does the detector response changes when changing the orientation of the lasers plane of polarisation?

#
# Get some libraries and functions used for characterising the detector and plotting stuff
#
source("bauteilCharakterisierung/charakterisierungDetektor_utilities.R")



# Fetch experimental data from elabFTW
detector.spectra <- GET.elabftw.bycaption(76, header=T, outputHTTP=T) %>% parseTimeSeries.elab(., header=F, sep="")


#
# PLOT THAT SHIT
#

# Plot the white lamp spectra for the detector without the microscope
plot.detector.whitelamp(data=makeSpectraPlotable(detector.spectra[[2]], 
                                                 colorFunc=function(polariserRotation) {mod(polariserRotation, 180) %>% `-`(.,90) %>% abs(.)} ), 
                        title="The Changing Detector Response For Different Linear Polarised White Light Of The WiTecs Detector")

# Plot the white lamp spectra for the detector with the microscope
plot.detector.whitelamp(data=makeSpectraPlotable(detector.spectra[[1]], 
                                                 colorFunc=function(polariserRotation) {mod(polariserRotation, 180) %>% `-`(.,90) %>% abs(.)} ), 
                        title="The Changing Detector Response For Different Linear Polarised White Light Of The WiTecs Detector And Microscope")


# How does the sensitivity of the detector change with the wavenumber
ggplot( data = data.frame(wavenumber = detector.spectra[[2]]$wavenumber,
                          difference = apply(detector.spectra[[2]][,-1], 1, function(slice) { max(slice)-min(slice) }) 
                          ),
        mapping = aes(x=wavenumber, y=difference)) +
  theme_hot() +
  labs(title = "Difference between maximal and minimal detector response",
       x = expression(bold("wavenumber / cm"^"-1")),
       y = "count difference") +
  geom_line()

# How does the sensitivity of the detector change with the wavenumber (difference method)
ggplot( data = data.frame(wavenumber = detector.spectra[[2]]$wavenumber,
                          difference = apply(detector.spectra[[2]][,-1], 1, function(slice) { max(slice)-min(slice) }) 
                        ),
        mapping = aes(x=wavenumber, y=difference) ) +
  theme_hot() +
  labs(title = "Difference between maximal and minimal detector response",
       x = expression(bold("wavenumber / cm"^"-1")),
       y = "count difference") +
  geom_line()


# How does the sensitivity of the detector change with the wavenumber (quotient method)
ggplot( data = data.frame(wavenumber = detector.spectra[[2]]$wavenumber,
                          quotient   = apply(detector.spectra[[2]][,-1], 1, function(slice) { min(slice)/max(slice) }) 
                          ),
        mapping = aes(x=wavenumber, y=quotient) ) +
  theme_hot() +
  labs(title = "Quotient of maximal and minimal detector response",
       x = expression(bold("wavenumber / cm"^"-1")),
       y = "min/max") +
  geom_line()

# Plot the WHITE LAMP SPECTRA in one 3d plot as 3D SURFACE
plot.detector.allSpectra(detector.spectra[[2]][,-c(21:24)])