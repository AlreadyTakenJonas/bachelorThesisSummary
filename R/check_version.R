#' Check The Version Of The Package
#' 
#' This function makes sure that the scripts your running is working with the correct version 
#' of RHotStuff. If the version does not match the expectations, the function prompts a warning.
#' 
#' This function can check also other packages, but it does not except a vector of package names.
#' The versions must be a string in the format "x.y.z". If the parameter strict is set FALSE, x
#' must match exactly, but two version will be considered equal if y and z are just greater or 
#' equal the expected version.
#' 
#' @param expected.version The version (as string) of the package the script was designed to use.
#' @param package The package that will be checked. A vector of packages can't be handled and will 
#' be ignored; except the first element of the vector!
#' @param strict If set TRUE, the expected version must match exactly the version of the package.
#' If set FALSE, not matching, but compatible versions will also be excepted.
#' @param ... Parameters passed on to packageVersion() function.
#' @return No return value. The function throws a warning if necessary.
#' 
#' @importFrom magrittr %>%
#' @export
check.version <- function(expected.version, package="RHotStuff", strict=FALSE, ...) {
  
  # Variable for keeping track of decission maling process
  version.match <- FALSE
  
  # Check if versions match exactly (only if parameter strict is set TRUE)
  if (strict & expected.version == packageVersion(package, ...)) version.match <- TRUE
  
  # Check if versions are not exactly matching, but compatible
  else {
    # Get the version of the package and split the versions at the "." into numeric vectors for easier comparision
    expected.version.split <- strsplit(expected.version, ".", fixed=TRUE) %>% .[[1]] %>% as.numeric
    package.version  <- packageVersion(package, ...) %>% as.character %>% strsplit(., ".", fixed=TRUE) %>% .[[1]] %>% as.numeric
    
    # Check if major digits [1] match exactly, to ensure compatibility of code and library
    if ( expected.version.split[1] == package.version[1] ) {
      # Check if minor digits [2] of used version is not smaller than the expected version, to ensure all needed functions are implemented
      # Check if bug fix digits [3] of used version is not smaller than the expected version, to ensure the used functions behave the way it's expected
      if ( expected.version.split[2] == package.version[2] & expected.version.split[3] <= package.version[3] ) version.match <- TRUE
      else if ( expected.version.split[2] < package.version[2] ) version.match <- TRUE
    }  
  }
  
  # Inform user, if versions match
  if (version.match == FALSE) {
    warning("VERSION MISMATCH RHOTSTUFF")
    warning(paste0("This script was designed for RHotStuff version ", expected.version, 
                 ", but version ", packageVersion("RHotStuff"), 
                 " is installed. Make sure the versions are compatible"))
  } else print("RHotStuff version meets the expectations.")
  
}
