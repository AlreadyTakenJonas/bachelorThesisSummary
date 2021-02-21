#
#   Set global knitr options
#
# German decimal point
options(OutDec= ",")

#
#   Load useful libraries
#
library("ggplot2")
library("magrittr")


# Custom Theme For GGPlot2
# 
# This function wraps a bunch of ggplot2 commands to style the plots in a consistent, easy to code and pretty hot way.
# 
# return: No idea what funky shit ggplot2 does. Use the return value like any other ggplot2 theme.
#
theme_hot <- function() {
  # Use the classic theme for default settings
  ggplot2::theme_classic() +
    # Change the default settings
    ggplot2::theme(
      # Change font size for the axis labels and axis title
      axis.text = ggplot2::element_text(size=12),
      # Add grid lines
      panel.grid.major = ggplot2::element_line("black", size = 0.1),
      panel.grid.minor = ggplot2::element_line("grey", size = 0.5),
      # Make the plot title and the axis titles bold
      title = ggplot2::element_text(face="bold"),
      axis.title = ggplot2::element_text(face="bold"),
      legend.title = ggplot2::element_text(face="bold"),
      legend.text = ggplot2::element_text(face="bold"),
      legend.position = "bottom"
    )
}