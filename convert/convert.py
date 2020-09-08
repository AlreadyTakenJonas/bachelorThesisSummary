#
#   EXTERNAL LIBARIES
#
# Purpose loggging
import logging

# Purpose: CLIFileNotFoundError:
import argparse

# Terminate program on exception
import sys

import numpy as np


#
#   MAIN PROGRAM
#
def main():

    log.info("START RAMAN TENSOR CONVERSION")

    # Read tensor file
    try:
        log.info("Read tensor from file " + cliArgs.tensorfile)
        with open(cliArgs.tensorfile, "r") as f:
            input = f.read()

    # Handle file not found
    except FileNotFoundError as e:
        log.critical("FATAL ERROR: File " + cliArgs.tensorfile + " not found!")
        log.exception(e, exc_info = True)
        sys.exit(-1)

    # Convert tensor file to list of tensors with descritive messages
    try:
        # Split file in seperate tensors and remove comments
        # Comments start with '#' and tensors with '!'
        input = [tensor.strip().split("\n") for tensor in input.split("!") if tensor.strip()[0] != "#"]
        # Build a list of dictionaries
        # Each dictionary contains a head with a descriptive message extracted from the file and a tensor extracted from the file
        tensorlist = [ { "head": tensor.pop(0),
                         "tensor": np.array([ tensor[0].split(),
                                              tensor[1].split(),
                                              tensor[2].split() ]).astype(np.float)
                       } for tensor in input ]

    # Handle unexprected error
    except:
        log.critical("FATAL ERROR: Raman tensors can't be read from file. Is the file format correct?")
        log.exception(sys.exc_info()[0])
        raise

    print(tensorlist)

    log.info("STOPPED RAMAN TENSOR CONVERSION SUCCESSFULLY")

#
#   START OF PROGRAM EXECUTION AS MAIN PROGRAM
#
if __name__ == "__main__":

    #
    #   CREATE COMMAND LINE INTERFACE
    #
    # Construct the commandline arguments
    # Initialise and set helping information
    ap = argparse.ArgumentParser(prog = "convert",
                                 description = "Converts raman tensors from the molecular coordinate system into the raman matrix of a solution in the labratory coordinate system via a monte carlo simulation.",
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
                    default = "./convertRamanTensor.log",
                    help = "defines path and name of a custom .log file. Default=./convertRamanTensor.log",
                    dest = "logfile")
    # Add input file for labratory setup
    ap.add_argument("tensorfile",
                    help = "text file containing the raman tensors that will be converted. Details are given in the README.")
    # Add iteration limit for monte carlo simulation
    ap.add_argument("-i", "--iterations",
                    help = "number of iterations the simulation will calculate. Default = 10",
                    required = False,
                    type = int,
                    nargs = 1,
                    default = 10,
                    dest = "iterationLimit")
    # Store command line arguments
    cliArgs = ap.parse_args()




    #
    # SETUPG LOGGING
    #
    # Logs to file and to console (to console only if verbose activated)
    # Set config for logfile
    logging.basicConfig(level=logging.DEBUG,
                        format='%(asctime)s : %(name)s : %(levelname)s : %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S',
                        filename= cliArgs.logfile,
                        filemode='a')

    # Define a Handler which writes DEBUG messages or higher to the sys.stderr, if the commandline flag -v is given
    # If the verbose flag is not given only CRITICAL messages will go to sys.stderr
    console = logging.StreamHandler()
    if cliArgs.verbose:
        console.setLevel(logging.DEBUG)
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
