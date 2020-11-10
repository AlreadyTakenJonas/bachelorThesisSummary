library(RHotStuff)
library(magrittr)

# Make sure the version of RHotStuff is compatible with the code
check.version("1.2.2")

# Get data from elabFTW
data.elab <- GET.elabftw.bycaption(66, header=T, outputHTTP=T) %>% parseTable.elabftw(., 
               func=function(x) qmean(x[,4], 0.8, na.rm=T, inf.rm=T),
               header=T, skip=14, sep=";")

#
# CALCULATE STOKES VECTORS
#
# Normalise the data
data <- lapply(data.elab, function(table) {
  data.frame( W    = table$X,
              PRE  = table$Y2/table$Y1,
              POST = table$Y4/table$Y3 )
})

# ASSUMPTION: S3 = 0
# Make sure the stokes vectors were measured for the same positions of the wave plate
if( !all(data[[1]]$W == data[[2]]$W) | !all(data[[1]]$W == data[[3]]$W) | !all(data[[1]]$W == data[[4]]$W) ) {
  stop("The wave plate positions don't match for all given tables.") 
} else {
  # Calculate stokes vectors
  stokes <- data.frame( W = data[[1]]$W,
                        PRE.S0 = data[[1]]$PRE + data[[2]]$PRE,
                        PRE.S1 = data[[1]]$PRE - data[[2]]$PRE,
                        PRE.S2 = data[[3]]$PRE - data[[4]]$PRE,
                        POST.S0 = data[[1]]$POST + data[[2]]$POST,
                        POST.S1 = data[[1]]$POST - data[[2]]$POST,
                        POST.S2 = data[[3]]$POST - data[[4]]$POST
  )
}

# Normalise stokes vectors
stokes[,c("PRE.S0","PRE.S1","PRE.S2")] <- stokes[,c("PRE.S0","PRE.S1","PRE.S2")]/stokes$PRE.S0
stokes[,c("POST.S0","POST.S1","POST.S2")] <- stokes[,c("POST.S0","POST.S1","POST.S2")]/stokes$POST.S0

# Compute polarisation ratio
stokes$PRE.polarisation <- (stokes$PRE.S1^2 + stokes$PRE.S2^2)/stokes$PRE.S0
stokes$POST.polarisation <- (stokes$POST.S1^2 + stokes$POST.S2^2)/stokes$POST.S0

# Compute polar stokes parameter
# The statistics for angles are kind of useless, because they are modular
stokes$PRE.sigma <- better.acos(stokes$PRE.S0, stokes$PRE.S1, stokes$PRE.S2)
stokes$POST.sigma <- better.acos(stokes$POST.S0, stokes$POST.S1, stokes$POST.S2)

#
# Calculate some interesting stuff
#
mod.change.in.epsilon <- better.subtraction(stokes$POST.sigma - stokes$PRE.sigma)/2
change.in.polarisation <- stokes$POST.polarisation / stokes$PRE.polarisation - 1
intensity <- data.frame(W = data.elab[[1]]$X,
                        PRE.I = data.elab[[1]]$Y1,
                        POST.I = data.elab[[1]]$Y3 )
intensity$LOSS.I <- intensity$POST.I/intensity$PRE.I

#
# DO THE STATISTICS
#
variables <- cbind.data.frame(stokes, mod.change.in.epsilon, change.in.polarisation, intensity[,-1])
stats <- data.frame( var  = sapply(variables, var ),
                     sd   = sapply(variables, sd  ),
                     mean = sapply(variables, mean)
                   )

# TODO: t-Test, Kruskal-Wallis-Test
