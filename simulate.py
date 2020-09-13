#
#   EXTERNAL LIBARIES
#
# Purpose loggging
import logging
# Enables logging with the logging module
log = logging.getLogger(__name__)
# Tells the logging module to ignore all logging message, if a program using this file does not use the logging module.
log.addHandler(logging.NullHandler())

# Purpose: CLI
import argparse

# Terminate program on exception
import sys

# Purpose: Math
import numpy as np

# Hanlde file paths
import pathlib

#
#   INTERNAL MODULES
#
import SetupDecoder as SetDec
import utilities as util

#
# MAIN PROGRAM
#
def main(cliArgs):
    """
    Function will be called by the subcommand 'run' and runs the main program: the mueller simulation
    """
    log.info("START MUELLER SIMULATION")
    log.info("Instruction File: " + str(cliArgs.inputfile) )

    # Read input file
    labratory_setup = util.readFileAsText(cliArgs.inputfile).splitlines()

    log.info("Matrix File: " + str(cliArgs.matrixfile.resolve()) )
    # Read matrices from file
    # Result is a list of dictionaries containing the matrices and descriptive headers
    sampleMatrix = util.readFileAsMatrices(cliArgs.matrixfile)

    # Make sure the matrix file is not the default matrix file containing just a unit matrix
    if cliArgs.matrixfile == pathlib.Path("unitmatrix.txt"):
        log.critical("WARNING: No matrix file specified. SMP will act as NOP!")

# INITIALISE SIMULATION

    # Declare one stokes vector for every raman matrix
    # Include the header information of sampleMatrix in state values
    initialState = [ { "head": matrix["head"], "state": np.array([0, 0, 0, 0]) } for matrix in sampleMatrix ]
    currentState = [ { "head": matrix["head"], "state": np.array([0, 0, 0, 0]) } for matrix in sampleMatrix ]

    # Get instruction decoder
    decoder = SetDec.SetupDecoder()

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

        elif decodedInstruction == "SMP":
            # SMP command detected

            # Convert state of simulation to the electrical field vector
            electricalField = [ { "head": state["head"], "state": util.stokesToElectricalField(state["state"]) } for state in currentState ]

            # Alter stokes vector with every mueller matrix of the sample
            for index, (state, matrix) in enumerate( zip(electricalField, sampleMatrix) ):

                if state["head"] == matrix["head"]:
                    # The stokes vector will only be changed if the header of the mueller matrix and the header of the stokes vector match
                    electricalField[index] = { "head": state["head"], "state": matrix["matrix"] @ state["state"] }

                else:
                    # Raise an exception if headers don't match
                    log.critical("INTERNAL ERROR: The headers of the samples mueller matrix and the current state of the simulation don't match.")
                    raise ValueError("INTERNAL ERROR: The headers of the samples mueller matrix and the current state of the simulation don't match.")

            # Convert electrical field vector back to stokes formalism
            currentState = [ { "head": state["head"], "state": util.electricalFieldToStokes(state["state"]) } for state in electricalField ]

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
