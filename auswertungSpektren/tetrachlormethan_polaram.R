library("RHotStuff")
library("magrittr")

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


#
# COMPUTE RAMAN SPECTRA AND FIT THE SIMULATION TO THE EXPERIMENTAL SPECTRA
#
# Compute the height of all peaks for all waveplate positions
tetra.polaram.spectra <- function(scaleX) {
  tetra.polaram.spectra <- sapply( unique(tetra.stokes.polaram$W), function(waveplate) {
    stokes <- tetra.stokes.polaram[which(tetra.stokes.polaram$W == waveplate), c("v", "S0.post", "S1.post")]
    polaram.as.spectrum( x = unique(stokes$v),
                         stokes.S0 = stokes$S0.post,
                         stokes.S1 = stokes$S1.post,
                         peaks.wavenumber = stokes$v,
                         gamma = 10,
                         scaleX = scaleX,
                         normalise = T)
  })
  return(tetra.polaram.spectra)
}
# Compute the ratio of a peaks maximum and minimum depending on the waveplate position
# The ratio is computed for a series of detector sensibilities to create data that can be fitted
tetra.test.sensitivity    <- seq(from=1.2, to=1.5, by=0.05)
tetra.polaram.fittingData <- data.frame( sensitivity = tetra.test.sensitivity,
                                         peakRatio   = sapply(tetra.test.sensitivity, function(scaleX) {
                                                          # Compute a series of spectra for different detector sensibilities
                                                          spectra <- tetra.polaram.spectra(scaleX)
                                                          # Compute the ratio of maximal and minimal height of the peaks
                                                          apply(spectra, 1, function(peak) {
                                                            max(peak)/min(peak)
                                                          })
                                                        }) %>% t(.) )


plot( x = tetra.spectra$wavenumber, y = polaram.as.spectrum(tetra.spectra$wavenumber, tetra.stokes.polaram$S0.post, tetra.stokes.polaram$S1.post, tetra.stokes.polaram$v) / 6e-9, type = "l", col="blue" )
lines(tetra.spectra[,1],tetra.spectra[,2]/max(tetra.spectra[,2]), col="red")

# Plot that shit for eyeballing the interval that shall be used for fitting
plot(tetra.polaram.fittingData[,c(1,2)], type="l")
lines(tetra.polaram.fittingData[,c(1,3)], type="l")
lines(tetra.polaram.fittingData[,c(1,4)], type="l")
lines(tetra.polaram.fittingData[,c(1,5)], type="l")

# Find the relationship between the peak height ratio and the detectors sensibility
tetra.polaram.fit <- matrix( c( lm(peakRatio.1 ~ sensitivity, data=tetra.polaram.fittingData)$coeff,
                                lm(peakRatio.2 ~ sensitivity, data=tetra.polaram.fittingData)$coeff,
                                lm(peakRatio.3 ~ sensitivity, data=tetra.polaram.fittingData)$coeff,
                                lm(peakRatio.4 ~ sensitivity, data=tetra.polaram.fittingData)$coeff ), byrow=T, ncol=2 ) %>%
                      as.data.frame
colnames(tetra.polaram.fit) <- c("intercept", "slope")
# Label data with peaks wavenumbers
tetra.polaram.fit$peak <- unique(tetra.stokes.polaram$v)
# Double the last peak, because this peak is split in the measured spectrum
tetra.polaram.fit[5,] <- tetra.polaram.fit[4,]

# COMPARE DETECTOR SENSIBILITY BETWEEN SIMULATION AND MEASURED RAMAN SPECTRA
tetra.simulated.sensitivity <- data.frame( wavenumber  = tetra.polaram.fit$peak,
                                           sensitivity = ( tetra.sensibility$quotient - tetra.polaram.fit$intercept ) / tetra.polaram.fit$slope )



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
# polram <- polaram.as.spectrum( x         = unique(tetra.unpolarised.polaram$v),
#                      stokes.S0 = tetra.unpolarised.polaram$S0.post,
#                      stokes.S1 = tetra.unpolarised.polaram$S1.post,
#                      peaks.wavenumber = tetra.unpolarised.polaram$v,
#                      scaleX = 1, scaleY = 1, normalise = T, gamma = 1)
# Gauss <- readLines("C:/Users/no83wec/code/PolaRam/gaussian/GLYKOGENFRAGMENT.LOG")
# WN <- Gauss[grepl("Frequencies --",Gauss)]
# Gauss <- Gauss[grepl("Raman Activ",Gauss)]
# Gauss <- read.table(text=Gauss)
# Gauss <- unlist(Gauss[,4:6])
# WN <- read.table(text=WN)
# WN <- unlist(WN[,3:5])
# 
# res <- data.frame(wavenumber=WN,gaussian=Gauss/max(Gauss),pol=polram/max(polram))
# res$gaussInt <- Act.To.Int(res$gaussian,res$wavenumber)
# res$gaussInt <- res$gaussInt / max(res$gaussInt)
# res$pol / res$gaussInt


# mspec <- rowMeans(tetra.spectra[,-1])
# plot(tetra.spectra[,1],mspec,type="l")
# meas <- data.frame(meas=c(max(mspec[tetra.spectra > 200 & tetra.spectra < 250]),
# max(mspec[tetra.spectra > 310 & tetra.spectra < 330]),
# max(mspec[tetra.spectra > 450 & tetra.spectra < 480]),
# max(mspec[tetra.spectra > 750 & tetra.spectra < 780])*2))
# meas <- meas / max(meas)

# Compare results from gaussian to polaram
res <- cbind(data.frame( wavenumber = unique(tetra.unpolarised.polaram$v),
            # The raman activities computed by Gaussian
            gaussian   = c(3.2483, 5.4818, 21.2683, 4.7293) / 21.2683,
            # Compute the normalised peak height of the unpolarised raman spectrum of tetra
            polaram    = polaram.as.spectrum( x         = unique(tetra.unpolarised.polaram$v),
                                              stokes.S0 = tetra.unpolarised.polaram$S0.post,
                                              stokes.S1 = tetra.unpolarised.polaram$S1.post,
                                              peaks.wavenumber = tetra.unpolarised.polaram$v,
                                              scaleX = 1, scaleY = 1, normalise = T, gamma = 1)) ,meas )


Act.To.Int <- function(Act, WN.Mode, WL.Laser=514, Temp=298)
{
  kB <- 1.38e-23
  h <- 6.626e-34
  c0 <- 2.998e8
  WN.Laser <- 1 / WL.Laser * 1e7
  WN.Mode <- WN.Mode
  
  (2*pi)^4 / 45 * (WN.Laser - WN.Mode)^4 * h / (8 * pi^2 * c0 * WN.Mode * ( 1 - exp( - (h * WN.Mode * c0) / (kB * Temp) )) ) * Act
}

res$gaussInt <- Act.To.Int(res$gaussian,res$wavenumber)
res$gaussInt <- res$gaussInt / max(res$gaussInt)
res
