library("RHotStuff")
library("magrittr")
library("ggplot2")

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