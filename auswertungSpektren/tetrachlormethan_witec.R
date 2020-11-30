#
# ANALYSING POLARISED RAMAN SPECTRA OF TETRA
#

#library("RHotStuff")
#library("magrittr")
#check.version("1.6.0")
# Load functions and libraries from detector analysis for plotting spectra
source("bauteilCharakterisierung/charakterisierungDetektor_utilities.R")


# Fetch data
tetra.spectra <- GET.elabftw.bycaption(79, header=T, outputHTTP=T) %>%
                  parseTimeSeries.elab(., col.spectra=3, sep="")


plot.detector.allSpectra.interactable(tetra.spectra[[1]])
