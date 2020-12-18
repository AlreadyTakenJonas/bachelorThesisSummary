#
# ANALYSING POLARISED RAMAN SPECTRA OF 4-AAP
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
# AAP Spectra
AAP.spectra.unprocessed <- GET.elabftw.bycaption(85, header=T, outputHTTP=T) %>%
  parseTimeSeries.elab(., col.spectra=3, sep="") %>% .[[1]]

# PREPROCESS
AAP.spectra <- AAP.spectra.unprocessed

#
# Remove the laser peak from the spectrum
#
AAP.spectra <- AAP.spectra[AAP.spectra$wavenumber>150,]


# Statistical Background Correction
#
# Peaks no longer available
# AAP.spectra[,-1] <- sapply(AAP.spectra[,-1], function(spec) spec-Peaks::SpectrumBackground(spec))
AAP.spectra[,-1] <- t( as.matrix(AAP.spectra[,-1]) ) %>%
  baseline::baseline(., method="fillPeaks", lambda=1, it=10, hwi=50, int=2000) %>%
  baseline::getCorrected(.) %>% t(.)


#
# Normalise each spectrum
#
# Normalisation with hghest point
# AAP.spectra[,-1] <- sapply(AAP.spectra[,-1], function(spec) spec/max(spec))
# Vector normalisation
AAP.spectra[,-1] <- apply(AAP.spectra[,-1], 2, function(spec) spec / sqrt(sum(spec^2)))



# FIND THE LOCATION OF THE PEAKS
# Plot single spectrum
plot(x = AAP.spectra$wavenumber, y = AAP.spectra$`0`, type="l")
locator()



# Plot ALL SPECTRA as 3d SURFACE
plot.detector.allSpectra.interactable(AAP.spectra, 
                                      title=expression(bold("Normalised Raman Spectra Of 4-AAP For Different Polarised Light")))

