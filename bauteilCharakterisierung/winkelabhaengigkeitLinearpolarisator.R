require(RHotStuff)
require(ggplot2)


#
# LINEARPOLARISATOR P1
#
# Extract data from eLabFTW
P1.transmission.data <- GET.elabftw.byselector(29, header = T)[[1]]

# Normalise data
P1.transmission.data$Y4 <- P1.transmission.data$Y4/P1.transmission.data$Y2 *100

# Write formatted data to folder for uploading it to overleaf later
write.table(P1.transmission.data, file="../overleaf/externalFilesForUpload/data/P1_transmission.csv", row.names=F)


# Plot
ggplot(data = P1.transmission.data, mapping = aes(x = Y3, y = Y4)) +
  geom_point() +
  theme_minimal() +
  labs(title = "Winkelabhängige Transmission von Linearpolarisator P1",
       x = "Rotationswinkel / °",
       y = "Anteil der Strahlung, die den Polarisator passieren / %")


#
# LINEARPOLARISATOR P2
#
# Extract data from eLabFTW
P2.transmission.data <- GET.elabftw.byselector(30, header = T)[[1]]

# Normalise data
P2.transmission.data$Y4 <- P2.transmission.data$Y4/P2.transmission.data$Y2 *100


# Write formatted data to folder for uploading it to overleaf later
write.table(P2.transmission.data, file="../overleaf/externalFilesForUpload/data/P2_transmission.csv", row.names=F)

# Plot
ggplot(data = P2.transmission.data, mapping = aes(x = Y3, y = Y4)) +
  geom_point() +
  theme_minimal() +
  labs(title = "Winkelabhängige Transmission von Linearpolarisator P2",
       x = "Rotationswinkel / °",
       y = "Anteil der Strahlung, die den Polarisator passieren / %")
