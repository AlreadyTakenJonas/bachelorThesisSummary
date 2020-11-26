#
# CHARACTERISING THE WITEC DETECTOR
#
# How does the detector response changes when changing the orientation of the lasers plane of polarisation?

#
# Get some libraries and functions used for characterising the detector and plotting stuff
#
source("bauteilCharakterisierung/charakterisierungDetektor_utilities.R")



# Fetch experimental data from elabFTW
detector.spectra <- GET.elabftw.bycaption(76, header=T, outputHTTP=T) %>% parseTimeSeries.elab(., header=F, sep="")


#
# PLOT THAT SHIT
#

# Plot the white lamp spectra
plot.detector.whitelamp(data=makeSpectraPlotable(detector.spectra[[2]], 
                                                 colorFunc=function(polariserRotation) {mod(polariserRotation, 180) %>% `-`(.,90) %>% abs(.)} ), 
                        title="The Changing Detector Response For Different Linear Polarised White Light Of The WiTecs Detector")




colnames(detector.spectra[[2]][,-1])[apply(detector.spectra[[2]][,-1],1,which.max)]

 #plot(detector.spectra[[2]][,1], as.numeric(colnames(detector.spectra[[2]])[-1]), col=detector.spectra[[2]][,-1])

#plot(apply(detector.spectra[[2]][,-1],1,function(x) x/max(x)),type="l")
#colnames(detector.spectra[[2]])[apply(detector.spectra[[2]][,-1],1,which.min)]
#apply(detector.spectra[[2]][,-1],1,which.min)

#plot(detector.spectra[[2]][,1],detector.spectra[[2]][,21],type="l")
#lines(detector.spectra[[2]][,1],detector.spectra[[2]][,2],type="l",col="red")
#lines(detector.spectra[[2]][,1],detector.spectra[[2]][,19],type="l",col="red")

#filled.contour(x=detector.spectra[[2]][,1],
#        y=as.numeric(colnames(detector.spectra[[2]])[-1]),
#        z=as.matrix(detector.spectra[[2]][,-1]-apply(detector.spectra[[2]][,-1],1,max)))
