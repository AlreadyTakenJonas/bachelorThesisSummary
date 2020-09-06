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

    def __init__(self, simulationPlan: List[str], simulationStep = 0, currentStokes = np.array([0, 0, 0, 0]), initialStokes = np.array([0, 0, 0, 0])):
        """
        Initialise the simulator class.
        Attributes:
            simulationPlan - List of strings with encoded commands, which describe the experimental setup that shall be simulated
            simulationStep - Positive integer that describes at which point of the simulatorPlan the simulator starts (defaults to zero, should not be messed with)
            currentStokes  - The stokes parameter that describe the current state of the simulation (defaults to zero vector, should not be messed with)
            initialStokes  - The stokes parameter that describe the inital state of the simulation (defauts to zero vector, should not be messed with)
        """

        # Make sure input is valid: simulationPlan
        if type(simulationPlan) != list or all( type(elem) != str for elem in simulationPlan ):
            raise TypeError("The simulationPlan must be a list of strings!")

        # Make sure input is valid: simulationStep
        if simulationStep < 0:
            raise ValueError("The simulation can't start before step zero. simulationStep can't be negative")
        if simulationStep > len(simulationPlan):
            raise ValueError("simulationStep must be within the index range of simulationPlan!")
        if type(simulationStep) != int:
            raise TypeError("The simulationStep must be type int!")

        # Make sure input is valid: currentStokes
        # Make sure input is valid: initialStokes
        if type(currentStokes) != np.ndarray or not all( isinstance(elem, np.float) or isinstance(elem, np.integer) for elem in currentStokes ):
            raise TypeError("Stokes vector (currentStokes) needs to be a float or integer numpy.ndarray!")
        if type(initialStokes) != np.ndarray or not all( isinstance(elem, np.float) or isinstance(elem, np.integer) for elem in initialStokes ):
            raise TypeError("Stokes vector (initialStokes) needs to be a float or integer numpy.ndarray!")
        if currentStokes.shape!= (4,):
            raise ValueError("currentStokes vector musst be a 4x1 dimensional vector!")
        if initialStokes.shape != (4,):
            raise ValueError("initialStokes vector musst be a 4x1 dimensional vector!")
        physicsValid = lambda stokes : stokes[0] >= 0 and stokes[0]**2 >= sum([ s**2 for s in stokes[1:] ])
        if not physicsValid(currentStokes):
            raise ValueError("Invalid stokes vector (currentStokes)! The first stokes parameter can't be negative and the square sum of the last three parameters musst be smaller or equal the squared first parameter!")
        if not physicsValid(initialStokes):
            raise ValueError("Invalid stokes vector (initialStokes)! The first stokes parameter can't be negative and the square sum of the last three parameters musst be smaller or equal the squared first parameter!")


        self.simulationPlan = simulationPlan
        self.simulationStep = simulationStep
        self.stokesVector = currentStokes
        self.initialStokesVecotr = initialStokes
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
