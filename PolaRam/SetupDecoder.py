#
#   EXTERNAL LIBARIES
#

# Purpose: Math
import numpy as np
import math as math

# Purpose: logging
import logging

# Enables logging with the logging module
log = logging.getLogger(__name__)
# Tells the logging module to ignore all logging message, if a program using this library does not use the logging module.
log.addHandler(logging.NullHandler())

#
#   CLASS for decding the user input that describes the labratory setup
#
class SetupDecoder:
    """
    This class contains functions to create mueller matrices and stokes vectors as representation of optical elements and lasers.
    The decode method translates assembly-like commands into mentioned matrices and vectors. For more details see README.md.
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
            theta - Angle of the fast axis in degrees. 0° means a vertical orientation.
            delta - Phase difference between fast and slow axis in degrees
        Return:
            special form of a mueller matrix
        """
        if type(theta) == bool or type(delta) == bool:
            raise TypeError("Arguments for the general linear retarder can't be bool!")
        # Convert input
        theta = math.radians(float(theta))
        delta = math.radians(float(delta))

        # Calculate
        cosTwoTheta = np.cos(2*theta)
        sinTwoTheta = np.sin(2*theta)
        cosDelta = np.cos(delta)
        sinDelta = np.sin(delta)
        muellerMatrix = np.array([  [1, 0, 0, 0],
                                    [0, cosTwoTheta**2 + sinTwoTheta**2 * cosDelta  , cosTwoTheta*sinTwoTheta*(1-cosDelta)      , sinTwoTheta*sinDelta],
                                    [0, cosTwoTheta*sinTwoTheta*(1-cosDelta)        , cosTwoTheta**2 * cosDelta + sinTwoTheta**2, -cosTwoTheta*sinDelta],
                                    [0, -sinTwoTheta*sinDelta                       , cosTwoTheta*sinDelta                      , cosDelta]  ])
        return muellerMatrix

    def linearHorizontalPolariser(self, angle = 0):
        """
        Mueller Matrix for linear polariser with horizontal transmission. The angle of transmission can be changed by an optional angle.
        User command: LHP *
        Attributes:
            angle - angle of the fast axis measured from the horizontal line in degrees
        Return:
            mueller matrix
        """

        if type(angle) == bool:
            raise TypeError("Arguments for the linear horizontal retarder can't be bool!")

        # Convert the angle to float
        angle = float(angle)

        # Declare the matrix for a horizontal linear polariser
        matrix = 0.5 * np.array([ [1, 1, 0, 0],
                                  [1, 1, 0, 0],
                                  [0, 0, 0, 0],
                                  [0, 0, 0, 0] ])

        # Rotate thepolariser if needed
        if angle != 0:
            matrix = self.rotateMatrix(angle, matrix)

        return  matrix

    def linearVerticalPolariser(self, angle = 0):
        """
        Mueller Matrix for linear polariser with vertical transmission. The angle of transmission can be changed by an optional angle.
        User command: LVP *
        Attributes:
            angle - angle of the fast axis measured from the vertical line in degrees
        Return:
            mueller matrix
        """

        if type(angle) == bool:
            raise TypeError("Arguments for the linear vertical retarder can't be bool!")

        # Convert the angle to float
        angle = float(angle)

        # Declare the matrix for a horizontal linear polariser
        matrix = 0.5 * np.array([ [ 1, -1, 0, 0],
                                  [-1,  1, 0, 0],
                                  [ 0,  0, 0, 0],
                                  [ 0,  0, 0, 0] ])

        # Rotate thepolariser if needed
        if angle != 0:
            matrix = self.rotateMatrix(angle, matrix)

        return  matrix

    def ramanMatrixOfSample(self):
        """
        Returns the string 'SMP'. The simulation will detect that and know how to proceed.
        The raman matrices are given to the simulation by command line arguments. The SetupDecoder has nothing to do with this part of the process.
        """
        return "SMP"

    def attenuatingFilter(self, transmission):
        """
        Attenuating filter for decreasing laser intensity.
        User command: FLR *
        Attributes:
            transmission - amount of light that can pass through the filter (ranges from 0 to 1)
        Return:
            mueller matrix of the filter
        """

        if type(transmission) == bool:
            raise TypeError("Arguments for the attenuating filter can't be bool!")

        # Convert input to float
        transmission = float(transmission)

        # Check if input valid
        if transmission > 1 or transmission < 0:
            raise ValueError("FATAL ERROR: Transmission must be a value between 0 and 1.")

        # Return filter matrix
        return transmission * self.unitMatrix()

    def halfWavePlate(self, theta):
        """
        Mueller Matrix for a half wave plate. Derived from general linear retarder. The arguments will be converted to floats and radians.
        User command: HWP *
        Attributes:
            theta - Phase difference between fast axis and the coordinate system of the labratory setup in dregrees. 0° means a vertical or horizontal orientation.
        Return:
            special form of a mueller matrix
        """
        delta = math.degrees(np.pi)
        matrix = self.generalLinearRetarder(theta, delta)
        return matrix

    def quarterWavePlate(self, theta):
        """
        Mueller Matrix for a quarter wave plate. Derived from general linear retarder. The arguments will be converted to floats and radians.
        User command: HWP *
        Attributes:
            theta - Phase difference between fast axis and the coordinate system of the labratory setup in dregrees. 0° means a vertical orientation.
        Return:
            special form of a mueller matrix
        """
        delta = math.degrees(np.pi/2)
        matrix = self.generalLinearRetarder(theta, delta)
        return matrix

    def unitMatrix(self):
        """
        Returns unit matrix. Comments in the input file are decoded as unit matrix (= no operation). The filter matrix also uses the unit matrix.
        User command: NOP
        No attributes
        Return:
            unit matrix
        """
        return np.array([ [1, 0, 0, 0],
                          [0, 1, 0, 0],
                          [0, 0, 1, 0],
                          [0, 0, 0, 1] ])

    def depolariser(self, polarisedPart):
        """
        Mueller matrix for an ideal depolariser.
        User command: DPL *
        Attributes:
            polarisedPart - Percentage of the light that stays polarised after interacting with the depolariser (value between 0 and 1)
        Returns:
            mueller matrix
        """
        try:
            # Convert attribute to float
            polarisedPart = float(polarisedPart)
        except:
            # Hanlde wrong input argument
            # Raise Value Error to make sure that the decode function prints the right error message
            raise ValueError("Argument can't be converted to float. Wrong argument was passed to depolariser().")

        if polarisedPart < 0 or polarisedPart > 1:
            raise ValueError("Argument for depolariser function may not be smaller than zero or greater than one!")

        # Return mueller matrix
        matrix = np.diag([1, polarisedPart, polarisedPart, polarisedPart])
        return matrix

    def opticalMultiModeFiber(self):
        """
        Mueller matrix of the optical multi-mode fiber labeled as F3. This mueller matrix was calculated from real experiments and describes
        only one specific fiber
        User command: OF3
        Attributes:
            NONE
        Returns:
            mueller matrix
        """

        return np.array([ [ 0.98734319,  0.004664235, -0.03808659,    0],
                          [ 0.02519393,  0.520569010,  0.27315076,    0],
                          [-0.04387837, -0.004022648,  0.60062411,    0],
                          [ 0         ,  0          ,  0         ,    0] ])

    def rotateMatrix(self, angle: float, matrix: np.ndarray):
        """
        Returns the rotated matrix of any given mueller matrix. The rotation works like the rotation of hypersphears in 4d space and quaternions.
        No user command
        Attributes:
            angle - the magnitute of the angle of rotation in degrees
            matrix - the mueller matrix to rotate
        Return:
            rotated matrix
        """

        if type(angle) == bool:
            raise TypeError("Arguments for the matrix rotation can't be bool!")

        if type(matrix) != np.ndarray:
            raise TypeError("Matrices for the matrix rotation needs to be type numpy.ndarray!")

        # Convert angle to radians
        angle = math.radians(angle)

        # Declare rotation matrix
        rotationMatrix = lambda angle : np.array([  [1, 0               , 0              , 0],
                                                    [0, np.cos(2*angle) ,-np.sin(2*angle), 0],
                                                    [0, np.sin(2*angle) , np.cos(2*angle), 0],
                                                    [0, 0               , 0              , 1]   ])

        # Compute the rotation
        rotatedMatrix = rotationMatrix(angle) @ matrix @ rotationMatrix(-angle)

        return rotatedMatrix

    #
    #   Dictionary for correlating user commands to corresponding function
    #
    commandDictionary = {
        # Encoded Instruction: [callback function, short help text]
        "GLR": [generalLinearRetarder       , "general linear retarder"],
        "LHP": [linearHorizontalPolariser   , "horizontal linear polariser (aligned along X-axis)"],
        "LVP": [linearVerticalPolariser     , "vertical linear polariser (aligned aling Y-axis)"],
        "SMP": [ramanMatrixOfSample         , "Raman scattering sample"],
        "FLR": [attenuatingFilter           , "attenuating filter"],
        "HWP": [halfWavePlate               , "half wave plate (special case of general linear retarder)"],
        "QWP": [quarterWavePlate            , "quarter wave plate (special case of general linear retarder)"],
        "NOP": [unitMatrix                  , "no operation / identity operation"],
        "DPL": [depolariser                 , "depolariser"],
        "OF3": [opticalMultiModeFiber       , "real optical multi-mode fiber F3 (computed from experimental data)"]
    }

    def decode(self, commandString: str):
        """
        Decodes user commands. Takes in one line of the input file as a string and calls appropriate function with the help of commandDictionary.
        Attributes:
            commandString - String with the command for a specific function and its arguments
        Return:
            Return value of the function. Usually a stokes vector or a mueller matrix
        """

        if type(commandString) != type("string"):
            raise TypeError("SetupDecoder can only decode strings!")

        if len(commandString.strip()) == 0:
            raise ValueError("SetupDecoder can't decode empty strings!")

        # Isolate command and arguments
        command = commandString.split()[0]
        args = commandString.split()[1:]
        # Call function
        try:
            # Execute instruction
            result = self.commandDictionary[command][0](self, *args)

        except TypeError as e:
            # Handle wrong argument list
            log.critical("FATAL ERROR: Unable to decode '" + commandString + "'. Wrong number of arguments! Exiting execution.")
            log.exception(e, exc_info = True)
            raise

        except KeyError as e:
            # Handle wrong command
            log.critical("FATAL ERROR: Unable to decode '" + commandString + "'. Unknown command! Exiting execution.")
            log.exception(e, exc_info = True)
            raise

        except ValueError as e:
            # Handle wrong values for parameters
            log.critical("FATAL ERROR: Unable to decode '" + commandString + "'. Not permitted value was given! Exiting execution.")
            log.exception(e, exc_info = True)
            raise

        # Return result of function call
        return result
