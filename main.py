#
#   EXTERNAL LIBARIES
#
# Purpose loggging
import logging

# Purpose: CLI
import argparse

# Handling file paths
import pathlib

#
#   INTERNAL MODULES
#
import simulate, convert, extract
import utilities as util

#
#   START OF PROGRAM EXECUTION AS MAIN PROGRAM
#
if __name__ == "__main__":

    #
    #   CREATE COMMAND LINE INTERFACE
    #
    # Construct the commandline arguments
    # Initialise and set helping information
    ap = argparse.ArgumentParser(prog = "polaram",
                                 description = "PolaRam simulates the influence of a raman active sample and the optical elements of the measurement setup on the polarisation of the laser. The calculations are performed with the mueller calculus and stokes vectors.",
                                 epilog = "Author: Jonas Eichhorn; License: MIT; Date: Sep.2020")
    sap = ap.add_subparsers(dest = "command", metavar = "subcommand")
    sap.required = True

    # Create simulate command
    sap_simulate = sap.add_parser("simulate",
                                  help = "Simulate laser polarisation changes in raman spectroscopy",
                                  description = "This program simulates the influence of a raman active sample and the optical elements of the measurement setup on the polarisation of the laser. The calculations are performed with the mueller calculus and stokes vectors.")
    # Adding arguments to simulate command
    # Add verbose
    sap_simulate.add_argument("-v", "--verbose",
                              required = False,
                              help = "runs programm and shows status and error messages",
                              action = "store_true")
    # Add logfile (default defined)
    sap_simulate.add_argument("-l", "--log",
                              required = False,
                              default = str(pathlib.Path(__file__).parent) + "/log/muellersimulation.log",
                              help = "defines path and name of a custom .log file. Default=PROGRAMPATH/log/muellersimulation.log",
                              dest = "logfile",
                              type = util.filepath)
    # Add input file for labratory setup
    sap_simulate.add_argument("inputfile",
                              help = "text file containing the labratory setup that needs to be simulated. Details are given in the README.",
                              type = util.filepath)
    # Add input file for raman tensors
    sap_simulate.add_argument("-m", "--matrix",
                              required = False,
                              default = str(pathlib.Path(__file__).parent) + "/unitmatrix.txt",
                              dest = "matrixfile",
                              help = "text file containing the raman matrices of the sample in the labratory cordinate system. Details are given in the README.",
                              type = util.filepath)

    # Create convert command
    sap_convert = sap.add_parser("convert",
                                 help = "Convert a raman tensor from the molecular to the labratory coordinate system",
                                 description = "Converts raman tensors from the molecular coordinate system into the raman matrix of a solution in the labratory coordinate system via a monte carlo simulation.")
    # Adding arguments to convert command
    # Add verbose
    sap_convert.add_argument("-v", "--verbose",
                             required = False,
                             help = "runs programm and shows status and error messages",
                             action = "store_true")
    # Add logfile (default defined)
    sap_convert.add_argument("-l", "--log",
                             required = False,
                             default = str(pathlib.Path(__file__).parent) + "/log/convertRamanTensor.log",
                             help = "defines path and name of a custom .log file. Default=PROGRAMPATH/log/convertRamanTensor.log",
                             dest = "logfile",
                             type = util.filepath)
    # Add input file for labratory setup
    sap_convert.add_argument("tensorfile",
                             help = "text file containing the raman tensors that will be converted. Details are given in the README.",
                             type = util.filepath)
    # Add iteration limit for monte carlo simulation
    sap_convert.add_argument("-i", "--iterations",
                             help = "number of iterations the simulation will calculate. Default = 10000",
                             required = False,
                             type = int,
                             default = 10000,
                             dest = "iterationLimit")
    # Add path to output file
    sap_convert.add_argument("-o", "--output",
                             help = "path to output file. Default=PROGRAMMPATH/res/labratoryTensor.txt",
                             required = False,
                             default = str(pathlib.Path(__file__).parent) + "/res/labratoryTensor.txt",
                             dest = "outputfile",
                             type = util.filepath)
    # Add argument that will be written as comment in the output file
    sap_convert.add_argument("-c", "--comment",
                             dest = "comment",
                             help = "comment that will be added to the output file",
                             required = False,
                             type = str,
                             default = "")
    # Add option to multiprocess calculation
    sap_convert.add_argument("-p", "--processes",
                             dest = "processCount",
                             help = "number of processes that compute in parallel. Default=2",
                             required = False,
                             default = 2,
                             type = util.positiveInt)
    sap_convert.add_argument("-s", "--cunksize",
                             dest = "chunksize",
                             required = False,
                             default = 500,
                             type = util.positiveInt,
                             help = "Length of array each subprocess is given to calculate. Default=500")

    # Create extract command
    sap_extract = sap.add_parser("extract",
                                 help = "Extract raman tensors from Gaussian .LOG-files. Tested for Gaussian16.",
                                 description = "This program reads gaussian log files of frequency calculations and writes the raman tensors into a text file readable by the other scripts. Tested for Gaussian16. Raman tensors are not put into the log file by default. See the readMe for details.")
    # Adding arguments to extract command
    # Add verbose
    sap_extract.add_argument("-v", "--verbose",
                             required = False,
                             help = "runs programm and shows status and error messages",
                             action = "store_true")
    # Add logfile (default defined)
    sap_extract.add_argument("-l", "--log",
                             required = False,
                             default = str(pathlib.Path(__file__).parent) + "/log/extractGaussianTensor.log",
                             help = "defines path and name of a custom .log file. Default=PROGRAMPATH/log/extractGaussianTensor.log",
                             dest = "logfile",
                             type = util.filepath)
    # Add input file for gaussian log file
    sap_extract.add_argument("gaussianfile",
                             help = "the log file of a gaussian frequency calculation",
                             type=util.filepath)
    # Add path to output file
    sap_extract.add_argument("-o", "--output",
                             help = "path to output file. Default=PROGRAMPATH/res/molecularTensor.txt",
                             required = False,
                             default = str(pathlib.Path(__file__).parent) + "/res/molecularTensor.txt",
                             dest = "outputfile",
                             type = util.filepath)
    # Add argument that will be written as comment in the output file
    sap_extract.add_argument("-c", "--comment",
                             dest = "comment",
                             help = "comment that will be added to the output file",
                             required = False,
                             type = str,
                             default = "")


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
                        filename= cliArgs.logfile.resolve(),
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
    # RUN SELECTED COMMAND
    #
    if cliArgs.command == "simulate":
        # Run simulate.py
        simulate.main(cliArgs)

    elif cliArgs.command == "convert":
        # Run convert.py
        convert.main(cliArgs)

    elif cliArgs.command == "extract":
        # Run extract.py
        extract.main(cliArgs)
