require("gg3D")
epsilon.rad <- pi/4
phase.periods  <- 0.2
time <- 0
x <- seq(from=-2,to=0,by=0.01)
Ex <- function(x=0, t=time) round(sin(epsilon.rad), digits=1)*cos(2*pi*(x-t))
Ey <- function(x=0, t=time) round(cos(epsilon.rad), digits=1)*cos(2*pi*(x-t+phase.periods)) 


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
               data.frame(x = 0,
                          y = Ey(x=0, t=x),
                          z = Ex(x=0, t=x),
                          col="polarisation", group="ellipse", linetype="A_solid") )
# Create e-field vector
lines <- rbind(lines, 
               data.frame(x = 0,
                          y = c(0, Ey()),
                          z = c(0, Ex()),
                          col="polarisation", group="vector", linetype="A_solid") )

# Create x-, y- and z-axis
axes <- data.frame(x = c(x[1], 0), y=0, z=0, axis = "x")
axes <- rbind(axes, data.frame(x = 0,
                               y = c(-max(Ex(), Ey()), max(Ex(), Ey())),
                               z = 0,
                               axis = "y"))
axes <- rbind(axes, data.frame(x = 0,
                               y = 0,
                               z = c(-max(Ex(), Ey()), max(Ex(), Ey())),
                               axis = "z"))


theta <- 60
phi <- 10
ggplot() +
  theme_void() +
  theme(legend.position="none") +
  stat_3D(geom="path",
          data=lines,
          size=2,
          mapping=aes(x = x, y=y, z=z, col=col, group=group, linetype=linetype),
          theta=theta, phi=phi) +
  stat_3D(geom="path",
          data=axes,
          size=2,
          arrow = arrow(length = unit(0.5, "cm")),
          mapping = aes(x=x, y=y, z=z, group=axis),
          theta=theta, phi=phi) +
  stat_3D(geom="path",
          data=data.frame(x = 0,
                          y = c(0, Ey()),
                          z = c(0, Ex()) ),
          size=2,
          arrow = arrow(length = unit(0.5, "cm")),
          mapping = aes(x=x, y=y, z=z, group="vector", col = "polarisation"),
          theta=theta, phi=phi) +
  stat_3D(geom="text", data=data.frame(x = 0,
                                       y = c(0, Ey()),
                                       z = c(0, Ex()) ),
          size=2,
          mapping = aes(x=x, y=y, z=z, group="vector", col = "polarisation"),
          theta=theta, phi=phi, label="FICK DICH")
