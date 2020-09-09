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

    # Read input file
    labratory_setup = util.readFileAsText(cliArgs.inputfile).splitlines()

    # Read matrix file if given
    if cliArgs.matrixfile == False:
        # Define dummy array for simulation inititialisation if no matrix file is given
        # Definition prevents error if no matrix file is given, but the input file contains 'SMP' command
        sampleMatrix = [{"head": "No Sample Defined", "matrix": np.array([ [1, 0, 0],
                                                                           [0, 1, 0],
                                                                           [0, 0, 1]  ]) }]
        log.critical("NO MATRIX FILE GIVEN. The SMP instruction will act as NOP!")
    else:
        # Read matrices from file
        # Result is a list of dictionaries containing the matrices and descriptive headers
        sampleMatrix = util.readFileAsMatrices(cliArgs.matrixfile)

        log.info("Matrix File: " + str(cliArgs.matrixfile) )

# INITIALISE SIMULATION

    # Declare one stokes vector for every raman matrix
    # Include the header information of sampleMatrix in state values
    initialState = [ { "head": matrix["head"], "state": np.array([0, 0, 0, 0]) } for matrix in sampleMatrix ]
    currentState = [ { "head": matrix["head"], "state": np.array([0, 0, 0, 0]) } for matrix in sampleMatrix ]

    # Get instruction decoder
    decoder = SetDec.SetupDecoder(sampleMatrix)

# RUN SIMULATION

    # Decode instructions and calculate simulation
    for step, encodedInstruction in enumerate(labratory_setup, 1):

        # Print info about progress
        log.info("Simulation Step: " + str(step) + "    Instruction: " + encodedInstruction)

        # Decode encoded into mueller matrix or stokes vector
        decodedInstruction = decoder.decode(encodedInstruction)

        # Check if instruction is a new stokes vector or a mueller matrix to multiply or the raman matrix of the sample to multiply
        if isinstance(decodedInstruction, np.ndarray) and decodedInstruction.ndim == 1:
            # LSR command detected
            # Reinitialsise the state of the simulation
            currentState = [ { "head": state["head"], "state": decodedInstruction } for state in currentState ]
            initialState = [ { "head": state["head"], "state": decodedInstruction } for state in initialState ]

        elif isinstance(decodedInstruction, np.ndarray) and decodedInstruction.ndim == 2:
            # Mueller matrix of optical element detected
            # Alter stokes vector with the mueller matrix
            currentState = [ { "head": state["head"], "state": decodedInstruction @ state["state"] } for state in currentState ]

        elif isinstance(decodedInstruction, list):
            # SMP command detected
            # Alter stokes vector with every mueller matrix of the sample
            for index, (state, matrix) in enumerate( zip(currentState, decodedInstruction) ):

                if state["head"] == matrix["head"]:
                    # The stokes vector will only be changed if the header of the mueller matrix and the header of the stokes vector match
                    currentState[index] = { "head": state["head"], "state": matrix["matrix"] @ state["state"] }

                else:
                    # Raise an exception if headers don't match
                    log.critical("INTERNAL ERROR: The headers of the samples mueller matrix and the current state of the simulation don't match.")
                    raise ValueError("INTERNAL ERROR: The headers of the samples mueller matrix and the current state of the simulation don't match.")

        else:
            # Handle unexpected behaviour
            log.critical("INTERNAL ERROR: Unexprected mueller matrix! '" + encodedInstruction + "' in line " + str(step) + " can't be executed. Exiting execution.")
            sys.exit(-1)

        # Log current state of simulation
        log.info("State of Simulation")
        logstring = str( np.array([ state["state"] for i, state in enumerate(currentState) ]) ).replace("[[", "").replace(" [", "").replace("]", "").splitlines()
        for index, state in enumerate(currentState):
            log.info("[ " + logstring[index] + " ] " + str(state["head"]))



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
