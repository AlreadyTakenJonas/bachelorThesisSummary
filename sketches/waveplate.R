require("gg3D")
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





# Create E_x
lines <- data.frame( x = x,
                     y = 0,
                     z = Ex(x),
                     col = "Ex", group="Ex", linetype="A_solid")
# Create E_y
lines <- rbind(lines, 
               data.frame(x = x, 
                          y = Ey(x), 
                          z=0, 
                          col="Ey", group="Ey", linetype="A_solid") )
# Create polarisation ellipse
lines <- rbind(lines,
               data.frame(x = x.waveplateStart,
                          y = Ey(x=x.waveplateStart, t=x),
                          z = Ex(x=x.waveplateStart, t=x),
                          col="polarisation", group="ellipsePRE", linetype="A_solid") )
lines <- rbind(lines,
               data.frame(x = x.waveplateEnd,
                          y = Ey(x=x.waveplateEnd, t=x),
                          z = Ex(x=x.waveplateEnd, t=x),
                          col="polarisation", group="ellipsePOST", linetype="A_solid") )
# Create e-field vector
lines <- rbind(lines, 
               data.frame(x = x.waveplateStart,
                          y = c(0, Ey(x=x.waveplateStart)),
                          z = c(0, Ex(x=x.waveplateStart)),
                          col="polarisation", group="vectorPRE", linetype="A_solid") )
lines <- rbind(lines, 
               data.frame(x = x.waveplateEnd,
                          y = c(0, Ey(x=x.waveplateEnd)),
                          z = c(0, Ex(x=x.waveplateEnd)),
                          col="polarisation", group="vectorPOST", linetype="A_solid") )
# Create e-field vector components
lines <- rbind(lines,
               data.frame(x = x.waveplateStart,
                          y = Ey(x=x.waveplateStart),
                          z = c(0, Ex(x=x.waveplateStart)),
                          col="Ex", group="xCompPRE", linetype="B_dotted") )
lines <- rbind(lines,
               data.frame(x = x.waveplateStart,
                          y = c(0, Ey(x=x.waveplateStart)),
                          z = Ex(x=x.waveplateStart),
                          col="Ey", group="yCompPRE", linetype="B_dotted"))
lines <- rbind(lines,
               data.frame(x = x.waveplateEnd,
                          y = Ey(x=x.waveplateEnd),
                          z = c(0, Ex(x=x.waveplateEnd)),
                          col="Ex", group="xCompPOST", linetype="B_dotted") )
lines <- rbind(lines,
               data.frame(x = x.waveplateEnd,
                          y = c(0, Ey(x=x.waveplateEnd)),
                          z = Ex(x=x.waveplateEnd),
                          col="Ey", group="yCompPOST", linetype="B_dotted"))

# Create x-, y- and z-axis
axes <- data.frame(x = c(x[1], tail(x, 1)), y=0, z=0, axis = "x")
axes <- rbind(axes, data.frame(x = c(x.waveplateStart, x.waveplateStart, 
                                     x.waveplateEnd, x.waveplateEnd) ,
                               y = c(-max(Ex(), Ey()), max(Ex(), Ey())),
                               z = 0,
                               axis = c("yPRE", "yPRE",
                                        "yPOST", "yPOST") ))
axes <- rbind(axes, data.frame(x = c(x.waveplateStart, x.waveplateStart, 
                                     x.waveplateEnd, x.waveplateEnd),
                               y = 0,
                               z = c(-max(Ex(), Ey()), max(Ex(), Ey())),
                               axis = c("zPRE", "zPRE",
                                        "zPOST", "zPOST") ))

theta <- 45
phi <- 20
ggplot() +
  theme_void() +
  theme(legend.position="none") +
  stat_3D(geom="path",
          data=axes,
          mapping = aes(x=x, y=y, z=z, group=axis),
          theta=theta, phi=phi) +
  stat_3D(geom="path",
          data=lines,
          mapping=aes(x = x, y=y, z=z, col=col, group=group, linetype=linetype),
          theta=theta, phi=phi)
