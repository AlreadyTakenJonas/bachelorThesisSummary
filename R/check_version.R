#' Check The Version Of The Package
#' 
#' This function makes sure that the scripts your running is working with the correct version 
#' of RHotStuff. If the version does not match the expectations, the function prompts a warning.
#' 
#' @param expected.version The version (as string) of RHotStuff the script was designed to use.
#' 
#' @export
check.version <- function(expected.version) {

  # TODO: split version at '.' and compare each part of the versions to allow versions that don't match 100%, but are compatible
  
  if (packageVersion("RHotStuff")!=expected.version) {
    warning("VERSION MISMATCH RHOTSTUFF")
    warning(paste0("This script was designed for RHotStuff version ", expected.version, 
                 ", but version ", packageVersion("RHotStuff"), 
                 " is installed. Make sure the versions are compatible"))
  } else print("RHotStuff version as expected.")
  
}