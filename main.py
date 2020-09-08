#
#   EXTERNAL LIBARIES
#
# Purpose loggging
import logging

# Purpose: CLI
import argparse

# Terminate program on exception
import sys

#
#   INTERNAL MODULES
#
import MuellerSimulator as MSim


#
#   CREATE COMMAND LINE INTERFACE
#
# Construct the commandline arguments
# Initialise and set helping information
ap = argparse.ArgumentParser(prog = "simulate",
                             description = "This program simulates the influence of a raman active sample and the optical elements of the measurement setup on the polarisation of the laser. The calculation are performed with the mueller calculus and stokes vectors.",
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
                default = "./muellersimulation.log",
                help = "defines path and name of a custom .log file. Default=./muellersimulation.log",
                dest = "logfile")
# Add input file for labratory setup
ap.add_argument("inputfile",
                help = "text file containing the labratory setup that needs to be simulated. Details are given in the README.")
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
# MAIN PROGRAMM
#
def main():

    log.info("START SIMULATION")
    log.info("Instruction File: " + cliArgs.inputfile)

    # Read input file
    labratory_setup = []
    try:
        with open(cliArgs.inputfile, "r") as f:
            labratory_setup = f.read().splitlines()
    except FileNotFoundError as e:
        log.critical("FATAL ERROR: File " + cliArgs.inputfile + " not found!")
        log.exception(e, exc_info = True)
        sys.exit(-1)

    # Decode and calculate simulation
    # Get instance of simulator class
    simulation = MSim.MuellerSimulator(labratory_setup)
    # Calculate the simulation command by command
    for step in labratory_setup:
        simulation.step()

    log.info("STOPPED SIMULATION SUCCESSFULLY")


#
#   START OF PROGRAMM
#
if __name__ == "__main__":
    main()
