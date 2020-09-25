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

# sqrt, ceiling and floor
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
def __monteCarlo(tensorlist):
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
    tensorlist - correctly formatted list of raman tensors in the molecular coordinate system
    Returns rotated version of tensorlist
    """
    # Choose random rotation parameters
    phi         = rand.uniform(0, 2*np.pi)
    theta       = rand.uniform(0, 2*np.pi)
    x           = rand.uniform(0, 1)

    # Calculate the rotation matrix with Arvos Alorithm "Fast Random Rotation Matrices"
    Rz = np.array([ [ np.cos(phi), np.sin(phi), 0],
                    [-np.sin(phi), np.cos(phi), 0],
                    [ 0          , 0          , 1]   ])
    mirrorNormal = np.array([ [ np.cos(theta)*math.sqrt(x) ],
                              [ np.sin(theta)*math.sqrt(x) ],
                              [ math.sqrt(1-x)             ]    ])
    householder = np.diag([1,1,1]) - 2 * ( mirrorNormal @ mirrorNormal.T )
    rotation = (-1 * householder) @ Rz

    # Create empty list to store results in
    result = []

    # Rotate every raman tensor and convert it into mueller formalism
    for index, tensor in enumerate(tensorlist):

        # Rotate tensor
        matrix = rotation.T @ tensor["matrix"] @ rotation

        # Convert tensor into mueller formalism
        matrix = util.buildRamanMuellerMatrix(matrix)

        result.append( {"head" : tensor["head"],
                        "matrix" : matrix        })

    # Return rotated tensors
    return result

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

    # Read tensor file as matrices
    tensorlist = util.readFileAsMatrices(cliArgs.tensorfile, (3,3))

# PREPARE SIMULATION

    log.info("Prepare simulation")

    # Copy the structure of tensorlist with empty arrays. This copy will be filled with the result of the simulation
    convertedTensorlist = [{"head": tensor["head"],
                            "matrix": np.diag([0, 0, 0, 0]).astype(np.float)
                           } for tensor in tensorlist]

    # Build a generator that returns the tensorlist that will be passed the monte-carlo-simulation function
    processArgs = ( tensorlist for i in range(cliArgs.iterationLimit) )

# RUN MONTE-CARLO SIMULATION
# Calculation:  1. M(phi, theta, x) = R(phi, theta, x)^T a_mol R(phi, theta, x)
#                  Calculate for random rotations with Arvos Algorithm - to guarantee uniformly distributed random rotations - the rotated molecular raman tensor (a_mol).
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
            # Tally the results of all processes up and divide by the iteration limit to get the mean of all computations
            convertedTensorlist = [ {"head": tensor["head"],
                                     "matrix": np.add(convertedTensorlist[index]["matrix"], tensor["matrix"]/cliArgs.iterationLimit)
                                    } for (index, tensor) in enumerate(result) ]

    log.info("STOPPED MONTE CARLO SIMULATION SUCCESSFULLY")

#
#   VALIDATE THE SIMULATION
#   by comparing the depolarisation ratio of the molecular tensor and the labratory matrix
#   Source: Richard N. Zare: Angular Momentum, p.129
#

    log.info("Validating monte-carlo-simulation via the depolarisation ratio.")

    # Check every matrix
    for input, output in zip(tensorlist, convertedTensorlist):

        log.debug("Check matrix '" + input["head"] + "'.")

        # Check if loop is comparing the right matrices
        if input["head"] != output["head"]:
            log.critical("INTERNAL ERROR: The header of input and output matrices don't match! Error in input tensor '" + input["head"] + "' and output matrix '" + output["head"] + "'." )
            log.critical("TERMINATE EXECUTION.")
            sys.exit(-1)

        # Compute eigenvalues of molecular tensor
        try:
            eigenvalues = np.linalg.eigvals(input["matrix"])

        except LinAlgError as e:
            # Eigenvalues do not converge. Log this issue, inform the user and skip iteration.
            log.critical("The eigenvalue computation of the input raman tensor '" + input["head"] + "' does not converge. Unable to validate monte-carlo-simulation!")
            log.critical("TERMINATE EXECUTION.")
            sys.exit(-1)

        # Compute depolarisation ratio of the inital tensor via the eigenvalues. See "Angluar Momentum" p.129.
        isotropicPolarisability = sum(eigenvalues)/3
        anisotropicPolarisability_squared = ( (eigenvalues[0]-eigenvalues[1])**2 + (eigenvalues[1]-eigenvalues[2])**2 + (eigenvalues[2]-eigenvalues[0])**2 )/2
        initialDepolarisationRatio = 3*anisotropicPolarisability_squared / ( 45*isotropicPolarisability**2 + 4*anisotropicPolarisability_squared )

        # Compute the depolarisation ratio of the final mueller matrix via raman scattering in Mueller-Formalism. See "Angluar Momentum" p.129.
        incomingLight  = np.array([1,1,0,0])
        scatteredLight = output["matrix"] @ incomingLight
        finalDepolarisationRatio = (scatteredLight[0]-scatteredLight[1])/(scatteredLight[0]+scatteredLight[1])

        # Check results
        if round(initialDepolarisationRatio, cliArgs.threshold) != round(finalDepolarisationRatio, cliArgs.threshold):
            log.critical("Validation failed for matrix '" + output["head"] + "'!")
            log.critical("Input: " + str(round(initialDepolarisationRatio, cliArgs.threshold)) + "      Simulation: " + str(round(finalDepolarisationRatio, cliArgs.threshold)))
            log.critical("TERMINATE EXECUTION.")
            sys.exit(-1)

    log.info("Validation done.")

# CONVERT RESULTS TO TEXT

    # Write the commandline parameters and the execution time in a string
    output_text  = "# polaram convert " + str(cliArgs.tensorfile.resolve())
    output_text += " --output " + str(cliArgs.outputfile.resolve())
    output_text += " --log " + str(cliArgs.logfile.resolve())
    output_text += " --iterations " + str(cliArgs.iterationLimit)
    output_text += " --threshold " + str(cliArgs.threshold)
    output_text += "\n# Execution time: " + str(datetime.now())

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
