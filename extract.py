#
#   EXTERNAL LIBARIES
#
# Purpose loggging
import logging

# Purpose: CLIFileNotFoundError:
import argparse

# Terminate program on exception
import sys

# Handling file paths
import pathlib

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

#
#   MAIN PROGRAM
#
def main():
    """
    Read gaussian log files of frequency calculations and writes the raman tensors into a text file readable by the other scripts.
    See the readMe for details.
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
        log.warning("Keyword 'freq(raman, printderivatives)' not found in input file. May not contain raman tensors. Ask user for prgram termination.")

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
    # Read the harmonic frequencies from the log file
    # Every entry util.findEntries returns contains three frequencies. Every triplett will be splitt into its elements and all frequencies are combined in a single flat list.
    frequencylist = [freq for triplett in util.findEntries(gaussianfile, FREQUENCY_KEYWORD) for freq in triplett[0].split()]

    log.info("Extract tensors from file.")
    # Read tensor entries from string and covert them into matrices
    # Find all tensors with util.findEntries()
    # Create with the result of util.findEntries() a list of dictionaries containing a descriptive headder ("head") and the tensor as numpy float array ("matrix")
    # The header will contain the unique incrementing number of the mode and the harmonix frequency of the mode
    tensorlist = [ { "head": "v_" + tensor[0] + " = " + frequencylist[ int(tensor[0])-1 ] + "/cm",
                     "matrix": np.array([ tensor[2].replace("D", "e").split()[1:],
                                          tensor[3].replace("D", "e").split()[1:],
                                          tensor[4].replace("D", "e").split()[1:]  ]).astype(np.float) } for tensor in util.findEntries(gaussianfile, TENSOR_KEYWORD, lines = 5) ]

# WRITE RESULTS TO FILE

    log.info("Write results to file.")
    

    log.info("STOPPED RAMAN TENSOR EXTRACTION SUCCESSFULLY")


#
#   START OF PROGRAM EXECUTION AS MAIN PROGRAM
#
if __name__ == "__main__":

    #
    #   CREATE COMMAND LINE INTERFACE
    #
    # Construct the commandline arguments
    # Initialise and set helping information
    ap = argparse.ArgumentParser(prog = "extract",
                                 description = "This program reads gaussian log files of frequency calculations and writes the raman tensors into a text file readable by the other scripts. Tested for Gaussian16. Raman tensors are not put into the log file by default. See the readMe for details.",
                                 epilog = "Author: Jonas Eichhorn; License: MIT; Date: Sep.2020")

    # Adding arguments
    # Add verbose
    ap.add_argument("-v", "--verbose",
                    required = False,
                    help = "runs programm and shows status and error messages",
                    action = "store_true")
    # Add logfile (default defined)
    ap.add_argument("-l", "--log",
                    required = False,
                    default = str(pathlib.Path(__file__).parent) + "/log/extractGaussianTensor.log",
                    help = "defines path and name of a custom .log file. Default=.PROGRAMPATH/log/extractGaussianTensor.log",
                    dest = "logfile")
    # Add input file for gaussian log file
    ap.add_argument("gaussianfile",
                    help = "the log file of a gaussian frequency calculation")
    # Add path to output file
    ap.add_argument("-o", "--output",
                    help = "path to output file. Defaults to path of tensor_gaussianfile.txt",
                    required = False,
                    default = False,
                    dest = "outputfile")
    # Store command line arguments
    cliArgs = ap.parse_args()


    # Convert all paths to pathlib.Path
    cliArgs.gaussianfile = pathlib.Path(cliArgs.gaussianfile)
    cliArgs.logfile = pathlib.Path(cliArgs.logfile)

    # Create output file path if none is given
    # or covert to pathlib.Paht if given
    if cliArgs.outputfile == False:
        cliArgs.outputfile = pathlib.Path(cliArgs.gaussianfile.parent, f"tensor_{cliArgs.gaussianfile.stem}.txt")
    else:
        cliArgs.outputfile = pathlib.Path(cliArgs.outputfile)



    #
    # SETUPG LOGGING
    #
    # Logs to file and to console (to console only if verbose activated)
    # Set config for logfile
    logging.basicConfig(level=logging.DEBUG,
                        format='%(asctime)s : %(name)s : %(levelname)s : %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S',
                        filename= str(cliArgs.logfile.resolve()),
                        filemode='a')

    # Define a Handler which writes DEBUG messages or higher to the sys.stderr, if the commandline flag -v is given
    # If the verbose flag is not given only CRITICAL messages will go to sys.stderr
    console = logging.StreamHandler()
    if cliArgs.verbose:
        console.setLevel(logging.INFO)
    else:
        console.setLevel(logging.CRITICAL)

    # Set a format which is simpler for console use
    formatter = logging.Formatter('%(message)s')
    # Tell the handler to use this format
    console.setFormatter(formatter)
    # Add the handler to the root logger
    logging.getLogger('').addHandler(console)

    # Create a logger
    log = logging.getLogger(__name__)

    #
    # RUN PROGRAM
    #
    main()
