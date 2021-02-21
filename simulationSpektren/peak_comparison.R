require(magrittr) # Used for piping %>%
library(dplyr)    # Used for data frame manipulation
require(ggplot2)
require(gganimate)
require(fields)
require(RHotStuff) # Some utility functions



# Define output folder for animation
output.dir <- ""
# Define file containing the simulation results (-> PolaRam simulate)
data.path  <- "muellersim/output_maltose_circle.txt"
# Define the title of the plot
plot.title <- "Maltose"
# Index of peak that will be put on the x-axis
mainpeakindex <- 10


#
# IMPORTANT ASSUMPTION: The fourth component of all stokes vectors is zero
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

# Write the height of a specific peak for every sigma in the data frame
mainpeak <- unique(data$v)[mainpeakindex]

#
# Create spectra
#

# Create for every sigma a data frame of the raman spectrum and combine all data frames into one
peakdf <- lapply(unique(data$sigma), function(sigma) {
  wavenumbers <- unique(data$v)
  # Fine tune how many and which peaks will be calculated and shown
  wavenumbers <-wavenumbers[seq(from = 5, to = length(wavenumbers), by = 10)] %>% sort
  
  # Extract all entries with the same initial stokes angle sigma
  # distinct makes sure that no peaks are counted multiple times (remember: 0°=360°)
  subset <- data[data$sigma==sigma,] %>% distinct(v, .keep_all = T)

  # Calculate the height of every signal
  signal <- polaram.as.spectrum(wavenumbers, subset$S0.R, subset$S1.R, subset$v)
  
  data.frame( v      = wavenumbers,
              signal = signal,
              sigma  = sigma,
              mainpeaksignal = signal[subset$v == mainpeak] 
            )
}) %>% bind_rows

# CREATE FIGURE
#
# Plot will show the height of each peak in comparison to one specific peak

peakplot <- ggplot() +
  theme_classic() +
  labs( x = paste0("rel. signal strength at ", mainpeak, "/cm"),
        y = expression("rel. signal strength at "*nu),
        title = "The change in signal strength for different polarised incident light",
        subtitle = plot.title,
        color = expression(nu*" / cm"^"-1")
  ) +
  scale_color_gradientn(colors = tim.colors()) +
  theme(text = element_text(size = 20),
        #aspect.ratio = 1,
        panel.grid.major = element_line(colour = "grey", size=0.5),
        panel.grid.minor = element_line(colour = "grey", size=0.25)
  ) +
  geom_line( data = peakdf,
             mapping = aes( x = mainpeaksignal, y = signal, group = v, color = v)
  )

peakplot
