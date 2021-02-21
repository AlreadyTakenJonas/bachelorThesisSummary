# Get some libraries and shit
source("R/lib.R")
require("tidyr")
require("gganimate")

# Read data from file
tetra.spectra <- read.table(file = "data/tetra_spectra.csv", header=T)

tetra.spectra <- pivot_longer(tetra.spectra, cols = !wavenumber, 
                              names_to = "P", values_to = "signal")
tetra.spectra$P <- gsub("X", "", tetra.spectra$P) %>% as.numeric
animateTetra <-
  ggplot(data = tetra.spectra,
         mapping = aes(x = wavenumber, y = signal, color = P, group = P)) +
  geom_line(size=1) +
  theme_hot() +
  theme(text = element_text(face="bold", size=16),
        axis.text = element_text(face="bold", size=16),
        legend.position = "right") +
  scale_x_continuous(limits = c(200,850)) +
  scale_color_gradientn(colours=scales::hue_pal()(3), 
                        breaks=seq(from=0, to=180, by=45)) +
  labs(x = expression(bold("Wavenumber "*nu*" / cm"^"-1")),
       y = "norm. Intensity",
       title = "Raman Spectra of Tetrachloromethane",
       color = expression(omega*" / °")) +
  transition_time(P)
animate(animateTetra, fps = 4, rewind=F, end_pause = 2, start_pause=2)

# Read data from file
tetra.realPeakChange <- read.table(file = "data/tetra_realPeakChange.csv", header=T)
# Create plot
ggplot(data = tidyr::pivot_longer(tetra.realPeakChange, cols=!waveplate,
                                  names_to="wavenumber", values_to="signal",
                                  names_pattern="(\\d+)"),
       mapping = aes(x=waveplate, y=signal, group=wavenumber, color=wavenumber) ) +
  geom_line(size=2) + geom_point(size=3) +
  theme_hot() + 
  theme(legend.position = "right",
        text = element_text(face="bold", size=16),
        axis.text = element_text(face="bold", size=16) ) +
  scale_x_continuous(breaks = seq(from=0, to=180, by=45)) +
  labs(x = expression(bold("Rotation of the Half-Waveplate "*omega*" / °")),
       y = "norm. Intensity",
       title = "Peakheight of Tetrachloromethane",
       color = expression(bold(nu*" / cm"^"-1")) )
