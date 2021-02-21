require(gridExtra)
require(gg3D)
require(magrittr)

epsilon.rad <- pi/2
x <- seq(from=-1, to=1, by=0.01)

E <- function(x=0) data.frame(
  x = x,
  y = round(cos(epsilon.rad), digits=1)*sin(4*pi*x),
  z = round(sin(epsilon.rad), digits=1)*sin(4*pi*x),
  col = "wave",
  group = "wave", alpha = 1
)
ellipsoid <- function(res = 10, radius = 1,
                      a = 1, b = 1, c = 1, 
                      zero.x = 0, zero.y = 0, zero.z = 0) {
  x.start <- seq(from = 0, to = a*sqrt(radius), length.out = res)
  y.max <- sqrt( radius - x.start^2/a^2) * b
  x <- sapply( 1:res, simplify = F,
               function(index) rep(x.start[index], res) ) %>% unlist
  y <- sapply( 1:res, simplify = F, 
               function(index) seq(from = 0, to=y.max[index], length.out = res) ) %>% unlist
  z <- sqrt( radius - x^2/a^2 - y^2/b^2 ) * c
  surface <- data.frame( x = c(x,  rev(x),  x,  rev(x)), 
                         y = c(y,  rev(y), -y, -rev(y)), 
                         z = c(z, -rev(z), -z,  rev(z)),
                         col = "ellipsoide", alpha = 0.5)
  surface <- surface[!is.nan(surface$z),]
  surfaceMirror <- surface
  surfaceMirror$x <- -surface$x
  surface <- rbind(surface, surfaceMirror)
  surface$group <- surface$x
  surface$x <- surface$x + zero.x
  surface$y <- surface$y + zero.y
  surface$z <- surface$z + zero.z
  return(surface)
}
ellipse.a <- 0.5
ellipse.b <- 0.25
ellipse.c <- 0.5
ellipse.r <- 1
polarisability <- ellipsoid(res=40, radius = ellipse.r, a=ellipse.a, b = ellipse.b, c = ellipse.c)

wave <- E(x=x)

axis.alpha <- 1
common.diagonal <- data.frame( x=c(x[1], x[1], tail(x, 1), tail(x, 1)), 
                             y=c(-1, 1, -1, 1), 
                             z=c(-1, 1, -1, 1), 
                             col="Z_HIDE", group="ROOM_DIAGONAL", alpha=0 )

wave.wavePlot <- rbind(common.diagonal, wave)
ellipsoid.wavePlot <- rbind(common.diagonal, polarisability)

axis.wavePlot <- rbind(common.diagonal,
                       data.frame(  x = c(x[1], tail(x, 1)) ,
                                    y = 0,
                                    z = 0,
                                    col = "axis",
                                    group = "xAxis",
                                    alpha = axis.alpha) )
axis.wavePlot <- rbind(axis.wavePlot,
                        data.frame( x = 0,
                                    y = c(-1,1),#c(min(polarisability[,"y"]), max(polarisability[,"y"]))*2,
                                    z = 0,
                                    col = "axis",
                                    group = "yAxis",
                                    alpha = axis.alpha
                        ))

axis.wavePlot <- rbind(axis.wavePlot,
                        data.frame( x = 0,
                                    y = 0,
                                    z = c(-1,1),#c(min(polarisability[,"z"]), max(polarisability[,"z"]))*1.5,
                                    group = "zAxis",
                                    col = "axis",
                                    alpha = axis.alpha
                        ))

theta.wavePlot <- 30
phi.wavePlot <- 30
ggplot(mapping = aes(x=x, y=y, z=z, col=col, group=group, alpha=alpha),
       theta=theta.wavePlot, phi=phi.wavePlot) +
  theme_void() +
  theme(legend.position="none") +
  scale_color_manual( palette = function(ncols) c("#000000", scales::hue_pal()(ncols-2), "#FFFFFF") )  +
  stat_3D(geom = "path",
          data = wave.wavePlot, size=2,
          theta=theta.wavePlot, phi=phi.wavePlot) +
  
  stat_3D(geom = "path", size=2,
          data = axis.wavePlot, arrow = arrow(length=unit(0.30,"cm")),
          theta=theta.wavePlot, phi=phi.wavePlot) +
  stat_3D(geom = "path",
          data = ellipsoid.wavePlot,
          theta=theta.wavePlot, phi=phi.wavePlot)



