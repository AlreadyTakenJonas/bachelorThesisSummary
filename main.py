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
                              dest = "logfile")
    # Add input file for labratory setup
    sap_simulate.add_argument("inputfile",
                              help = "text file containing the labratory setup that needs to be simulated. Details are given in the README.")
    # Add input file for raman tensors
    sap_simulate.add_argument("-m", "--matrix",
                              required = False,
                              default = False,
                              dest = "matrixfile",
                              help = "text file containing the raman matrices of the sample in the labratory cordinate system. Details are given in the README.")

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
                             dest = "logfile")
    # Add input file for labratory setup
    sap_convert.add_argument("tensorfile",
                             help = "text file containing the raman tensors that will be converted. Details are given in the README.")
    # Add iteration limit for monte carlo simulation
    sap_convert.add_argument("-i", "--iterations",
                             help = "number of iterations the simulation will calculate. Default = 10000",
                             required = False,
                             type = int,
                             default = 10000,
                             dest = "iterationLimit")
    # Add path to output file
    sap_convert.add_argument("-o", "--output",
                             help = "path to output file. Defaults to path of conveted_tensorfile.txt",
                             required = False,
                             default = False,
                             dest = "outputfile")
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
                             help = "number of processes that compute in parallel. Default = 1",
                             required = False,
                             default = 1,
                             type = util.positiveInt)

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
                             help = "defines path and name of a custom .log file. Default=.PROGRAMPATH/log/extractGaussianTensor.log",
                             dest = "logfile")
    # Add input file for gaussian log file
    sap_extract.add_argument("gaussianfile",
                             help = "the log file of a gaussian frequency calculation")
    # Add path to output file
    sap_extract.add_argument("-o", "--output",
                             help = "path to output file. Defaults to path of tensor_gaussianfile.txt",
                             required = False,
                             default = False,
                             dest = "outputfile")
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
    #   SAVE FILE PATHS AS pathlib.Path OBJECT
    #
    if cliArgs.command == "simulate":
        # Convert file paths to pathlib.Path
        cliArgs.inputfile = pathlib.Path(cliArgs.inputfile)
        if cliArgs.matrixfile != False:
            cliArgs.matrixfile = pathlib.Path(cliArgs.matrixfile)

    elif cliArgs.command == "convert":
        # Convert all paths to pathlib.Path
        cliArgs.tensorfile = pathlib.Path(cliArgs.tensorfile)
        cliArgs.logfile = pathlib.Path(cliArgs.logfile)

        # Create output file path if none is given
        # or covert to pathlib.Paht if given
        if cliArgs.outputfile == False:
            cliArgs.outputfile = pathlib.Path(cliArgs.tensorfile.parent, f"converted_{cliArgs.tensorfile.stem}.txt")
        else:
            cliArgs.outputfile = pathlib.Path(cliArgs.outputfile)

    elif cliArgs.command == "extract":
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
                        filename= pathlib.Path(cliArgs.logfile).resolve(),
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
