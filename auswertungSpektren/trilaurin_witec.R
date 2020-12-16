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
trilaurin.spectra.unprocessed <- GET.elabftw.bycaption(79, header=T, outputHTTP=T) %>%
  parseTimeSeries.elab(., col.spectra=3, sep="") %>% .[[1]]

# PREPROCESS
trilaurin.spectra <- trilaurin.spectra.unprocessed
