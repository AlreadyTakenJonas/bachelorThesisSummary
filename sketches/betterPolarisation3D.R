require(plot3D)

epsilon.rad <- pi/4
phase.periods  <- 0
time <- 0
x <- seq(from=-2,to=0,by=0.01)
Ex <- function(x=0, t=time) round(sin(epsilon.rad), digits=1)*cos(2*pi*(x-t))
Ey <- function(x=0, t=time) round(cos(epsilon.rad), digits=1)*cos(2*pi*(x-t+phase.periods)) 


# Create plot
# Z-Axis
arrows3D(x0=x[1], x1=tail(x,1)+0.5,
         y0=0, y1=0, 
         z0=0, z1=0, 
         col="black", lwd = 2,
         bty="n", 
         zlim=c(-1,1), ylim=c(-1,1),
         theta=60, phi=10,
         resfac=5)
text3D(x=tail(x, 1)+0.55, y=0, z=0, labels="z", add=T)
# Wave along x axis
lines3D(x=x, y=rep(0, length(x)), z=Ex(x), col="red", lwd = 2, add=T)
# Wave along y axis
lines3D(x=x, y=Ey(x), z=rep(0,length(x)), col="green", lwd = 2, add=T)
# Add y- and x-axis
arrows3D(x0 = tail(x, 1), x1=0,
         y0 = -1, y1 = 1,
         z0 = 0, z1 = 0, col="black", lwd = 2, add=T)
text3D(x=tail(x,1), y=1.05, z=0, labels = "y", add=T)
arrows3D(x0 = tail(x, 1), x1=0,
         y0 = 0, y1 = 0,
         z0 = -1, z1 = 1, col="black", lwd = 2, add=T)
text3D(x=tail(x,1), y=0, z=1.05, labels = "x", add=T)
# Add polarisation plane
rect3D(x0 = 0, x1 = NULL,
       y0 = -0.8, y1 = 0.8,
       z0 = -0.8, z1 = 0.8,
       add = T, col="blue", alpha=0.1)
# Add polarisation ellipse
lines3D(x = rep(tail(x,1), length(x)), 
        y=Ey(x), z=Ex(x), add=T, col="blue", lwd = 2)
# Add polarisation vector
arrows3D( x0 = tail(x,1), x1 = tail(x,1),
          y0 = 0,         y1 = Ey(tail(x,1)), 
          z0 = 0,         z1 = Ex(tail(x,1)),
          add=T, col="blue", lwd = 2)
