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
    Calculation:  1. Rotate all raman tensors randomly via matrix multiplication
                     Uniformly distributed random rotations are generated with James Arvo's Algorithm "Fast Random Rotation Matrices". See pdf file jamesArvoAlgorithm.pdf for the math.
                  2. Compute the mueller matrix of the rotated raman tensor. For the math, see pdf file ramanMuellerMatrix.pdf.
                  3. Compute the mean of all rotated mueller matrices and raman tensors. The mean will be computed by the main function.

    Attributes:
    tensorlist - correctly formatted list of raman tensors in the molecular coordinate system
    Returns rotated version of tensorlist as raman tensor and mueller matrix of the raman tensor
    """
    # Choose random rotation parameters
    phi         = rand.uniform(0, 2*np.pi)
    theta       = rand.uniform(0, 2*np.pi)
    x           = rand.uniform(0, 1)

    # Calculate the rotation matrix with Arvo's Alorithm "Fast Random Rotation Matrices"
    # Random rotation around the z-axis
    Rz = np.array([ [ np.cos(phi), np.sin(phi), 0],
                    [-np.sin(phi), np.cos(phi), 0],
                    [ 0          , 0          , 1]   ])
    # Get a random reflection plane, by defining its normal vector
    # The rotation will be performed by doing one rotation and two reflections; this guarantees uniformly distributed random rotation matrices
    mirrorNormal = np.array([ [ np.cos(theta)*math.sqrt(x) ],
                              [ np.sin(theta)*math.sqrt(x) ],
                              [ math.sqrt(1-x)             ]    ])
    # Get the householder matrix describing the reflection
    householder = np.diag([1,1,1]) - 2 * ( mirrorNormal @ mirrorNormal.T )
    # Contruct the final random rotation matrix
    # by combining the reflection operators -1 and the householder matrix with the rotation around the z axis.
    rotation = (-1 * householder) @ Rz

    # Create empty list to store results in
    result = []

    # Rotate every raman tensor and convert it into mueller formalism
    for index, tensor in enumerate(tensorlist):

        # Rotate tensor
        raman = rotation.T @ tensor["matrix"] @ rotation

        # Convert tensor into mueller formalism
        mueller = util.buildRamanMuellerMatrix(raman)

        # Store result
        result.append( {"head"          : tensor["head"],
                        "muellerMatrix" : mueller,
                        "ramanTensor"   : raman             })

    # Return rotated tensors
    return result

#
#   MAIN PROGRAM
#
def main(cliArgs):
    """
    Reads input file and runs monte carlo simulation to convert raman tensors from molecular to labratory coordinates
    and prints the matrix in the mueller formalism to a file
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
                            "muellerMatrix": np.diag([0, 0, 0, 0]).astype(np.float),
                            "ramanTensor": np.diag([0, 0, 0]).astype(np.float)
                           } for tensor in tensorlist]

    # Set a flag to signal the while loop below wether or not to rerun the simulation if validation fails
    runMonteCarlo = True

    # Total number of iterations
    # This number will increase if the simulation is not validated and run again
    totalIterations = cliArgs.iterationLimit

# RUN MONTE-CARLO SIMULATION
# The steps 1. and 2. will be performed by the function __monteCarlo(). Step 3. will be performed by this function.
# Calculation:  1. Rotate all raman tensors randomly via matrix multiplication
#                  Uniformly distributed random rotations are generated with James Arvo's Algorithm "Fast Random Rotation Matrices". See pdf file jamesArvoAlgorithm.pdf for the math.
#               2. Compute the mueller matrix of the rotated raman tensor. For the math, see pdf file ramanMuellerMatrix.pdf.
#               3. Compute the mean of all rotated mueller matrices and raman tensors. The mean will be computed by the main function.
# The while loop gives the opportunity to run the simulatio again, if the validation of the simulation fails.
    while( runMonteCarlo == True ):
        log.info("START MONTE CARLO SIMULATION")

        # !!!!! LOGGING IS OMITTED DURING THE SIMULATION DUE TO SEVERE PERFORMANCE ISSUES !!!!!!

        # Build a generator that returns the tensorlist that will be passed to every iteration of the monte-carlo-simulation
        processArgs = ( tensorlist for i in range(cliArgs.iterationLimit) )

        # Create a pool of workers sharing the computation task
        with multiprocessing.Pool(processes = cliArgs.processCount) as pool:

            # Start child processes which run __monteCarlo()
            # Each subprocess will be given a list of size chunksize. Each element of the list contains the list of all raman tensor.
            # Each subprocess will therefore run the function __monteCarlo() cunksize times and passes the tensorlist to every function call.
            # The computation will be slow if the chunksize is to big or to small
            process = pool.imap_unordered(__monteCarlo, processArgs, chunksize = cliArgs.chunksize)

            # Loop over all ready results, while the processes are still running
            # process contains all rotated matrices
            # tqdm prints a lovely progress bar
            for result in tqdm( process, total = cliArgs.iterationLimit,
                                         desc = "Processes " + str(cliArgs.processCount) ):
                # Tally the results of all processes up and divide by the iteration limit to get the mean of all computations
                convertedTensorlist = [ {"head"         : tensor["head"],
                                         "muellerMatrix": np.add(convertedTensorlist[index]["muellerMatrix"], tensor["muellerMatrix"]/totalIterations),
                                         "ramanTensor"  : np.add(convertedTensorlist[index]["ramanTensor"]  , tensor["ramanTensor"]  /totalIterations)
                                        } for (index, tensor) in enumerate(result) ]

        log.info("STOPPED MONTE CARLO SIMULATION SUCCESSFULLY")

    #
    #   VALIDATE THE SIMULATION
    #   by comparing the depolarisation ratio of the molecular tensor and the labratory matrix
    #   Source: Richard N. Zare: Angular Momentum, p.129
    #

        log.info("Validating monte-carlo-simulation via the depolarisation ratio.")

        # Check every matrix
        for initial, final in zip(tensorlist, convertedTensorlist):

            log.debug("Check matrix '" + initial["head"] + "'.")

            # Check if loop is comparing the right matrices
            if initial["head"] != final["head"]:
                log.critical("INTERNAL ERROR: The header of input and output matrices don't match! Error in input tensor '" + initial["head"] + "' and output matrix '" + final["head"] + "'." )
                log.critical("TERMINATE EXECUTION.")
                sys.exit(-1)

            # Compute eigenvalues of molecular tensor
            try:
                eigenvalues = np.linalg.eigvals(initial["matrix"])

            except LinAlgError as e:
                # Eigenvalues do not converge. Log this issue and exit execution.
                log.critical("The eigenvalue computation of the input raman tensor '" + initial["head"] + "' does not converge. Unable to validate monte-carlo-simulation!")
                log.critical("TERMINATE EXECUTION.")
                sys.exit(-1)

            # Compute depolarisation ratio of the inital tensor via the eigenvalues. See Richard N. Zare: "Angluar Momentum", p.129.
            isotropicPolarisability = sum(eigenvalues)/3
            anisotropicPolarisability_squared = ( (eigenvalues[0]-eigenvalues[1])**2 + (eigenvalues[1]-eigenvalues[2])**2 + (eigenvalues[2]-eigenvalues[0])**2 )/2
            initialDepolarisationRatio = 3*anisotropicPolarisability_squared / ( 45*isotropicPolarisability**2 + 4*anisotropicPolarisability_squared )

            log.debug("Initial Depolarisation Ratio: " + str(initialDepolarisationRatio))

            # Compute the depolarisation ratio of the final mueller matrix via raman scattering in Mueller-Formalism. See Richard N. Zare: "Angluar Momentum", p.129.
            # Compute light intensities along x- and y-axis via stokes parameter:
            # I_x = S_0 + S_1
            # I_y = S_0 - S_1
            # depolarisationRatio = I_y / I_x ; if the incoming light is polarised along the x-axis.
            incomingLight  = np.array([1,1,0,0])
            scatteredLight = final["muellerMatrix"] @ incomingLight
            finalDepolarisationRatio = (scatteredLight[0]-scatteredLight[1])/(scatteredLight[0]+scatteredLight[1])

            log.debug("Final Depolarisation Ratio: " + str(finalDepolarisationRatio))

            #
            #   CHECK RESULTS
            #
            #   Give the user the opportunity to run the simulation
            #   again and use the computation time that's been spent so far
            #
            if round(initialDepolarisationRatio, cliArgs.threshold) != round(finalDepolarisationRatio, cliArgs.threshold):
                success = False
                break
            else:
                success = True

        #
        #   DECIDE TO CONTINUE OR END THE PROGRAM
        #
        if success == True:
            # Simulation is valid exit while loop
            runMonteCarlo = False
            log.info("Validation done.")

        else:
            # The validation failed
            log.critical("Validation failed for matrix '" + final["head"] + "'!")
            log.critical("Input: " + str(round(initialDepolarisationRatio, cliArgs.threshold)) + "      Simulation: " + str(round(finalDepolarisationRatio, cliArgs.threshold)))
            log.critical("Ask for user input. Should the simulation run again?")
            # Ask user if he/she wants to run more iterations and try the validation again
            response = input("The simulation did " + str(totalIterations) + " iterations. Do you wish to compute another "
                                + str(cliArgs.iterationLimit) + " iterations and try the validation again? [Y/n] ").lower()
            log.critical("Users response: " + response)
            if response == "n":
                # User wants to exit
                log.critical("The user does not want to continue the computation.")
                log.critical("TERMINATE EXECUTION.")
                sys.exit(-1)
            else:
                # User wants to continue
                runMonteCarlo = True
                log.info("Run Monte-Carlo-Simulation again.")
                # Save the number of computed iterations done so far
                iterationsSoFar = totalIterations
                # Compute new number of total iterations
                totalIterations = iterationsSoFar + cliArgs.iterationLimit
                # Rescale the calculated matrices.
                # There is following problem:   The programm does not save a list of all computed matrices.
                #                               It only saves the mean value. In order to use the current mean
                #                               value of the matrices to compute the mean you get when doing more
                #                               iterations, you have to multiply the matrices by the number of
                #                               iterations done so far and divide it by the total number of
                #                               iterations that will be done after rerunning the simulation.
                log.info("Prepare rerun of simulation by rescaling the mueller matrices mean.")
                scalingFactor = iterationsSoFar / totalIterations
                print(scalingFactor)
                print(convertedTensorlist[1]["muellerMatrix"])
                convertedTensorlist = [ {"head"         : entry["head"],
                                         "muellerMatrix": entry["muellerMatrix"] * scalingFactor,
                                         "ramanTensor"  : entry["ramanTensor"]   * scalingFactor
                                        } for entry in convertedTensorlist ]
                print(convertedTensorlist[1]["muellerMatrix"])

##### END OF MONTE-CARLO-SIMULATIONS WHILE LOOP


# CONVERT RESULTS TO TEXT

    # Write the commandline parameters and the execution time in a string
    output_text  = "# polaram convert " + str(cliArgs.tensorfile.resolve())
    output_text += " --output " + str(cliArgs.outputfile.resolve())
    output_text += " --log " + str(cliArgs.logfile.resolve())
    output_text += " --iterations " + str(totalIterations)
    output_text += " --threshold " + str(cliArgs.threshold)
    output_text += "\n# Execution time: " + str(datetime.now())

    # Add user comment to string
    # Given via command line interface
    if cliArgs.comment != "":
        output_text += "\n\n# " + str(cliArgs.comment)

    # Add the calculated matrices to the string. The matrices are formated like the tensor input file
    for dict in convertedTensorlist:
        # Print mean of mueller matrices
        output_text += "\n\n! " + dict["head"] + "\n" + np.array2string(dict["muellerMatrix"], sign = None).replace("[[", "").replace(" [", "").replace("]", "")
        # Print mean of raman tensors as comments
        output_text += "\n\n#! " + dict["head"] + " (Mean Of Rotated Raman Tensors)\n" + np.array2string(dict["ramanTensor"], sign = None).replace("[[", "#").replace(" [", "#").replace("]", "")

    # Log and write text to file
    log.debug("Writing results to '" + str(cliArgs.outputfile.resolve()) + "':\n\n" + output_text + "\n")
    print(output_text)
    cliArgs.outputfile.write_text(output_text)

    log.info("STOPPED RAMAN TENSOR CONVERSION SUCCESSFULLY")
