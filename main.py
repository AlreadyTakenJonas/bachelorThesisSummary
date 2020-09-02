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
# MAIN PROGRAMM
#
def main():

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



#
#   START OF PROGRAMM
#
if __name__ == "__main__":
    main()
