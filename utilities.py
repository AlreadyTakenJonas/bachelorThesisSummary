#
#   MODULE FOR UTILITY FUNCTIONS
#

# Terminate program on exception
import sys

# Handling file paths
import pathlib

# Matrix multiplication and trigonometric functions
import numpy as np

# Purpose: logging
import logging

# Enables logging with the logging module
log = logging.getLogger(__name__)
# Tells the logging module to ignore all logging message, if a program using this library does not use the logging module.
log.addHandler(logging.NullHandler())

#
#   UTILITIES
#

# Displays or updates a console progress bar
def update_progress(progress):
    """
    update_progress() : Displays or updates a console progress bar
    Accepts a float between 0 and 1. Any int will be converted to a float.
    A value under 0 represents a 'halt'.
    A value at 1 or bigger represents 100%
    """
    barLength = 40 # Modify this to change the length of the progress bar
    status = ""
    if isinstance(progress, int):
        progress = float(progress)
    if not isinstance(progress, float):
        progress = 0
        status = "error: progress var must be float\r\n"
        log.debug("utilities.update_progress expects int or float as input. Given argument: " + str(progress))
    if progress < 0:
        progress = 0
        status = "Halt...\r\n"
    if progress >= 1:
        progress = 1
        status = "Done...\r\n"
    block = int(round(barLength*progress))
    text = "\rRunning: [{0}] {1}% {2}".format( "#"*block + "-"*(barLength-block), round(progress*100, 1), status)
    sys.stdout.write(text)
    sys.stdout.flush()

def readFileAsText(path):
    """
    Read a text file and return a string with the content

    Arguments:
    path - pathlib.Path object pointing to the file

    Returns: String containing the content of the text file
    """
    # Check argument type
    if not isinstance(path, pathlib.Path):
        log.critical("FATAL ERROR: readFileAsText expects a pathlib.Path object as argument! File '" + str(path) + "' can't be read.")
        raise TypeError("Function readFileAsText expects a pathlib.Path object as argument!")

    try:
        # Read file
        return path.read_text()

    except FileNotFoundError as e:
        # Handle file not found
        log.critical("FATAL ERROR: File " + str(path.resolve()) + " not found!")
        log.exception(e, exc_info = True)
        sys.exit(-1)

    except:
        # Log unexpected exception
        log.critical("FATAL ERROR: File '" + str(path.resolve()) + "' can't be read.")
        log.exception(sys.exc_info()[0])
        raise

def convertTextToMatrices(string):
    """
    Converting a string into a list of dictionaries. Each dictionary contains a 3x3 matrix and a head.
    The head is a descriptive header extracted from the text file.
    The text must follow this syntax:
    1. Lines starting with # will be ignored
    2. Lines starting with ! mark the beginning of a header, every header marks the beginning of a matrix
    3. The lines following the header define the headers matrix
    4. Matrix rows are seperated by a linebreak and columns by a white space

    Arguments:
    string - string that will be converted into matrices

    Returns: list of dictionary with matrices and descriptive headers
    """
    if not isinstance(string, str):
        log.critical("FATAL ERROR: convertTextToMatrices expects a string as argument! Type'" + type(string) + "' was passed.")
        raise TypeError("Function convertTextToMatrices expects a string as argument!")

    # Convert matrix file to list of matrices with descritive messages
    try:
        # Split file in seperate matrices and remove comments
        # Comments start with '#' and matrices with '!'
        matrixlist = [matrix.strip().split("\n") for matrix in string.split("!") if matrix.strip()[0] != "#"]
        # Build a list of dictionaries
        # Each dictionary contains a head with a descriptive message extracted from the file and a matrix extracted from the file
        matrixlist = [ { "head": matrix.pop(0),
                         "matrix": np.array([ matrix[0].split(),
                                              matrix[1].split(),
                                              matrix[2].split() ]).astype(np.float)
                       } for matrix in matrixlist ]

        return matrixlist

    except:
        # Log unexpected exceptions
        log.critical("FATAL ERROR: Raman matrices can't be read from file. Is the file format correct?")
        log.exception(sys.exc_info()[0])
        raise

def readFileAsMatrices(path):
    """
    Shorthand for convertTextToMatrices(readFileAsText)
    """
    text = readFileAsText(path)
    return convertTextToMatrices(text)

def electricalFieldToStokes(eVector):
    """
    Convert a 3x1 vector describing the electrical field of the laser light into the stokes formalism (4x1 vector)
    """

    # TODO: Check type and physical validity (Ez == 0)

    # Electrical field in x and y axis
    Ex = eVector[0]
    Ey = eVector[1]

    # Conversion into stokes formalism
    stokes = np.array([ Ex**2 + Ey**2,
                        Ex**2 - Ey**2,
                        2*Ex*Ey,
                        0           ])

    # TODO: Check polarisation grade

    # Return result
    return stokes

def stokesToElectricalField(sVector):
    """
    Convert a 4x1 stokes vector into 3x1 electrical field vector
    """

    # TODO: Check type and polarisation grade
    # s_3 must be zero
    # Formulas only works for completly polarised light if the light is not vertically or horizontally polarised

    # Check polarisation
    if (sVector[2] == 0):
        # Light horizontally or vertically polarised
        eVector = np.array([ np.sqrt( 0.5 * (sVector[0] + sVector[1]) ),
                             np.sqrt( 0.5 * (sVector[0] - sVector[1]) ),
                                                0                       ])

    elif (sVector[0]^2 == sVector[1]^2 + sVector[2]^2):
        # Light is (partially) diagonially polarised and totally polarised
        eVector = np.array([      sVector[2] / np.sqrt( 2*(sVector[0] - sVector[1]) )  ,
                             abs( sVector[2] / np.sqrt( 2*(sVector[0] + sVector[1]) ) ),
                                                    0                                     ])

    else:
        # Throw error: Stokes vector can't be converted
        raise Error("SOME ERROR MESSAGE I NEED TO WRITE")

    # Return result
    return eVector

def findEntries(string, keyword, lines = 1, returnKeyword = False):
    """
    This function searches for keyword in a string and yields for every occurence of keyword a list of strings of it.
    Attributes:
    string - string to be searched
    keyword - keyword marking the begin of a substring to yield
    lines - the number of lines following keyword that should be yielded when finding keyword
    returnKeyword - leaves keyword out of yielded string if False
    Returns: Generator containing the searched substrings splitted by splitlines()
    """

    # TODO check input -> types, lines greater zero

    # Find first occurence of keyword in string
    index = string.find(keyword)

    if index == -1:
        # No matching enrty found
        log.warning("No entries found. Return empty generator. \nSearched keyword: '")

    # Find and yield all occurencens of keyword in the string
    while index != -1:
        # Get location where entry begins
        entryStart = index
        if not returnKeyword:
            # Cut out the keyword if necessary
            entryStart += len(keyword)

        try:
            # Slice found entry and yield it
            yield [line.strip() for line in string[entryStart:].splitlines()[:lines] ]

        except IndexError as e:
            # The string does not contain as much lines as it was requested at function call.
            log.critical("FATAL ERROR: One of the requested entries has less lines than expected. The data can't be read.")
            sys.exit(-1)

        # Search next entry
        index = string.find(keyword, index+len(keyword))
