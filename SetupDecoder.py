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
        unityMatrix = np.matrix("1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1")

        return transmission * unityMatrix

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
        "QWP": quarterWavePlate
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
