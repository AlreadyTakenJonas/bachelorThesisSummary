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

#
# UTILITIES
#

# Displays or updates a console progress bar
def update_progress(progress):
    """
    update_progress() : Displays or updates a console progress bar
    Accepts a float between 0 and 1. Any int will be converted to a float.
    A value under 0 represents a 'halt'.
    A value at 1 or bigger represents 100%
    """
    barLength = 20 # Modify this to change the length of the progress bar
    status = ""
    if isinstance(progress, int):
        progress = float(progress)
    if not isinstance(progress, float):
        progress = 0
        status = "error: progress var must be float\r\n"
    if progress < 0:
        progress = 0
        status = "Halt...\r\n"
    if progress >= 1:
        progress = 1
        status = "Done...\r\n"
    block = int(round(barLength*progress))
    text = "\rRunning: [{0}] {1}% {2}".format( "#"*block + "-"*(barLength-block), round(progress*100, 1), status)
    sys.stdout.write(text)
    sys.stdout.flush()



#
#   MAIN PROGRAM
#
def main():
    """
    Reads input file and runs monte carlo simulation to convert molecular to labratory coordinate system
    """

    log.info("START RAMAN TENSOR CONVERSION")

    # Read tensor file
    try:
        log.info("Read tensor from file " + cliArgs.tensorfile)
        with open(cliArgs.tensorfile, "r") as f:
            input = f.read()

    # Handle file not found
    except FileNotFoundError as e:
        log.critical("FATAL ERROR: File " + cliArgs.tensorfile + " not found!")
        log.exception(e, exc_info = True)
        sys.exit(-1)

    # Convert tensor file to list of tensors with descritive messages
    try:
        # Split file in seperate tensors and remove comments
        # Comments start with '#' and tensors with '!'
        input = [tensor.strip().split("\n") for tensor in input.split("!") if tensor.strip()[0] != "#"]
        # Build a list of dictionaries
        # Each dictionary contains a head with a descriptive message extracted from the file and a tensor extracted from the file
        tensorlist = [ { "head": tensor.pop(0),
                         "tensor": np.array([ tensor[0].split(),
                                              tensor[1].split(),
                                              tensor[2].split() ]).astype(np.float)
                       } for tensor in input ]

    # Handle unexprected error
    except:
        log.critical("FATAL ERROR: Raman tensors can't be read from file. Is the file format correct?")
        log.exception(sys.exc_info()[0])
        raise



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
                            "tensor": np.array([ [0, 0, 0],
                                                 [0, 0, 0],
                                                 [0, 0, 0]  ]).astype(np.float)
                           } for tensor in tensorlist]
    # Scale the original tensorlist down by a factor of iterationLimit to make sure that the sum over all iterations will be the mean over all iterations
    tensorlist = [{ "head": tensor["head"],
                    "tensor": tensor["tensor"]/cliArgs.iterationLimit } for tensor in tensorlist]

    # Run monte carlo simulation
    # Calculation:  1. M(phi, theta, zeta) = (R_z)^T (R_y)^T (R_x)^T a_mol R_x R_y R_z
    #               2. a_lab = < M >
    # Description:  1. Calculate for random rotation angles around all axis (x,y,z) the rotated molecular raman tensor (a_mol).
    #                  Use the roation matrices R_x, R_y and R_z.
    #               2. Calculate the mean over all rotation angles
    log.info("START MONTE CARLO SIMULATION")

    # Print progress
    update_progress(0)

    for i in range(1, cliArgs.iterationLimit+1):
        log.debug("Start iteration " + str(i) + "/" + str(cliArgs.iterationLimit))

        # Print progress
        update_progress(i / cliArgs.iterationLimit)

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
            rotatedTensor = transposed @ tensor["tensor"] @ Rx @ Ry @ Rz
            convertedTensor["tensor"] += rotatedTensor

        log.debug("End iteration " + str(i) + "/" + str(cliArgs.iterationLimit))

    log.info("STOPPED MONTE CARLO SIMULATION SUCCESSFULLY")

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
                    help = "number of iterations the simulation will calculate. Default = 10",
                    required = False,
                    type = int,
                    default = 10,
                    dest = "iterationLimit")
    # Store command line arguments
    cliArgs = ap.parse_args()




    #
    # SETUPG LOGGING
    #
    # Logs to file and to console (to console only if verbose activated)
    # Set config for logfile
    logging.basicConfig(level=logging.DEBUG,
                        format='%(asctime)s : %(name)s : %(levelname)s : %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S',
                        filename= cliArgs.logfile,
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
