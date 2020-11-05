require(RHotStuff)
require(ggplot2)

#
# LINEARPOLARISATOR P1
#
# Extract Data from eLabFTW
metadata <- GET.elabftw.byselector(25, node.selector = "#meta-data")[[1]]
data <- GET.elabftw.byselector(25, header = T)[[1]]

# Normalise data
data$Y1 <- data$Y1 / metadata[3,2] *100

# Plot
ggplot(data = data, mapping = aes(x = X, y = Y1)) +
  geom_point(size = 0.5) +
  theme_minimal() +
  labs(title = "Die Durchlässigkeit des Linearpolarisators P1 in Abhänigkeit des Rotationswinkels",
       x = "Winkel / °",
       y = "Anteil der Strahlung, die den Polarisator passiert / %")



#
# LINEARPOLARISATOR P2
#
# Extract Data from eLabFTW
metadata <- GET.elabftw.byselector(26, node.selector = "#meta-data")[[1]]
data <- GET.elabftw.byselector(26, header = T)[[1]]

# Normalise data
data$Y1 <- data$Y1 / metadata[3,2] *100

# Plot
ggplot(data = data, mapping = aes(x = X, y = Y1)) +
  geom_point(size = 0.5) +
  theme_minimal() +
  labs(title = "Die Durchlässigkeit des Linearpolarisators P2 in Abhänigkeit des Rotationswinkels",
       x = "Winkel / °",
       y = "Anteil der Strahlung, die den Polarisator passiert / %")
