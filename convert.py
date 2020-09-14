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

# ceiling and floor
import math

# Pseudo-random number generator
import random as rand

# Get time and date for output file
from datetime import datetime

# Run multiple processes in parallel
import multiprocessing

# Process bar
from tqdm import tqdm

#
#   INTERNAL MODULES
#
import utilities as util

#
#   FUNCTION TO BE CALLED BY PARALLEL SUBPROCESSES
#
def __monteCarlo(param):
    """
    RUN ONE ITERATION OF THE MONTE-CARLO SIMULATION
    !!!!! LOGGING IS OMITTED DURING THE SIMULATION DUE TO SEVERE PERFORMANCE ISSUES !!!!!!
    Should not be called outside of convert.py! No parameter testing or unittests in place!
    Calculation:  1. M(phi, theta, zeta) = (R_z)^T (R_y)^T (R_x)^T a_mol R_x R_y R_z
                     Calculate for random rotation angles around all axis (x,y,z) the rotated molecular raman tensor (a_mol).
                     Use the roation matrices R_x, R_y and R_z.
                  2. a_lab = < M >
                    Calculate the mean over all random rotation angles (will be done by main function)
    Attributes:
    param - a tuple containing following elements:
        phi, theta, zeta - rotation angles in radians
        tensorlist - correctly formatted list of raman tensors in the molecular coordinate system
    Returns rotated version of tensorlist
    """
    # Expand parameters
    phi         = param[0]
    theta       = param[1]
    zeta        = param[2]
    tensorlist  = param[3]

    # Calculate the rotation matrices
    Rx = np.array([ [1, 0          ,  0          ],
                    [0, np.cos(phi), -np.sin(phi)],
                    [0, np.sin(phi),  np.cos(phi)]      ])

    Ry = np.array([ [ np.cos(theta), 0, np.sin(theta)],
                    [ 0            , 1, 0            ],
                    [-np.sin(theta), 0, np.cos(theta)]  ])

    Rz = np.array([ [np.cos(zeta), -np.sin(zeta), 0],
                    [np.sin(zeta),  np.cos(zeta), 0],
                    [0           ,  0           , 1]    ])

    # Calculate the first half of the rotation
    transposed = Rz.T @ Ry.T @ Rx.T

    # Rotate every raman tensor and add the result to convertedTensorlist
    for index, tensor in enumerate(tensorlist):

        tensorlist[index]["matrix"] = transposed @ tensor["matrix"] @ Rx @ Ry @ Rz

    # Return rotated tensors
    return tensorlist


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

    # Copy the structure of tensorlist with empty arrays. This copy will be filled with the result of the simulation
    convertedTensorlist = [{"head": tensor["head"],
                            "matrix": np.array([ [0, 0, 0],
                                                 [0, 0, 0],
                                                 [0, 0, 0]  ]).astype(np.float)
                           } for tensor in tensorlist]
    # Scale the original tensorlist down by a factor of iterationLimit to make sure that the sum over all iterations will equal the mean over all iterations
    tensorlist = [{ "head": tensor["head"],
                    "matrix": tensor["matrix"]/cliArgs.iterationLimit } for tensor in tensorlist]

    # Build a generator that returns a tuple that can be passed to the monte-carlo-simulation function
    # It contains one tuple for every iteration. The tuples contain three random anlges in radians and the tensorlist, that will be rotated.
    processArgs = ( (rand.random() * 2*np.pi, rand.random() * 2*np.pi, rand.random() * 2*np.pi, tensorlist) for i in range(cliArgs.iterationLimit) )


# RUN MONTE-CARLO SIMULATION
# Calculation:  1. M(phi, theta, zeta) = (R_z)^T (R_y)^T (R_x)^T a_mol R_x R_y R_z
#                  Calculate for random rotation angles around all axis (x,y,z) the rotated molecular raman tensor (a_mol).
#                  Use the roation matrices R_x, R_y and R_z.
#               2. a_lab = < M >
#                  Calculate the mean over all random rotation angles
    log.info("START MONTE CARLO SIMULATION")

    # !!!!! LOGGING IS OMITTED DURING THE SIMULATION DUE TO SEVERE PERFORMANCE ISSUES !!!!!!

    # Create a pool of workers sharing the computation task
    with multiprocessing.Pool(processes = cliArgs.processCount) as pool:

        # Start child processes wich run __monteCarlo()
        # The list of all random angles is split into chunksize pieces (500 is a good value) and each piece is given to one subprocess to calculate the rotated tensors
        # The computation will be slow if the chunksize is to big or to small
        process = pool.imap_unordered(__monteCarlo, processArgs, chunksize = cliArgs.chunksize)

        # Loop over all ready results, while the processes are still running
        # tqdm prints a lovely progress bar
        for result in tqdm( process, total = cliArgs.iterationLimit,
                                     desc = "Processes " + str(cliArgs.processCount) ):
            # Tally the results of all processes up in order to get the mean of all computations
            convertedTensorlist = [ {"head": tensor["head"],
                                     "matrix": np.add(convertedTensorlist[index]["matrix"], tensor["matrix"]) } for (index, tensor) in enumerate(result) ]


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
