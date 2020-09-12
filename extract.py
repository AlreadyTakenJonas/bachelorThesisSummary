#
#   EXTERNAL LIBARIES
#
# Purpose loggging
import logging
# Enables logging with the logging module
log = logging.getLogger(__name__)
# Tells the logging module to ignore all logging message, if a program using this file does not use the logging module.
log.addHandler(logging.NullHandler())

# Terminate program on exception
import sys

# Math stuff and arrays
import numpy as np

#
#   INTERNAL MODULES
#
import utilities as util

#
#   MARKOS
#

# This string should be present in valid input file
LOGFILE_KEYWORD = "freq(raman, printderivatives)"
# This string marks beginning of raman tensor in input file
TENSOR_KEYWORD = "Polarizability derivatives wrt mode"
# This string marks the beginning of the frequencies of the modes that belong to the raman tensors
FREQUENCY_KEYWORD = "Frequencies -- "
# This string marks the beginning of the meta data about the calculation: Gaussian version, date of execution, basis set, ...
METADATA_KEYWORD = "******************************************\n Gaussian"



#
#   MAIN PROGRAM
#
def main(cliArgs):
    """
    Read gaussian log files of frequency calculations and writes the raman tensors into a text file readable by the other scripts.
    See the readMe for details.
    Attributes:
    cliArgs - object containing the command line arguments parsed in main.py
    """

    log.info("START RAMAN TENSOR EXTRACTION")

# READ AND CHECK DATA

    # Read gaussian log file
    log.info("Read gaussian log file " + str(cliArgs.gaussianfile.resolve()))
    gaussianfile = util.readFileAsText(cliArgs.gaussianfile)

    # Check if it is a gaussian log file with raman tensors
    log.info("Check data")

    if not LOGFILE_KEYWORD in gaussianfile:
        # Key word not found, probably wrong file
        log.warning("Keyword 'freq(raman, printderivatives)' not found in input file. May not contain raman tensors. Ask user for program termination.")

        # Ask user if he wants to continiue execution
        if bool(input("WARNING: This file is probably no gaussian log file or may not contain raman tensors. Continue anyway? [y/N] ").lower() != 'y'):
            # Terminate program
            print("As you wish, my Lord.")
            log.info("USER STOPPED EXECUTION")
            sys.exit(-1)

        # Continue program
        print("As you wish, my Lord.")
        log.info("Continue execution.")

    if not TENSOR_KEYWORD in gaussianfile:
        # File does not contain raman tensors
        log.warning("Keyword 'Polarizability derivatives wrt mode' not found in input file. Can't find raman tensors.")
        log.critical("This file does not contain raman tensors. Exiting program.")
        log.info("RAMAN TENSOR EXTRACTION FAILED")
        sys.exit(-1)

# EXTRACT DATA

    log.info("Extract harmonic frequencies from file.")
    try:
        # Read the harmonic frequencies from the log file
        # Every entry util.findEntries returns contains three frequencies. Every triplett will be splitt into its elements and all frequencies are combined in a single flat list.
        frequencylist = [freq for triplett in util.findEntries(gaussianfile, FREQUENCY_KEYWORD) for freq in triplett[0].split()]

        # Write function that returns elements of frequencylist
        # Use function not list in case exceptions is raised
        def frequency(mode_index):
            return frequencylist[mode_index]

        # Make sure all frequencies are real
        # Gaussian writes imaginary frequencies as negative real numbers
        for freq in frequencylist:
            if float(freq) < 0:
                raise ValueError

    except ValueError:
        # Handle imaginary frequencies
        log.warning("File contains complex frequencies! Raman tensors might be wrong. Ask user for prgram termination.")

        # Ask user if he wants to continiue execution
        if bool(input("WARNING: File contains complex frequencies! Raman tensors might be wrong. Continue anyway? [y/N] ").lower() != 'y'):
            # Terminate program
            print("As you wish, my Lord.")
            log.info("USER STOPPED EXECUTION")
            sys.exit(-1)

        # Continue program
        print("As you wish, my Lord.")
        log.info("Continue execution.")

    except:
        # Handle unexpected errors
        log.error("UNKNOWN ERROR: Unable to extract raman frequencies from file. Is the file corrupted? Continuing execution.")
        log.exception(sys.exc_info()[0])

        # Define dummy values for following tensorlist definition
        def frequency(mode_index):
            return "??"

    log.info("Extract tensors from file.")
    try:
        # Read tensor entries from string and covert them into matrices
        # Find all tensors with util.findEntries()
        # Create with the result of util.findEntries() a list of dictionaries containing a descriptive headder ("head") and the tensor as numpy float array ("matrix")
        # The header will contain the unique incrementing number of the mode and the harmonix frequency of the mode
        tensorlist = [ { "head": "v_" + tensor[0] + " = " + frequency( int(tensor[0])-1 ) + "/cm",
                         "matrix": np.array([ tensor[2].replace("D", "e").split()[1:],
                                              tensor[3].replace("D", "e").split()[1:],
                                              tensor[4].replace("D", "e").split()[1:]  ]).astype(np.float) } for tensor in util.findEntries(gaussianfile, TENSOR_KEYWORD, lines = 5) ]

    except:
        # Log unexpected error
        log.critical("UNKNWON ERROR: Unable to extract raman tensors from file. Is the file corrupted? Exiting.")
        log.exception(sys.exc_info()[0])
        raise

    log.info("Extract meta data about computation.")
    try:
        # Read meta data like computation date, gaussian version or computation job
        # Get only the first element of the generator returned by util.findEntries
        metadata = next( util.findEntries(gaussianfile, METADATA_KEYWORD, lines = 10, returnKeyword = True) )

    except StopIteration as e:
        # Catch exception if no meta data is available
        log.error("No meta information in log file available.")
        metadata = ["NO META DATA IN GAUSSIAN .LOG-FILE " + str(cliArgs.gaussianfile.resolve())]

# WRITE RESULTS TO FILE

    log.info("Write results to file.")
    # Create string to write to file
    output_text = "# Raman tensors calculated by Gaussian\n# Gaussian .LOG-file: " + str(cliArgs.gaussianfile.resolve()) + "\n\n# Gaussian calculation settings:"

    # Add meta data to output
    for line in metadata:
        output_text += "\n# " + line

    # Add user comment to string
    if cliArgs.comment != "":
        output_text += "\n\n# " + str(cliArgs.comment)

    # Add tensors to output
    for tensor in tensorlist:
            output_text += "\n\n! " + tensor["head"] + "\n" + np.array2string(tensor["matrix"], sign = None).replace("[[", "").replace(" [", "").replace("]", "")

    # Log and write text to file
    log.debug("Writing results to '" + str(cliArgs.outputfile.resolve()) + "':\n\n" + output_text + "\n")
    print(output_text)
    cliArgs.outputfile.write_text(output_text)

    log.info("STOPPED RAMAN TENSOR EXTRACTION SUCCESSFULLY")
