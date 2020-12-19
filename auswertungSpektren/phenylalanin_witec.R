#
# ANALYSING POLARISED RAMAN SPECTRA OF 4-phenylalanin
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
# phenylalanin Spectra
phenylalanin.spectra.unprocessed <- GET.elabftw.bycaption(83, header=T, outputHTTP=T) %>%
  parseTimeSeries.elab(., col.spectra=3, sep="") %>% .[[1]]
# Save unprocessed spectra locally
write.table(phenylalanin.spectra.unprocessed, file="../tmp/phenylalanin_unprocessed.csv", row.names = F)


# PREPROCESS
phenylalanin.spectra <- phenylalanin.spectra.unprocessed

#
# Remove the laser peak from the spectrum
#
phenylalanin.spectra <- phenylalanin.spectra[phenylalanin.spectra$wavenumber>150 & phenylalanin.spectra$wavenumber<2000,]


# Statistical Background Correction
#
# Peaks no longer available
phenylalanin.spectra[,-1] <- sapply(phenylalanin.spectra[,-1], function(spec) spec-Peaks::SpectrumBackground(spec))
phenylalanin.spectra[,-1] <- t( as.matrix(phenylalanin.spectra[,-1]) ) %>%
  baseline::baseline(., method="fillPeaks", lambda=1, it=10, hwi=50, int=2000) %>%
  baseline::getCorrected(.) %>% t(.)


#
# Normalise each spectrum
#
# Normalisation with hghest point
# phenylalanin.spectra[,-1] <- sapply(phenylalanin.spectra[,-1], function(spec) spec/max(spec))
# Vector normalisation
phenylalanin.spectra[,-1] <- apply(phenylalanin.spectra[,-1], 2, function(spec) {
  spec / sqrt(sum(spec^2))
})


# FIND THE LOCATION OF THE PEAKS
# Plot single spectrum
plot(x = phenylalanin.spectra$wavenumber, y = phenylalanin.spectra$`0`, type="l")
for(i in 3:10) { lines(phenylalanin.spectra[,c(1,i)], type="l", col=i) }

which(phenylalanin.spectra$`0`== max(phenylalanin.spectra[,2]))
plot(colnames(phenylalanin.spectra[,-1]), 
     phenylalanin.spectra[176, -1]/max(phenylalanin.spectra[176, -1]), type="o")
