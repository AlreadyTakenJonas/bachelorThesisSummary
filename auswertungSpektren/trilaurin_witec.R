#
# ANALYSING POLARISED RAMAN SPECTRA OF Trilaurin
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
# Trilaurin Spectra
trilaurin.spectra.unprocessed <- GET.elabftw.bycaption(84, header=T, outputHTTP=T) %>%
  parseTimeSeries.elab(., col.spectra=3, sep="") %>% .[[1]]

# Save unprocessed spectra locally
write.table(trilaurin.spectra.unprocessed, file="../tmp/trilaurin_unprocessed.csv", row.names = F)


# PREPROCESS
trilaurin.spectra <- trilaurin.spectra.unprocessed

#
# Remove the laser peak from the spectrum
#
trilaurin.spectra <- trilaurin.spectra[trilaurin.spectra$wavenumber>230,]


# Statistical Background Correction
#
# Peaks no longer available
# trilaurin.spectra[,-1] <- sapply(trilaurin.spectra[,-1], function(spec) spec-Peaks::SpectrumBackground(spec))
trilaurin.spectra[,-1] <- t( as.matrix(trilaurin.spectra[,-1]) ) %>%
  baseline::baseline(., method="fillPeaks", lambda=1, it=10, hwi=50, int=2000) %>%
  baseline::getCorrected(.) %>% t(.)


#
# Normalise each spectrum
#
# Normalisation with hghest point
# trilaurin.spectra[,-1] <- sapply(trilaurin.spectra[,-1], function(spec) spec/max(spec))
# Vector normalisation
trilaurin.spectra[,-1] <- apply(trilaurin.spectra[,-1], 2, function(spec) spec / sqrt(sum(spec^2)))



# FIND THE LOCATION OF THE PEAKS
# Plot single spectrum
plot(x = trilaurin.spectra$wavenumber, y = trilaurin.spectra$`0`, type="l")
locator()





# Plot ALL SPECTRA as 3d SURFACE
plot.detector.allSpectra.interactable(trilaurin.spectra, 
                                      title=expression(bold("Normalised Raman Spectra Of Trilaurin For Different Polarised Light")))

plot(trilaurin.spectra[,c(1,2)], type="l", col=1)
