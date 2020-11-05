require(RHotStuff)
require(ggplot2)


#
# LINEARPOLARISATOR P1
#
# Extract data from eLabFTW
data <- GET.elabftw.byselector(29, header = T)[[1]]

# Normalise data
data$Y4 <- data$Y4/data$Y2 *100

# Plot
ggplot(data = data, mapping = aes(x = Y3, y = Y4)) +
  geom_point() +
  theme_minimal() +
  labs(title = "Winkelabhängige Transmission von Linearpolarisator P1",
       x = "Rotationswinkel / °",
       y = "Anteil der Strahlung, die den Polarisator passieren / %")


#
# LINEARPOLARISATOR P2
#
# Extract data from eLabFTW
data <- GET.elabftw.byselector(30, header = T)[[1]]

# Normalise data
data$Y4 <- data$Y4/data$Y2 *100

# Plot
ggplot(data = data, mapping = aes(x = Y3, y = Y4)) +
  geom_point() +
  theme_minimal() +
  labs(title = "Winkelabhängige Transmission von Linearpolarisator P2",
       x = "Rotationswinkel / °",
       y = "Anteil der Strahlung, die den Polarisator passieren / %")
