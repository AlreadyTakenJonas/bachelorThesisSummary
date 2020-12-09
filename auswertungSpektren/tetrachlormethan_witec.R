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
# Get white lamp spectra measured with WiTec at ZAF
whitelamp.measured <- GET.elabftw.bycaption(81, header=T, outputHTTP=T) %>% 
                              parseTimeSeries.elab(., header=F, sep="")

# PREPROCESS
tetra.spectra <- tetra.spectra.unprocessed
# Remove every spectra measured for waveplate positions grater than 90°
# This makes sure that all used waveplate positions are uniformly spaced. Important 
# for comparing with white lamp spectra
tetra.spectra <- tetra.spectra[,c(T, colnames(tetra.spectra[,-1]) %>% as.numeric %>% `<=`(.,90))]
#
# Statistical Background Correction
#
# Peaks no longer available
#tetra.spectra[,-1] <- sapply(tetra.spectra[,-1], function(spec) spec-Peaks::SpectrumBackground(spec))
tetra.spectra[,-1] <- t( as.matrix(tetra.spectra[,-1]) ) %>%
                        baseline::baseline(., method="fillPeaks", lambda=1, it=10, hwi=50, int=2000) %>%
                        baseline::getCorrected(.) %>% t(.)

#
# Remove the laser peak from the spectrum
#
tetra.spectra <- tetra.spectra[tetra.spectra$wavenumber>100,]
#
# Normalise each spectra by its highest peak
#
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
sapply(seq_along(tetra.peakChange[,-1]), function(index) {
  # The minimal height of the current peak
  peakHeight <- min(tetra.peakChange[,index+1])
  # Get the index of the minimal
  select <- which(peakHeight==tetra.peakChange[,index+1])
  # If there are multiple minima its propably the peak I normalised with
  # Just return NA in this case
  if (length(select)>1) return(NA)
  # Return the wave plates position
  return( tetra.peakChange[ select,1 ] )
})
# According to sapply above the minimal peak heigt is measured for 85° wave plate rotation
# Output of sapply: c(0, 85, NA, 80, 80) Keep in mind: 0° = 90°
tetra.minimal.waveplate <- 85




#
# Correct spectrum with white lamp spectra
#
# Remove white lamp spectra measured with linear polariser positions greater than 180°
# This ensures that all spectra are measured with uniformly distributed polariser positions
# This is important for comparing white lamp spectra with raman spectra
whitelamp.measured <- lapply(whitelamp.measured, function(spectra) { 
  spectra[,c(T, colnames(spectra[,-1]) %>% as.numeric %>% `<=`(.,180))] 
})
# Is the linear polariser aligned with the detectors optical axis?
# Which rotation of the linear polariser yields the smallest detector response?
# Needed for comparing white lamp spectra with raman spectra
whitelamp.minimal.polariser <- sapply(whitelamp.measured, function(spectra) {
  # Get the intensity at biggest wavenumber
  # The difference between minimal and maximal
  # signal height is for larger wavenumbers bigger
  peakHeight <- tail(spectra, n=1L)[-1]
  # Find smallest peak height
  minimalPeakHeight <- min(peakHeight)
  # Get the polariser position for the smallest peak height
  minimal.polariser <- colnames(peakHeight)[minimalPeakHeight == peakHeight] %>% as.numeric
  minimal.polariser
})
# How much does the orientation of the wave plate/linear polariser differ between the raman and white light spectra?
shiftBetweenRamanAndWhiteLamp <- whitelamp.minimal.polariser - tetra.minimal.waveplate*2
# Shift the polariser positions so that the minimal detector response of the white lamp spectra
# matches the minimal detector response of the raman spectra
whitelamp.measured <- lapply(seq_along(whitelamp.measured), function(index) {
  # Convert the column names if the white lamp spectra into numbers (column names contain polariser position)
  newOrderOfColumns <- colnames(whitelamp.measured[[index]][,-1]) %>% as.numeric %>% 
  # Shift the polariser position to match the orientation of the wave plate used to measure the raman spectra
    `+`(., shiftBetweenRamanAndWhiteLamp[index]) %>%
  # Use modulus of 180 to ensure that the new column names exist
    mod(., 180)
  # Return white lamp spectra with shifted column order
  whitelamp.measured[[index]][,c("wavenumber", newOrderOfColumns)]
})

# Compare measured and ideal white lamp spectra
generate.whitelamp.scaleingFactors <- function(measuredSpectrum  = whitelamp.measured[[1]], 
                                              idealSpectrum.path = "./auswertungSpektren/Weisslichtspektrum_Julian.txt",
                                              laser.wavelength   = 514.624) {
  # Read 'ideal' white lamp spectrum (given by Julian Hniopek)
  whitelamp.ideal <- read.table(file=idealSpectrum.path, header=T)
  # Normalise white lamp spectrum with highest peak
  whitelamp.ideal$Intensity <- whitelamp.ideal$Intensity %>% `/`(., max(.))
  measuredSpectrum[,-1] <- apply(measuredSpectrum[,-1], 2, function(spectrum) { spectrum / max(spectrum) })
  
  # Convert raman shift into absolute wavelength
  measuredSpectrum <- data.frame(wavelength = 1/(1/laser.wavelength - measuredSpectrum$wavenumber*1e-7),
                                 wavenumber = measuredSpectrum$wavenumber,
                                 P          = measuredSpectrum[,-1])
  
  # # Calculate the ideal white lamp spectrum for data points measured with the WiTec
  whitelamp.ideal.approx <- approx(x = whitelamp.ideal$Wavelength,
                                   y = whitelamp.ideal$Intensity,
                                   xout = measuredSpectrum$wavelength) %>% as.data.frame
  colnames(whitelamp.ideal.approx) <- c("wavelength", "intensity")
  
  # Divide the ideal white lamp spectrum by the measured white light spectrum
  whitelamp.scaleingFactors <- sapply(3:ncol(measuredSpectrum), function(index) {
    whitelamp.ideal.approx$intensity / measuredSpectrum[,index]
  }) %>% data.frame(wavenumber = measuredSpectrum$wavenumber, .)
  colnames(whitelamp.scaleingFactors) <- colnames(measuredSpectrum[,-1])
  
  # Return results
  return(whitelamp.scaleingFactors)
}
whitelamp.scaleingFactors <- generate.whitelamp.scaleingFactors()
# Correct tetra spectra with white lamp scaling factors
tetra.spectra[,-1] <- sapply(2:ncol(tetra.spectra), function(index) {
  # For some fucking reason are the tetra spectra one data point shorter than the white lamp spectra
  # Filter this missing data point out
  commonWavenumberAxis <- ( whitelamp.scaleingFactors$wavenumber %in%  tetra.spectra$wavenumber)
  # Get the current spectrum
  spec <- tetra.spectra[,index]
  # Get the current scaling facors
  scale <- whitelamp.scaleingFactors[commonWavenumberAxis,index]
  # Scale and renormalise the spectra
  spec <- spec * scale
  spec <- spec / max(spec)
  return(spec)
})


# COMPUTE DETECTORS SENSITIBLITY FOR LIGHT POLARISED ALONG DIFFERENT OPTICAL AXIS
# Important: Recompute the peak Height changes of the spectra (get.tetra.peakChange), because they were
#             calculated before the spectra were scaled with the white lamp spectra
tetra.peakChange.final <- get.tetra.peakChange()
tetra.sensibility <- sapply(tetra.peakChange.final[,-1], function(peakheight) max(peakheight)/min(peakheight))
tetra.sensibility <- data.frame(wavenumber = names(tetra.sensibility) %>% as.numeric,
                                quotient   = tetra.sensibility %>% unname)



#
# PLOT THE RESULTS
#
# Plot ALL SPECTRA OVERLAYERD as 2d plot
tetra.plot.allSpetra <- ggplot( data = makeSpectraPlotable(tetra.spectra[tetra.spectra$wavenumber>100,-c(21:24)], 
                                                           colorFunc=function(waveplateRotation) 
                                                           { mod(waveplateRotation-(tetra.minimal.waveplate-45), 90) %>% 
                                                               `-`(., 45) %>% abs } ),
                                mapping = aes(x = wavenumber, ymax = signal, ymin=0, group = P, fill = color) ) +
   scale_fill_gradientn(colors = c("green", "orange", "red"),
                        breaks = seq(from=0, to=45, length.out=4) ) +
  theme_hot() +
  labs(title = "Influence Of Light Polarisation On Raman Spectrum Of Tetrachloromethane",
       y = "normalised intensity",
       x = expression(bold("wavenumber / cm"^"-1")),
       subtitle = "the color gradient encodes the absolute deviation D of the wave plates position \nfrom the detectors least sensitive axis",
       fill = "D / °") +
   geom_ribbon()
# Plot all wavenumbers
tetra.plot.allSpetra
# Show just the interesting part
tetra.plot.allSpetra + coord_cartesian(xlim = c(150, 850), ylim = c(0,0.55))

# Plot ALL SPECTRA as 3d SURFACE
plot.detector.allSpectra.interactable(tetra.spectra[ which(tetra.spectra$wavenumber>100 & tetra.spectra$wavenumber<1000), ], 
                                      title=expression(bold("Normalised Raman Spectra Of Tetrachloromethane For Different Polarised Light")))

# Plot the HEIGHT OF PEAKS against the wave plates position
plot(x=tetra.peakChange.final$waveplate, y=tetra.peakChange.final[,2], type="n", ylim=c(0,1),
     main = "Peakheight Change Due To Polarisation Change",
     xlab = "waveplate rotation / °",
     ylab = "normalised peak height")
# Plot final peak change
for (index in seq_along(tetra.peakChange.final[,-1])) lines(x=tetra.peakChange.final$waveplate, y=tetra.peakChange.final[,index+1], col=index, type="o")
# Plot peak change before rescaling with white lamp spectra
for (index in seq_along(tetra.peakChange[,-1])) lines(x=tetra.peakChange$waveplate, y=tetra.peakChange[,index+1], col=index+5, type="o")

# Plot the quotient of the DETECTOR RESPONSE along its optical axis
plot(tetra.sensibility, type="h", lwd=2,
     main = "Quotient of maximal and minimal detector response",
     xlab = "max/min",
     ylab = expression("wavenumber / cm"^"-1") )

