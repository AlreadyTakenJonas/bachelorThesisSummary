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

# Get time and date for output file
from datetime import datetime

# Process bar
from tqdm import tqdm


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
    There will be a series of calculations for every vibrational mode of a molecule. All computations are matrix
    multiplications in the mueller formalism, to simulate a laser beam travelling through an optical setup and a
    sample which scatters the light (raman scattering).
    The function takes the result of the command line parser argparse (see main.py) as input.
    See README.md for details.
    """
    log.info("START MUELLER SIMULATION")

    # Read input file
    # This file describes the optical elements in the light beams path
    log.info("Instruction File: " + str(cliArgs.inputfile) )
    labratory_setup = util.readFileAsText(cliArgs.inputfile).splitlines()

    # Read matrices from file. The matrices are the mueller matrices that describe
    # the raman scattering behaviour of the vibrational modes
    # Result is a list of dictionaries containing the matrices and descriptive headers
    log.info("Matrix File: " + str(cliArgs.matrixfile.resolve()) )
    sampleMatrix = util.readFileAsMatrices(cliArgs.matrixfile, (4,4))

    # Make sure the matrix file is not the default matrix file containing just a unit matrix
    # If no matrix file is given every vibrational mode will be described by the unit matrix
    if cliArgs.matrixfile == pathlib.Path("unitmatrix.txt"):
        log.critical("WARNING: No matrix file specified. SMP will act as NOP!")

# RUN THE SIMULATION FOR EVERY GIVEN LASER POLARISATION

    # Create an empty string. The result of every simulation will be put into the string.
    result_text = ""

    # Add progress bar if the verbose flag is not set
    if cliArgs.verbose == False:
        initialStokesVectorsList = tqdm(cliArgs.laser)
    else:
        initialStokesVectorsList = cliArgs.laser

    # DO LOOP over every initial stokes vector
    for initialStokesVector in initialStokesVectorsList:
        # INITIALISE SIMULATION
            log.info("Initialise Simulation " + str(initialStokesVector))

            # Declare one stokes vector for every raman mueller matrix
            # Include the header information of sampleMatrix in state values
            # The header contains a unique description
            currentState = [ { "head": matrix["head"], "state": initialStokesVector } for matrix in sampleMatrix ]

            # Get instruction decoder
            # Used to decode the instructions given in the input file
            # The SetupDecoder returns for every instruction a mueller matrix or a stokes vector
            decoder = SetDec.SetupDecoder()

            # RUN SIMULATION

            # Decode instructions and calculate the simulation
            # Start enumeration at index (= step) 1 not zero
            for step, encodedInstruction in enumerate(labratory_setup, 1):

                # Log info about progress
                log.info("Simulation Step: " + str(step) + "    Instruction: " + encodedInstruction)

                # Decode encoded instruction into mueller matrix or stokes vector
                decodedInstruction = decoder.decode(encodedInstruction)

                if isinstance(decodedInstruction, np.ndarray) and decodedInstruction.ndim == 2:
                    # Mueller matrix of optical element detected
                    # Alter stokes vector with the mueller matrix
                    currentState = [ { "head": state["head"], "state": decodedInstruction @ state["state"] } for state in currentState ]

                elif decodedInstruction == "SMP":
                    # SMP command detected
                    # Use the raman mueller matrix specified via the command line interface

                    for index, (state, tensor) in enumerate( zip(currentState, sampleMatrix) ):

                        # Make sure the headers of the stokes vector and the mueller matrix match
                        if state["head"] == tensor["head"]:
                            # The stokes vector will only be changed if the header of the mueller matrix and the header of the stokes vector match

                            # Make sure the conversion formula for the raman tensor into the mueller matrix does apply
                            # The math is explained in a seperate pdf-file (PolaRam/ramanMuellerMatrix.pdf)
                            # The light must be fully polarised and there may be no circular polarisation
                            log.info("Check state vector '" + state["head"] + "'.")

                            # Make sure the polarisation grade Π is 1
                            # Π = sqrt( S_1^2 + S_2^2 + S_3^2 ) / S_0
                            # This check can be skipped by the user. In two specific cases does the mueller matrix generated by polaram convert apply
                            # to all linear polarised stokes vectors. See the README for details.
                            polarisation = np.sqrt(state["state"][1]**2 + state["state"][2]**2 + state["state"][3]**2) / state["state"][0]
                            polarisation = round( polarisation , 7)
                            if np.not_equal(polarisation, 1) and cliArgs.allowUnpolarisedRamanScattering == False:
                                log.error("SIMULATION ERROR: Error for initial state " + str(initialStokesVector) + ". Error in state vector '" + state["head"] + "'. Polarisation grade is " + str(polarisation) + ". Must be equal to one for SMP instruction! See the README for details.")
                                raise ValueError("SIMULATION ERROR: Error for initial state " + str(initialStokesVector) + ". Error in state vector '" + state["head"] + "'. Polarisation grade is " + str(polarisation) + ". Must be equal to one for SMP instruction! See the README for details.")

                            # Make sure there is no circular polarisation
                            if round( state["state"][3], 7 ) != 0:
                                log.error("SIMULATION ERROR: Error for initial state " + str(initialStokesVector) + ". Error in state vector '" + state["head"] + "'. The SMP instruction can't handle circular polarisation!")
                                raise ValueError("SIMULATION ERROR: Error for initial state " + str(initialStokesVector) + ". Error in state vector '" + state["head"] + "'. The SMP instruction can't handle circular polarisation!")

                            log.info("Apply raman mueller matrix to state vector.")
                            # Apply mueller matrix to current state of the simulation
                            currentState[index] = { "head": state["head"], "state": tensor["matrix"] @ state["state"] }

                        else:
                            # Raise an exception if headers don't match
                            log.critical("INTERNAL ERROR: Error for initial state " + str(initialStokesVector) + ". The headers of the samples raman tensor and the current state of the simulation don't match.")
                            raise ValueError("INTERNAL ERROR: Error for initial state " + str(initialStokesVector) + ". The headers of the samples raman tensor and the current state of the simulation don't match.")

                else:
                    # Handle unexpected/unknown instruction
                    log.critical("INTERNAL ERROR: Error for initial state " + str(initialStokesVector) + ". Unexprected mueller matrix! '" + encodedInstruction + "' in line " + str(step) + " can't be executed. Exiting execution.")
                    sys.exit(-1)

                # Log current state of simulation
                log.info("State of Simulation")
                # Put all vectors in a list of nicely formated strings
                logstring = str( np.array([ state["state"] for i, state in enumerate(currentState) ]) ).replace("[[", "").replace(" [", "").replace("]", "").splitlines()
                # Log every state with its header and value
                for index, state in enumerate(currentState):
                    log.info("[ " + logstring[index] + " ] " + str(state["head"]))

                # Make sure the computed stokes vectors are physical possible
                log.info("Check validity of simulation step.")
                for state in currentState:
                    # Make sure that the polarisation grade Π is not greater than one
                    # Rounding to avoid exceptions due to floating point errors
                    # Π = sqrt( S_1^2 + S_2^2 + S_3^2 ) / S_0
                    polarisation = np.sqrt(state["state"][1]**2 + state["state"][2]**2 + state["state"][3]**2) / state["state"][0]
                    polarisation = round( polarisation , 7)
                    if np.greater(polarisation, 1):
                        log.error("SIMULATION ERROR: Error for initial state " + str(initialStokesVector) + ". Error in state vector '" + state["head"] + "'. Polarisation grade is " + str(polarisation) + ". Can't be greater than one!")
                        raise ValueError("SIMULATION ERROR: Error for initial state " + str(initialStokesVector) + ". Error in state vector '" + state["head"] + "'. Polarisation grade greater than one is not possible!")

                    # Make sure that the light intensity is not smaller than zero
                    elif state["state"][0] < 0:
                        log.error("SIMULATION ERROR: Error for initial state " + str(initialStokesVector) + ". Error in state vector '" + state["head"] + "'. The total light intensity can't be negative!")
                        raise ValueError("SIMULATION ERROR: Error for initial state " + str(initialStokesVector) + ". Error in state vector '" + state["head"] + "'. The total light intensity can't be negative!")

        # SAVE RESULTS TO STRING
            # Format output minimalistic. Ideal for post processing large amounts of data
            if cliArgs.rawOutput == True:
                # Create table containing: initial state, the header of every state and the final state of the simulation
                # TODO: Improve table alignement
                result_text += "# State.Header   Initial.State.S0  Initial.State.S1  Initial.State.S2  Initial.State.S3     Final.State.S0  Final.State.S1  Final.State.S2  Final.State.S3"
                for final in currentState:
                    result_text += "\n" + str(final["head"]).replace(" ", "_") + "  " + str(initialStokesVector).replace("[", "").replace("]", "") + "      " + str(final["state"]).replace("[", "").replace("]", "")

                result_text += "\n"

            # Format output nicely
            else:
                # Add the calculated states to the output file.
                result_text += "\n# Simulation Results For Initial State " + str(initialStokesVector) + ":"
                # Create list of all calculated vectors as nicely formated strings
                formattedTable = str( np.array([ state["state"] for i, state in enumerate(currentState) ]) ).replace("[[", "").replace(" [", "").replace("]", "").splitlines()
                # Add calculated stokes vectors with header and value to the output file
                for index, vector in enumerate(formattedTable):
                    result_text += "\n[" + vector + " ] " + currentState[index]["head"]

            result_text += "\n"
    # END LOOP over every initial stokes vector

# PRINT RESULTS TO FILE

    # Add command line arguments and time of execution in the output file
    output_text  = "# polaram simulate " + str(cliArgs.inputfile.resolve())
    output_text += " --output " + str(cliArgs.outputfile.resolve())
    output_text += " --log " + str(cliArgs.logfile.resolve())
    output_text += " --matrix " + str(cliArgs.matrixfile.resolve())
    output_text += "\n# Execution time: " + str(datetime.now()) + "\n"

    # Add user comment to output file
    if cliArgs.comment != "":
        output_text += "# " + str(cliArgs.comment) + "\n"

    if cliArgs.rawOutput == False:
        # Add the optical elements and the labratory setup that was simulated to output file
        output_text += "\n# Simulation Program:\n" + "\n".join(labratory_setup)

    output_text = output_text + "\n" + result_text

    # Log and write text to file
    log.debug("Writing results to '" + str(cliArgs.outputfile.resolve()) + "':\n\n" + output_text + "\n")
    if cliArgs.showPrint == True:
        print(output_text)
    with cliArgs.outputfile.open(cliArgs.writeMode) as file:
        file.write(output_text)


    log.info("STOPPED MUELLER SIMULATION SUCCESSFULLY")
