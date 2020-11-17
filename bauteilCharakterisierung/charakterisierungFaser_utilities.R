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
    # Normalise stokes vectors
    table[,c("S0", "S1", "S2")] <- table[,c("S0", "S1", "S2")] / table$S0
    
    # Polarisation ratio
    table$polarisation <- sqrt(table$S1^2 + table$S2^2) / table$S0
    
    # Polar stokes angle
    table$sigma <- better.acos( table$polarisation*table$S0, table$S1, table$S2)
    
    # Polar electrical field coordinate
    # !!! Keep in mind: This may be bullshit, if the polarisation ratio is smaller than one!
    # I'm to 90% sure that this conversion is also valid for partially polarised light
    table$epsilon <- table$sigma / 2
    
    # Return result
    return(table)
  })
  
  # CALCULATE CHANGE OF THE STOKES VECTORS PROPERTIES
  # Change in epsilon, change in polarisation, change in laser intensity
  stokes[["change"]]   <- data.frame("W"                      = stokes$PRE$W,
                                     # How much gets the plane of polarisation rotated?
                                     # Calculate the difference as smallest signed distance between two modular numbers
                                     # !!! Keep in mind: This is bullshit, if the polarisation ratio is smaller than one!
                                     "mod.change.in.epsilon"  = better.subtraction(stokes$POST$epsilon - stokes$PRE$epsilon, base=  pi),
                                     "mod.change.in.sigma"    = better.subtraction(stokes$POST$sigma   - stokes$PRE$sigma  , base=2*pi),
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
# !!! Keep in mind: The statistics for the angles sigma and epsilon are not done with modular functions
#                   The modular numbers sigma and epsilon will therefore have the wrong mean, variance, sd, ...
#                   In this case only the modular calculated difference can be trusted.
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
