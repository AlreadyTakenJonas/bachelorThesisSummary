require(RHotStuff)
require(ggplot2)

#
# LINEARPOLARISATOR P1
#
# Extract Data from eLabFTW
P1.maxmin.metadata <- GET.elabftw.byselector(25, node.selector = "#meta-data")[[1]]
P1.maxmin.data <- GET.elabftw.byselector(25, header = T)[[1]]

# Normalise data
P1.maxmin.data$Y1 <- P1.maxmin.data$Y1 / P1.maxmin.metadata[3,2] *100

# Write formatted data to folder for uploading it to overleaf later
write.table(P1.maxmin.data, file="../overleaf/externalFilesForUpload/data/P1_nullpunkt.csv", row.names=F)

# Plot
ggplot(data = P1.maxmin.data, mapping = aes(x = X, y = Y1)) +
  geom_point(size = 0.5) +
  theme_minimal() +
  labs(title = "Die Durchlässigkeit des Linearpolarisators P1 in Abhänigkeit des Rotationswinkels",
       x = "Winkel / °",
       y = "Anteil der Strahlung, die den Polarisator passiert / %")

# Compare maximal and minimal transmission
max(P1.maxmin.data$Y1)/min(P1.maxmin.data$Y1)

#
# LINEARPOLARISATOR P2
#
# Extract Data from eLabFTW
P2.maxmin.metadata <- GET.elabftw.byselector(26, node.selector = "#meta-data")[[1]]
P2.maxmin.data <- GET.elabftw.byselector(26, header = T)[[1]]

# Normalise data
P2.maxmin.data$Y1 <- P2.maxmin.data$Y1 / P2.maxmin.metadata[3,2] *100

# Write formatted data to folder for uploading it to overleaf later
write.table(P2.maxmin.data, file="../overleaf/externalFilesForUpload/data/P2_nullpunkt.csv", row.names=F)

# Plot
ggplot(data = P2.maxmin.data, mapping = aes(x = X, y = Y1)) +
  geom_point(size = 0.5) +
  theme_minimal() +
  labs(title = "Die Durchlässigkeit des Linearpolarisators P2 in Abhänigkeit des Rotationswinkels",
       x = "Winkel / °",
       y = "Anteil der Strahlung, die den Polarisator passiert / %")

# Compare maximal and minimal transmission
max(P2.maxmin.data$Y1)/min(P2.maxmin.data$Y1)
