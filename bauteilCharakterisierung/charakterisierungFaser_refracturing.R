#
# Get some libraries and functions used for characterising optical fibers
#
source("bauteilCharakterisierung/charakterisierungFaser_utilities.R")



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

# TODO: CHECK POLARISATION RATIO <=1



#
# PLOT THAT SHIT
#
# How does the polarisation ratio change relative to the initial polarisation ratio?
plot.polarisation.change <- function(data, 
                                     title = expression(bold("The Depolarising Behaviour Of <YOUR OPTICAL FIBER>"))
                                     ) {
  # EXPECTED PARAMETERS:
  # data : processedStokesExperiments$change (output of process.stokesVec)
  # title : expression(bold("The Depolarising Behaviour Of <YOUR OPTICAL FIBER>"))
                                    
  # Create the plot
  ggplot(data    = data,
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
plot.polarisation.change(data  = F1.data.stokes$change, 
                         title = expression(bold("The Depolarising Behaviour Of An Optical PM-Fiber") )
