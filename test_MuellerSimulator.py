#
#   UNITTESTS
#
import unittest

# Import class that shall be tested and create an instance of it
from MuellerSimulator import MuellerSimulator
MuellerSimulator = MuellerSimulator(["UNITTEST"])

#
#   EXTERNAL LIBARIES
#
import numpy as np


class TestMuellerSimulator_Init(unittest.TestCase):
    """
    Test initialisation function in MuellerSimulator
    """

    def test_values(self):
        """
        Make sure value errors are raise if necessary
        """

        self.assertRaises(ValueError, MuellerSimulator.__init__, ["str"], simulationStep = -1)
        self.assertRaises(ValueError, MuellerSimulator.__init__, ["str"], simulationStep = 2)
        self.assertRaises(ValueError, MuellerSimulator.__init__, ["str"], initialStokes = np.array([-1, 0, 0, 0]) )
        self.assertRaises(ValueError, MuellerSimulator.__init__, ["str"], initialStokes = np.array([0, 0, 0]) )
        self.assertRaises(ValueError, MuellerSimulator.__init__, ["str"], initialStokes = np.array([0, 0, 0, 0, 0]) )
        self.assertRaises(ValueError, MuellerSimulator.__init__, ["str"], initialStokes = np.array([1, 10, 0, 0]) )
        self.assertRaises(ValueError, MuellerSimulator.__init__, ["str"], currentStokes = np.array([-1, 0, 0, 0]) )
        self.assertRaises(ValueError, MuellerSimulator.__init__, ["str"], currentStokes = np.array([0, 0, 0]) )
        self.assertRaises(ValueError, MuellerSimulator.__init__, ["str"], currentStokes = np.array([0, 0, 0, 0, 0]) )
        self.assertRaises(ValueError, MuellerSimulator.__init__, ["str"], currentStokes = np.array([1, 10, 0, 0]) )


    def test_types(self):
        """
        Make sure type errors are raised if necessary
        """

        self.assertRaises(TypeError, MuellerSimulator.__init__, 0)
        self.assertRaises(TypeError, MuellerSimulator.__init__, 1.0)
        self.assertRaises(TypeError, MuellerSimulator.__init__, "str")
        self.assertRaises(TypeError, MuellerSimulator.__init__, [0,0])
        self.assertRaises(TypeError, MuellerSimulator.__init__, True)
        self.assertRaises(TypeError, MuellerSimulator.__init__, False)
        self.assertRaises(TypeError, MuellerSimulator.__init__, 1+1j)
        self.assertRaises(TypeError, MuellerSimulator.__init__, ["str"], simulationStep = "str")
        self.assertRaises(TypeError, MuellerSimulator.__init__, ["str"], simulationStep = [0,0])
        self.assertRaises(TypeError, MuellerSimulator.__init__, ["str"], simulationStep = 0+1j)
        self.assertRaises(TypeError, MuellerSimulator.__init__, ["str"], simulationStep = True)
        self.assertRaises(TypeError, MuellerSimulator.__init__, ["str"], simulationStep = False)
        self.assertRaises(TypeError, MuellerSimulator.__init__, ["str"], initialStokes = [0,0,0,0])
        self.assertRaises(TypeError, MuellerSimulator.__init__, ["str"], initialStokes = np.array(["str","str","str","str"]))
        self.assertRaises(TypeError, MuellerSimulator.__init__, ["str"], initialStokes = np.array([0+1j,0+1j,0+1j,0+1j]))
        self.assertRaises(TypeError, MuellerSimulator.__init__, ["str"], initialStokes = np.array([True,True,True,True]))
        self.assertRaises(TypeError, MuellerSimulator.__init__, ["str"], currentStokes = [0,0,0,0])
        self.assertRaises(TypeError, MuellerSimulator.__init__, ["str"], currentStokes = np.array(["str","str","str","str"]))
        self.assertRaises(TypeError, MuellerSimulator.__init__, ["str"], currentStokes = np.array([0+1j,0+1j,0+1j,0+1j]))
        self.assertRaises(TypeError, MuellerSimulator.__init__, ["str"], currentStokes = np.array([True,True,True,True]))
