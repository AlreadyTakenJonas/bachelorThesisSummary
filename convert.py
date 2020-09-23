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

    # Create empty list to store results in
    result = []

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

    Rcos = np.array([   [np.cos(phi)*np.cos(theta)*np.cos(zeta)-np.sin(phi)*np.sin(zeta),      np.sin(phi)*np.cos(theta)*np.cos(zeta)+np.cos(phi)*np.sin(zeta),       -np.sin(phi)*np.cos(zeta)],
                        [-np.cos(phi)*np.cos(theta)*np.sin(zeta)-np.sin(phi)*np.cos(zeta),     -np.sin(phi)*np.cos(theta)*np.sin(zeta)+np.cos(phi)*np.cos(zeta),       np.sin(phi)*np.sin(zeta)],
                        [np.cos(phi)*np.sin(theta),                                            np.sin(phi)*np.sin(theta),                                              np.cos(theta)            ]  ])

    # Calculate the first half of the rotation
    transposed = Rz.T @ Ry.T @ Rx.T

    # Rotate every raman tensor
    for index, tensor in enumerate(tensorlist):

    #    result.append( {"head" : tensor["head"],
    #                    "matrix" : transposed @ tensor["matrix"] @ Rx @ Ry @ Rz })

        #matrix = np.linalg.inv(Rcos) @ tensor["matrix"] @ Rcos

        matrix = transposed @ tensor["matrix"] @ Rx @ Ry @ Rz

        azz = matrix[2,2]**2
        axz = matrix[0,2]**2

        #print("EIGENVALUE: " + tensor["head"])
        #print( np.linalg.eigvals(matrix))

        incomingLight = np.array([0,0,1])
        scatteredLight = ( matrix @ incomingLight )**2
        # Divide the intensity of the light orthogonal to the intial light polarsation by the intensity of the light parallel polarised to the inital polarisation
        #terminalDepolarisationRatio = scatteredLight[0]**2 / scatteredLight[2]**2

        result.append( {"head" : tensor["head"],
                        "matrix" : matrix,
                        "scattered": scatteredLight,
                        "axz_square": axz,
                        "azz_square": azz })

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

    # Check if cliArgs.iterationLimit is smaller than 1
    if cliArgs.iterationLimit < 1:
        log.critical("WARNING: The minimal amount of iterations is 1. Setting iterationlimit to 1.")
        cliArgs.iterationLimit = 1

    # Read tensor file as matrices
    tensorlist_input = util.readFileAsMatrices(cliArgs.tensorfile)

# PREPARE SIMULATION

    log.info("Prepare simulation")

    # Copy the structure of tensorlist with empty arrays. This copy will be filled with the result of the simulation
    convertedTensorlist = [{"head": tensor["head"],
                            "matrix": np.array([ [0, 0, 0],
                                                 [0, 0, 0],
                                                 [0, 0, 0]  ]).astype(np.float),
                            "scattered": np.array([0,0,0]),
                            "axz_square": 0,
                            "azz_square": 0
                           } for tensor in tensorlist_input]
    # Scale the original tensorlist down by a factor of iterationLimit to make sure that the sum over all iterations will equal the mean over all iterations
    tensorlist = [{ "head": tensor["head"],
                    "matrix": tensor["matrix"] } for tensor in tensorlist_input]

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

    # Clear test log file
    open('log/convergence.txt', 'w').close()

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
            # Tally the results of all processes up to get the mean of all computations
            convertedTensorlist = [ {"head": tensor["head"],
                                     "matrix": np.add(convertedTensorlist[index]["matrix"], tensor["matrix"]/cliArgs.iterationLimit),
                                     "scattered": np.add(convertedTensorlist[index]["scattered"], tensor["scattered"]),
                                     "axz_square": convertedTensorlist[index]["axz_square"] + tensor["axz_square"],
                                     "azz_square": convertedTensorlist[index]["azz_square"] + tensor["azz_square"] } for (index, tensor) in enumerate(result) ]

            # Log depolarisation ratio to file
            with open("log/convergence.txt", "a") as file:
                depol = ""
                for dict in convertedTensorlist:
                    depol += str( dict["axz_square"] / dict["azz_square"] ) + "   "
                file.write(depol + "\n")


    log.info("STOPPED MONTE CARLO SIMULATION SUCCESSFULLY")

#
#   VALIDATE THE SIMULATION
#   by comparing the depolarisation ratio of the molecular tensor and the labratory matrix
#   Source: Richard N. Zare: Angular Momentum, p.129
#

    log.info("Validating monte-carlo-simulation via the depolarisation ratio.")

    # Check every matrix
    for input, output in zip(tensorlist_input, convertedTensorlist):

        log.debug("Check matrix '" + input["head"] + "'.")

        print("\n" + input["head"] + "  " + output["head"])

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


        print("Eigenvalue initial: " + str(eigenvalues) )
        print("Egenvalue terminal: " + str(np.linalg.eigvals(output["matrix"])))
        # Compute depolarisation ration of the inital tensor via the eigenvalues. See "Angluar Momentum" p.129.
        isotropicPolarisability = sum(eigenvalues)/3
        anisotropicPolarisability_squared = ( (eigenvalues[0]-eigenvalues[1])**2 + (eigenvalues[1]-eigenvalues[2])**2 + (eigenvalues[2]-eigenvalues[0])**2 )/2
        initialDepolarisationRatio = 3*anisotropicPolarisability_squared / ( 45*isotropicPolarisability**2 + 4*anisotropicPolarisability_squared )


        print("ScatterdLight: " + str(output["scattered"]))
        # Compute depolarisation ratio of simulation result by comparing the polarisation change, when an e-field vector gets scattered
        #incomingLight = np.array([0,0,1])
        #scatteredLight = output["matrix"] @ incomingLight
        # Divide the intensity of the light orthogonal to the intial light polarsation by the intensity of the light parallel polarised to the inital polarisation
        #terminalDepolarisationRatio = scatteredLight[0]**2 / scatteredLight[2]**2
        terminalDepolarisationRatio = output["scattered"][0] / output["scattered"][2]
        print("Terminal Depolarisation via scattering: " + str(terminalDepolarisationRatio))

        rand.random()*2*np.pi
        division = output["axz_square"] / output["azz_square"]
        print("Terminal Depol via a_xz/a_zz: " + str(division))

        eigenvalues = np.linalg.eigvals(output["matrix"])
        isotropicPolarisability = sum(eigenvalues)/3
        anisotropicPolarisability_squared = ( (eigenvalues[0]-eigenvalues[1])**2 + (eigenvalues[1]-eigenvalues[2])**2 + (eigenvalues[2]-eigenvalues[0])**2 )/2
        terminalDepolarisationRatio = 3*anisotropicPolarisability_squared / ( 45*isotropicPolarisability**2 + 4*anisotropicPolarisability_squared )
        print("Terminal Depolr. via Eigenval:" + str(terminalDepolarisationRatio))

        print("Initial Depolar.:" + str(initialDepolarisationRatio))

        # Check results
        #if round(initialDepolarisationRatio, 7) != round(terminalDepolarisationRatio, 7):
        #    log.critical("Validation failed for matrix '" + output["head"] + "'!")
        #    log.critical("Input: " + str(round(initialDepolarisationRatio, 7)) + "      Simulation: " + str(round(terminalDepolarisationRatio, 7)))
        #    log.critical("TERMINATE EXECUTION.")
            #sys.exit(-1)

    log.info("Validation done.")


# CONVERT RESULTS TO TEXT

    # Write the commandline parameters and the execution time in a string
    output_text = "# polaram convert " + str(cliArgs.tensorfile.resolve()) + " --output " + str(cliArgs.outputfile.resolve()) + " --log " + str(cliArgs.logfile.resolve()) + " --iterations " + str(cliArgs.iterationLimit) + "\n# Execution time: " + str(datetime.now())

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


    phi = rand.random()*2*np.pi
    theta = rand.random()*2*np.pi
    zeta = rand.random()*2*np.pi
    Rcos = np.array([   [np.cos(phi)*np.cos(theta)*np.cos(zeta)-np.sin(phi)*np.sin(zeta),      np.sin(phi)*np.cos(theta)*np.cos(zeta)+np.cos(phi)*np.sin(zeta),       -np.sin(theta)*np.cos(zeta)],
                        [-np.cos(phi)*np.cos(theta)*np.sin(zeta)-np.sin(phi)*np.cos(zeta),     -np.sin(phi)*np.cos(theta)*np.sin(zeta)+np.cos(phi)*np.cos(zeta),       np.sin(phi)*np.sin(zeta)],
                        [np.cos(phi)*np.sin(theta),                                            np.sin(phi)*np.sin(theta),                                              np.cos(theta)            ]  ])
    RcMult = Rcos @ Rcos.T
    print("normal")
    print(Rcos)
    print("transpose")
    print(Rcos.T)
    print("inverse")
    print(np.linalg.inv(Rcos))
    print("prod")
    print(RcMult)
