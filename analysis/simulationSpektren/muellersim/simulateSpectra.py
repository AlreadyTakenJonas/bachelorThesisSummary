

# This script uses the program PolaRam at the location /home/jonas/code/python/PolaRam/main.py
# It generates a bunch of polarised states and simulates the raman scattering process with polaram simulate

import numpy as np
import subprocess
import os


# Scale the initial electrical field component in x- and y-direction 
scaleX = 1
scaleY = 1

# Some file paths
rootdir    = os.path.dirname(os.path.abspath(__file__))
polaram    = "/home/jonas/code/python/PolaRam/main.py"
matrixfile = rootdir + "/input/labratoryMatrixWater.txt"
outputfile = rootdir + "/output_water_circle.txt"


# Clear outputfile
with open(outputfile, "w") as file:
    file.write("# SIMULATION OF RAMAN SCATTERING DEPENDING OF THE ORIENTATION OF THE POLARISATION PLAIN\n# scaleX = " + str(scaleX) + " scaleY = " + str(scaleY) + "\n\n" )


# Create a temporary instruction file for polaram; with the commands SMP
# See polaram repository for details
instr = "SMP\n"
with open(rootdir + "/tmp.txt", "w") as file:
    file.write(instr)
 

# Create a list of all stokes vectors that must be simulated
stokesVectors = []
for sigma in range(0, 360):
    
    # Calculate e-field vector from polar stokes vector 
    # and scale the components to get different magnitudes for different stokes angles
    epsilon = sigma/2
    Ex = np.cos(epsilon/180 *np.pi) * scaleX
    Ey = np.sin(epsilon/180 *np.pi) * scaleY
    
    # Calculate polar coordinates of e-field vector
    # Polar coodinates make the transformation into cartesian stokes coordinates easier
    E = np.sqrt( Ex**2 + Ey**2 )
    epsilon = np.arccos( Ex / E )
    
    # Calculate the stokes vector from the e-field polar coordinates epsilon and E
    vec = np.array([  E**2                                                                      ,
                      Ex**2 - Ey**2                                                             ,
                    ( E * np.cos(epsilon - np.pi/4) )**2 - ( E * np.sin(epsilon - np.pi/4) )**2 ,
                      0 
                   ])
    
    # Make sure the formula checks out
    # Check the polarisation grade. It must be one for polaram to work
    pol = np.sqrt(sum([ s**2 for s in vec[1:] ]) ) / vec[0]
    pol = round(pol, 8)
    if pol != 1:
        print(str(sigma) + " " + str(pol))
    
    vec = ["-lsr"] + [ str(round(elem, 10)) for elem in vec]
    
    stokesVectors += vec
    
# Call polaram and give it the instruction file and the path to the output file and a file containing the raman mueller matrices for the raman scattering process
# The flag -a ensure that polaram will append the results to the output file and not owerwrite it every iteration
# The flag -r creates a easy paseable table as output. It is less fancy than the default settings, but good for post-processing the data
cliargs = ["python3", polaram, "simulate", "tmp.txt", "-m", matrixfile, "-o", outputfile, "-r", "-s"] + stokesVectors
subprocess.run(cliargs)
