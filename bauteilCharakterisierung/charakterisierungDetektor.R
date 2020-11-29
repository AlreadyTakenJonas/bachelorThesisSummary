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

# Plot the white lamp spectra for the detector without the microscope
plot.detector.whitelamp(data=makeSpectraPlotable(detector.spectra[[2]], 
                                                 colorFunc=function(polariserRotation) {mod(polariserRotation, 180) %>% `-`(.,90) %>% abs(.)} ), 
                        title="The Changing Detector Response For Different Linear Polarised White Light Of The WiTecs Detector")

# Plot the white lamp spectra for the detector with the microscope
plot.detector.whitelamp(data=makeSpectraPlotable(detector.spectra[[1]], 
                                                 colorFunc=function(polariserRotation) {mod(polariserRotation, 180) %>% `-`(.,90) %>% abs(.)} ), 
                        title="The Changing Detector Response For Different Linear Polarised White Light Of The WiTecs Detector And Microscope")


# How does the sensitivity of the detector change with the wavenumber
ggplot( data = data.frame(wavenumber = detector.spectra[[2]]$wavenumber,
                          difference = apply(detector.spectra[[2]][,-1], 1, function(slice) { max(slice)-min(slice) }) 
                          ),
        mapping = aes(x=wavenumber, y=difference)) +
  theme_hot() +
  labs(title = "Difference between maximal and minimal detector response",
       x = expression(bold("wavenumber / cm"^"-1")),
       y = "count difference") +
  geom_line()

# How does the sensitivity of the detector change with the wavenumber (difference method)
ggplot( data = data.frame(wavenumber = detector.spectra[[2]]$wavenumber,
                          difference = apply(detector.spectra[[2]][,-1], 1, function(slice) { max(slice)-min(slice) }) 
                        ),
        mapping = aes(x=wavenumber, y=difference) ) +
  theme_hot() +
  labs(title = "Difference between maximal and minimal detector response",
       x = expression(bold("wavenumber / cm"^"-1")),
       y = "count difference") +
  geom_line()


# How does the sensitivity of the detector change with the wavenumber (quotient method)
ggplot( data = data.frame(wavenumber = detector.spectra[[2]]$wavenumber,
                          quotient   = apply(detector.spectra[[2]][,-1], 1, function(slice) { min(slice)/max(slice) }) 
                          ),
        mapping = aes(x=wavenumber, y=quotient) ) +
  theme_hot() +
  labs(title = "Quotient of maximal and minimal detector response",
       x = expression(bold("wavenumber / cm"^"-1")),
       y = "min/max") +
  geom_line()



#
# Plot all spectra as 3d-surface
#
library(fields)
plot.detector.allSpectra <- function(data,
                                     title = expression(bold("The White Lamp Raman Spectra For Different Polarised Light")),
                                     color.resolution = 100,
                                     color.ramp = c("blue", "red"),
                                     theta = 270,
                                     phi = 20,
                                     grid.resolution.X = 20,
                                     grid.resolution.Y = 2
                                     
) {
  # Seperate wavenumber axis, polariser position and spectra
  PlotMat <- as.matrix(data[, -1])
  wavenumber <- data$wavenumber
  polariser <- as.numeric( colnames(PlotMat) )
  
  # Create a grid for plotting
  grid <- list(ordinate = wavenumber, abcissa = polariser)
  grid.surface <- make.surface.grid(grid)
  
  # Create a 3d plottable surface
  surface <- as.surface(grid.surface, PlotMat)
  
  # Create color palette
  col.Palette <- colorRampPalette(color.ramp)(color.resolution)
  # Calculate Color of the surface according to the z-value of the corresponding point
  zfacet <- PlotMat[-1, -1] + PlotMat[-1, -ncol(PlotMat)] + PlotMat[-nrow(PlotMat), -1] + PlotMat[-nrow(PlotMat), -ncol(PlotMat)] 
  facetcol <- cut(zfacet, color.resolution)
  plotCol <- persp(surface, theta=theta, phi=phi)
  
  # Create the plor
  plot.surface(surface, type="p", theta=theta, border=NA, phi=phi)
  
  # Add grid lines
  # Get the position of the gridlines
  select.X <- seq(1,length(grid[[1]]), by=grid.resolution.X)
  select.Y <- seq(1,length(grid[[2]]), by=grid.resolution.Y)
  xGrid <- grid[[1]][select.X]
  yGrid <- grid[[2]][select.Y]
  
  # Draw the gridlines
  for(i in select.X) lines(trans3d(x=rep(grid[[1]][i],ncol(PlotMat)),
                               y=grid[[2]],
                               z=PlotMat[i,],pmat=plotCol))
  for(i in select.Y) lines(trans3d(x=grid[[1]],
                               y=rep(grid[[2]][i],nrow(PlotMat)),
                               z=PlotMat[,i],pmat=plotCol))
}
plot.detector.allSpectra(detector.spectra[[2]][,-c(21:24)])



rgl::persp3d()
