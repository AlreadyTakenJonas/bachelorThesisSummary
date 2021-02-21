#
# Get some libraries and functions used for characterising optical fibers and plotting stuff
#
source("bauteilCharakterisierung/charakterisierungFaser_utilities.R")


# F1 : POLARISATION-MAINTAING-FIBER

#
# FETCH data from local files
#
# F1.data.elab <- lapply(c(58, 67, 68), function(id) {
#   # Read all three experiments
#   pattern <- paste0("expID-", id)
#   F1.localPath <- list.files("../data/", pattern=pattern) %>% paste0("../data/", .)
#   F1.localFiles <- list.files(F1.localPath, pattern="^W")
#   F1.waveplatePosition <- sub("W", "", F1.localFiles) %>% sub("deg.*", "", .) %>% unique
#   # Process files
#   lapply(c("000", "090", "045", "135"), function(polariser) {
#     # Create a table for every polariser position used to measure the stokes vectors
#     lapply(F1.waveplatePosition, function(waveplate) {
#       # Read background and actual measurements from local files
#       # Get file name
#       background.PRE <- F1.localFiles[grep(waveplate, F1.localFiles)] %>% .[grep("background_noFiber", .)] %>% 
#         paste(F1.localPath, ., sep="/")
#       background.POST <- F1.localFiles[grep(waveplate, F1.localFiles)] %>% .[grep("background_fiber", .)] %>% 
#         paste(F1.localPath, ., sep="/")
#       measurement.PRE <- F1.localFiles[grep(paste0("W", waveplate), F1.localFiles)] %>% 
#         .[grep(paste0(polariser, "deg_noFiber"), .)] %>% paste(F1.localPath, ., sep="/")
#       measurement.POST <- F1.localFiles[grep(paste0("W", waveplate), F1.localFiles)] %>% 
#         .[grep(paste0(polariser, "deg_fiber"), .)] %>% paste(F1.localPath, ., sep="/")
#       
#       # Read file
#       background.PRE <- read.table(file=background.PRE, skip=15, sep=";") %>% .[,4] %>% qmean(., 0.8, na.rm=T, inf.rm=T)
#       background.POST <- read.table(file=background.POST, skip=15, sep=";") %>% .[,4] %>% qmean(., 0.8, na.rm=T, inf.rm=T)
#       measurement.PRE <- read.table(file=measurement.PRE, skip=15, sep=";") %>% .[,4] %>% qmean(., 0.8, na.rm=T, inf.rm=T)
#       measurement.POST <- read.table(file=measurement.POST, skip=15, sep=";") %>% .[,4] %>% qmean(., 0.8, na.rm=T, inf.rm=T)
#       data.frame(X = as.numeric(waveplate),
#                  Y1 = background.PRE,
#                  Y2 = measurement.PRE,
#                  Y3 = background.POST,
#                  Y4 = measurement.POST)
#     }) %>% rbind
#   })
# }) %>% better.rbind

# F1.error.elab <- lapply(c(66), function(id) {
#   # Read all three experiments
#   pattern <- paste0("expID-", id)
#   F1.localPath <- list.files("../data/", pattern=pattern) %>% paste0("../data/", .)
#   F1.localFiles <- list.files(F1.localPath, pattern="^W")
#   # Process files
#   lapply(c("000", "090", "045", "135"), function(polariser) {
#     # Create a table for every polariser position used to measure the stokes vectors
#     lapply(c("000deg-a", "000deg-b", "000deg-c", "000deg-d", "000deg-e"), function(waveplate) {
#       # Read background and actual measurements from local files
#       # Get file name
#       background.PRE <- F1.localFiles[grep(waveplate, F1.localFiles)] %>% .[grep("background_noFiber", .)] %>% 
#         paste(F1.localPath, ., sep="/")
#       background.POST <- F1.localFiles[grep(waveplate, F1.localFiles)] %>% .[grep("background_fiber", .)] %>% 
#         paste(F1.localPath, ., sep="/")
#       measurement.PRE <- F1.localFiles[grep(paste0("W", waveplate), F1.localFiles)] %>% 
#         .[grep(paste0(polariser, "deg_noFiber"), .)] %>% paste(F1.localPath, ., sep="/")
#       measurement.POST <- F1.localFiles[grep(paste0("W", waveplate), F1.localFiles)] %>% 
#         .[grep(paste0(polariser, "deg_fiber"), .)] %>% paste(F1.localPath, ., sep="/")
#       
#       # Read file
#       background.PRE <- read.table(file=background.PRE, skip=15, sep=";") %>% .[,4] %>% qmean(., 0.8, na.rm=T, inf.rm=T)
#       background.POST <- read.table(file=background.POST, skip=15, sep=";") %>% .[,4] %>% qmean(., 0.8, na.rm=T, inf.rm=T)
#       measurement.PRE <- read.table(file=measurement.PRE, skip=15, sep=";") %>% .[,4] %>% qmean(., 0.8, na.rm=T, inf.rm=T)
#       measurement.POST <- read.table(file=measurement.POST, skip=15, sep=";") %>% .[,4] %>% qmean(., 0.8, na.rm=T, inf.rm=T)
#       data.frame(X = 0,
#                  Y1 = background.PRE,
#                  Y2 = measurement.PRE,
#                  Y3 = background.POST,
#                  Y4 = measurement.POST)
#     }) %>% rbind
#   })
# }) %>% better.rbind


#
# FETCH data from elabftw
#
F1.data.elab <- lapply(c(58, 67, 68), function(experimentID) {
  GET.elabftw.bycaption(experimentID, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                                     func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                                     header=T, skip=14, sep=";")
}) %>% better.rbind(., sort.byrow=1)


# Fetch the meta data of one of the experiments
F1.meta.elab <- GET.elabftw.bycaption(67, caption="Metadaten", header=T, outputHTTP=T) %>% parseTable.elabftw(.,
                                                                                            func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                                            header=T, skip=14, sep=";")

# Get the measurements for the error estimation
F1.error.elab <- GET.elabftw.bycaption(66, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                                          func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                                          header=T, skip=14, sep=";")

#
# COMPUTE stokes vectors and do statistics on the error estimations
#
F1.data.stokes <- getStokes.from.expData(F1.data.elab)  %>% process.stokesVec
F1.meta.stokes <- getStokes.from.metaData(F1.meta.elab) %>% process.stokesVec
F1.error.stats <- getStokes.from.expData(F1.error.elab) %>% process.stokesVec %>% do.statistics

# COMPUTE the mueller matrix of the fiber, using the stokes vectors measured before and after the fiber
F1.muellermatrix <- muellermatrix(F1.data.stokes)
# PREDICT the stokes vectors after the fiber from the mueller matrix and the stokes vectors measured before the fiber
F1.data.stokes   <- predict.stokesVec(F1.data.stokes, F1.muellermatrix)

#
# Write formatted and processed data to folder for uploading it to overleaf later
#
write.table(F1.data.stokes$PRE, file="../overleaf/externalFilesForUpload/data/F1_stokes_pre.csv", row.names=F)
write.table(F1.data.stokes$POST, file="../overleaf/externalFilesForUpload/data/F1_stokes_post.csv", row.names=F)
write.table(F1.data.stokes$change, file="../overleaf/externalFilesForUpload/data/F1_stokes_change.csv", row.names=F)
write.table(F1.data.stokes$POST.PREDICT, file="../overleaf/externalFilesForUpload/data/F1_stokes_predict.csv", row.names=F)
write.table(F1.data.stokes$PREDICT.ERROR, file="../overleaf/externalFilesForUpload/data/F1_stokes_errorPredict.csv", row.names=F)

write.table(F1.error.stats$PRE, file="../overleaf/externalFilesForUpload/data/F1_error_pre.csv", row.names=T)
write.table(F1.error.stats$POST, file="../overleaf/externalFilesForUpload/data/F1_error_post.csv", row.names=T)
write.table(F1.error.stats$change, file="../overleaf/externalFilesForUpload/data/F1_error_change.csv", row.names=T)


#
# PLOT THAT SHIT
#
# How does the polarisation ratio change relative to the initial polarisation ratio?
plot.polarisation.change(data  = F1.data.stokes, 
                         title = expression(bold("The Depolarising Behaviour Of An Optical PM-Fiber (F1)") )
)
# COMPARING POLARISATION RATIOS before and after interacting with the fiber
plot.polarisation(data       = F1.data.stokes, 
                  statistics = F1.error.stats,
                  title      = expression(bold("The Effect Of An Optical PM-Fiber (F1) On The Polarisation Ratio "*Pi))
)

# CHANGE in LASER POWER due to optical fiber
plot.intensity.change(data  = F1.data.stokes,
                      title = expression(bold("The Transmittance Of An Optical PM-Fiber (F1)"))
)
# COMPARING LASER POWER before and after interacting with the fiber
plot.intensity(data  = F1.data.stokes, 
               title = expression(bold("The Effect Of An Optical PM-Fiber (F1) On The Lasers Power "*P))
)


# COMPARE PREDICTED and MEASURED STOKES parameters and polarisation ratio
plot.stokesPredict(data = F1.data.stokes,
                   title = "Näherung der Stokesparamter für Faser F1")
# UGLY VERSION
# Plot and compare the PREDICTED and MEASURED STOKES parameters
# S0
plot(x = F1.data.stokes$POST$W, y = F1.data.stokes$POST$S0, col="red", type="l",
     main = expression("F1: Predicted/Measured S"[0]*" (blue/red)"),
     xlab = "wave plate position / °",
     ylab = expression("stokes parameter S"[0]))
lines(x = F1.data.stokes$POST$W, y = F1.data.stokes$POST.PREDICT$S0, col="blue")
# S1
plot(x = F1.data.stokes$POST$W, y = F1.data.stokes$POST$S1, col="red", type="l",
     main = expression("F1: Predicted/Measured S"[1]*" (blue/red)"),
     xlab = "wave plate position / °",
     ylab = expression("stokes parameter S"[1]))
lines(x = F1.data.stokes$POST$W, y = F1.data.stokes$POST.PREDICT$S1, col="blue")
# S2
plot(x = F1.data.stokes$POST$W, y = F1.data.stokes$POST$S2, col="red", type="l",
     main = expression("F1: Predicted/Measured S"[2]*" (blue/red)"),
     xlab = "wave plate position / °",
     ylab = expression("stokes parameter S"[2]))
lines(x = F1.data.stokes$POST$W, y = F1.data.stokes$POST.PREDICT$S2, col="blue")
# Polarisation ratio
plot(x = F1.data.stokes$POST$W, y = F1.data.stokes$POST.PREDICT$polarisation, col="blue", type="l",
     main = expression("F1: Predicted/Measured "*Pi*" (blue/red)"),
     xlab = "wave plate position / °",
     ylab = expression("grade of polarisation "*Pi),
     ylim = c(0.3, 1.1))
lines(x = F1.data.stokes$POST$W, y = F1.data.stokes$POST$polarisation, col="red")

