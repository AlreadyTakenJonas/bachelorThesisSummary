#
#   EXTERNAL LIBARIES
#
# Purpose loggging
import logging

# Purpose: CLIFileNotFoundError:
import argparse

# Terminate program on exception
import sys

# Matrix multiplication and trigonometric functions
import numpy as np

# Pseudo-random number generator
import random as rand

# Handling file paths
import pathlib

# Get time and date for output file
from datetime import datetime

#
#   INTERNAL MODULES
#
import utilities as util

#
#   MAIN PROGRAM
#
def main():
    """
    Reads input file and runs monte carlo simulation to convert molecular to labratory coordinate system
    """

    log.info("START RAMAN TENSOR CONVERSION")

    # Read tensor file as matrices
    tensorlist = util.readFileAsMatrices(cliArgs.tensorfile)

    # Prepare simulation
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
    # Scale the original tensorlist down by a factor of iterationLimit to make sure that the sum over all iterations will be the mean over all iterations
    tensorlist = [{ "head": tensor["head"],
                    "matrix": tensor["matrix"]/cliArgs.iterationLimit } for tensor in tensorlist]

    # Run monte carlo simulation
    # Calculation:  1. M(phi, theta, zeta) = (R_z)^T (R_y)^T (R_x)^T a_mol R_x R_y R_z
    #               2. a_lab = < M >
    # Description:  1. Calculate for random rotation angles around all axis (x,y,z) the rotated molecular raman tensor (a_mol).
    #                  Use the roation matrices R_x, R_y and R_z.
    #               2. Calculate the mean over all rotation angles
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
        for tensor, convertedTensor in zip(tensorlist, convertedTensorlist):
            log.debug("Rotate tensor '" + tensor["head"] + "'")
            rotatedTensor = transposed @ tensor["matrix"] @ Rx @ Ry @ Rz
            convertedTensor["matrix"] += rotatedTensor

        log.debug("End iteration " + str(i) + "/" + str(cliArgs.iterationLimit))

    log.info("STOPPED MONTE CARLO SIMULATION SUCCESSFULLY")

    # Convert results into lovely text
    output_text = "# convert " + str(cliArgs.tensorfile.resolve()) + " --output " + str(cliArgs.outputfile.resolve()) + " --log " + str(cliArgs.logfile.resolve()) + " --iterations " + str(cliArgs.iterationLimit) + "\n# Execution time: " + str(datetime.now())
    for tensor in convertedTensorlist:
        output_text += "\n\n! " + tensor["head"] + "\n" + np.array2string(tensor["matrix"], sign = None).replace("[[", "").replace(" [", "").replace("]", "")

    # Log and write text to file
    log.debug("Writing results to '" + str(cliArgs.outputfile.resolve()) + "':\n\n" + output_text + "\n")
    print(output_text)
    cliArgs.outputfile.write_text(output_text)

    log.info("STOPPED RAMAN TENSOR CONVERSION SUCCESSFULLY")

#
#   START OF PROGRAM EXECUTION AS MAIN PROGRAM
#
if __name__ == "__main__":

    #
    #   CREATE COMMAND LINE INTERFACE
    #
    # Construct the commandline arguments
    # Initialise and set helping information
    ap = argparse.ArgumentParser(prog = "convert",
                                 description = "Converts raman tensors from the molecular coordinate system into the raman matrix of a solution in the labratory coordinate system via a monte carlo simulation.",
                                 epilog = "Author: Jonas Eichhorn; License: MIT; Date: Sep.2020")

    # Adding arguments
    # Add verbose
    ap.add_argument("-v", "--verbose",
                    required = False,
                    help = "runs programm and shows status and error messages",
                    action = "store_true")
    # Add logfile (default defined)
    ap.add_argument("-l", "--log",
                    required = False,
                    default = "./convertRamanTensor.log",
                    help = "defines path and name of a custom .log file. Default=./convertRamanTensor.log",
                    dest = "logfile")
    # Add input file for labratory setup
    ap.add_argument("tensorfile",
                    help = "text file containing the raman tensors that will be converted. Details are given in the README.")
    # Add iteration limit for monte carlo simulation
    ap.add_argument("-i", "--iterations",
                    help = "number of iterations the simulation will calculate. Default = 10000",
                    required = False,
                    type = int,
                    default = 10000,
                    dest = "iterationLimit")
    # Add path to output file
    ap.add_argument("-o", "--output",
                    help = "path to output file. Defaults to path of conveted_tensorfile.txt",
                    required = False,
                    default = False,
                    dest = "outputfile")
    # Store command line arguments
    cliArgs = ap.parse_args()


    # Convert all paths to pathlib.Path
    cliArgs.tensorfile = pathlib.Path(cliArgs.tensorfile)
    cliArgs.logfile = pathlib.Path(cliArgs.logfile)

    # Create output file path if none is given
    # or covert to pathlib.Paht if given
    if cliArgs.outputfile == False:
        cliArgs.outputfile = pathlib.Path(cliArgs.tensorfile.parent, f"converted_{cliArgs.tensorfile.stem}.txt")
    else:
        cliArgs.outputfile = pathlib.Path(cliArgs.outputfile)


    #
    # SETUPG LOGGING
    #
    # Logs to file and to console (to console only if verbose activated)
    # Set config for logfile
    logging.basicConfig(level=logging.DEBUG,
                        format='%(asctime)s : %(name)s : %(levelname)s : %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S',
                        filename= str(cliArgs.logfile.resolve()),
                        filemode='a')

    # Define a Handler which writes DEBUG messages or higher to the sys.stderr, if the commandline flag -v is given
    # If the verbose flag is not given only CRITICAL messages will go to sys.stderr
    console = logging.StreamHandler()
    if cliArgs.verbose:
        console.setLevel(logging.INFO)
    else:
        console.setLevel(logging.CRITICAL)

    # Set a format which is simpler for console use
    formatter = logging.Formatter('%(message)s')
    # Tell the handler to use this format
    console.setFormatter(formatter)
    # Add the handler to the root logger
    logging.getLogger('').addHandler(console)

    # Create a logger
    log = logging.getLogger(__name__)

    #
    # RUN PROGRAM
    #
    main()
