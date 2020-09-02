#
#   EXTERNAL LIBARIES
#

# Purpose: Math
import numpy as np
import math as math

# Purpose: annotate list with expected element types in function definition
# Example: def func(l: List[str]): ....
from typing import List

# Purpose: Termiante execution when fatal error occurs
import sys

# Purpose: logging
import logging

#
#   INTERNAL MODULES
#
import SetupDecoder as SetDec


# Enables logging with the logging module
log = logging.getLogger(__name__)
# Tells the logging module to ignore all logging message, if a program using this library does not use the logging module.
log.addHandler(logging.NullHandler())



#
#   CLASS for calculating the simulation
#
class MuellerSimulator:
    """
    This class contains a method for performing matrix operations on a stokes vector to describe the interaction of a laser beam with optical elements. This class uses the SetupDecoder class.
    """

    def __init__(self, simulationPlan: List[str], simulationStep = 0):
        self.simulationPlan = simulationPlan
        self.simulationStep = simulationStep
        self.stokesVector = np.array("0 0 0 0")
        self.initialStokesVecotr = np.array("0 0 0 0")
        self.decoder = SetDec.SetupDecoder()

    def step(self):
        """
        Calculate one step in the simulation by decoding the simulationPlan and performing a matrix-vector-multiplication on a mueller matrix and a stokes vector.
        """
        # Print info about progress
        encodedInstruction =  self.simulationPlan[self.simulationStep][:]
        instructionString = encodedInstruction
        log.info("Simulation Step: " + str(self.simulationStep) + "    Instruction: " + instructionString)

        # Pass encoded instruction by value ([:]) and decode it into mueller matrix or stokes vector
        encodedInstruction = self.simulationPlan[self.simulationStep][:]
        decodedInstruction = self.decoder.decode(encodedInstruction)

        # Check if instruction is a new stokes vector or a mueller matrix to multiply or multiple martrices to multiply
        if decodedInstruction.ndim == 1:
            # Save stokes vector as attribute
            self.stokesVector = decodedInstruction
            self.initialStokesVecotr = decodedInstruction

        elif decodedInstruction.ndim == 2:
            # Alter stokes vector with the mueller matrix
            self.stokesVector = self.stokesVector * decodedInstruction

        elif decodedInstruction.ndmim == 3:
            # Handle List of raman tensors
            pass

        else:
            # Handle unexpected behaviour
            log.error("FATAL ERROR: Mueller matrix exceeds expected dimensions! '" + instructionString + "' in line " + str(self.simulationStep+1) + " can't be executed. Exiting execution.")
            sys.exit(-1)

        log.info("Current stokes vector: " + str(self.stokesVector))
        self.simulationStep = self.simulationStep + 1
