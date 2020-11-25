#
# CHARACTERISING THE WITEC DETECTOR
#
# How does the detector response changes when changing the orientation of the lasers plane of polarisation?

library("RHotStuff")
library("magrittr")
library("ggplot2")

# Make sure the version of RHotStuff is compatible with the code
check.version("1.5.0")

# Fetch experimental data from elabFTW
detector.spectra <- GET.elabftw.bycaption(76, header=T, outputHTTP=T) %>% parseTimeSeries.elab(., header=F, sep="")


#
# PLOT THAT SHIT
#
ggplot( data = data.frame(wavenumber = detector.spectra[[2]]$wavenumber,
                          signal = unlist(detector.spectra[[2]][,-1]) %>% unname,
                          group = lapply(seq_along(detector.spectra[[2]][,-1])+1, function(index) rep( colnames(detector.spectra[[2]])[index], length.out=length(detector.spectra[[2]][,index]) ) ) %>% unlist,
                          color = lapply(seq_along(detector.spectra[[2]][,-1])+1, function(index) rep( colnames(detector.spectra[[2]])[index], length.out=length(detector.spectra[[2]][,index]) ) ) %>% unlist %>%  as.numeric %>% `-`(.,170) %>% mod(.,90) %>% abs
                          ),
        mapping = aes(x = wavenumber, y = signal, group = group, color = color)
        ) +
  geom_line() +
  scale_color_gradient(low="blue", high="red")


colnames(detector.spectra[[2]])[apply(detector.spectra[[2]][,-1],1,which.min)]

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
