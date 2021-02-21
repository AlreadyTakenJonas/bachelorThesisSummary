# Read some important code
# Read data
source("R/fibers.R")
require(dplyr)

# Create a plot
plot.intensity.change(  data  = F1.stokes,
                        title = "Transmission Behaviour of PM-Fiber F1" )
plot.intensity.change(  data  = F2.stokes,
                        title = "Transmission Behaviour of SM-Fiber F2" )
plot.intensity.change(  data  = F3.stokes,
                        title = "Transmission Behaviour of MM-Fiber F3" )


plot.polarisation(  data       = F1.stokes, 
                    statistics = F1.error,
                    title      = expression(bold("F1's Influence on the Degree of Polarisation "*Pi))   ) +
  theme(legend.position = "right",
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1) ) +
  scale_y_continuous(breaks = seq(from = 0, to = 110, by = 20))
plot.polarisation(  data       = F2.stokes, 
                    statistics = F2.error,
                    title      = expression(bold("F2's Influence on the Degree of Polarisation "*Pi))   ) +
  theme(legend.position = "right",
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1) ) +
  scale_y_continuous(breaks = seq(from = 0, to = 110, by = 20))
plot.polarisation(  data       = F3.stokes, 
                    statistics = F3.error,
                    title      = expression(bold("F3's Influence on the Degree of Polarisation "*Pi))   ) +
  theme(legend.position = "right",
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1) ) +
  scale_y_continuous(breaks = seq(from = 0, to = 110, by = 20))


# Read data
F2.rotation <- read.table(file = "data/F2_rotation.csv", header = T)
F3.rotation <- read.table(file = "data/F3_rotation.csv", header = T)

# Add group column for facets
F2.rotation[["fiber"]] <- "single-mode"
F3.rotation[["fiber"]] <- "multi-mode"

# Shift the data by the initial angle of rotation -> data aligns nicely with line through origin
# Combine table for F2 and F3 into single table
F2F3.rotation <- lapply(list(F2.rotation, F3.rotation), function(table) {
  # Remove NA
  table <- table[!is.na(table[["X"]]),]
  # Shift data
  table[["before"]] <- table[["Y2"]] - table[["Y2"]][table[["X"]]==0]
  # Shift data
  table[["after"]]  <- table[["Y1"]] - table[["Y1"]][table[["X"]]==0]
  return(table)
}) %>% dplyr::bind_rows(.)

# Subset data
F2F3.rotation <- F2F3.rotation[0 <= F2F3.rotation[["X"]] & F2F3.rotation[["X"]] <= 180,]

# Plot data
ggplot( data = F2F3.rotation ) +
  # Verlauf einer idealen Wellenplatte
  geom_abline( mapping = aes(intercept = 0, slope = 2, color="c_ideal"),
               size = 1 ) +
  geom_abline( mapping = aes(intercept = 0, slope = -2, color="c_ideal") ,
               size = 1) +
  # Gemessener Verlauf vorher/nachher
  geom_point( mapping = aes(x = X, y = before, color = "a_vorher") ) +
  geom_point( mapping = aes(x = X, y = after, color = "b_nachher") ) +
  # Formatting
  theme_hot() +
  theme( strip.text.x = element_text(face="bold", size=12),
         axis.title.x  = element_text(face="bold", size=13),
         legend.position = "right",
         axis.title.y = element_text(face="bold", size=15) ) +
  scale_color_manual( labels = c("before", "after", "ideal"), values = scales::hue_pal()(3) ) + 
  scale_x_continuous(breaks = seq(from=0, to=300, by=45) ) +
  scale_y_continuous(breaks = seq(from=-360, to=360, by=90) ) +
  labs(   title = "Fiber-Induced Rotation of the Plane of Polarisation",
          y = expression(bold(epsilon*" / °")),
          x = expression(bold("Rotation of Half-Waveplate "*omega*" / °")),
          color = element_blank()
  ) +
  facet_wrap(facets = vars(fiber), scales = "free_y")


# Plot data
plot.stokesPredict(data = F1.stokes, title = "Validating F1's Mueller-Matrix")
plot.stokesPredict(data = F2.stokes, title = "Validating F2's Mueller-Matrix")
plot.stokesPredict(data = F3.stokes, title = "Validating F3's Mueller-Matrix")
