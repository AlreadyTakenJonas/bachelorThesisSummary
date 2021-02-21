# Get some libraries and shit
source("R/lib.R")
require("gganimate")

# Read data from file
AAP.spectra <- read.table("data/AAP_spectra.csv", header=T)
# Plot
animateAAP <- 
  ggplot(data = AAP.spectra,
         mapping = aes(x = wavenumber, y = signal, color=as.numeric(waveplate)*2, group=waveplate) ) +
  geom_line() +
  scale_color_gradientn(colours=scales::hue_pal()(3), 
                        breaks=seq(from=0, to=180, by=45)) +
  theme_hot() +
  theme(legend.position="right") +
  labs( x = expression(bold("Wavenumber "*nu*" / cm"^"-1")),
        y = "norm. Intensity",
        color = expression(bold(epsilon*" / °")),
        title = "Excerpt Raman Spectra of 4-AAP") + 
  coord_cartesian(xlim=c(1150, 1700)) +
  transition_reveal(waveplate)
animate(animateAAP, fps = 10, rewind=F, end_pause = 10, start_pause=5)
