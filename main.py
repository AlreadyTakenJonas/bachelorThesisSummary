#
#   EXTERNAL LIBARIES
#
# Purpose loggging
import logging

# Purpose: CLI
import argparse

# Terminate program on exception
import sys

# Purpose: Math
import numpy as np

# Handling file paths
import pathlib

#
#   INTERNAL MODULES
#
import SetupDecoder as SetDec
import utilities as util

#
# MAIN PROGRAM
#
def main():
    """
    Function will be called by the subcommand 'run' and runs the main program: the mueller simulation
    """
    log.info("START MUELLER SIMULATION")
    log.info("Instruction File: " + str(cliArgs.inputfile) )
    if cliArgs.matrixfile == False:
        log.info("No matrix file given.")
    else:
        log.info("Matrix File: " + str(cliArgs.matrixfile) )

    # Read input file
    #try:
    #    labratory_setup = cliArgs.inputfile.read_text().splitlines()
    #except FileNotFoundError as e:
        # Handle file not found
    #    log.critical("FATAL ERROR: File " + str(cliArgs.inputfile) + " not found!")
    #    log.exception(e, exc_info = True)
    #    sys.exit(-1)
    labratory_setup = util.readFileAsText(cliArgs.inputfile).splitlines()

    # Read matrix file if given
    if cliArgs.matrixfile == False:
        # Define dummy array for simulation inititialisation if no matrix file is given
        # Definition prevents error if no matrix file is given, but the input file contains 'SMP' command
        sampleMatrix = [{"head": "No Sample Defined", "matrix": np.array([ [1, 0, 0],
                                                                           [0, 1, 0],
                                                                           [0, 0, 1]  ]) }]
    else:
        sampleMatrix = util.readFileAsMatrices(cliArgs.matrixfile)
    #    try:
    #        # Read matrix file
    #        sampleMatrix = cliArgs.matrixfile.read_text()
#
#            # Convert text to matrices
#            # Split file in seperate matrices and remove comments
#            # Comments start with '#' and matrices with '!'
#            sampleMatrix = [matrix.strip().split("\n") for matrix in sampleMatrix.split("!") if matrix.strip()[0] != "#"]
#            # Build a list of dictionaries
#            # Each dictionary contains a head with a descriptive message extracted from the file and a matrix extracted from the file
#            sampleMatrix = [ { "head": matrix.pop(0),
#                               "matrix": np.array([ matrix[0].split(),
#                                                    matrix[1].split(),
#                                                    matrix[2].split() ]).astype(np.float)
#                             } for matrix in sampleMatrix ]

        # Handle unexprected error
#        except:
#            log.critical("FATAL ERROR: Raman matrix can't be read from file. Is the file format correct?")
#            log.exception(sys.exc_info()[0])
#            raise

    # Initialise simulation
    # Declare one stokes vector for every raman matrix
    # Include the header information of sampleMatrix in state values
    initialState = [ { "head": matrix["head"], "state": np.array([0, 0, 0, 0]) } for matrix in sampleMatrix ]
    currentState = [ { "head": matrix["head"], "state": np.array([0, 0, 0, 0]) } for matrix in sampleMatrix ]

    # Get instruction decoder
    decoder = SetDec.SetupDecoder(sampleMatrix)

    # Decode instructions and calculate simulation
    for encodedInstruction, step in zip(labratory_setup, range(1, len(labratory_setup)+1)):

        # Print info about progress
        log.info("Simulation Step: " + str(step) + "    Instruction: " + encodedInstruction)

        # Decode encoded into mueller matrix or stokes vector
        decodedInstruction = decoder.decode(encodedInstruction)

        # Check if instruction is a new stokes vector or a mueller matrix to multiply or the raman matrix of the sample to multiply
        if isinstance(decodedInstruction, np.ndarray) and decodedInstruction.ndim == 1:
            # Reinitialsise the state of the simulation
            currentState = [ { "head": state["head"], "state": decodedInstruction } for state in currentState ]
            initialState = [ { "head": state["head"], "state": decodedInstruction } for state in initialState ]

        elif isinstance(decodedInstruction, np.ndarray) and decodedInstruction.ndim == 2:
            # Alter stokes vector with the mueller matrix
            currentState = [ { "head": state["head"], "state": decodedInstruction @ state["state"] } for state in currentState ]

        elif isinstance(decodedInstruction, list):
            # Alter stokes vector with the mueller matrix of the sample
            for index, (state, matrix) in enumerate( zip(currentState, decodedInstruction) ):

                if state["head"] == matrix["head"]:
                    # The stokes vector will only be changed if the header of the mueller matrix and the header of the stokes vector are the same
                    currentState[index] = { "head": state["head"], "state": matrix["matrix"] @ state["state"] }

                else:
                    # Raise an exception if headers don't match
                    log.critical("INTERNAL ERROR: The headers of the samples mueller matrix and the current state of the simulation don't match.")
                    raise ValueError("INTERNAL ERROR: The headers of the samples mueller matrix and the current state of the simulation don't match.")

        else:
            # Handle unexpected behaviour
            log.error("FATAL ERROR: Unexprected mueller matrix! '" + encodedInstruction + "' in line " + str(step) + " can't be executed. Exiting execution.")
            sys.exit(-1)

        log.info("Current stokes vector: " + str(currentState))





    log.info("STOPPED MUELLER SIMULATION SUCCESSFULLY")

#
# START PROGRAM EXECUTION
#
if __name__ == "__main__":

    #
    #   CREATE COMMAND LINE INTERFACE
    #
    # Construct the commandline arguments
    # Initialise and set helping information
    ap = argparse.ArgumentParser(prog = "simulate",
                                 description = "This program simulates the influence of a raman active sample and the optical elements of the measurement setup on the polarisation of the laser. The calculation are performed with the mueller calculus and stokes vectors.",
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
                    default = "./muellersimulation.log",
                    help = "defines path and name of a custom .log file. Default=./muellersimulation.log",
                    dest = "logfile")
    # Add input file for labratory setup
    ap.add_argument("inputfile",
                    help = "text file containing the labratory setup that needs to be simulated. Details are given in the README.")
    # Add input file for raman tensors
    ap.add_argument("-m", "--matrix",
                    required = False,
                    default = False,
                    dest = "matrixfile",
                    help = "text file containing the raman matrices of the sample in the labratory cordinate system. Details are given in the README.")

    # Store command line arguments
    cliArgs = ap.parse_args()

    # Convert file paths to pathlib.Path
    cliArgs.inputfile = pathlib.Path(cliArgs.inputfile)
    if cliArgs.matrixfile != False:
        cliArgs.matrixfile = pathlib.Path(cliArgs.matrixfile)



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
        console.setLevel(logging.DEBUG)
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
    #   RUN PROGRAM
    #
    main()
