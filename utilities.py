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
        log.critical("FATAL ERROR: File " + str(cliArgs.inputfile) + " not found!")
        log.exception(e, exc_info = True)
        sys.exit(-1)

    except:
        # Log unexpected exception
        log.critical("FATAL ERROR: File '" + str(path) + "' can't be read.")
        log.exception(sys.exc_info()[0])
        raise

def readFileAsMatrices(path):
    """
    Read a text file by calling readFileAsText and converting the content into a list of dictionaries.
    Each dictionary contains a matrix and a head. The head is a descriptive header extracted from the text file.
    The originial file must follow this syntax:
    1. Lines starting with # will be ignored
    2. Lines starting with ! mark the beginning of a header, every header marks the beginning of a matrix
    3. The lines following the header define the headers matrix
    4. Matrix rows are seperated by a linebreak and columns by a white space

    Arguments:
    path - pathlib.Path object pointing to the file (passed to readFileAsText)

    Returns: list of dictionary with matrices and descriptive headers
    """
    # Read file as text
    text = readFileAsText(path)

    # Convert matrix file to list of matrices with descritive messages
    try:
        # Split file in seperate matrices and remove comments
        # Comments start with '#' and matrices with '!'
        input = [matrix.strip().split("\n") for matrix in text.split("!") if matrix.strip()[0] != "#"]
        # Build a list of dictionaries
        # Each dictionary contains a head with a descriptive message extracted from the file and a matrix extracted from the file
        matrixlist = [ { "head": matrix.pop(0),
                         "matrix": np.array([ matrix[0].split(),
                                              matrix[1].split(),
                                              matrix[2].split() ]).astype(np.float)
                       } for matrix in input ]

        return matrixlist

    except:
        # Log unexpected exceptions
        log.critical("FATAL ERROR: Raman matrices can't be read from file. Is the file format correct?")
        log.exception(sys.exc_info()[0])
        raise
