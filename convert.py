#
#   EXTERNAL LIBARIES
#
# Purpose loggging
import logging
# Enables logging with the logging module
log = logging.getLogger(__name__)
# Tells the logging module to ignore all logging message, if a program using this file does not use the logging module.
log.addHandler(logging.NullHandler())

# Terminate program on exception
import sys

# Matrix multiplication and trigonometric functions
import numpy as np

# Pseudo-random number generator
import random as rand

# Get time and date for output file
from datetime import datetime

#
#   INTERNAL MODULES
#
import utilities as util

#
#   MAIN PROGRAM
#
def main(cliArgs):
    """
    Reads input file and runs monte carlo simulation to convert raman tensors from molecular to labratory coordinates
    Attributes:
    cliArgs - object containing the command line arguments parsed in main.py
    """

    log.info("START RAMAN TENSOR CONVERSION")

    # Check if cliArgs.iterationLimit is smaller than 1
    if cliArgs.iterationLimit < 1:
        log.critical("WARNING: The minimal amount of iterations is 1. Setting iterationlimit to 1.")
        cliArgs.iterationLimit = 1

    # Read tensor file as matrices
    tensorlist = util.readFileAsMatrices(cliArgs.tensorfile)

# PREPARE SIMULATION

    log.info("Prepare simulation")

    # Define rotation matrices
    rotateX = lambda phi : np.array([ [1, 0          ,  0          ],
                                      [0, np.cos(phi), -np.sin(phi)],
                                      [0, np.sin(phi),  np.cos(phi)]    ])

    rotateY = lambda theta : np.array([ [ np.cos(theta), 0, np.sin(theta)],
                                        [ 0            , 1, 0            ],
                                        [-np.sin(theta), 0, np.cos(theta)]  ])

    rotateZ = lambda zeta : np.array([ [np.cos(zeta), -np.sin(zeta), 0],
                                       [np.sin(zeta),  np.cos(zeta), 0],
                                       [0           ,  0           , 1]     ])

    # Copy the structure of tensorlist with empty arrays. This copy will be filled with the result of the simulation
    convertedTensorlist = [{"head": tensor["head"],
                            "matrix": np.array([ [0, 0, 0],
                                                 [0, 0, 0],
                                                 [0, 0, 0]  ]).astype(np.float)
                           } for tensor in tensorlist]
    # Scale the original tensorlist down by a factor of iterationLimit to make sure that the sum over all iterations will equal the mean over all iterations
    tensorlist = [{ "head": tensor["head"],
                    "matrix": tensor["matrix"]/cliArgs.iterationLimit } for tensor in tensorlist]

# RUN MONTE-CARLO SIMULATION
# Calculation:  1. M(phi, theta, zeta) = (R_z)^T (R_y)^T (R_x)^T a_mol R_x R_y R_z
#                  Calculate for random rotation angles around all axis (x,y,z) the rotated molecular raman tensor (a_mol).
#                  Use the roation matrices R_x, R_y and R_z.
#               2. a_lab = < M >
#                  Calculate the mean over all random rotation angles

    log.info("START MONTE CARLO SIMULATION")

    # Print progress bar
    util.update_progress(0)

    # Run simulation
    for i in range(1, cliArgs.iterationLimit+1):
        log.debug("Start iteration " + str(i) + "/" + str(cliArgs.iterationLimit))

        # Update progress bar
        util.update_progress(i / cliArgs.iterationLimit)

        # Get random rotation angles
        phi   = rand.random() * 2*np.pi
        theta = rand.random() * 2*np.pi
        zeta  = rand.random() * 2*np.pi

        # Calculate the rotation matrices
        Rx = rotateX(phi)
        Ry = rotateY(theta)
        Rz = rotateZ(zeta)

        # Calculate the first half of the rotation
        transposed = Rz.T @ Ry.T @ Rx.T

        # Rotate every raman tensor and add the result to convertedTensorlist
        for index, tensor in enumerate(tensorlist):

            log.debug("Rotate tensor '" + tensor["head"] + "'")

            rotatedTensor = transposed @ tensor["matrix"] @ Rx @ Ry @ Rz
            convertedTensorlist[index]["matrix"] += rotatedTensor

        log.debug("End iteration " + str(i) + "/" + str(cliArgs.iterationLimit))

    log.info("STOPPED MONTE CARLO SIMULATION SUCCESSFULLY")

# CONVERT RESULTS TO TEXT

    # Write the commandline parameters and the execution time in a string
    output_text = "# convert " + str(cliArgs.tensorfile.resolve()) + " --output " + str(cliArgs.outputfile.resolve()) + " --log " + str(cliArgs.logfile.resolve()) + " --iterations " + str(cliArgs.iterationLimit) + "\n# Execution time: " + str(datetime.now())

    # Add user comment to string
    if cliArgs.comment != "":
        output_text += "\n\n# " + str(cliArgs.comment)

    # Add the calculated tensors to the string. The tensors are formated like the tensor input file
    for tensor in convertedTensorlist:
        output_text += "\n\n! " + tensor["head"] + "\n" + np.array2string(tensor["matrix"], sign = None).replace("[[", "").replace(" [", "").replace("]", "")

    # Log and write text to file
    log.debug("Writing results to '" + str(cliArgs.outputfile.resolve()) + "':\n\n" + output_text + "\n")
    print(output_text)
    cliArgs.outputfile.write_text(output_text)

    log.info("STOPPED RAMAN TENSOR CONVERSION SUCCESSFULLY")
