# Load libraries and shit
source("R/lib.R")


# Read data for optical fiber F1
F1.stokes <- list(  PRE             = read.table(file="/compile/data/F1_stokes_pre.csv", header=T),
                    POST            = read.table(file="/compile/data/F1_stokes_post.csv", header=T),
                    change          = read.table(file="/compile/data/F1_stokes_change.csv", header=T),
                    POST.PREDICT    = read.table(file="/compile/data/F1_stokes_predict.csv", header=T),
                    PREDICT.ERROR   = read.table(file="/compile/data/F1_stokes_errorPredict.csv", header=T)  )
F1.error <- list(   PRE             = read.table(file="/compile/data/F1_error_pre.csv", header=T, row.names=1),
                    POST            = read.table(file="/compile/data/F1_error_post.csv", header=T, row.names=1),
                    change          = read.table(file="/compile/data/F1_error_change.csv", header=T, row.names=1) )
            
# Read data for optical fiber F2
F2.stokes <- list(  PRE             = read.table(file="/compile/data/F2_stokes_pre.csv", header=T),
                    POST            = read.table(file="/compile/data/F2_stokes_post.csv", header=T),
                    change          = read.table(file="/compile/data/F2_stokes_change.csv", header=T),
                    POST.PREDICT    = read.table(file="/compile/data/F2_stokes_predict.csv", header=T),
                    PREDICT.ERROR   = read.table(file="/compile/data/F2_stokes_errorPredict.csv", header=T)  )
F2.error <- list(   PRE             = read.table(file="/compile/data/F2_error_pre.csv", header=T, row.names=1),
                    POST            = read.table(file="/compile/data/F2_error_post.csv", header=T, row.names=1),
                    change          = read.table(file="/compile/data/F2_error_change.csv", header=T, row.names=1) )

# Read data for optical fiber F3
F3.stokes <- list(  PRE             = read.table(file="/compile/data/F3_stokes_pre.csv", header=T),
                    POST            = read.table(file="/compile/data/F3_stokes_post.csv", header=T),
                    change          = read.table(file="/compile/data/F3_stokes_change.csv", header=T),
                    POST.PREDICT    = read.table(file="/compile/data/F3_stokes_predict.csv", header=T),
                    PREDICT.ERROR   = read.table(file="/compile/data/F3_stokes_errorPredict.csv", header=T)  )
F3.error <- list(   PRE             = read.table(file="/compile/data/F3_error_pre.csv", header=T, row.names=1),
                    POST            = read.table(file="/compile/data/F3_error_post.csv", header=T, row.names=1),
                    change          = read.table(file="/compile/data/F3_error_change.csv", header=T, row.names=1) )


#
#   PLOT THAT SHIT
#

# COMPARING POLARISATION RATIOS before and after interacting with the fiber
plot.polarisation <- function(data,
                              statistics,
                              title = expression(bold("The Effect Of An <YOUR OPTICAL FIBER> On The Polarisation Ratio "*Pi))
                              ) {
  # PARAMETERS
  # data : processedStokesExperiments (output of process.stokesVec)
  # statistics : processsedErrorMeasurementExperiment (output of process.stokesVec)
  # title : expression(bold("The Effect Of An <YOUR OPTICAL FIBER> On The Polarisation Ratio "*Pi))
  
  # Translate rotation of waveplate to rotation of plane of polarisation
  data$PRE$W  <- data$PRE$W*2
  data$POST$W <- data$POST$W*2
  
  # Select only data points with rotation values below or equal 360°
  data <- lapply(data, function(table) {
      table <- table[table$W<=360,]
  })
  
  # Plot that bitch
  ggplot(data = data.frame( W = c(data$POST$W, data$PRE$W) %>% as.factor,
                            polarisation = c(data$POST$polarisation, data$PRE$polarisation),
                            group = c( rep("B_POST", length(data$POST$W)), rep("A_PRE", length(data$PRE$W)) )
                        ),
        mapping=aes(x=W, y=polarisation*100, fill=group)) +
    geom_bar(stat="identity", position = "dodge") +
    theme_hot() +
    scale_y_continuous(breaks = seq(from=0, to=110, by=10),
                       expand=c(0,0)) +
    scale_x_discrete(breaks = as.factor(data$POST$W))+
    theme(axis.text = element_text(size=12),
          panel.grid.major.x = element_blank(),
          panel.grid.minor.x = element_blank(),
          legend.position = "bottom") +
    labs(title = title,
         x     = expression(bold("Rotation der Polarisationsebene "*epsilon*" / °")),
         y     = expression(bold(Pi*" / %")),
         fill  = "" ) +
    scale_fill_discrete( labels=c( expression(bold("vorher")), expression(bold("nachher")) ) ) +
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
  
  # Transform rotation of waveplate into rotation of polarisation plane
  data$change$W <- data$change$W*2
  # Leave out repeating values
  data$change   <- data$change[data$change$W<=180 & data$change$W>=0,] 
  
  ggplot( data    = data$change, 
          mapping = aes(x = W, y = change.in.intensity*100) ) +
    geom_bar(stat="identity") +
    theme_hot() +
    scale_x_continuous(breaks = seq(from=0, to=180, by=45)) +
    theme(axis.text = element_text(size=12),
          panel.grid.major.x = element_blank(),
          panel.grid.minor.x = element_blank() ) +
    labs(title = title,
         x = expression(bold("Rotation der Polarisationsebene "*epsilon*" / °")),
         y = "Transmission / %" )
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