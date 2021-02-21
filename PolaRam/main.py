#
#   EXTERNAL LIBARIES
#
# Purpose loggging
import logging

# Purpose: CLI
import argparse

# Handling file paths
import pathlib

# Math stuff
import numpy as np

# Get current version from git tags
from git import Repo
# Execute "git describe --tags" in the folder of the currently running file
__version__ =  Repo( str(pathlib.Path(__file__).parents[0]) ).git.execute(["git", "describe", "--tags"])

#
#   INTERNAL MODULES
#
import simulate, list, convert, extract
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
                                 epilog = "Author: Jonas Eichhorn; License: MIT; Date: Okt.2020")
    ap.add_argument('--version', "-v", action='version', version="%(prog)s " + __version__)
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
    # Add path to output file
    sap_simulate.add_argument("-o", "--output",
                              help = "path to output file. Default=PROGRAMMPATH/res/muellersimulation.txt",
                              required = False,
                              default = str(pathlib.Path(__file__).parent) + "/res/muellersimulation.txt",
                              dest = "outputfile",
                              type = util.filepath)
    # Add argument that will be written as comment in the output file
    sap_simulate.add_argument("-c", "--comment",
                              dest = "comment",
                              help = "comment that will be added to the output file",
                              required = False,
                              action = util.joinString,
                              nargs = "*",
                              default = "")
    sap_simulate.add_argument("-a", "--append",
                              dest = "writeMode",
                              action = "store_const",
                              const = "a",
                              default = "w",
                              required = False,
                              help = "if enabled the output file will not be overwritten, but the new results will be appended to the output file")
    sap_simulate.add_argument("-r", "--raw-output",
                               dest = "rawOutput",
                               action = "store_true",
                               default = False,
                               help = "controls the format of the output file. If enabled the results will be written as a easy parseable table. Useful for post processing large amount of data.")
    sap_simulate.add_argument("-s", "--silent",
                               dest = "showPrint",
                               action = "store_false",
                               default = True,
                               required = False,
                               help = "if enabled the final output will be only written to file and not printed on the screen")
    sap_simulate.add_argument("-lsr", "--laser",
                              dest = "laser",
                              action = util.stokesvectorlist,
                              help = "the initial polarisation state of the simulation, encoded as stokes parameters. It is possible to pass more than one stokes vector by using the flag multiple times. Default=1 1 0 0",
                              default = [np.array([1., 1., 0., 0.])] )
    sap_simulate.add_argument("-u", "--unpolarised-scattering",
                              dest = "allowUnpolarisedRamanScattering",
                              action = "store_true",
                              default = False,
                              required = False,
                              help = "if enabled unpolarised stokes vectors won't cause an exception when simulating the raman scattering. Use this option with care! Enabling this flag makes only sense in some specific cases. See the README for details.")

	# Create list command
    sap_list = sap.add_parser("list",
                                  help = "Lists all instruction polaram simulate can decode",
                                  description = "This program lists all instructions that can be used to describe a simulation. For details see the documentation on the simulate subprogramm.")
    # The subcommand list does not need any arguments, but the logging setup expects default values
    # for the logfile path and the verbose flag.
    # Add logfile (copied from sap_simulate)
    sap_list.add_argument("-l", "--log",
                              required = False,
                              default = str(pathlib.Path(__file__).parent) + "/log/muellersimulation.log",
                              # argparse.SUPPRESS hides this argument in the help text
                              help = argparse.SUPPRESS,
                              dest = "logfile",
                              type = util.filepath)
    # Add verbose (copied from sap_simulate)
    sap_list.add_argument("-v", "--verbose",
                              required = False,
                              # argparse.SUPPRESS hides this argument in the help text
                              help = argparse.SUPPRESS,
                              action = "store_true")



    # Create convert command
    sap_convert = sap.add_parser("convert",
                                 help = "Convert a raman tensor in the molecular coodinate system into a mueller matrix in the labratory coordinate system",
                                 description = "Converts raman tensors from the molecular coordinate system into the raman mueller matrix of a solution in the labratory coordinate system via a monte carlo simulation.")
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
                             help = "number of iterations the simulation will calculate. Default = 1000000",
                             required = False,
                             type = util.positiveInt,
                             default = 1000000,
                             dest = "iterationLimit")
    # Add path to output file
    sap_convert.add_argument("-o", "--output",
                             help = "path to output file. Default=PROGRAMMPATH/res/labratoryMuellerMatrix.txt",
                             required = False,
                             default = str(pathlib.Path(__file__).parent) + "/res/labratoryMuellerMatrix.txt",
                             dest = "outputfile",
                             type = util.filepath)
    # Add argument that will be written as comment in the output file
    sap_convert.add_argument("-c", "--comment",
                             dest = "comment",
                             help = "comment that will be added to the output file",
                             required = False,
                             action = util.joinString,
                             nargs = "*",
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
                             help = "length of array each subprocess is given to calculate. Default=500")
    sap_convert.add_argument("-t", "--threshold",
                             dest = "threshold",
                             required = False,
                             default = 2,
                             type = util.positiveInt,
                             help = "number of digits the depolarisation ratio before and after the monte-carlo-simulation must match for the result to pass validation. Default=2")

    # Create extract command
    sap_extract = sap.add_parser("extract",
                                 help = "Extract raman tensors from Gaussian .LOG-files. Tested for Gaussian16.",
                                 description = "This program reads gaussian log files of frequency calculations and writes the raman tensors into a text file that can be read by the other scripts. Tested for Gaussian16. Raman tensors are not put into the log file by default. See the readMe for details.")
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
                             action = util.joinString,
                             nargs = "*",
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

    elif cliArgs.command == "list":
        # Run list.py
        list.main()

    elif cliArgs.command == "convert":
        # Run convert.py
        convert.main(cliArgs)

    elif cliArgs.command == "extract":
        # Run extract.py
        extract.main(cliArgs)
