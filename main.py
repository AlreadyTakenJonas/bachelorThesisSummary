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


#
#   CLASS for decding the user input that describes the labratory setup
#
class SetupDecoder:
    """
    Some docstring I need to write
    """

    def __init__(self):
        pass

    #
    #   Mueller Matrices for optical elements
    #
    def generalLinearRetarder(self, theta, delta):
        """
        Mueller Matrix for linear retarders in its general form. Used for calculation of wave plates. The arguments will be converted to floats and radians.
        User command: GLR * *
        Attributes:
            theta - Angle between slow and fast axis in degrees
            delta - Phase difference between fast and slow axis in degrees
        Return:
            special form of a mueller matrix
        """
        # Convert input
        theta = math.radians(float(theta))
        delta = math.radians(float(delta))

        # Calculate
        cosTwoTheta = np.cos(2*theta)
        sinTwoTheta = np.sin(2*theta)
        cosDelta = np.cos(delta)
        sinDelta = np.sin(delta)
        muellerMatrix = np.matrix([ [1, 0, 0, 0],
                                [0, cosTwoTheta**2 + sinTwoTheta**2 * cosDelta, cosTwoTheta*sinTwoTheta*(1-cosDelta), sinTwoTheta*sinDelta],
                                [0, cosTwoTheta*sinTwoTheta*(1-cosDelta), cosTwoTheta**2 * cosDelta + sinTwoTheta**2, -cosTwoTheta*sinDelta],
                                [0, -sinTwoTheta*sinDelta, cosTwoTheta*sinDelta, cosDelta]
                            ])
        return muellerMatrix

    def linearHorizontalPolariser(self):
        """
        Mueller Matrix for linear polariser with horizontal transmission.
        User command: LHP
        No Attributes
        Return:
            mueller matrix
        """
        return  0.5 * np.matrix("1 1 0 0;     1 1 0 0;    0 0 0 0;    0 0 0 0")

    def linearVerticalPolariser(self):
        """
        Mueller Matrix for linear polariser with vertical transmission
        User command: LVP
        No Attributes
        Return:
            mueller matrix
        """
        return 0.5 * np.matrix("1 -1 0 0;     -1 1 0 0;    0 0 0 0;    0 0 0 0")

    def initialStokesVector(self, s0, s1, s2, s3):
        """
        Initial polarisation vector of the laser.
        User command: LSR * * * *
        Attributes:
            s0 - Component describing intensity
            s1 - Component describing linear polarisation in horizontal and vertical direction
            s2 - Component describing linear polarisation in diagonal direction
            s3 - Component describing circular polarisation
        Return:
            stokes vector of initial laser polarisation
        """
        # Converting input to float and normalising with s0
        stokes_vector = np.array([s0, s1, s2, s3]).astype(float)
        stokes_vector = stokes_vector / stokes_vector[0]

        return stokes_vector

    def ramanTensorOfProbe(self):
        """
        WORK IN PROGRESS. Describtion of the probe as raman tensor. The tensor needs to be translated into the mueller formalism.
        Returns unity matrix for now
        """
        return np.matrix("1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1")


    #
    #   Dictionary for correlation user commands to appropriate function
    #
    commandDictionary = {
        "GLR": generalLinearRetarder,
        "LHP": linearHorizontalPolariser,
        "LVP": linearVerticalPolariser,
        "LSR": initialStokesVector,
        "PRB": ramanTensorOfProbe
    }

    def decode(self, userCommand: str):
        """
        Decodes user commands. Takes in one line of the input file as a list of strings and calls appropriate function with the help of commandDictionary.
        Attributes:
            userCommand - List of strings with the command for a specific function and its arguments
        Return:
            Return value of the function. Usually a stokes vector or a mueller matrix
        """
        # Isolate command and arguments
        commandString = userCommand
        userCommand = userCommand.split()
        command = userCommand.pop(0)
        args = userCommand
        # Call function
        try:
            result = self.commandDictionary[command](self, *args)
        except TypeError as e:
            # Handle wrong argument list
            print("FATAL ERROR: Unable to decode '" +commandString + "'. Wrong number of arguments! Exiting execution.")
            sys.exit(-1)
        except KeyError as e:
            # Handle wrong command
            arguments = str()
            print("FATAL ERROR: Unable to decode '" + commandString + "'. Unknown command! Exiting execution.")
            sys.exit(-1)

        # Return result of function call
        return result


#
#   CLASS for calculating the simulation
#
class MuellerSimulator:
    """
    Docstring I need to write
    """

    def __init__(self, simulationPlan: List[str], simulationStep = 0):
        self.simulationPlan = simulationPlan
        self.simulationStep = simulationStep
        self.stokesVector = np.array("0 0 0 0")
        self.initialStokesVecotr = np.array("0 0 0 0")
        self.decoder = SetupDecoder()

    def step(self):
        """
        Calculate one step in the simulation
        """
        # Print info about progress
        encodedInstruction =  self.simulationPlan[self.simulationStep][:]
        instructionString = encodedInstruction
        print("Simulation Step: " + str(self.simulationStep) + "    Instruction: " + instructionString)

        # Pass encoded instruction by value ([:]) and decode it into mueller matrix or stokes vector
        encodedInstruction = self.simulationPlan[self.simulationStep][:]
        decodedInstruction = self.decoder.decode(encodedInstruction)

        # Check if instruction is a new stokes vector or a mueller matrix to multiply or multiple martrices to multiply
        if decodedInstruction.ndim == 1:
            self.stokesVector = decodedInstruction
            self.initialStokesVecotr = decodedInstruction

        elif decodedInstruction.ndim == 2:
            self.stokesVector = self.stokesVector * decodedInstruction

        elif decodedInstruction.ndmim == 3:
            # Handle List of raman tensors
            pass

        else:
            # Handle unexpected behaviour
            print("FATAL ERROR: Mueller matrix exceeds expected dimensions! '" + instructionString + "' in line " + str(self.simulationStep+1) + " can't be executed. Exiting execution.")
            sys.exit(-1)

        print(self.stokesVector)
        self.simulationStep = self.simulationStep + 1



#
#   DEFINE input
#   temporary solution, CLI planned
#
test_input_file = "./test_input.txt"


#
# MAIN PROGRAMM
#
def main():

    # Read input file
    labratory_setup = []
    with open(test_input_file, "r") as f:
        labratory_setup = f.read().splitlines()


    # Decode and calculate simulation
    # Get instance of simulator class
    simulation = MuellerSimulator(labratory_setup)
    # Calculate the simulation command by command
    for step in labratory_setup:
        simulation.step()



#
#   START OF PROGRAMM
#
if __name__ == "__main__":
    main()
