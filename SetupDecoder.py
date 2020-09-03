#
#   EXTERNAL LIBARIES
#

# Purpose: Math
import numpy as np
import math as math

# Purpose: Termiante execution when fatal error occurs
import sys

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
    This class contains functions to create mueller matrices and stokes vectors as representation of optical elements and lasers. The decode method translates assembly-like commands into mentioned matrices and vectors.
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
            theta - Angle of the fast axis in degrees
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
        muellerMatrix = np.matrix([ [1, 0, 0, 0],
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
            raise TypeError("Arguments for the general linear retarder can't be bool!")

        # Convert the angle to float
        angle = float(angle)

        # Declare the matrix for a horizontal linear polariser
        matrix = 0.5 * np.matrix("1 1 0 0;     1 1 0 0;    0 0 0 0;    0 0 0 0")

        # Rotate thepolariser if needed
        if angle != 0:
            matrix = self.rotateMatrix(self, angle, matrix)

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

        # Convert the angle to float
        angle = float(angle)

        # Declare the matrix for a horizontal linear polariser
        matrix = 0.5 * np.matrix("1 -1 0 0;     -1 1 0 0;    0 0 0 0;    0 0 0 0")

        # Rotate thepolariser if needed
        if angle != 0:
            matrix = self.rotateMatrix(angle, matrix)

        return  matrix

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

    def attenuatingFilter(self, transmission):
        """
        Attenuating filter for decreasing laser intensity.
        User command: FLR *
        Attributes:
            transmission - percentage of light that can pass through the filter
        Return:
            mueller matrix of the filter
        """
        # Convert input to float
        transmission = float(transmission)

        # Check if input valid
        if transmission > 1 or transmission < 0:
            raise ValueError("FATAL ERROR: Transmission must be a value between 0 and 1.")

        # Return filter matrix
        return transmission * self.unityMatrix()

    def halfWavePlate(self, theta):
        """
        Mueller Matrix for a half wave plate. Derived from general linear retarder. The arguments will be converted to floats and radians.
        User command: HWP *
        Attributes:
            theta - Phase difference between fast and slow axis in degrees
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
            theta - Phase difference between fast and slow axis in degrees
        Return:
            special form of a mueller matrix
        """
        delta = math.degrees(np.pi/2)
        matrix = self.generalLinearRetarder(theta, delta)
        return matrix

    def unityMatrix(self):
        """
        Returns unity matrix. Comments in the input file are decoded as unity matrix (= no operation). The filter matrix also uses the unity matrix.
        User command: NOP
        No attributes
        Return:
            unity matrix
        """
        return np.matrix("1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1")

    def rotateMatrix(self, angle: float, matrix: np.matrix):
        """
        Returns the rotated matrix of any given mueller matrix. The rotation works like the rotation of hypersphears in 4d space and quaternions.
        No user command
        Attributes:
            angle - the magnitute of the angle of rotation in degrees
            matrix - the mueller matrix to rotate
        Return:
            rotated matrix
        """
        # Convert angle to radians
        angle = math.radians(angle)

        # Declare rotation matrix
        rotationMatrix = lambda angle : np.matrix([ [1, 0               , 0              , 0],
                                                    [0,  np.cos(2*angle), np.sin(2*angle), 0],
                                                    [0, -np.sin(2*angle), np.cos(2*angle), 0],
                                                    [0, 0               , 0              , 1]   ])

        # Compute the rotation
        rotatedMatrix = rotationMatrix(angle) * matrix * rotationMatrix(-angle)

        return rotatedMatrix

    #
    #   Dictionary for correlation user commands to appropriate function
    #
    commandDictionary = {
        "GLR": generalLinearRetarder,
        "LHP": linearHorizontalPolariser,
        "LVP": linearVerticalPolariser,
        "LSR": initialStokesVector,
        "PRB": ramanTensorOfProbe,
        "FLR": attenuatingFilter,
        "HWP": halfWavePlate,
        "QWP": quarterWavePlate,
        "NOP": unityMatrix
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
            if command[0] == "#":
                # If the command starts with '#' the line will be ignored and the unity matrix is returned
                result = self.unityMatrix()
                log.info("Comment found in input file ('" + commandString + "'). Unity matrix will be returned.")
            else:
                # Execute instruction
                result = self.commandDictionary[command](self, *args)

        except TypeError as e:
            # Handle wrong argument list
            log.critical("FATAL ERROR: Unable to decode '" + commandString + "'. Wrong number of arguments! Exiting execution.")
            log.debug(e)
            sys.exit(-1)

        except KeyError as e:
            # Handle wrong command
            arguments = str()
            log.critical("FATAL ERROR: Unable to decode '" + commandString + "'. Unknown command! Exiting execution.")
            sys.exit(-1)

        except ValueError as e:
            # Handle wrong values for parameters
            log.critical("FATAL ERROR: Unable to decode '" + commandString + "'. Not permitted value was given! Exiting execution.")
            log.critical(e)
            sys.exit(-1)

        # Return result of function call
        return result
