require(RHotStuff)
require(ggplot2)

# Extract data from eLabFTW
W2.data <- GET.elabftw.byselector(28, header = T)[[1]]

# Replace NA values by using the previous value in the vector
fillVector <- function(vector) {
  for (index in seq_along(vector)) {
    if (is.na(vector[index])) { vector[index] <- vector[index-1] }
  }
  return(vector)
}
W2.data$Y2 <- fillVector(W2.data$Y2)
W2.data$Y4 <- fillVector(W2.data$Y4)

# Normalise
W2.data$Y1 <- (W2.data$Y1/W2.data$Y2) %>% `/`(., max(.)) *100
W2.data$Y3 <- W2.data$Y3/W2.data$Y4 *100

# Plot
ggplot(data = W2.data, mapping = aes(x = X, y=Y3)) +
  geom_point() +
  theme_minimal() +
  labs(title = "Durchlässigkeit der Wellenplatte W2 in Abhängigkeit des Rotationswinkels",
       x = "Rotationswinkel / °",
       y = "Anteil der Strahlung, die die Wellenplatte passiert / %")
ggplot(data = W2.data, mapping = aes(x=X, y=Y1)) +
  geom_point(size=0.5) +
  theme_minimal() +
  labs(title = "Nullpunktsbestimmung der Wellenplatte W2",
       x = "Rotationswinkel / °",
       y = "Anteil der Strahlung, die den Analysator passiert / %")
