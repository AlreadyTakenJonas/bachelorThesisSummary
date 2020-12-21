library(RHotStuff)
library(magrittr)
library(ggplot2)

# Make sure the version of RHotStuff is compatible with the code
check.version("1.4.0")


#
# CALCULATE STOKES VECTORS AND THEIR PROPERTIES
#
# Normalise stokes vector and compute polarisation ratio and such shit
# ASSUMPTION: S3 = 0
process.stokesVec <- function(stokes) {
  # Compute properties of stokes vectors and normalise -> polarisation ratio, ...
  stokes <- lapply(stokes, function(table) { 
    # Normalise stokes vectors with initial first stokes parameter
    table[,c("S0", "S1", "S2")] <- table[,c("S0", "S1", "S2")] / stokes$PRE$S0
    
    # Polarisation ratio
    table$polarisation <- sqrt(table$S1^2 + table$S2^2) / table$S0
    
    # Return result
    return(table)
  })
  
  # CALCULATE CHANGE OF THE STOKES VECTORS PROPERTIES
  # Change in epsilon, change in polarisation, change in laser intensity
  stokes[["change"]]   <- data.frame("W"                      = stokes$PRE$W,
                                     # How much does the polarisation ratio change?
                                     "change.in.polarisation" = stokes$POST$polarisation / stokes$PRE$polarisation - 1,
                                     # How much does the intensity of the light change?
                                     "change.in.intensity"    = stokes$POST$I / stokes$PRE$I
  )
  
  return(stokes)
  
}
#
# DO THE STATISTICS
#
# error.stokes contains the data for several identical measurements
# following function will therefore compute statistical properties 
# like sd or mean for every column of the tables
do.statistics <- function(error.stokes) {
  lapply(error.stokes, function(table) {
    stats.table <- data.frame( var  = sapply(table, var ),
                               sd   = sapply(table, sd  ),
                               mean = sapply(table, mean)
    )
    return(stats.table)
  }) %>% return
  
  
  # TODO: t-Test, Kruskal-Wallis-Test
}


#
# COMPUTE THE MUELLER MATRIX OF THE OPTICAL FIBER
#
# This function takes at least three pairs stokes vectors describing the polarisation of a laser before (S^PRE) and after (S^POST) interacting
# with an optical fiber (input is the output of process.stokesVec())
muellermatrix <- function(stokes) {
  # Fit following system of linear equation of three unknown variables (a, b, c) with many known stokes vector pairs
  # Ignore last stokes parameter
  # (I)   S_0^POST = a_0 * S_0^PRE + b_0 * S_1^PRE + c_0 * S_2^PRE + d_0 * S_3^PRE (S_3^PRE=0)
  # (II)  S_1^POST = a_1 * S_0^PRE + b_1 * S_1^PRE + c_1 * S_2^PRE + d_1 * S_3^PRE (S_3^PRE=0)
  # (III) S_2^POST = a_2 * S_0^PRE + b_2 * S_1^PRE + c_2 * S_2^PRE + d_2 * S_3^PRE (S_3^PRE=0)
  # (IV)  S_3^POST = a_3 * S_0^PRE + b_3 * S_1^PRE + c_3 * S_2^PRE + d_3 * S_3^PRE (S_3^PRE=0, S_3^POST=0)
  # Build mueller matrix as following:
  # | a_0 b_0 c_0 d_0 |   | a_0 b_0 c_0  0 |
  # | a_1 b_1 c_1 d_1 | = | a_1 b_1 c_1  0 | 
  # | a_2 b_2 c_2 d_2 |   | a_2 b_2 c_2  0 |
  # | a_3 b_3 c_3 d_3 |   |  0   0   0   0 |
  matrix( c( limSolve::Solve(as.matrix(stokes$PRE[,c(2,3,4)]), stokes$POST$S0), 0,
             limSolve::Solve(as.matrix(stokes$PRE[,c(2,3,4)]), stokes$POST$S1), 0,
             limSolve::Solve(as.matrix(stokes$PRE[,c(2,3,4)]), stokes$POST$S2), 0,
             0, 0, 0                                                          , 0 ), 
          ncol = 4, byrow = T )
}
# Predict the polarisation state after interacting with an optical fiber by using the initial 
# measured stokes vector and the muller matrix of the fiber
predict.stokesVec <- function(stokes, mueller) {
  # Calculate stokes vectors describing polarisation after the fiber by matrix multiplication in the mueller formalism
  # Ignore the last stokes parameter
  stokes.post <- apply(stokes$PRE[,c(2,3,4)], 1, function(stokes) { 
    mueller[1:3,1:3] %*% ( stokes %>% unlist ) 
  })
  # Calculate the grade of polarisation
  polarisation <- apply(stokes.post, 2, function(stokes) { 
    sqrt(sum(stokes[c(2,3)]^2)) / stokes[1] 
  } )
  
  # Put the result into the inital list of stokes parameters
  stokes$POST.PREDICT <- data.frame(W  = stokes$PRE$W,
                                    S0 = stokes.post[1,],
                                    S1 = stokes.post[2,],
                                    S2 = stokes.post[3,],
                                    I  = NA,
                                    polarisation = polarisation)
  
  # Calculate the difference between measured and predicted stokes vector
  stokes$PREDICT.ERROR <- data.frame(W = stokes$POST.PREDICT$W,
                                     diff.S0 = stokes$POST$S0 - stokes$POST.PREDICT$S0,
                                     diff.S1 = stokes$POST$S1 - stokes$POST.PREDICT$S1,
                                     diff.S2 = stokes$POST$S2 - stokes$POST.PREDICT$S2,
                                     diff.polarisation = stokes$POST$polarisation - stokes$POST.PREDICT$polarisation )
  
  return(stokes)
}




#
#   PLOT THAT SHIT
#
# How does the POLARSATION RATIO change RELATIVE to the initial polarisation ratio?
plot.polarisation.change <- function(data, 
                                     title = expression(bold("The Depolarising Behaviour Of <YOUR OPTICAL FIBER>"))
                                     ) {
  # EXPECTED PARAMETERS:
  # data : processedStokesExperiments (output of process.stokesVec)
  # title : expression(bold("The Depolarising Behaviour Of <YOUR OPTICAL FIBER>"))
  
  # Create the plot
  ggplot(data    = data$change,
         mapping = aes(x = as.factor(W), y = change.in.polarisation*100) ) +
    geom_bar(stat="identity") +
    theme_classic() +
    theme( axis.text = element_text(size=12),
           panel.grid.major.y = element_line("black", size = 0.1),
           panel.grid.minor.y = element_line("grey", size = 0.5) ) +
    labs(title = title,
         x = expression(bold("the have-waveplates angle of rotation "*omega*" / °")),
         y = expression(bold("the relative change in the ratio of polarisation "*Delta*Pi*" / %")) )
  
}

# COMPARING POLARISATION RATIOS before and after interacting with the fiber
plot.polarisation <- function(data,
                              statistics,
                              title = expression(bold("The Effect Of An <YOUR OPTICAL FIBER> On The Polarisation Ratio "*Pi)) 
                              ) {
  # PARAMETERS
  # data : processedStokesExperiments (output of process.stokesVec)
  # statistics : processsedErrorMeasurementExperiment (output of process.stokesVec)
  # title : expression(bold("The Effect Of An <YOUR OPTICAL FIBER> On The Polarisation Ratio "*Pi))
  
  ggplot(data = data.frame(W = c(data$POST$W, data$PRE$W),
                           polarisation = c(data$POST$polarisation, data$PRE$polarisation),
                           group = c( rep("B_POST", length(data$POST$W)), rep("A_PRE", length(data$PRE$W)) )
                          ),
        mapping=aes(x=as.factor(W), y=polarisation*100, fill=group)) +
    geom_bar(stat="identity", position = "dodge") +
    theme_classic() +
    scale_y_continuous(breaks = seq(from=0, to=110, by=10),
                       expand=c(0,0)) +
    theme(axis.text = element_text(size=12),
          panel.grid.major.y = element_line("black", size = 0.1),
          panel.grid.minor.y = element_line("grey", size = 0.5) ) +
    labs(title = title,
         x     = expression(bold("the have-waveplates angle of rotation "*omega*" / °")),
         y     = expression(bold("the polarisation ratio "*Pi*" / %")),
         fill  = "" ) +
    scale_fill_discrete( labels=c( expression(bold("before")), expression(bold("after")) ) ) +
    geom_errorbar(data=data.frame(W     = c(data$PRE$W, data$POST$W) %>% as.factor, 
                                  upper = c(data$PRE$polarisation+statistics$POST["polarisation","sd"]*3, data$POST$polarisation+statistics$POST["polarisation","sd"]*3)*100,
                                  lower = c(data$PRE$polarisation-statistics$POST["polarisation","sd"]*3, data$POST$polarisation-statistics$POST["polarisation","sd"]*3)*100,
                                  group = c( rep("A_PRE", length(data$POST$W)), rep("B_POST", length(data$PRE$W)) ),
                                  polarisation = c(data$PRE$polarisation, data$POST$polarisation) ),
                  mapping = aes(x=W, ymin = lower, ymax=upper, group=group),
                  position = "dodge"
    ) 
}

# CHANGE in LASER POWER due to optical fiber
plot.intensity.change <- function(data, 
                                  title = expression(bold("The Transmittance Of <YOUR OPTICAL FIBER>"))
                                  ) {
  # EXPECTED PARAMETERS:
  # data : processedStokesExperiments (output of process.stokesVec)
  # title : expression(bold("The Depolarising Behaviour Of <YOUR OPTICAL FIBER>"))
  
  ggplot( data    = data$change, 
          mapping = aes(x = as.factor(W), y = change.in.intensity*100) ) +
    geom_bar(stat="identity") +
    theme_classic() +
    theme(axis.text = element_text(size=12),
          panel.grid.major.y = element_line("black", size = 0.1),
          panel.grid.minor.y = element_line("grey", size = 0.5) ) +
    labs(title = title,
         x = expression(bold("the have-waveplates angle of rotation "*omega*" / °")),
         y = expression(bold("the transmitted part of the laser P"[trans]*" / %")) )
}


# COMPARING LASER POWER before and after interacting with the fiber
plot.intensity <- function(data, 
                           title = expression(bold("The Effect Of <YOUR OPTICAL FIBER> On The Lasers Power "*P))
                          ) {
  # EXPECTED PARAMETERS:
  # data : processedStokesExperiments (output of process.stokesVec)
  # title : expression(bold("The Depolarising Behaviour Of <YOUR OPTICAL FIBER>"))
  
  ggplot(data = data.frame(W = c(data$POST$W, data$PRE$W),
                           intensity = c(data$POST$I, data$PRE$I) /  data$PRE$I,
                           group = c( rep("B_POST", length(data$POST$W)), rep("A_PRE", length(data$PRE$W)) )
                          ),
         mapping=aes(x=as.factor(W), y=intensity*100, fill=group)) +
    geom_bar(stat="identity", position = "dodge") +
    theme_classic() +
    theme(axis.text = element_text(size=12),
          panel.grid.major.y = element_line("black", size = 0.1),
          panel.grid.minor.y = element_line("grey", size = 0.5) ) +
    labs(title = title,
         x     = expression(bold("the have-waveplates angle of rotation "*omega*" / °")),
         y     = expression(bold("the normalised laser power "*P*" / %")),
         fill  = "" ) +
    scale_fill_discrete( labels=c( expression(bold("before")), expression(bold("after")) ) )  
}


# How does the fiber influence the PLANE OF POLARISATIONS ORIENTATION?
plot.plane.rotation <- function(data, 
                                title = expression(bold("The Impact Of The <YOUR FIBER> On The Orientation Of The Plane Of Polarisation")) 
) {
  # EXPECTED PARAMETERS:
  # data : elabFTW table of angle dependent rotation behavior of optical fibers
  # title : expression(bold("The Impact Of The <YOUR FIBER> On The Orientation Of The Plane Of Polarisation"))
  
  ggplot( data = data[!is.na(data$X),] ) +
    geom_abline( mapping = aes(intercept = 0, slope = 2, color="ideal waveplate") ) +
    geom_abline( mapping = aes(intercept = 0, slope = -2, color="ideal waveplate") ) +
    geom_point( mapping = aes(x = X, y = Y1-Y1[X==0], color = "after") ) +
    geom_point( mapping = aes(x = X, y = Y2-Y2[X==0], color = "before") ) +
    theme_classic() +
    theme(panel.grid.major = element_line("black", size=0.1),
          panel.grid.minor = element_line("grey", size=0.1) ) +
    scale_x_continuous(breaks = seq(from=-20, to=300, by=20) ) +
    scale_y_continuous(breaks = seq(from=-360, to=360, by=90) ) +
    labs(title = title,
         x = expression(bold("rotation waveplate / °")),
         y = expression(bold("rotation linear polariser / °")),
         color = "" )
}


# COMPARE PREDICTED and MEASURED STOKES parameters and polarisation ratio
plot.stokesPredict <- function(data,
                               title = "Näherung von ??") {
  
  # EXPECTED PARAMETERS:
  # data : predicted and processed stokes parameters (output of predict.stokesVec)
  # title : Descriptive title
  
  # Reorganise data into three columns: X, Y, Group, Color
  # X: wave plate position
  # Y: Stokes parameters / polarisation
  # Group: group to distinguish wich X-Y-pair belongs to which subplot
  # Color: is it the measured or predicted data?
  grouped.data <- data.frame(
    W     = rep(data$POST$W, 8),
    Y     = c( data$POST$S0, data$POST.PREDICT$S0,
               data$POST$S1, data$POST.PREDICT$S1,
               data$POST$S2, data$POST.PREDICT$S2,
               data$POST$polarisation, data$POST.PREDICT$polarisation ),
    Group = c( rep("S0", length.out=length(data$POST$S0)*2),
               rep("S1", length.out=length(data$POST$S1)*2),
               rep("S2", length.out=length(data$POST$S2)*2),
               rep("polarisation", length.out=length(data$POST$polarisation)*2) ),
    Color = c( rep("Messung", length.out=length(data$POST$S0)), rep("Prognose", length.out=length(data$POST.PREDICT$S0)),
               rep("Messung", length.out=length(data$POST$S1)), rep("Prognose", length.out=length(data$POST.PREDICT$S1)),
               rep("Messung", length.out=length(data$POST$S2)), rep("Prognose", length.out=length(data$POST.PREDICT$S2)),
               rep("Messung", length.out=length(data$POST$polarisation)), rep("Prognose", length.out=length(data$POST.PREDICT$polarisation)) )
  )
  
  # Generate titles for the subplots
  facet.labels <- list( "S0" = "Erster Stokesparameter",
                        "S1" = "Zweiter Stokesparameter",
                        "S2" = "Dritter Stokesparameter",
                        "polarisation" = "Polarisationsgrad" )
  
  # Plot data as four different plots
  ggplot(data = grouped.data, 
         mapping = aes(x = W, y = Y, color = Color) ) +
    geom_point() +
    geom_line() +
    theme_hot() +
    scale_x_continuous(breaks = seq(from=0, to=360, by=90)) +
    theme(legend.position = "bottom",
          strip.text.x = element_text(face="bold") ) +
    labs(title = title,
         y = element_blank(),
         x = expression(bold("Rotation der Halbwellenplatte "*omega*" / °")),
         color = element_blank()) +
    facet_wrap(facets = vars(Group),
               scales = "free_y",
               labeller = as_labeller( function(x) {facet.labels[x]} )
    )
}