#
# ANALYSING POLARISED RAMAN SPECTRA OF TETRA
#

#library("RHotStuff")
#library("magrittr")
#check.version("1.6.0")
# Load functions and libraries from detector analysis for plotting spectra
source("bauteilCharakterisierung/charakterisierungDetektor_utilities.R")

# Load library for background correction
library.dynam("Peaks","Peaks",lib.loc=NULL)

# FETCH DATA
tetra.spectra <- GET.elabftw.bycaption(79, header=T, outputHTTP=T) %>%
                  parseTimeSeries.elab(., col.spectra=3, sep="") %>% .[[1]]

# PREPROCESS
# Statistical Background Correction
tetra.spectra[,-1] <- sapply(tetra.spectra[,-1], function(spec) spec-SpectrumBackground(spec))
# Normalise each spectra by its highest peak
tetra.spectra[,-1] <- sapply(tetra.spectra[,-1], function(spec) spec/max(spec))


# FIND THE LOCATION OF THE PEAKS
# Plot single spectrum
plot(x = tetra.spectra$wavenumber, y = tetra.spectra$`0`, type="l")
locator()
# Guess the general area (wavenumbers) where the peak lays in
tetra.peakMargins   <- list( c(100, 250),
                             c(250, 340),
                             c(340, 580),
                             c(580, 770),
                             c(770, 890) )
# Find the maximum in each guessed area
tetra.peakLocations <- sapply(tetra.peakMargins, function(margins) {
  # Guess the broad location of the peak
  selectGeneralPeakLocation <- which(tetra.spectra$wavenumber > margins[1] & tetra.spectra$wavenumber < margins[2])
  # Find the maximum of the guessed area and returns its location
  peak.value <- max( tetra.spectra$`0`[selectGeneralPeakLocation] )
  peak.location <- tetra.spectra$wavenumber[tetra.spectra$`0` == peak.value]
  return(peak.location)
})


# EXTRACT THE PEAK HEIGHTS FOR DIFFERENT LASER POLARISATIONS
# Create empty matrix
tetra.peakChange <- matrix( rep(NA, ncol(tetra.spectra[,-1])*(length(tetra.peakLocations)+1) ), nrow = ncol(tetra.spectra[,-1]) )
# Add column with the wave plate position
tetra.peakChange[,1] <- colnames(tetra.spectra[,-1]) %>% as.numeric
# Loop over all peaks and and add their heights to the matrix
for (index in seq_along(tetra.peakLocations)) {
  # Get the wavenumber of the peak
  peak <- tetra.peakLocations[index]
  # Add the corresponding row of the spectra table to the matrix
  tetra.peakChange[,index+1] <- tetra.spectra[ which(tetra.spectra$wavenumber==peak),-1 ] %>% unlist
}
# Add describtive column names
colnames(tetra.peakChange) <- c("waveplate", tetra.peakLocations)
# Translate matrix to data.frame
tetra.peakChange <- as.data.frame(tetra.peakChange)


# PLOT THE RESULTS
# Plot all spectra as 3d surface
plot.detector.allSpectra.interactable(tetra.spectra[ which(tetra.spectra$wavenumber>100 & tetra.spectra$wavenumber<1000), ], 
                                      title=expression(bold("Normalised Raman Spectra Of Tetrachloromethane For Different Polarised Light")))

# Plot the height of the peaks against the wave plates position
plot(x=tetra.peakChange$waveplate, type="n", ylim=c(0,1),
     main = "Peakheight Change Due To Polarisation Change",
     xlab = "waveplate rotation / °",
     ylab = "normalised peak height")
for (index in seq_along(tetra.peakChange[,-1])) lines(x=tetra.peakChange$waveplate, y=tetra.peakChange[,index+1], col=index)

