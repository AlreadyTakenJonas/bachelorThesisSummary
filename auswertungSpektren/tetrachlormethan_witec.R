#
# ANALYSING POLARISED RAMAN SPECTRA OF TETRA
#


# Load functions and libraries from detector analysis for plotting spectra
source("bauteilCharakterisierung/charakterisierungDetektor_utilities.R")
#library("RHotStuff")
#library("magrittr")
#check.version("1.6.0")

# Load library for background correction
# Peaks needs to be loaded this way for the internal C-scripts to be callable
library.dynam("Peaks","Peaks",lib.loc=NULL)
library("baseline")

# FETCH DATA
# Tetracholomethane Spectra
tetra.spectra.unprocessed <- GET.elabftw.bycaption(79, header=T, outputHTTP=T) %>%
                              parseTimeSeries.elab(., col.spectra=3, sep="") %>% .[[1]]

# PREPROCESS
tetra.spectra <- tetra.spectra.unprocessed

#
# Remove the laser peak from the spectrum
#
tetra.spectra <- tetra.spectra[tetra.spectra$wavenumber>100,]


# Statistical Background Correction
#
# Peaks no longer available
#tetra.spectra[,-1] <- sapply(tetra.spectra[,-1], function(spec) spec-Peaks::SpectrumBackground(spec))
tetra.spectra[,-1] <- t( as.matrix(tetra.spectra[,-1]) ) %>%
                        baseline::baseline(., method="fillPeaks", lambda=1, it=10, hwi=50, int=2000) %>%
                        baseline::getCorrected(.) %>% t(.)

#
# Normalise each spectrum
#
# Normalisation with hghest point
# tetra.spectra[,-1] <- sapply(tetra.spectra[,-1], function(spec) spec/max(spec))
# Vector normalisation
tetra.spectra[,-1] <- apply(tetra.spectra[,-1], 2, function(spec) spec / sqrt(sum(spec^2)))



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
  peak.value <- max( tetra.spectra$"0"[selectGeneralPeakLocation] )
  peak.location <- tetra.spectra$wavenumber[tetra.spectra$`0` == peak.value]
  return(peak.location)
})

 

# EXTRACT THE PEAK HEIGHTS FOR DIFFERENT LASER POLARISATIONS
get.tetra.peakChange <- function() {
  # Create empty matrix
  tetra.peakChange <- matrix( NA, nrow = ncol(tetra.spectra[,-1]), ncol = length(tetra.peakLocations)+1 )
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
  
  return(tetra.peakChange)
}
tetra.peakChange <- get.tetra.peakChange()
# Normalise the peakChange with the maximum
# tetra.peakChange[,-1] <- apply(tetra.peakChange[,-1], 2, function(vec) vec / max(vec))


# HOW ARE THE OPTICAL AXIS OF THE DETECTOR ALIGNED?
# This is important for comparing raman spectra and white lamp spectra
#
# The wave plates position of the maximal detector response
# Loop over all peaks and compare the height between the different spectra
# sapply(seq_along(tetra.peakChange[,-1]), function(index) {
#   # The maximal height of the current peak
#   peakHeight <- max(tetra.peakChange[,index+1])
#   # Get the index of the maximum
#   select <- which(peakHeight==tetra.peakChange[,index+1])
#   # If there are multiple maxima its propably the peak I normalised with
#   # Just return NA in this case
#   if (length(select)>1) return(NA)
#   # Return the wave plates position
#   return( tetra.peakChange[ select,1 ] )
# }) 
#
# The wave plates position of the minimal detector response
# Loop over all peaks and compare the height between the different spectra
# sapply(seq_along(tetra.peakChange[,-1]), function(index) {
#    # The minimal height of the current peak
#    peakHeight <- min(tetra.peakChange[,index+1])
#    # Get the index of the minimal
#    select <- which(peakHeight==tetra.peakChange[,index+1])
#    # If there are multiple minima its propably the peak I normalised with
#    # Just return NA in this case
#    if (length(select)>1) return(NA)
#    # Return the wave plates position
#    return( tetra.peakChange[ select,1 ] )
# })
# Find the minimal value of all spectra and return the wave number position
# of the spectrum containing the value
tetra.minimal.waveplate <- sapply(tetra.spectra[,-1], function(spec) { 
    min(tetra.spectra[,-1]) %in% spec 
  }) %>% which %>% names %>% as.numeric






# COMPUTE DETECTORS SENSITIBLITY FOR LIGHT POLARISED ALONG DIFFERENT OPTICAL AXIS
tetra.sensibility <- sapply(tetra.peakChange[,-1], function(peakheight) max(peakheight)/min(peakheight))
tetra.sensibility <- data.frame(wavenumber = names(tetra.sensibility) %>% as.numeric,
                                quotient   = tetra.sensibility %>% unname)



#
# PLOT THE RESULTS
#
# Plot ALL SPECTRA OVERLAYERD as 2d plot
tetra.plot.allSpetra <- ggplot( data = makeSpectraPlotable(tetra.spectra[tetra.spectra$wavenumber>100,-c(21:24)], 
                                                           colorFunc=function(waveplateRotation) 
                                                           { mod(waveplateRotation-(tetra.minimal.waveplate), 90) %>% 
                                                               `-`(., 45) %>% abs } ),
                                # mapping = aes(x = wavenumber, ymax = signal, ymin=0, group = P, fill = color) ) +
                                mapping = aes(x = wavenumber, y = signal, group = P, color = color) ) +
  scale_fill_gradientn(colors = c("green", "orange", "red"),
                       breaks = seq(from=0, to=45, length.out=4) ) +
  scale_color_gradientn(colors = c("green", "orange", "red"),
                        breaks = seq(from=0, to=45, length.out=4) ) +
  theme_hot() +
  labs(title = "Influence Of Light Polarisation On Raman Spectrum Of Tetrachloromethane",
       y = "normalised intensity",
       x = expression(bold("wavenumber / cm"^"-1")),
       subtitle = "the color gradient encodes the absolute deviation D of the wave plates position \nfrom the detectors least sensitive axis",
       fill = "D / °") +
   geom_line(size=0.4)
# Plot all wavenumbers
tetra.plot.allSpetra
# Show just the interesting part
tetra.plot.allSpetra + coord_cartesian(xlim = c(150, 850))

# Plot ALL SPECTRA as 3d SURFACE
plot.detector.allSpectra.interactable(tetra.spectra[ which(tetra.spectra$wavenumber>100 & tetra.spectra$wavenumber<1000), ], 
                                      title=expression(bold("Normalised Raman Spectra Of Tetrachloromethane For Different Polarised Light")))

# Plot the HEIGHT OF PEAKS against the wave plates position
plot(x=tetra.peakChange$waveplate, y=tetra.peakChange[,2], type="n",
     main = "Peakheight Change Due To Polarisation Change",
     xlab = "waveplate rotation / °",
     ylab = "normalised peak height", 
     ylim = c(min(tetra.peakChange[,-1]),
              max(tetra.peakChange[,-1])) )
# Plot peak change
for (index in seq_along(tetra.peakChange[,-1])) lines(x=tetra.peakChange$waveplate, y=tetra.peakChange[,index+1], col=index+5, type="o")

