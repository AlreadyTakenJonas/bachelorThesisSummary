require(dplyr) # Used for transforming list of data frames into one data frame
require(magrittr) # Used for piping %>%
require(ggplot2)
require(fields) # -> tim.colors
require(RHotStuff)

# SETTINGS

# PolaRam output
input_path <- "muellersim/output_maltose_ellipse-longY.txt"
output_path <- "visualisation/spectra_maltose_longY_normal.png"
# Angle of polarisation in degrees that shall be plotted (every angle will be rounded to the nearest integer)
epsilonToPlot <- c(0, 45, 90, 135)
# Should the spectrum be normalised with the highes peak?
normalise.spectrum <- T
# The title of the plot
plot.title <- "Simulated and normalised raman spectra of maltose for different polarised incident light"
# Lowest wavenumber, that can be plotted
minimalWavenumber <- 300


#
# ACTUAL CODE
#

# Read data
  rawdata <- read.csv(input_path, comment.char = "#", sep = "", header = F)
  
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
  
  # Create a list of angles that should be plotted
  sigmaToPlot <- unique(data$sigma[round(data$sigma*180/pi) == round(epsilonToPlot*2)])
  
  #
  # Create spectra
  #
  
  # Create for every sigma a data frame of the raman spectrum and combine all data frames into one
  spectrumdf <- lapply(sigmaToPlot, function(sigma) {
    wavenumbers <- seq( from = min(data$v)-100, to = max(data$v)+100, by = 1 )
    wavenumbers <- wavenumbers[wavenumbers > minimalWavenumber]
    
    # Extract all entries with the same inital stokes angle sigma
    # distinct makes sure that no peaks are countet multiple times (remember: 0°=360°)
    subset <- data[data$sigma==sigma,] %>% distinct(v, .keep_all = T)
    
    data.frame( v      = wavenumbers,
                signal = polaram.as.spectrum(wavenumbers, subset$S0.R, subset$S1.R, subset$v, 25, T),
                epsilon  = round(sigma/2/pi*180) )
  }) %>% bind_rows
  
  
  #
  # Plot that shit
  #
  ggplot( data = spectrumdf, mapping = aes(x = v, y = signal, color = epsilon, group = epsilon) ) +
          theme_classic() +
          labs( x = expression("wavenumber / cm"^"-1"),
                y = "rel. signal strength",
                color = expression(epsilon*" / °"),
                title = plot.title,
                subtitle = expression("The angle "*epsilon*" is the angle between the x-axis and the incident lights plane of polarisation.")
              ) +
          scale_color_gradientn( colours = tim.colors(),
                                 breaks = unique(spectrumdf$epsilon)
                              ) +
          geom_line() +
    theme(text = element_text(size = 20),
          #aspect.ratio = 1,
          panel.grid.major = element_line(colour = "grey", size=0.5),
          panel.grid.minor = element_line(colour = "grey", size=0.25)
    )

  #ggsave(filename = output_path, device = png(width = 800, height = 300))
  