library("RHotStuff")
library("magrittr")
library("ggplot2")


#
# FETCH DATA FROM ELABFTW
#
P3.absorbance <- GET.elabftw.bycaption(78, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                          func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                          header=T, skip=14, sep=";") %>% .[[1]]
colnames(P3.absorbance) <- c("P3", "P4", "background", "measured")

#
# ANALYSE DATA
#
# Normalise data
P3.absorbance$transmittance <- P3.absorbance$measured / P3.absorbance$background

#
# PLOT THAT SHIT
#
# Does the transmittance of the linear polariser change when rotating the polariser and the laser in the same manner?
ggplot(data = P3.absorbance,
       mapping = aes(x = P3, y = transmittance*100) ) +
  geom_bar(stat="identity") +
  theme_classic() +
  theme( axis.text = element_text(size=12),
         axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),
         panel.grid.major.y = element_line("black", size = 0.1),
         panel.grid.minor.y = element_line("grey", size = 0.5) ) +
  scale_y_continuous(expand = c(0,0)) +
  scale_x_continuous(breaks = P3.absorbance$P3) +
  labs(title = expression(bold("The maximal transmittance of the linear polariser P3")),
       x = expression(bold("rotation of P3 or the lasers plane of polarisation / °")),
       y = expression(bold("transmittance / %"))
       )
