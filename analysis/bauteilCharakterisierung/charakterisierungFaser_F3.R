#
# Get some libraries and functions used for characterising optical fibers and plotting stuff
#
source("bauteilCharakterisierung/charakterisierungFaser_utilities.R")


# FIBER F3 : MULTI-MODE-FIBER

#
# FETCH data from elabftw
#
# stokes vectors
F3.data.elab <- GET.elabftw.bycaption(74, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                                         func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                                         header=T, skip=14, sep=";")
# Rotation of plane of polarisation
F3.rotation.elab <- GET.elabftw.bycaption(73, header=T)[[1]]


# Fetch the meta data of one of the experiments
F3.meta.elab <- GET.elabftw.bycaption(74, caption="Metadaten", header=T, output=T) %>% parseTable.elabftw(.,
                                                                                        func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                                        header=T, skip=14, sep=";")


# Get the measurements for the error estimation
F3.error.elab <- GET.elabftw.bycaption(75, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
                                                                                          func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
                                                                                          header=T, skip=14, sep=";")




#
# COMPUTE stokes vectors and do statistics on the error estimations
#
F3.data.stokes <- getStokes.from.expData(F3.data.elab)  %>% process.stokesVec
F3.meta.stokes <- getStokes.from.metaData(F3.meta.elab) %>% process.stokesVec
F3.error.stats <- getStokes.from.expData(F3.error.elab) %>% process.stokesVec %>% do.statistics

# Compute the mueller matrix of the fiber, using the stokes vectors measured before and after the fiber
F3.muellermatrix <- muellermatrix(F3.data.stokes)
# Predict the stokes vectors after the fiber from the mueller matrix and the stokes vectors measured before the fiber
F3.data.stokes   <- predict.stokesVec(F3.data.stokes, F3.muellermatrix)


#
# Write formatted and processed data to folder for uploading it to overleaf later
#
write.table(F3.data.stokes$PRE, file="../overleaf/externalFilesForUpload/data/F3_stokes_pre.csv", row.names=F)
write.table(F3.data.stokes$POST, file="../overleaf/externalFilesForUpload/data/F3_stokes_post.csv", row.names=F)
write.table(F3.data.stokes$change, file="../overleaf/externalFilesForUpload/data/F3_stokes_change.csv", row.names=F)
write.table(F3.data.stokes$POST.PREDICT, file="../overleaf/externalFilesForUpload/data/F3_stokes_predict.csv", row.names=F)
write.table(F3.data.stokes$PREDICT.ERROR, file="../overleaf/externalFilesForUpload/data/F3_stokes_errorPredict.csv", row.names=F)

write.table(F3.error.stats$PRE, file="../overleaf/externalFilesForUpload/data/F3_error_pre.csv", row.names=T)
write.table(F3.error.stats$POST, file="../overleaf/externalFilesForUpload/data/F3_error_post.csv", row.names=T)
write.table(F3.error.stats$change, file="../overleaf/externalFilesForUpload/data/F3_error_change.csv", row.names=T)

write.table(F3.rotation.elab, file="../overleaf/externalFilesForUpload/data/F3_rotation.csv", row.names=F)

write.table(F3.muellermatrix, file="../overleaf/externalFilesForUpload/data/F3_muellermatrix.csv", row.names=F, col.names=F)

#
# PLOT THAT SHIT
#
# How does the polarisation ratio change relative to the initial polarisation ratio?
plot.polarisation.change(data  = F3.data.stokes, 
                         title = expression(bold("The Depolarising Behaviour Of An Optical MM-Fiber (F3)") )
)
# COMPARING POLARISATION RATIOS before and after interacting with the fiber
plot.polarisation(data       = F3.data.stokes, 
                  statistics = F3.error.stats,
                  title      = expression(bold("The Effect Of An Optical MM-Fiber (F3) On The Polarisation Ratio "*Pi))
)

# CHANGE in LASER POWER due to optical fiber
plot.intensity.change(data  = F3.data.stokes,
                      title = expression(bold("The Transmittance Of An Optical MM-Fiber (F3)"))
)
# COMPARING LASER POWER before and after interacting with the fiber
plot.intensity(data  = F3.data.stokes, 
               title = expression(bold("The Effect Of An Optical MM-Fiber (F3) On The Lasers Power "*P))
)

# How does the fiber influence the PLANE OF POLARISATIONS ORIENTATION
plot.plane.rotation(F2.rotation.elab, F3.rotation.elab, 
                    title = expression(bold("The Impact Of Fibers On The Orientation Of The Plane Of Polarisation"))
)


# Plot and compare the PREDICTED and MEASURED STOKES parameters
# S0
plot(x = F3.data.stokes$POST$W, y = F3.data.stokes$POST$S0, col="red", type="l",
     main = expression("F3: Predicted/Measured S"[0]*" (blue/red)"),
     xlab = "wave plate position / °",
     ylab = expression("stokes parameter S"[0]))
lines(x = F3.data.stokes$POST$W, y = F3.data.stokes$POST.PREDICT$S0, col="blue")
# S1
plot(x = F3.data.stokes$POST$W, y = F3.data.stokes$POST$S1, col="red", type="l",
     main = expression("F3: Predicted/Measured S"[1]*" (blue/red)"),
     xlab = "wave plate position / °",
     ylab = expression("stokes parameter S"[1]))
lines(x = F3.data.stokes$POST$W, y = F3.data.stokes$POST.PREDICT$S1, col="blue")
# S2
plot(x = F3.data.stokes$POST$W, y = F3.data.stokes$POST$S2, col="red", type="l",
     main = expression("F3: Predicted/Measured S"[2]*" (blue/red)"),
     xlab = "wave plate position / °",
     ylab = expression("stokes parameter S"[2]))
lines(x = F3.data.stokes$POST$W, y = F3.data.stokes$POST.PREDICT$S2, col="blue")
# Polarisation ratio
plot(x = F3.data.stokes$POST$W, y = F3.data.stokes$POST.PREDICT$polarisation, col="blue", type="l",
     main = expression("F3: Predicted/Measured "*Pi*" (blue/red)"),
     xlab = "wave plate position / °",
     ylab = expression("grade of polarisation "*Pi))
lines(x = F3.data.stokes$POST$W, y = F3.data.stokes$POST$polarisation, col="red")


#
# Lässt sich die Rotation der Polarisationsebene anhand unvollständig polarisierter Stokesvektoren berechnen?
# Berechnung der Polarisationsebene für Stokesparameter: 
# S_0,neu = sqrt( S_1^2 + S_2^2 ) / S_0 (= Polarisationsgrad)
# S_1,neu = S_1
# S_2,neu = S_2
#
# Vor der Faser
plot(  x = F3.rotation.elab$X %>% .[which(. %in% F3.data.stokes$PRE$W)],
       y = F3.rotation.elab$Y2[which(F3.rotation.elab$X %in% F3.data.stokes$PRE$W)] %>% mod(., 180),
       col = "red",
       type = "o",
       main = "Die Rotation der Polarisationsebene vor F3",
       sub  = "Vergleich gemessene Polarisationsebene (rot) und mit Stokesvektor berechnete Polarisationsebene (blau)",
       xlab = "Position Wellenplatte / °",
       ylab = "Rotation der Polarisationsebene / °", 
       yaxp = c(0, 180, 4), xaxp = c(-90, 270, 4), ylim = c(0, 180), xlim = c(-22, 270) )
lines( x = F3.data.stokes$PRE$W,
       y = better.acos(F3.data.stokes$PRE$polarisation, F3.data.stokes$PRE$S1, F3.data.stokes$PRE$S2) %>% `/`(., pi)*180 %>% `/`(., 2),
       type = "o",
       col = "blue")
abline(h = c(0, 180) ) 
# Nach der Faser
plot(  x = F3.rotation.elab$X %>% .[which(. %in% F3.data.stokes$POST$W)],
       y = F3.rotation.elab$Y1[which(F3.rotation.elab$X %in% F3.data.stokes$POST$W)] %>% mod(., 180),
       col = "red",
       type = "o",
       main = "Die Rotation der Polarisationsebene nach F3",
       sub  = "Vergleich gemessene Polarisationsebene (rot) und mit Stokesvektor berechnete Polarisationsebene (blau)",
       xlab = "Position Wellenplatte / °",
       ylab = "Rotation der Polarisationsebene / °", 
       yaxp = c(0, 180, 4), xaxp = c(-90, 270, 4), ylim = c(0, 180), xlim = c(-22, 270) )
lines( x = F3.data.stokes$POST$W,
       y = better.acos(F3.data.stokes$POST$polarisation, F3.data.stokes$POST$S1, F3.data.stokes$POST$S2) %>% `/`(., pi)*180 %>% `/`(., 2),
       type = "o",
       col = "blue")
abline(h = c(0, 180) ) 
