require(plot3D)

epsilon.rad <- 3*pi/4
phase.periods  <- 0.1
time <- 0
x.waveplateStart <- 0
x.waveplateEnd   <- 2
waveplate.shiftPeriods <- 0.5
x <- seq(from=-1,to=2,by=0.01)
Ex <- function(x=0, t=time) {
  shift <- sapply(x, function(x) {
    if(x < x.waveplateStart) shift <- 0
    else if(x > x.waveplateEnd) shift <- waveplate.shiftPeriods
    else shift <- (x - x.waveplateStart) / (x.waveplateEnd - x.waveplateStart) * waveplate.shiftPeriods
    return(shift)
  })
  round(sin(epsilon.rad), digits=2)*cos(2*pi*(x-t-shift))
}
Ey <- function(x=0, t=time) round(cos(epsilon.rad), digits=2)*cos(2*pi*(x-t+phase.periods))



# Create plot
# Z-Axis
arrows3D(x0=x[1], x1=tail(x,1)+0.5,
         y0=0, y1=0, 
         z0=0, z1=0, 
         col="black", lwd = 2,
         bty="n", 
         zlim=c(-1,1), ylim=c(-1,1),
         theta=45, phi=20)
text3D(x=tail(x, 1)+0.55, y=0, z=0, labels="z", add=T)
# Wave along x axis
lines3D(x=x, y=rep(0, length(x)), z=Ex(x), col="red", lwd = 2, add=T)
# Wave along y axis
lines3D(x=x, y=Ey(x), z=rep(0,length(x)), col="green", lwd = 2, add=T)

# Add axes
segments3D(x0=x.waveplateStart, x1=x.waveplateStart,
         y0=-0.8, y1=0.8,
         z0=0, z1=0,
         col="black", lwd = 2,
         add=T)
segments3D(x0=x.waveplateStart, x1=x.waveplateStart,
         y0=0, y1=0,
         z0=-0.8, z1=0.8,
         col="black", lwd = 2,
         add=T)
arrows3D(x0=x.waveplateEnd, x1=x.waveplateEnd,
         y0=-1, y1=1, 
         z0=0, z1=0, 
         col="black", lwd = 2,
         add=T)
text3D(x=x.waveplateEnd, y = 1.05, z = 0, labels = "y", add=T)
arrows3D(x0=x.waveplateEnd, x1=x.waveplateEnd,
         y0=0, y1=0, 
         z0=-1, z1=1, 
         col="black", lwd = 2,
         add=T)
text3D(x=x.waveplateEnd, y = 0, z = 1.05, labels = "x", add=T)

# Add polarisation shit
# START
# Add polarisation plane
rect3D(x0 = x.waveplateStart, x1 = NULL,
       y0 = -0.8, y1 = 0.8,
       z0 = -0.8, z1 = 0.8,
       add = T, col="blue", alpha=0.1)
# Add polarisation ellipse
lines3D(x = rep(x.waveplateStart, length(x)), 
        y = Ey(x=x.waveplateStart, t=x), 
        z = Ex(x=x.waveplateStart, t=x), 
        add=T, col="blue", lwd = 2)
# Add polarisation vector
arrows3D( x0 = x.waveplateStart, x1 = x.waveplateStart,
          y0 = 0,         y1 = Ey(x.waveplateStart), 
          z0 = 0,         z1 = Ex(x.waveplateStart),
          add=T, col="blue", lwd = 2)
# Add polarisation shit
# END
# Add polarisation plane
rect3D(x0 = x.waveplateEnd, x1 = NULL,
       y0 = -0.8, y1 = 0.8,
       z0 = -0.8, z1 = 0.8,
       add = T, col="blue", alpha=0.1)
# Add polarisation ellipse
lines3D(x = rep(x.waveplateEnd, length(x)), 
        y = Ey(x=x.waveplateEnd, t=x), 
        z = Ex(x=x.waveplateEnd, t=x), 
        add=T, col="blue", lwd = 2)
# Add polarisation vector
arrows3D( x0 = x.waveplateEnd, x1 = x.waveplateEnd,
          y0 = 0,         y1 = Ey(x.waveplateEnd), 
          z0 = 0,         z1 = Ex(x.waveplateEnd),
          add=T, col="blue", lwd = 2)