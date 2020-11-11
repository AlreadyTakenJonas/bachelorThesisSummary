#' Preprocess Meta Data From Stokes Measurements Of Optical Fibers
#' 
#' This function takes the output from RHotStuff::GET.elabftw.bycaption 
#' or RHotStuff::parseTable.elabftw with the parameter outputHTTP=FALSE 
#' (see the man page of the functions for details) and computes the stokes
#' vectors for the meta data of the experiment. The function extracts the
#' power measurements from the input table, normalises it with data from 
#' the input table and calculates the stokes vector before and after the
#' optical fiber.
#' 
#' This function expects the input to be in a specific format. If the elabFTW 
#' template "Bestimmung von Stokesvektoren an einer optischen Faser" is used
#' for logging the measurements, the data meets the expectations. If the right 
#' template is used, the data can be downloaded like shown in the examples.
#' @examples
#' # Read data from elabFTW
#' input.data <- GET.elabftw.bycaption(EXPID, caption="Metadaten")
#' # Read data from elabFTW and read the attached .csv files
#' input.data <- GET.elabftw.bycaption(EXPID, caption="Metadaten", outputHTTP=T) 
#'                %>% parseTable.elabftw(., func=function(x) qmean(x[,4], 
#'                                                                 0.8, 
#'                                                                 na.rm=T, 
#'                                                                 inf.rm=T),
#'                                       header=T, skip=14, sep=";")
#' # Convert the measurements into stokes vectors
#' getStokes.from.metaData(input.data)
#' 
#' @param meta.elab The meta data of a stokes measurement experiment
#' @return A list containing two data.frames: The stokes vector before interferring with the fiber,
#' after interferring with the fiber. The data.frames also contain the total measured laser 
#' power after and before the fiber.The returned data has the same structure as the return value of 
#' getStokes.from.expData.
#' @importFrom magrittr %>%
#' @export
getStokes.from.metaData <- function(meta.elab) {
  
  # Normalise data and compute stokes vectors for unmanipulated stokes vector of the laser
  
  # Extract tables from list
  meta.laser     <- meta.elab[[1]]
  meta.polariser <- meta.elab[[2]]
  
  # Normalise the data
  # Not that great normalisation, because the maximal laser power (meta.laser[1,2]) 
  # is only measured without the optical fiber
  meta.polariser$Y2 <- as.numeric(as.character(meta.polariser$Y2)) / as.numeric(as.character(meta.laser[1,2]))
  
  # Compute stokes vectors and organise them exaclty like getStokes.from.expData
  # ASSUMPTION: S3 = 0
  meta.stokes <- list( PRE = data.frame(W = NA, 
                                        S0 = meta.polariser[c(1),"Y2"]+meta.polariser[c(2),"Y2"],
                                        S1 = meta.polariser[c(1),"Y2"]-meta.polariser[c(2),"Y2"],
                                        S2 = meta.polariser[c(3),"Y2"]-meta.polariser[c(4),"Y2"],
                                        I = NA),
                       POST = data.frame(W = NA, 
                                         S0 = meta.polariser[c(5),"Y2"]+meta.polariser[c(6),"Y2"],
                                         S1 = meta.polariser[c(5),"Y2"]-meta.polariser[c(6),"Y2"],
                                         S2 = meta.polariser[c(7),"Y2"]-meta.polariser[c(8),"Y2"],
                                         I = NA) 
  )
  # Return result
  return(meta.stokes)
}

#' Preprocess Data From Stokes Measurements Of Optical Fibers
#' 
#' This function takes the output from RHotStuff::GET.elabftw.bycaption 
#' or RHotStuff::parseTable.elabftw with the parameter outputHTTP=FALSE 
#' (see the man page of the functions for details) and computes the stokes
#' vectors for the experimental data of the experiment. The function extracts 
#' the power measurements from the input table, normalises it with data from 
#' the input table and calculates the stokes vectors before and after the
#' optical fiber for different inital orientations of the lasers plane of 
#' polarisation.
#' 
#' This function expects the input to be in a specific format. If the elabFTW 
#' template "Bestimmung von Stokesvektoren an einer optischen Faser" is used
#' for logging the measurements, the data meets the expectations. If the right 
#' template is used, the data can be downloaded like shown in the examples.
#' @examples
#' # Read data from elabFTW
#' input.data <- GET.elabftw.bycaption(EXPID, caption="Messdaten", header=T)
#' # Read data from elabFTW and read the attached .csv files
#' input.data <- GET.elabftw.bycaption(EXPID, caption="Messdaten", header=T, outputHTTP=T) 
#'                %>% parseTable.elabftw(., func=function(x) qmean(x[,4], 
#'                                                                 0.8, 
#'                                                                 na.rm=T, 
#'                                                                 inf.rm=T),
#'                                       header=T, skip=14, sep=";")
#' # Convert the measurements into stokes vectors
#' getStokes.from.expData(input.data)
#' 
#' @param data.elab The experimental data of a stokes measurement experiment
#' @return A list containing two data.frames: The stokes vectors before interferring with the 
#' fiber, after interferring with the fiber for different inital orientations of the lasers 
#' plane of polarisation. The data.frames also contain the total measured laser power after 
#' and before the fiber. The returned data has the same structure as the return value of 
#' getStokes.from.metaData.
#' @importFrom magrittr %>%
#' @export
getStokes.from.expData <- function(data.elab) {
  
  # Normalise data and compute stokes vectors for experimental data
  
  # Sort data.elab by position of the waveplate
  data.elab <- lapply(data.elab, function(table) table[order(table$X),])
  
  # Normalise the data
  data <- lapply(data.elab, function(table) {
    data.frame( W    = table$X,
                PRE  = table$Y2/table$Y1,
                POST = table$Y4/table$Y3 )
  })
  
  # Compute the stokes vectors before and after the optical fiber
  # ASSUMPTION: S3 = 0
  # Make sure the stokes vectors were measured for the same positions of the wave plate
  if( !all(data[[1]]$W == data[[2]]$W) | !all(data[[1]]$W == data[[3]]$W) | !all(data[[1]]$W == data[[4]]$W) ) {
    stop("The wave plate positions don't match for all given tables.") 
  } else {
    # Calculate stokes vectors and the total laser intensity before and after the optical fiber
    stokes <- list( PRE = data.frame( W = data[[1]]$W,
                                      S0 = data[[1]]$PRE + data[[2]]$PRE,
                                      S1 = data[[1]]$PRE - data[[2]]$PRE,
                                      S2 = data[[3]]$PRE - data[[4]]$PRE,
                                      I  = sapply(data.elab, function(table) table$Y1) %>% rowMeans ),
                    POST = data.frame( W = data[[1]]$W,
                                       S0 = data[[1]]$POST + data[[2]]$POST,
                                       S1 = data[[1]]$POST - data[[2]]$POST,
                                       S2 = data[[3]]$POST - data[[4]]$POST,
                                       I  = sapply(data.elab, function(table) table$Y3) %>% rowMeans)
    )
  }
  
  # Return the stokes vectors
  return(stokes)
}