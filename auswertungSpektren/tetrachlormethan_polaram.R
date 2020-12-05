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
# CLI command to run PolaRam (on linux)
polaram              <- "python3 ~/code/python/PolaRam/main.py"
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

system( paste(c(polaram, polaram.args, polaram.lsr), collapse=" ") )

