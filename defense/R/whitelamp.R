# Get some libraries and shit
source("R/lib.R")
require("dplyr")
require("gganimate")

facet.labels <- list( "Mit Mikroskop" = "With Microscope",
                      "Ohne Mikroskop" = "Without Microscope")

# Read data from file
whitelamp.spectra <- read.table(file = "data/detector_spectra.csv", header = T)
# Create plot
absoluteWhiteLamp <- 
  ggplot(distinct(whitelamp.spectra, color, wavenumber, exp, .keep_all=T),
         mapping = aes(x=wavenumber, y=signal, color=color, group=P) ) +
  geom_line(size=0.2) +
  facet_wrap(facets=vars(exp), scales = "free_y",
             labeller = as_labeller( function(x) {facet.labels[x]} )) +
  theme_hot() + 
  theme(strip.text = element_text(face="bold"), 
        legend.position = "right") +
  scale_color_gradient(low    = "blue", 
                       high   = "red", 
                       breaks = seq(from=0, to=90, by=45) ) +
  scale_x_continuous(breaks = seq(from=500, to=4000, by=1000)) +
  labs(x = expression(bold("Wavenumber "*nu*" / cm"^"-1")),
       y = expression(bold("norm. Intensity")),
       title = "Polarisation Dependent White Lamp Spectra",
       color = expression(bold(epsilon*" / °"))) +
  transition_reveal(color)
animate(absoluteWhiteLamp, rewind=F, fps=10, end_pause = 10,
        height = 4, width = 8, units = "in", res = 150)

# Read data from file
whitelamp.relDiff <- read.table(file = "data/detector_relDiff.csv", header = T)
# Create plot
relativeWhiteLamp <- 
  ggplot(distinct(whitelamp.relDiff, color, wavenumber, exp, .keep_all=T),
         mapping = aes(x=wavenumber, y=signal, color=color, group=P) ) +
  geom_line(size=0.2) +
  facet_wrap(facets=vars(exp), 
             labeller = as_labeller( function(x) {facet.labels[x]} )) +
  theme_hot() + 
  theme(strip.text = element_text(face="bold"), 
        legend.position = "right") +
  scale_color_gradient(low    = "blue", 
                       high   = "red", 
                       breaks = seq(from=0, to=90, by=45) ) +
  scale_x_continuous(breaks = seq(from=500, to=4000, by=1000)) +
  labs(x = expression(bold("Wavenumber "*nu*" / cm"^"-1")),
       y = expression(bold("Deviation "*Delta["rel"])),
       title = "The Spectrometers Anisotropy",
       color = expression(bold(epsilon*" / °"))) +
  transition_reveal(color)
animate(relativeWhiteLamp, rewind=F, fps=10, end_pause = 10,
        height = 4, width = 8, units = "in", res = 150)
