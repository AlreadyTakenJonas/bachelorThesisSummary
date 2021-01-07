library("RHotStuff")
library("magrittr")
require(ggplot2)

# Check the RHotStuff version
check.version("1.6.0")

# Download the waveplate positions that were used to measure the raman spectra of tetrachloromethane
tetra.waveplate <- GET.elabftw.bycaption(79, header=T) %>% .[[1]] %>% .$X

# Get the stokes vectors behind the optical fiber F2 for different wave plate positions
# This code is just copied from bauteilCharakterisierung/charakterisierungFaser_F2.R
source("./bauteilCharakterisierung/charakterisierungFaser_utilities.R")
# Fetch from elab
F2.data.elab <- lapply(c(69, 70), function(experimentID) {
  GET.elabftw.bycaption(experimentID, header=T, outputHTTP=T) %>%
    parseTable.elabftw(., 
                       func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                       header=T, skip=14, sep=";")
}) %>% better.rbind(., sort.byrow=1)
# Compute stokes vectors
F2.data.stokes <- getStokes.from.expData(F2.data.elab)  %>% process.stokesVec

# Extract which waveplate position goes with which final stokes vector
# Ignore the waveplate positions that were not used for the raman spectra
tetra.stokes.postF2 <- data.frame( W  = F2.data.stokes$POST$W  %>% .[.                     %in% tetra.waveplate],
                                   S0 = F2.data.stokes$POST$S0 %>% .[F2.data.stokes$POST$W %in% tetra.waveplate],
                                   S1 = F2.data.stokes$POST$S1 %>% .[F2.data.stokes$POST$W %in% tetra.waveplate],
                                   S2 = F2.data.stokes$POST$S2 %>% .[F2.data.stokes$POST$W %in% tetra.waveplate],
                                   S3 = 0 ) 

#
# RUN POLARAM to simulate the raman scattering sample and the fiber F3
#
# CLI command to run PolaRam (env variable POLARAM contains the command specific for the running operating system)
polaram              <- Sys.getenv("POLARAM")
# File contaning mueller matrices for tetrachloromethane
tetra.mueller.matrix <- "./auswertungSpektren/polaram/labratoryMatrixTetrachlormethan.txt"
# File containing simulation program for polaram
polaram.witec        <- "./auswertungSpektren/polaram/witec.txt"
# Output file for polaram
polaram.tetra.output <- "./auswertungSpektren/polaram/result_witec_tetra.txt"

# Check the version of PolaRam should be at least v2.2
system(paste(polaram, "-v"))

# Assemble polaram command line call
polaram.args <- c("simulate", polaram.witec, 
                  paste("--output", polaram.tetra.output),
                  paste("--matrix", tetra.mueller.matrix),
                  "--unpolarised-scattering", "--verbose",
                  "--raw-output", "--silent")
# Convert list of stokes vectors into a command line arguments for polaram
polaram.lsr <- apply(tetra.stokes.postF2[,-1], 1, function(stokes) paste(c("--laser", stokes), collapse=" ") )

# Run polaram with the cli arguments and the stokes vectors used to measure the raman spectra
system( paste(c(polaram, polaram.args, polaram.lsr), collapse=" ") )

#
# READ POLARAM RESULTS AND FORMAT
#
# Read the results of the polaram simulation
tetra.stokes.polaram <- read.table(file = polaram.tetra.output, comment.char = "#")
# Give the columns describtive names
colnames(tetra.stokes.polaram) <- c("v", "S0.pre", "S1.pre", "S2.pre", "S3.pre", "S0.post", "S1.post", "S2.post", "S3.post")
# Extract the wavenumber of the spectras peaks from the polaram output
tetra.stokes.polaram$v <- stringr::str_extract(tetra.stokes.polaram$v, "\\d+\\.\\d+") %>% as.numeric
# Match the initial stokes vectors from the polaram output to the input that was given to polaram
# Add the waveplate position of the matching initial stokes vectors to polarams output
tetra.stokes.polaram$W <- apply(tetra.stokes.polaram[, c("S0.pre", "S1.pre", "S2.pre", "S3.pre")], 1,function(stokes) {
  commonSignifDigits <- 8
  commonSeperator <- " "
  # Round the stokes vectors to a shared number of digits
  # Convert the stokes vectors to strings to make it easier to compare them
  # Select the row with matching stokes vectors
  selectRow <- ( paste(round(stokes, commonSignifDigits), collapse=commonSeperator) == with(round(tetra.stokes.postF2, commonSignifDigits), paste(S0, S1, S2, S3, sep = commonSeperator)) )
  # Return the waveplate position of the matching stokes vectors
  tetra.stokes.postF2$W[which(selectRow)]
})

# Compare both measured and simulated spectrum
plot( x = tetra.spectra$wavenumber, 
      y = polaram.as.spectrum(tetra.spectra$wavenumber, 
                              tetra.stokes.polaram$S0.post, 
                              tetra.stokes.polaram$S1.post, 
                              tetra.stokes.polaram$v) %>% `/`(., max(.)), type = "l", col="blue" )
lines(tetra.spectra[,1],tetra.spectra[,2]/max(tetra.spectra[,2]), col="red")



#
# COMPUTE RAMAN SPECTRA AND FIT THE SIMULATION TO THE EXPERIMENTAL SPECTRA
#

# PREPARE DATA FOR FITTING
#
# Compute how the intensity in x- and y-direction are changing with the waveplate position
# for every peak of the spectrum
tetra.polaram.intensityChange <- lapply(unique(tetra.stokes.polaram$v), function(peak) {
  # Subset the data set containing the polaram results
  # Get the results for one single peak
  stokes <- tetra.stokes.polaram[which(tetra.stokes.polaram$v == peak), c("W", "S0.post", "S1.post")]
  
  # Normalise Stokes parameters
  stokes[,c("S0.post", "S1.post")] <- stokes[,c("S0.post", "S1.post")] / stokes[,"S0.post"]

  # Compute the light intensity along the x- and y-direction depending on the wave plate position
  intensity <- data.frame( W = stokes$W,
                           I.x = (stokes$S0.post + stokes$S1.post)/2,
                           I.y = (stokes$S0.post - stokes$S1.post)/2 )
  
  # Compute the mean of intensities for degenerate peaks
  intensity <- sapply(unique(intensity$W), function(waveplate){
    # Get the light intensities for each waveplate position 
    degeneratePeakIntensity <- intensity[which(intensity$W == waveplate),]
    # Compute the mean intensity in x- and y-direction
    meanIntensity <- colMeans(degeneratePeakIntensity)
    return(meanIntensity)
  
  }) %>% 
    # Convert matrix to data.frame
    t %>% data.frame
})
# Name the list by wavenumber of peak
names(tetra.polaram.intensityChange) <- unique(tetra.stokes.polaram$v)

# Organise data by wavenumber and combine data of simulation and experiment in one data frame
#
# Convert the peak location of the experimental spectrum into the peak location in the simualtion
tetra.convert.peakLocations <- data.frame(
  # Wavenumbers of all peaks in the experimental spectrum
  exp.wavenumber = colnames(tetra.peakChange.deviation[,-1]),
  # Wavenumber of all peaks in the calculated spectrum
  # (the last peak is included twice, because it's a double peak in the experimental spectrum)
  sim.wavenumber = names(tetra.polaram.intensityDeviation)[c(1:4,4)]
)

# Subset the measured peak height change by selecting only waveplate position that where simulated by polaram
tetra.witec.peakChange <- tetra.peakChange[which(tetra.peakChange$waveplate %in% tetra.polaram.intensityChange[[1]]$W),]

tetra.combined.peakChange <- lapply(unique(colnames(tetra.witec.peakChange[,-1])), function(peak) {
  # Get the wavenumber of the peak in the simulated spectrum
  sim.peak <- tetra.convert.peakLocations[tetra.convert.peakLocations$exp.wavenumber==peak, "sim.wavenumber"]
  # Get the simulated change of intensity for the peak
  simulation <- tetra.polaram.intensityChange[[sim.peak]]
  # Get the experimental peak hight change
  experiment <- tetra.witec.peakChange[,c("waveplate", peak)]
  
  # Do the waveplate axis of the two data sets match?
    if(all(simulation$W == experiment$waveplate) == FALSE) stop("Simulation and Experiment have different waveplate axis!")
  
  # Combine the experimental and simulated data
  # Shift the simulated intensities to match experimental signal height
  data <- data.frame(
            # Rotation of the half wave plate -> Rotation of the plane of polarisation
            waveplate = experiment$waveplate,
            # Experimental peak height depending on the rotation of the half wave plate
            exp.signal = experiment[,2],
            # Wavenumer of the current peak
            wavenumber = peak,
            # Intensity along the x-axis shifted to match the general experimental peak height
            sim.I.x   = simulation$I.x - mean(simulation$I.x) + mean(experiment[,2]),
            # Intensity along the y-axis shifted to match the general experimental peak height
            sim.I.y   = simulation$I.y - mean(simulation$I.y) + mean(experiment[,2]) )
  return(data)
})
names(tetra.combined.peakChange) <- unique(colnames(tetra.witec.peakChange[,-1]))

tetra.detectorBias <- sapply(tetra.combined.peakChange, function(peak) {
  fit <- nls( formula = exp.signal ~ (sim.I.x + biasY*sim.I.y)/(1+biasY),
              start   = list(biasY = 1),
              data    = peak )
  fit$m$getPars()
})
names(tetra.detectorBias) <- names(tetra.combined.peakChange)

# Format calculated biases and write them to file -> upload to overleaf
write.table(data.frame(wavenumber = as.numeric(names(tetra.detectorBias)),
                       biasY      = tetra.detectorBias),
            file = "../overleaf/externalFilesForUpload/data/tetra_fittedBiasY.csv", row.names=F)
#
# END SPECTRUM FITTING/SIMULATION -------------------------------------------------------
#

#
# PLOT THAT SHIT
#

# Rearrange data for plotting and calculate the simulated peak change with result of nls fit
tetra.plotable.combined.peakChange <- lapply(tetra.combined.peakChange, function(signalChange) {
  # Get the fitted bias
  bias <- tetra.detectorBias[signalChange$wavenumber[1]]
  # Compute the simulated signal change
  signalChange$sim.signal <- ( signalChange$sim.I.x + bias*signalChange$sim.I.y )/(1+bias)
  # Return results
  return(signalChange[,c("waveplate", "exp.signal", "wavenumber", "sim.signal")])
}) %>% 
  # Collapse list of data frames into one data frame
  dplyr::bind_rows(.) %>% 
  # Combine experimentally measured peak change and simulated peak change
  # into one column and add new column for grouping the data
  tidyr::pivot_longer(., cols=c(exp.signal, sim.signal),
                      names_to="source", values_to="signal",
                      names_pattern="(\\w+)")
# Format wavenumbers. Add unit and decimal comma
tetra.plotable.combined.peakChange$wavenumber <- 
  paste(stringr::str_extract(tetra.plotable.combined.peakChange$wavenumber, "(\\d+)"), "/ cm")
# Copy the whole data set and row bind the copy with the original data
# This allows ggplot to show one plot for each peak and one extra plot
# with all peaks
{
  # Create new column to group the data when plotting
  tetra.plotable.combined.peakChange$group <- paste0(tetra.plotable.combined.peakChange$wavenumber, 
                                                     tetra.plotable.combined.peakChange$source)
  # Copy the data set ...
  copy <- tetra.plotable.combined.peakChange
  # ..., set the wavenumber of all peaks in the copy to a describtive name and ...
  copy$wavenumber = "Zusammenfassung"
  # ... combine original data set with copy.
  tetra.plotable.combined.peakChange <- rbind(tetra.plotable.combined.peakChange, copy)
}

# Write the formatted results to a file. Will be uploaded to overleaf
write.table(tetra.plotable.combined.peakChange, row.names = F,
            file = "../overleaf/externalFilesForUpload/data/tetra_simulatedPeakChange.csv")

# Plot the data
ggplot(data = tetra.plotable.combined.peakChange,
      mapping = aes( x = waveplate, y = signal, group = group, color = source ) ) +
  facet_wrap(facets = vars(wavenumber), scales="free_y", ncol=3 ) +
  geom_line() + geom_point() + 
  theme_hot() + 
  theme(strip.text.x = element_text(face="bold"),
        legend.position = "bottom") +
  scale_color_manual(name   = element_blank(), 
                     labels = c("Messung", "Simulation"),
                     values = scales::hue_pal()(2)) +
  labs(x = expression(bold("Rotation der Halbwellenplatte "*omega*" / °")),
       y = "normierte Intensität",
       title = "Vergleich von gemessenen und simulierten Ramanspektren")




#
#
# OLD UNMAINTAINED CODE. WAS USED TO CHECK SOMETHING.
#
#

#
# CHECK IF POLARAM AND GAUSSIAN CALCULATE THE SAME SPECTRA
#
# File containing simulation program for polaram
polaram.SMP                      <- "./auswertungSpektren/polaram/SMP.txt"
# Output file for polaram
polaram.tetra.unpolarised.output <- "./auswertungSpektren/polaram/result_compareGaussian_tetra.txt"

polaram.args <- c("simulate", polaram.SMP, 
                  paste("--output", polaram.tetra.unpolarised.output),
                  #paste("--matrix", "C:/Users/no83wec/Documents/bachelorarbeit/scripts/simulationSpektren/muellersim/input/labratoryMatrixMaltose.txt"),
                  paste("--matrix", tetra.mueller.matrix),
                  "--unpolarised-scattering", "--verbose",
                  "--raw-output", "--silent", "--laser 1 0 0 0")

# Run polaram with the cli arguments with an unpolarised stokes vector
system( paste(c(polaram, polaram.args), collapse=" ") )
# Read the results of the polaram simulation
tetra.unpolarised.polaram <- read.table(file = polaram.tetra.unpolarised.output, comment.char = "#")
# Give the columns describtive names
colnames(tetra.unpolarised.polaram) <- c("v", "S0.pre", "S1.pre", "S2.pre", "S3.pre", "S0.post", "S1.post", "S2.post", "S3.post")
# Extract the wavenumber of the spectras peaks from the polaram output
tetra.unpolarised.polaram$v <- stringr::str_extract(tetra.unpolarised.polaram$v, "\\d+\\.\\d+") %>% as.numeric

# Compare results from gaussian and measurements and polaram
# Create data.frame with peak heights given by polaram and the raman activities given by gaussian
compare.peakHeight <- data.frame( wavenumber = unique(tetra.unpolarised.polaram$v),
                                  # The raman activities computed by Gaussian
                                  gaussAct   = c(3.2483, 5.4818, 21.2683, 4.7293) / 21.2683,
                                  # Compute the normalised peak height of the unpolarised raman spectrum of tetra
                                  polaram    = polaram.as.spectrum( x         = unique(tetra.unpolarised.polaram$v),
                                                                    stokes.S0 = tetra.unpolarised.polaram$S0.post,
                                                                    stokes.S1 = tetra.unpolarised.polaram$S1.post,
                                                                    peaks.wavenumber = tetra.unpolarised.polaram$v,
                                                                    scaleX = 1, scaleY = 1, normalise = T, gamma = 1) ) %>%
                      # Add last row twice to the data.frame, because real spectrum has a doubble peak as last peak
                      .[ c(1:nrow(.), nrow(.)), ]
# Add measured peak heights
compare.peakHeight$measuredMean <- sapply(tetra.spectra[-1], function(spec) { 
                                    spec[tetra.spectra$wavenumber %in% tetra.peakLocations] 
                                   }) %>% rowMeans

# Compute the intensity of a peak by gaussians raman activity
Act.To.Int <- function(Act, WN.Mode, WL.Laser=514, Temp=298)
{
  kB <- 1.38e-23
  h <- 6.626e-34
  c0 <- 2.998e8
  WN.Laser <- 1 / WL.Laser * 1e7
  WN.Mode <- WN.Mode
  
  (2*pi)^4 / 45 * (WN.Laser - WN.Mode)^4 * h / (8 * pi^2 * c0 * WN.Mode * ( 1 - exp( - (h * WN.Mode * c0) / (kB * Temp) )) ) * Act
}
# Add peak height given by gaussian to data.frame
compare.peakHeight$gaussInt <- Act.To.Int(res$gaussian,res$wavenumber) %>% `/`(., max(.))
# Print table
compare.peakHeight
