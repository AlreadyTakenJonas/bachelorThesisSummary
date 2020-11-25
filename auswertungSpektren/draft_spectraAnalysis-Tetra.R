#
# DRAFT FOR PLOTTING AND ANALYSING MEASURED RAMAN-SPECTRA OF TETRACHLOROMETHANE
#


# Read spectra from file
Specs <- sapply(dir("../data/2020-11-24_expID-79",pattern="Spec.Data",full.names=T),read.table,
                USE.NAMES = T,simplify=F)
# Get the waveplates orientation from the file name
names(Specs) <- stringr::str_extract(names(Specs),"(?<=W)[0-9]{3}")

# Load library for background correction
library("Peaks")
library.dynam("Peaks","Peaks",lib.loc=NULL)

# Create color palette for plotting
cols <- colorRampPalette(c("blue","red"))(length(Specs))

# Normalise with highest peak / Background correction
Specs2 <- lapply(Specs, function(sp) sp[,2] - Peaks::SpectrumBackground(sp[,2]))
Specs2 <- lapply(Specs2, function(sp) sp / max(sp[90:135]))


# Plot all spectra in one plot
plot(NA,type="l",col="white",xlim=c(100,850),ylim=c(0,1))
for(i in seq_along(Specs)) lines(Specs[[i]][,1],Specs2[[i]],col=cols[i])

# Get the location of all peaks -> used for calculating peak areas
margins <- data.frame(lower=c(184,267,418),upper=c(266,366,508))
ranges <- lapply(1:3,function(mar) which(Specs[[1]][,1] > margins$lower[mar] & Specs[[1]][,1] < margins$upper[mar]))

# Calculate the peak ratios (by area) for peak 1 and 2 in comparision to largest peak (peak 3)
Ratios <- t(sapply(Specs2, function(sp) c(Ratio1=sum(sp[ranges[[3]]]) / sum(sp[ranges[[1]]]),
                              Ratio2=sum(sp[ranges[[3]]]) / sum(sp[ranges[[2]]])) ))

# Plot peak reatios
plot(as.numeric(names(Specs))*2,Ratios[,1],pch=19,ylim=c(1,3),xlab="Laser Rotation",ylab="Ratio")
points(as.numeric(names(Specs))*2,Ratios[,2],pch=19,col="red")

# Plot one specific spectrum
plot(Specs2[[2]],type="l")
# Get coordinates of points in plot
locator()
