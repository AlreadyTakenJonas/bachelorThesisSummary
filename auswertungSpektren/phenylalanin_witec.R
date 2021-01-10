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



# FETCH DATA
# phenylalanin Spectra
phenylalanin.spectra.unprocessed <- GET.elabftw.bycaption(83, header=T, outputHTTP=T) %>%
  parseTimeSeries.elab(., col.spectra=3, sep="") %>% .[[1]]
# Save unprocessed spectra locally
write.table(phenylalanin.spectra.unprocessed, file="../tmp/phenylalanin_unprocessed.csv", row.names = F)


# PREPROCESS
phenylalanin.spectra <- phenylalanin.spectra.unprocessed
plot(x = phenylalanin.spectra.unprocessed$wavenumber, 
     y = phenylalanin.spectra.unprocessed$`0`, type="l", 
     xlim = c(250, 2000), ylim=c(250, 2500) )


#
# Remove the laser peak from the spectrum
#
phenylalanin.spectra <- phenylalanin.spectra[phenylalanin.spectra$wavenumber>250 & phenylalanin.spectra$wavenumber<2000,]


# Statistical Background Correction
#
# Peaks no longer available
#phenylalanin.spectra[,-1] <- sapply(phenylalanin.spectra[,-1], function(spec) spec-Peaks::SpectrumBackground(spec))
phenylalanin.spectra[,-1] <- t( as.matrix(phenylalanin.spectra[,-1]) ) %>%
  baseline::baseline(., method="fillPeaks", lambda=0.01, it=20, hwi=100, int=2000) %>%
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
abline(h=0)
for(i in 3:10) { lines(phenylalanin.spectra[,c(1,i)], type="l", col=i) }
locator()

# Highest Peak
phenylalanin.index.highestPeak <- which(phenylalanin.spectra$`0`== max(phenylalanin.spectra[,2]))
# Peak next to highest peak
phenylalanin.index.neighbouringPeak <- which( 
  phenylalanin.spectra$`0` == max(phenylalanin.spectra$`0`[ which(1020 < phenylalanin.spectra$wavenumber & phenylalanin.spectra$wavenumber < 1050) ])
)


#
# COMPUTE PEAK CHANGE RATIO
#
# sensitivity is the maximum of the peak height divided by its minimum
# phenylalanin.sensitivity <- data.frame( wavenumber  = phenylalanin.spectra$wavenumber[c(phenylalanin.index.highestPeak, phenylalanin.index.neighbouringPeak)],
#                                         sensitivity = c( max(phenylalanin.spectra[phenylalanin.index.highestPeak, -1])/min(phenylalanin.spectra[phenylalanin.index.highestPeak, -1]), 
#                                                          max(phenylalanin.spectra[phenylalanin.index.neighbouringPeak, -1])/min(phenylalanin.spectra[phenylalanin.index.neighbouringPeak, -1]) 
#                                                        )
#                                       )

#
# Plot change of peak height
#
plot(colnames(phenylalanin.spectra[,-1]), 
     phenylalanin.spectra[phenylalanin.index.neighbouringPeak, -1]/max(phenylalanin.spectra[phenylalanin.index.neighbouringPeak, -1]), 
     type="o", xaxp  = c(0, 90, 9), col="blue")
lines(colnames(phenylalanin.spectra[,-1]), 
      phenylalanin.spectra[phenylalanin.index.highestPeak, -1]/max(phenylalanin.spectra[phenylalanin.index.highestPeak, -1]),
      type="o", col="red")



#
# PLOT THE SPECTRA FOR OVERLEAF
#
# Reorganise data
phenylalanin.plotable.spectra <- 
  tidyr::pivot_longer(phenylalanin.spectra, cols=!wavenumber,
                      names_to="waveplate", values_to="signal")
# Write data to file
write.table(phenylalanin.plotable.spectra,
            file="../overleaf/externalFilesForUpload/data/phe_spectra.csv",
            row.names=F)

# Plot that shit
ggplot(data = phenylalanin.plotable.spectra,
       mapping = aes(x = wavenumber, y = signal, color=as.numeric(waveplate), group=waveplate) ) +
  geom_line() +
  scale_color_gradientn(colours=scales::hue_pal()(2), 
                        breaks=seq(from=0, to=90, by=30)) +
  theme_hot() +
  labs( x = expression(bold("Wellenzahl "*nu*" / cm"^"-1")),
        y = "normierte Intensität",
        color = expression(bold(omega*" / °")),
        title = "Polarisationsabhängige Ramanspektren von Phenylalanin")
