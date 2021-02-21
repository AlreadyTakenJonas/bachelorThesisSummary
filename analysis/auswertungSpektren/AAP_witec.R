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
# Save unprocessed spectra locally
write.table(AAP.spectra.unprocessed, file="../tmp/4-AAP_unprocessed.csv", row.names = F)


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
# Vector normalisation
AAP.spectra[,-1] <- apply(AAP.spectra[,-1], 2, function(spec) spec / sqrt(sum(spec^2)))



# FIND THE LOCATION OF THE PEAKS
# Plot single spectrum
plot(x = AAP.spectra$wavenumber, y = AAP.spectra$`0`, type="l")
abline(h=0)
locator()

which(max(AAP.spectra[,2]) == AAP.spectra[,2])
AAP.spectra$wavenumber[246]

plot(x=colnames(AAP.spectra[246,-1]), y=AAP.spectra[246,-1], type="o")

plot(x = AAP.spectra$wavenumber, y = AAP.spectra[,2], typ="n", xlim=c(1150,1700))
for(i in 2:ncol(AAP.spectra)) lines(x = AAP.spectra$wavenumber, y = AAP.spectra[,i], col=i)
locator()

findPeak <- function(interval, spectrum) {
  # Subset the spectrum to region around searched peak
  peakInterval <- spectrum[interval[1]<spectrum$wavenumber & spectrum$wavenumber<interval[2],]
  # Get the wavenumber of the maxium of the subset
  wavenumberPeak <- peakInterval$wavenumber[which.max(peakInterval[,2])]
  return(wavenumberPeak)
} 

#
# ESTIMATE DETECTOR ANISOTROPY WITH 4-AAP SPECTRA
# Divide for every wavenumber maximimal and minimal intensity
# Compare the resulting curve to results derived from white lamp spectra and
# Peak locations of 4-AAP spectrum
#
AAP.plotable.bias <- data.frame(
            # Wavenumber axis 
            wavenumber = AAP.spectra$wavenumber,
            # Detector bias derived from 4-AAP
            AAP.bias   = apply( AAP.spectra[,-1], 1, function(pixel) max(pixel)/min(pixel) ),
            # Detector bias derived from white lamp
            detector.bias = sapply(detector.bias, function(detector) {
                                bias <- approx( x    = detector$wavenumber, 
                                                y    = detector$bias, 
                                                xout = AAP.spectra$wavenumber )
                                return(bias$y)
                              }),
            # Single 4-AAP spectrum scaled to match common y-axis
            spectrum = AAP.spectra$`0`/max(AAP.spectra$`0`)+0.5
) %>% tidyr::pivot_longer(., cols=!wavenumber, names_to="exp", values_to="bias")
# Add new column for grouping the data into different plots
AAP.plotable.bias$facets = sapply(AAP.plotable.bias$exp, function(pixel) pixel=="spectrum" )
# Plot detector bias and spectrum
ggplot(AAP.plotable.bias, mapping=aes(x=wavenumber, y=bias, color=exp, group=exp)) +
  geom_line() + 
  facet_wrap(vars(facets), ncol=1, scales="free_y") +
  theme(strip.text = element_blank()) +
  coord_cartesian(ylim=c(0.5,1.5), xlim=c(500,1700))



# Plot ALL SPECTRA as 3d SURFACE
plot.detector.allSpectra.interactable(AAP.spectra, 
                                      title=expression(bold("Normalised Raman Spectra Of 4-AAP For Different Polarised Light")))

#
# CREATE PLOT FOR OVERLEAF
#
# Restructure data
AAP.plotable.spectra <- tidyr::pivot_longer(AAP.spectra, cols=!wavenumber,
                                            names_to="waveplate", values_to="signal")
# Write to file
write.table(AAP.plotable.spectra, 
            file="../overleaf/externalFilesForUpload/data/AAP_spectra.csv", row.names=F)
# Create plot
ggplot(AAP.plotable.spectra,
       mapping = aes(x=wavenumber, y=signal, group=waveplate, color=as.numeric(waveplate)) ) +
  geom_line() +
  scale_color_gradientn(colours=scales::hue_pal()(3), 
                        breaks=seq(from=0, to=90, by=30)) +
  theme_hot() +
  labs(x = expression(bold("Wellenzahl "*nu*" / cm"^"-1")),
       y = "normierte Intensität",
       color = expression(bold(omega*" / °")),
       title = "Polarisationsabhängige Ramanspektren von 4-AAP") #+
  #scale_x_continuous(limits=c(1150, 1700))
