#' Compute A Raman Spectrum From PolaRam Output
#'       
#' This function takes the output of the polaram simulate program and computes one possible raman spectrum. PolaRam is a program that simulates the
#' raman scattering process with respect to the polarisation of the light. For details see the [GitHub-Repository](https://github.com/AlreadyTakenJonas/PolaRam).
#' The spectrum will be computed as sum of loretz curves. Every peak of the spectrum will be modeled by a lorentz curve. This function makes the assuption, that
#' the spectrum was created with a hypothetical photo detector, that responds differently to light polarised along the x-axis and y-axis. The two scalars scaleX
#' and scaleY allow to influence the height of the signal, depending of the polarisation of the hypothetically detectable light. If both values are one, the light
#' will be not distinguished by its polarisation.
#' 
#' @param x A vector of wavnumbers. The function computes for every wavenumber one point of the spectrum.
#' @param stokes.S0 The first stokes parameter of the scattered light. It may be a vector with one element for each peak.
#' @param stokes.S1 The second stokes parameter of the scattered light. It may be a vector with one element for each peak.
#' @param peaks.wavenumber The wavenumber of the raman peak. It may be a vector with one element for each peak.
#' @param gamma A scalar describing the width of the peaks. It may be a vector with one element for each peak. If the vector gamma is shorter than the peaks.wavenumber
#' vector, gamma will be reapeated until the length of both vectors match. The FWHM is in terms of the peaks width gamma (g) and the peaks wavenumber (v):
#' FWHM = sqrt(v^2 + vg) - sqrt(v^2 - vg) .
#' @param normalise Boolean value. If true the spectrum will be divided by its maximum.
#' @param scaleX Multiplicator, which describes how sensitive the photo detector is along the x-axis.
#' @param scaleY Multiplicator, which describes how sensitive the photo detector is along the y-axis.
#' @return A data frame containing a calculated raman spectrum.
#' @export                                                                                                                                                                                                                                                                                                          
polaram.as.spectrum <- function( x, stokes.S0, stokes.S1, peaks.wavenumber, 
                                 gamma = 25, 
                                 normalise = FALSE,
                                 scaleX = 2,
                                 scaleY = 1 ) {                                                                                                                                                                                                                                                                                                                             

  # Make gamma the same length as the input data                                                                                                                                                                                                                                                                                                                                               
  # Avoids errors when computing the lorentz curves                                                                                                                                                                                                                                                                                                                                        
  gamma <- rep( gamma, length.out = max(length(stokes.S0), length(stokes.S0), length(peaks.wavenumber)) )                                                                                                                                                                                                                                                                                                                                   
  
  # The intensity of the scatterd light in x- and y-direction
  # See the definition of stokes vectors for more details
  intensity.x <- (stokes.S0 + stokes.S1) / 2                                                                                                                                                                                                                                                                                                                                           
  intensity.y <- (stokes.S0 - stokes.S1) / 2                                                                                                                                                                                                                                                                                                                                           
  
  # The signal response of the detector
  # It is assumed that a photo detector responds differntly to light along the x- and y-axis
  detector.response <- scaleX*intensity.x + scaleY*intensity.y                                                                                                                                                                                                                                                                                                                                       
  
  # Compute spectrum as sum of lorentz curves                                                                                                                                                                                                                                                                                                                                              
  # Each peak is a lorentz curve                                                                                                                                                                                                                                                                                                                                                           
  spectrum <- sapply(x, function(x) {                                                                                                                                                                                                                                                                                                                                                      
    # Compute the lorentz curve for every peak                                                                                                                                                                                                                                                                                                                                             
    # The width is gamma, the maximum is at wavenumber and the detector.response scales the peak
    # The Full width at half height is correlated with gamma
    peaks <- detector.response / ( ( x^2 - peaks.wavenumber^2 )^2 + gamma^2 * peaks.wavenumber^2 )                                                                                                                                                                                                                                                                                                         
    
    # Return the sum of all peaks                                                                                                                                                                                                                                                                                                                                                          
    return( sum(peaks) )                                                                                                                                                                                                                                                                                                                                                                   
  })                                                                                                                                                                                                                                                                                                                                                                                       
  
  # Normalise the spectrum with the largest peak                                                                                                                                                                                                                                                                                                                                           
  if (normalise == TRUE) spectrum <- spectrum / max(spectrum)                                                                                                                                                                                                                                                                                                                              
  
  # Return the spectrum                                                                                                                                                                                                                                                                                                                                                                    
  spectrum                                                                                                                                                                                                                                                                                                                                                                     
  
}
