# Get some libraries and shit
source("R/lib.R")

# Read data from file
tetra.simulatedPeakChange <- read.table(file="data/tetra_simulatedPeakChange.csv", header=T)
tetra.simulatedPeakChange$wavenumber <- gsub("Zusammenfassung", "Summary", tetra.simulatedPeakChange$wavenumber)
# Plot that shit
ggplot(data = tetra.simulatedPeakChange,
       mapping = aes( x = waveplate, y = signal, group = group, color = source ) ) +
  facet_wrap(facets = vars(wavenumber), scales="free_y", ncol=3 ) +
  geom_line() + geom_point() + 
  theme_hot() + 
  theme(strip.text.x = element_text(face="bold"),
        legend.position = "right") +
  scale_color_manual(name   = element_blank(), 
                     labels = c("Measured", "Simulated"),
                     values = scales::hue_pal()(2)) +
  labs(x = expression(bold("Rotation of the Half-Waveplate "*omega*" / °")),
       y = "norm. Intensity",
       title = "Simulating the Anisotrope Raman Spectrometer")
