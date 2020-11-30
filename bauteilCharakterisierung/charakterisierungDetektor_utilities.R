library("RHotStuff")
library("magrittr")
library("ggplot2")
library("fields")

# Make sure the version of RHotStuff is compatible with the code
check.version("1.5.0")

# CONVERT TIME SERIES OF SPECTRA INTO EASY PLOTABLE DATA.FRAME
# This function turns a data.frame with multiple spectra organised in multiple columns into a data.frames with all spectra staked in the same columns
# Makes plotting with ggplot easier
makeSpectraPlotable <- function(spectra, colorFunc=function(x) return(x)) {
  # PARAMETERS
  # spectra : the return value of parseTimeSeries.elab, contains a time series with multiple spectra
  # colorFunc : a custom function applied to the time variable (in this case the position of the linear polariser) to tweak the color scale
  # RETURN VALUE
  # A data.frame with all spectra stacked on top of each other. data.frame has the columns: wavenumber, signal, P (linear polarisers rotation), color
  
  # Extract the position of the linear polariser from the column names and repeat the value to match the length of the corresponding spectrum
  # Used for colouring and grouping the data correctly when plotting with ggplot
  polariser <- lapply(seq_along(spectra[,-1])+1, function(index) {
    rep( colnames(spectra)[index], length.out=length(spectra[,index]) ) 
  } ) %>% unlist %>% as.numeric
  
  # Create a dataframe with all spectra stacked on top of each other, instead of every spectrum in an own column
  data.frame(wavenumber   = spectra$wavenumber,
             signal       = unlist(spectra[,-1]) %>% unname,
             P            = polariser,
             # Hand the polariser position to a custom function to tweak the color scale
             color        = colorFunc(polariser)
  )
}



#
# PLOTING FUNCTIONS
#
# Plot all measured WHITE LIGHT SPECTRA in one plot and color code them according to the rotation of the linear polariser
# The color should show the absolute DEVIATION of the lasers plane of polarisation FROM THE DETECTORS MOST SENSITIVE AXIS 
plot.detector.whitelamp <- function(data,
                                    title = "The Changing Detector Response For Different Linear Polarised White Light <Of Your Equipment>"
                                   ) {
  # PARAMETERS
  # data : plotable time series of spectra. Use the return value of RHotStuff::parseTimeSeries.elab() %>% makeSpectraPlotable()
  # title : Some descriptive title
  
  ggplot( data = data,
          mapping = aes(x = wavenumber, y = signal, group = P, color = color)
         ) +
    scale_color_gradient(low    = "blue", 
                         high   = "red", 
                         breaks = seq(from=0, to=90, by=22.5)
                        ) +
    theme_hot() +
    labs(title = title,
         y = "counts",
         x = expression(bold("wavenumber / cm"^"-1")),
         subtitle = "the color gradient encodes the absolute deviation D of the linear polarisers position \nfrom the detectors most sensitive axis",
         color = "D / °") +
    geom_line()
  
}

# Plot the WHITE LAMP SPECTRA in one 3d plot as 3D SURFACE (rotatable plot with openGL)
plot.detector.allSpectra.interactable <- function(data, 
                                                  title = expression(bold("White Lamp Raman Spectra For Different Polarised Light")) 
) {
  # PARAMETER
  # data : plotable time series of spectra. Use the return value of RHotStuff::parseTimeSeries.elab() %>% makeSpectraPlotable()
  # title : Some descriptive title
  
  # Extract data
  wavenumber <- detector.spectra[[2]][,1]
  polariser  <- colnames(detector.spectra[[2]][,-1]) %>% as.numeric
  counts     <- detector.spectra[[2]][,-1] %>% as.matrix
  # Create a color ramp
  ncol = 100
  color = rev(rainbow(ncol, start = 0/6, end = 4/6))
  zcol  = cut(counts, ncol)
  # Plot the spectra as 3d surface
  rgl::persp3d( x = detector.spectra[[2]][,1],
                y = colnames(detector.spectra[[2]][,-1]) %>% as.numeric,
                z = detector.spectra[[2]][,-1] %>% as.matrix,
                col = color[zcol],
                xlab = expression(bold("wavenumber / cm"^"-1")),
                ylab = expression(bold("wave plate position / °")),
                zlab = expression(bold("detector signal / counts")),
                main = title )
  # Add grid to the axis
  rgl::grid3d(c("x+", "y+", "z"))
}

# Plot WHITE LAMP SPECTRA in one 3d plot as 3D SURFACE (single picture)
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
  plot.surface(surface, type="p", theta=theta, border=NA, phi=phi,
               xlab = "wavenumber / cm^-1",
               ylab = "wave plate position / °",
               zlab = "detector signal / counts",
               main = title)

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
