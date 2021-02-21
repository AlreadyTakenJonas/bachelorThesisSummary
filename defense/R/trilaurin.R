# Get some libraries and shit
source("R/lib.R")
require("gganimate")

# Read data from file
trilaurin.spectra <- read.table("data/trilaurin_spectra.csv", header=T)
# Plot
animateTrilaurin <-
  ggplot(data = trilaurin.spectra,
         mapping = aes(x = wavenumber, y = signal, color=as.numeric(waveplate)*2, group=waveplate) ) +
  geom_line() +
  scale_color_gradientn(colours=scales::hue_pal()(3), 
                        breaks=seq(from=0, to=180, by=45)) +
  theme_hot() +
  theme(legend.position="right") +
  labs( x = expression(bold("Wavenumber "*nu*" / cm"^"-1")),
        y = "norm. Intensity",
        color = expression(bold(epsilon*" / °")),
        title = "Raman Spectra of Trilaurin") +
  transition_time(waveplate)
animate(animateTrilaurin, fps = 10, rewind=T, end_pause = 10, start_pause=5)
