#
#   EXTERNAL LIBARIES
#
# Purpose loggging
import logging
# Enables logging with the logging module
log = logging.getLogger(__name__)
# Tells the logging module to ignore all logging message, if a program using this file does not use the logging module.
log.addHandler(logging.NullHandler())

# Checking the number of arguments a function expects
from inspect import signature

#
#   INTERNAL MODULES
#
import SetupDecoder as SetDec

def main():
    """
    This function will be called by main.py as subcommand 'list'. It prints a help text to the screen. The help text
    describes all instructions the main subprogramm 'simulate' can understand and handle.
    No parameters expected. No value returned.
    """

    print("List Of Available Instructions")
    print("------------------------------\n")


    print("See README.md for details.\n")

    print("COMMAND\t DESCRIPTION")
    print("       \t USAGE")

    # Get an instance of the SetupDecoder
    decoder = SetDec.SetupDecoder()

    # Loop over every command in the commandDictionary
    # The commandDictionary contains all the instruction the SetupDecoder understands
    for key, value in decoder.commandDictionary.items():
        # Get the encoded instruction, the function call it encodes and its help text
        instruction = key
        function    = value[0]
        help        = value[1]

        # Get some meta data on the encoded function
        functionSigniture = signature(function)
        # How many parameters does the function expect (except parameter 'self')?
        # numberOfArguments = len(functionSigniture.parameters)-1
        # Which parameters are expected (except parameter 'self')?
        listOfArguments = [param for param in functionSigniture.parameters if param != "self"]

        # Construct and print help text
        print(instruction, "\t", help)
        print(len(instruction)*" ", "\t", key, " ".join(listOfArguments) )
