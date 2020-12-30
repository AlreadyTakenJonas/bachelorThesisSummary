library("RHotStuff")
library("magrittr")

# Check the RHotStuff version
check.version("1.6.0")

# Download the waveplate positions that were used to measure the raman spectra of phenylalanin
phenylalanin.waveplate <- GET.elabftw.bycaption(83, header=T) %>% .[[1]] %>% .$X

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
phenylalanin.stokes.postF2 <- data.frame( W  = F2.data.stokes$POST$W  %>% .[.                     %in% phenylalanin.waveplate],
                                          S0 = F2.data.stokes$POST$S0 %>% .[F2.data.stokes$POST$W %in% phenylalanin.waveplate],
                                          S1 = F2.data.stokes$POST$S1 %>% .[F2.data.stokes$POST$W %in% phenylalanin.waveplate],
                                          S2 = F2.data.stokes$POST$S2 %>% .[F2.data.stokes$POST$W %in% phenylalanin.waveplate],
                                          S3 = 0 ) 

#
# RUN POLARAM to simulate the raman scattering sample and the fiber F3
#
# CLI command to run PolaRam (env variable POLARAM contains the command specific for the running operating system)
polaram                     <- Sys.getenv("POLARAM")
# File contaning mueller matrices for phenylalanine
phenylalanin.mueller.matrix <- "./auswertungSpektren/polaram/labratoryMatrixPhenylalanine.txt"
# File containing simulation program for polaram
polaram.witec               <- "./auswertungSpektren/polaram/witec.txt"
# Output file for polaram
polaram.phenylalanin.output <- "./auswertungSpektren/polaram/result_witec_phenylalanine.txt"

# Check the version of PolaRam should be at least v2.2
system(paste(polaram, "-v"))

# Assemble polaram command line call
polaram.args <- c("simulate", polaram.witec, 
                  paste("--output", polaram.phenylalanin.output),
                  paste("--matrix", phenylalanin.mueller.matrix),
                  "--unpolarised-scattering", "--verbose",
                  "--raw-output", "--silent")
# Convert list of stokes vectors into a command line arguments for polaram
polaram.lsr <- apply(phenylalanin.stokes.postF2[,-1], 1, function(stokes) paste(c("--laser", stokes), collapse=" ") )

# Run polaram with the cli arguments and the stokes vectors used to measure the raman spectra
system( paste(c(polaram, polaram.args, polaram.lsr), collapse=" ") )


#
# READ POLARAM RESULTS AND FORMAT
#
# Read the results of the polaram simulation
phenylalanin.stokes.polaram <- read.table(file = polaram.phenylalanin.output, comment.char = "#")
# Give the columns describtive names
colnames(phenylalanin.stokes.polaram) <- c("v", "S0.pre", "S1.pre", "S2.pre", "S3.pre", "S0.post", "S1.post", "S2.post", "S3.post")
# Extract the wavenumber of the spectras peaks from the polaram output
phenylalanin.stokes.polaram$v <- stringr::str_extract(phenylalanin.stokes.polaram$v, "\\d+\\.\\d+") %>% as.numeric
# Match the initial stokes vectors from the polaram output to the input that was given to polaram
# Add the waveplate position of the matching initial stokes vectors to polarams output
phenylalanin.stokes.polaram$W <- apply(phenylalanin.stokes.polaram[, c("S0.pre", "S1.pre", "S2.pre", "S3.pre")], 1,function(stokes) {
  commonSignifDigits <- 8
  commonSeperator <- " "
  # Round the stokes vectors to a shared number of digits
  # Convert the stokes vectors to strings to make it easier to compare them
  # Select the row with matching stokes vectors
  selectRow <- ( 
    paste(round(stokes, commonSignifDigits), collapse=commonSeperator) == with(round(phenylalanin.stokes.postF2, commonSignifDigits), 
                                                                                            paste(S0, S1, S2, S3, sep = commonSeperator)) 
  )
  # Return the waveplate position of the matching stokes vectors
  phenylalanin.stokes.postF2$W[which(selectRow)]
})

#
# COMPUTE RAMAN SPECTRA AND FIT THE SIMULATION TO THE EXPERIMENTAL SPECTRA
#
# Compute the height of all peaks for all waveplate positions and use them to
# Compute the ratio of a peaks maximum and minimum depending on the waveplate position
phenylalanin.polaram.peakRatio <- function(biasY) {
  peaks.wavenumber <- unique(phenylalanin.stokes.polaram$v)
  peakRatio <- sapply( peaks.wavenumber, function(wavenumber) {
    # Get waveplate positions and first two stokes components of simulation for a specific peak
    stokes <- phenylalanin.stokes.polaram[which(phenylalanin.stokes.polaram$v == wavenumber), c("W", "S0.post", "S1.post")]
    
    # Compute intensities in x- and y-direction
    I.x <- (stokes$S0.post + stokes$S1.post)/2
    I.y <- (stokes$S0.post - stokes$S1.post)/2
    # Compute detector response with bias
    signal <- (I.x + biasY*I.y) / (1+biasY)
    
    # Compute the ratio of the maximal and minimal peak height
    peakRatio <- max(signal) / min(signal)
    
    return(peakRatio)
  })
  
  rownames(peakRatio) <- peaks.wavenumber
  
  return(peakRatio)
}
# The ratio is computed for a series of detector sensibilities to create data that can be fitted
phenylalanin.test.sensitivity    <- seq(from=1.2, to=1.5, by=0.05)
phenylalanin.polaram.fittingData <- data.frame( sensitivity = phenylalanin.test.sensitivity,
                                                phenylalanin.polaram.peakRatio(biasY) %>% t(.) )