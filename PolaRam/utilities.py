#
#   MODULE FOR UTILITY FUNCTIONS
#

# Terminate program on exception
import sys

# Handling file paths
import pathlib

# Matrix multiplication and trigonometric functions
import numpy as np

# Used for flooring numbers
import math

# Purpose: logging
import logging

# Used for raising argparse.ArgumentTypeError
import argparse

# Enables logging with the logging module
log = logging.getLogger(__name__)
# Tells the logging module to ignore all logging message, if a program using this library does not use the logging module.
log.addHandler(logging.NullHandler())

#
#   UTILITIES: Defines functions used by the other python scripts
#


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

def convertTextToMatrices(string, shape = None):
    """
    Converting a string into a list of dictionaries. Each dictionary contains a matrix and a head.
    The head is a descriptive header extracted from the text file.
    The text must follow this syntax:
    1. Lines starting with # will be ignored
    2. Lines starting with ! mark the beginning of a header, every header marks the beginning of a matrix
    3. The lines following the header define the headers matrix
    4. Matrix rows are seperated by a linebreak and columns by a white space
    If the matrix has more than 3 rows, will the function ignore all rows except the first three. If the matrix has to few, an exception will be raised.
    An exception will be raised for a wrong number of columns and rows. The number of expected columns and rows can be defined with the shape argument.
    If no shape is sepcified, there will be no check.

    Arguments:
    string - string that will be converted into matrices. The expected format is described in README.md.
    shape  - a integer tuple specifing the expected np.ndarray.shape of the matrices. If none is given, the shape won't be checked.

    Returns: list of dictionary with matrices and descriptive headers
    """
    # Make sure string is a string
    if not isinstance(string, str):
        log.critical("FATAL ERROR: convertTextToMatrices expects a string as argument! Type'" + type(string) + "' was passed.")
        raise TypeError("Function convertTextToMatrices expects a string as argument!")

    # Make sure shape is a tuple of two integers or the default value None.
    if shape != None:
        if ( not isinstance(shape, tuple) or len(shape) != 2 or not all(type(elem) is int for elem in shape) ):
            log.critical("FATAL ERROR: convertTextToMatrices expects a tuple of two positive integers as argument! " + str(shape) + " was passed.")
            raise TypeError("FATAL ERROR: convertTextToMatrices expects a tuple of two positive integers as argument! " + str(shape) + " was passed.")

    # Convert matrix file to list of matrices with descritive messages
    try:
        # Remove comments from string
        # Comments start with '#'
        string = "\n".join( [ line for line in string.splitlines() if line.strip().find("#") != 0 ] )
        # Split file in seperate matrices and remove empty lines
        # Matrices start with '!'
        matrixlist = [matrix.strip().split("\n") for matrix in string.split("!") if matrix.strip() != ""]
        # Build a list of dictionaries
        # Each dictionary contains a head with a descriptive message extracted from the file and a matrix extracted from the file
        matrixlist = [ { "head": matrix.pop(0),
                         "matrix": np.array([ row.split() for row in matrix ]).astype(np.float)
                       } for matrix in matrixlist ]

    except:
        # Log unexpected exceptions
        log.critical("FATAL ERROR: Raman matrices can't be read from file. Is the file format correct?")
        log.exception(sys.exc_info()[0])
        raise

    # Check shape of result, if a control variable was passed to the function
    if shape != None:
        # Check the shape of every matrix
        for matrix in matrixlist:
            if matrix["matrix"].shape != shape:
                raise IndexError("Polaram expected matrices of shape " + str(shape) + "! The shape " + str(matrix["matrix"].shape) + " does not meet the expectations.")

    # Return result
    return matrixlist

def readFileAsMatrices(path, *args):
    """
    Shorthand for convertTextToMatrices(readFileAsText)
    Attributes:
    path - pathlib.Path object pointing to the file that will be read
    args - a list of arguments, that will be passed on to convertTextToMatrices
    """
    text = readFileAsText(path)
    return convertTextToMatrices(text, *args)

def buildRamanMuellerMatrix(ramanTensor: np.ndarray):
    """
    This function builds the mueller matrix for a given raman tensor. Details for the conversion are given in the README
    and the seperate pdf-file ramanMuellerMatrix.pdf. This conversion does only work for fully polarised light with no
    circular polarised component.
    Attribures:
    ramanTensor - raman tensor (3x3 numpy.ndarray) that will be translated into a mueller matrix
    Returns: Mueller matrix as 4x4 numpy.ndarray
    """

    # Check type of input
    if not isinstance(ramanTensor, np.ndarray):
        raise TypeError("utilities.buildRamanMuellerMatrix expects a numpy.ndarray as input!")
    if ramanTensor.shape != (3,3):
        raise TypeError("utilities.buildRamanMuellerMatrix expects a 3x3 numpy.ndarray as input!")

    # Extract elements from raman tensor
    xx = ramanTensor[0,0]
    xy = ramanTensor[0,1]
    yx = ramanTensor[1,0]
    yy = ramanTensor[1,1]

    # Build new matrix
    # The conversion is described in ramanMuellerMatrix.pdf
    # This conversion does only work for fully polarised light with no circular polarised component
    muellerMatrix = np.array([  [ (xx**2 + yx**2 + xy**2 + yy**2)/2 , (xx**2 + yx**2 - xy**2 - yy**2)/2 , xy*xx + yx*yy , 0 ],
                                [ (xx**2 - yx**2 + xy**2 - yy**2)/2 , (xx**2 - yx**2 - xy**2 + yy**2)/2 , xy*xx - yx*yy , 0 ],
                                [  xx*yx + xy*yy                    ,  xx*yx - xy*yy                    , xx*yy + xy*yx , 0 ],
                                [  0                                ,  0                                , 0             , 0 ]    ])

    return muellerMatrix

def findEntries(string: str, keyword: str, lines: int = 1, returnKeyword: bool = False):
    """
    This function searches for the string keyword in a string and yields for every occurence of keyword as a list of strings.
    The strings contain the first lines following the keyword. Every string in the yielded list is a line in the original string.
    The number of read lines is specified by the argument lines. returnKeyword specifies wether to include the keyword in
    the final list or not.
    Attributes:
    string - string to be searched
    keyword - keyword marking the begining of a substring to yield
    lines - the number of lines following keyword that should be yielded
    returnKeyword - leaves keyword out of yielded string if False
    Returns: Generator containing the searched substrings splitted by splitlines()
    """
    # Check input
    if type(keyword) != type("str"):
        raise TypeError("utilities.findEntries expects keyword to be a string!")
    if lines < 1:
        raise ValueError("utilities.findEntries expects lines to be equal or greater than 1!")

    # Find first occurence of keyword in string
    index = string.find(keyword)

    if index == -1:
        # No matching enrty found
        log.warning("No entries found. Return empty generator. \nSearched keyword: '" + keyword +"'")

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

def positiveInt(string):
    """
    ARGPARSE TYPE: Used by argparse. DO NOT USE try-except-statements, because argparse can't detect errors if exceptions will be handled by the function itself.
    Type checking function for cli. Converts string given by cli to int and raises Exception if it is smaller 1.
    Attribute:
    string - string to convert to positive integer
    Returns positive integer
    """
    value = int(string)

    if value < 1:
        raise argparse.ArgumentTypeError("%s is no positive integer" % value)

    return value

def filepath(string):
    """
    ARGPARSE TYPE: Used by argparse. DO NOT USE try-except-statements, because argparse can't detect errors if exceptions will be handled by the function itself.
    Type checking function for cli. Converts string given by cli to pathlib.Path object.
    Attribute:
    string - string to convert to pathlib.Path object
    Returns pathlib.path object
    """
    return pathlib.Path(string)

class joinString(argparse.Action):
    """
    ARGPARSE ACTION: Used by argparse. DO NOT USE try-except-statements, because argparse can't detect errors if exceptions will be handled by the function itself.
    Class converts a list of strings (values) into a single string and sets the cli argument self.dest to this string. This enables the program to read a list of words
    in the command line as a single string.
    """
    def __call__(self, parser, args, values, option_string=None):
        setattr(args, self.dest, ' '.join(values))

class stokesvectorlist(argparse.Action):
    """
    ARGPARSE ACTION: Used by argparse. DO NOT USE try-except-statements, because argparse can't detect errors if exceptions will be handled by the function itself.
    This class converts a list of four numbers into a numpy array and puts the array into a list. If this class is called multiple times every new numpy array will
    be appended to the list. Every numpy will be checked, to make sure that they are all physical possible stokes vectors.
    """
    def __init__(self, option_strings, dest, nargs=None, const=None, default=None, type=None, choices=None, required=False, help=None, metavar=None):
        """
        Constructor: Calls the constructor of the parent and sets defaultIsSet variable. defaultIsSet will be used to determine if a new array will be appended to
        the vectorlist or if the vectorlist does only contain the default values and will therefore be overriden
        """
        # Call parents cunstroctur
        argparse.Action.__init__(self, option_strings=option_strings, dest=dest, nargs=4, const=const, default=default, type=float, choices=None, required=required, help=help, metavar=metavar)

        # Set a flag to keep track wether or not the currently saved vectorlist is the default. If the saved list is the default, it will be overriden, when the class is called
        if dest is None:
            self.defaultIsSet = False
        else:
            self.defaultIsSet = True

    def __call__(self, parser, args, values, option_string=None):
        """
        This function takes as a list of and appends them as a numpy array to a list of numpy arrays
        Attributes:
            self - this class
            parser - no idea, some argparse shit
            args - namespace with all command line arguments
            values - list of values given by user via command line
            option_string - no idea; some argparse shit
        """
        # Check if given values make physical sense
        if values[0] < 0:
            raise argparse.ArgumentError(self, "The first stokes parameter in %s can't be negativ!" % values)
        if 1 < round( sum([ s**2 for s in values[1:] ]) / values[0]**2 , 6):
            raise argparse.ArgumentError(self, "The square sum of the last three stokes parameters in %s can't be greater than the squared first stokes parameter!" % values)

        # Get current list of numpy arrays from argparse namespace
        vectorlist = getattr(args, self.dest)

        if self.defaultIsSet == False:
            # Append new vector to the list
            vectorlist = vectorlist + [np.array(values)]
        else:
            # Override default list
            vectorlist = [np.array(values)]
            self.defaultIsSet = False

        # Save updated vectorlist ot argparse namespace
        setattr( args, self.dest, vectorlist )
