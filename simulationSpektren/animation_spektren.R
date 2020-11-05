require(magrittr) # Used for piping %>%
library(dplyr)    # Used for data frame manipulation
require(ggplot2)
require(gganimate)
require(fields)
require(RHotStuff)


# Define output folder for animation
output.dir <- "visualisation/maltose/frames_longY_normal"
# Define file containing the simulation results (-> PolaRam simulate)
data.path  <- "muellersim/output_maltose_ellipse-longY.txt"
# Define the title of the plot
plot.title <- "Simulierte und normalisierte Ramanspektren von Maltose für verschieden polarisiertes Anregungslicht"
normalise.spectrum <- T
# Lowest wavenumber, that can be plotted
minimalWavenumber <- 300


#
# IMPORTANT ASSUMPTION: The fourth component of all stokes vectors is zero
#

#
# UTILITY FUNCTIONS
#

# Create a function that computes the lorentz curves for every peak in a spectrum
# The lorentz curves will be added together to get the whole spectrum
# rawdata is a data.frame containing the scattered stokes parameters, the wavenumber of the peaks and an angle, 
#   characterising the polar stokes parameter sigma of initial polarisation state
spectrum <- function( x, data, sigma, gamma, normalise = F ) {
  
  # Extract all entries with the same inital stokes angle sigma
  # distinct makes sure that no peaks are countet multiple times (remember: 0°=360°)
  subset <- data[data$sigma==sigma,] %>% distinct(v, .keep_all = T)
  
  # Make gamma the same length as the subset
  # Avoids errors when computing the lorentz curves
  gamma <- rep( gamma, length.out = length(subset[,1]) )
  
  # The intensity of the scatterd light in x- and y-direction
  intensity.x <- (subset$S0.R + subset$S1.R) / 2
  intensity.y <- (subset$S0.R - subset$S1.R) / 2
  
  # The signal response of the detector
  detector.response <- 2*intensity.x + 1*intensity.y
  
  # Compute spectrum as sum of lorentz curves
  # Each peak is a lorentz curve
  spectrum <- sapply(x, function(x) {
    # Compute the lorentz curve for every peak
    # The width is gamma, the maximum is at wavenumber and the detector.response scales the peak
    peaks <- detector.response / ( ( x^2 - subset$v^2 )^2 + gamma^2 * subset$v^2 )
    
    # Return the sum of all peaks
    return( sum(peaks) )
  })
  
  # Normalise the spectrum with the largest peak
  if (normalise == TRUE) spectrum <- spectrum / max(spectrum)
  
  # Return the spectrum
  return(spectrum)
  
}



#
# ACTUAL CODE
#

# Read data
rawdata <- read.csv(data.path, comment.char = "#", sep = "", header = F)

# Transform into useable form
data <- data.frame( v    = rawdata$V1 %>% as.character %>% strsplit(., "_") %>%  lapply(., function(x) { return(x[4]) }) %>% unlist %>% gsub("/cm", "", .) %>% as.numeric,
                    S0.R = rawdata$V6,
                    S1.R = rawdata$V7,
                    S2.R = rawdata$V8,
                    S0   = rawdata$V2,
                    S1   = rawdata$V3,
                    S2   = rawdata$V4
                  )
data$sigma.R <- better.acos(data$S0.R, data$S1.R, data$S2.R )
data$sigma   <- better.acos(data$S0  , data$S1  , data$S2   )


#
# Create indicator: Graph that demonstrates the orientation of the polarisation plain of the light
#
# 1. Create circle/ellipse showing all initial e-field angles and magnitudes
# 2. Create for every stokes angle the corresponding line the e-field oscillates on
#

# Calculate all e-field vectos that were used as initial state
E.polar <- data.frame( E  = sqrt( data$S0 ),
                       epsilon = data$sigma/2
                     ) %>% distinct()
# Mirror the field with respect to the x-axis, to cover all angles between 0 and 2*pi 
E.polar <- data.frame( E = c(E.polar$E, E.polar$E),
                       epsilon = c(E.polar$epsilon, E.polar$epsilon+pi) 
                     )
# Sort the data frame by column epsilon
E.polar <- arrange(E.polar, epsilon)
# Define a dataframe, describing the cartesian coordinate system, that will later be added to the polar plot
E.axis.length <- max(E.polar$E) +0.2
E.axis <- data.frame( E       = c(E.axis.length, 0   , E.axis.length, 0   , E.axis.length, 0   , E.axis.length, 0     ),
                      epsilon = c(0            , 0   , pi           , pi  , pi/2         , pi/2, 3*pi/2       , 3*pi/2),
                      group   = c("x1"         , "x1", "x2"         , "x2", "y1"         , "y1", "y2"         , "y2"  )
                    )

#
# Create spectra
#

# Create for every sigma a data frame of the raman spectrum and combine all data frames into one
spectrumdf <- lapply(unique(data$sigma), function(sigma) {
  wavenumbers <- seq( from = min(data$v)-100, to = max(data$v)+100, by = 1 )
  wavenumbers <- wavenumbers[wavenumbers > minimalWavenumber]
  
  # Extract all entries with the same inital stokes angle sigma
  # distinct makes sure that no peaks are countet multiple times (remember: 0°=360°)
  subset <- data[data$sigma==sigma,] %>% distinct(v, .keep_all = T)
  
  data.frame( v      = wavenumbers,
              signal = polaram.as.spectrum(wavenumbers, subset$S0.R, subset$S1.R, subset$v, 25, normalise.spectrum),
              sigma  = sigma )
}) %>% bind_rows





#
# CREATE ANIMATION
#

# All angles that will be covered by the animation
unique.sigma <- unique(data$sigma)[1]
lastframe    <- length( unique.sigma )
for ( index in seq(from = 1, to = lastframe, by = 1) ) {
  
  cat( paste("Frame", index, "/", length(unique.sigma), "\n" ) )
  # Incrementer. Defines wich polarisation plain is shown
  current.epsilon <- unique.sigma[index] / 2
  current.sigma   <- unique.sigma[index]
  
  
  # DEFINE GGPLOTS FOR ANIMATION:
  # 1. The initial electrical field vector
  # 2. The raman spectrum
  # 3. Place the first plot as inset into the spectrum
  
  # Plot electrical field in polar coordinates
  # Create plot
  polarplot <- ggplot() +
    theme_minimal() +
    # Define blank polar coordinate system
    coord_polar( theta = "y", start = -pi/2, direction = -1,  ) +
    scale_y_continuous( limits = c(0, 2*pi),
                        breaks = seq(from = 0, to = 2*pi, by = pi/4) 
    ) +
    scale_x_continuous( limits = c(0, E.axis.length),
                        breaks = seq(from = 0, to = max(E.polar$E), length.out = 5 )
    ) +
    theme( axis.title.x = element_blank(),
           axis.text.x  = element_blank(),
           axis.ticks.x = element_blank(),
           axis.title.y = element_blank(),
           axis.text.y  = element_blank(),
           axis.ticks.y = element_blank(),
           legend.position="none",
           panel.background = element_rect(fill = "white",
                                           color = "grey80"
           ) 
    ) +
    # Define cartesian coordinate axis
    geom_path( data = E.axis, mapping = aes( x = E, y = epsilon, group = group) ) +
    geom_text( mapping = aes(x = E.axis.length, y = 0.05 ), label = expression("E"["x"]) ) +
    geom_text( mapping = aes(x = E.axis.length, y = pi/2-0.05 ), label = expression("E"["y"]) ) +
    # Show current calculated polarisation plane
    geom_path( data = data.frame( E       = rep( c(0, E.polar$E[E.polar$epsilon == current.epsilon]), 2 ),
                                  epsilon = c(current.epsilon, current.epsilon, current.epsilon+pi, current.epsilon+pi) 
                                ),
               mapping = aes( x = E, y = epsilon, group = epsilon, color = "blue"),
               arrow = arrow(length=unit(0.30,"cm"), ends="last", type = "open"),
               size = 1.2 ) +
    # Show ellipse of all possible polarisation states
    geom_path( data = E.polar, mapping = aes(x = E, y = epsilon, color = "red") )
  
  #polarplot
  
  # Create raman spectrum
  spectrumplot <- ggplot() +
    theme_classic() +
    labs( x = expression("Wellenzahl / cm"^"-1"),
          y = "rel. Signalstärke",
          title = plot.title
    ) +
    theme(legend.position = "none",
          text = element_text(size = 20),
          panel.grid.major = element_line(colour = "grey", size=0.5),
          panel.grid.minor = element_line(colour = "grey", size=0.25)
         ) +
    scale_y_continuous( limits = c( min(spectrumdf$signal), max(spectrumdf$signal) ) ) +
    geom_line( data = spectrumdf[ spectrumdf$sigma == current.sigma, ],
               mapping = aes( x = v, y = signal, group = sigma)
              )
  
  spectrumplot
  
  # Open new output file which is named after the current index
  paddingZeros <- rep("0", ( nchar(as.character( lastframe )) - nchar(as.character(index)) ) )
  framenumber <- paste0( c( paddingZeros, index), collapse = "" )
  png( filename = paste0(output.dir, "/frame", framenumber, ".png"), width = 1600, height = 900)
  # Combine spectrum and inset (polarplot); print both to file
  vp <- viewport( height = 0.4, width = 0.4, x = 1.1, y = 0.95, just = c("right", "top") )
  print(spectrumplot)
  print(polarplot, vp = vp)
  # Close file
  dev.off()
  
} 
    
    