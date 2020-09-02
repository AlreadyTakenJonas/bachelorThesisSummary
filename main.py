#
#   EXTERNAL LIBARIES
#
import logging

#
#   INTERNAL MODULES
#
import MuellerSimulator as MSim


#
#   DEFINE input
#   temporary solution, CLI planned
#
test_input_file = "./test_input.txt"

#
# SETUPG LOGGING
#
# Logs to file and to console (to console only if verbose activated)
# Set config for logfile
logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s : %(name)s : %(levelname)s : %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S',
                    filename= "log.log", #args["logfile"],
                    filemode='a')

# Define a Handler which writes DEBUG messages or higher to the sys.stderr, if the commandline flag -v is given
# If the verbose flag is not given only CRITICAL messages will go to sys.stderr
console = logging.StreamHandler()
#if args["verbose"]:
#    console.setLevel(logging.DEBUG)
#else:
#    console.setLevel(logging.CRITICAL)

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
    log.info("Instruction File: " + test_input_file)

    # Read input file
    labratory_setup = []
    with open(test_input_file, "r") as f:
        labratory_setup = f.read().splitlines()


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
