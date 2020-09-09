#
#   UNITTESTS
#
import unittest

# Import class that shall be tested and create an instance of it
import utilities as util

#
#   EXTERNAL LIBARIES
#

# Handling files
import pathlib

# math stuff
import numpy as np


class TestUtilities_ReadFileAsText(unittest.TestCase):
    """
    Test utilities.readFileAsText()
    """

    def test_types(self):
        """
        Make sure type errors are raised if necessary
        """
        self.assertRaises(TypeError, util.readFileAsText, "string")
        self.assertRaises(TypeError, util.readFileAsText, 1)
        self.assertRaises(TypeError, util.readFileAsText, True)
        self.assertRaises(TypeError, util.readFileAsText, False)
        self.assertRaises(TypeError, util.readFileAsText, 1.0)
        self.assertRaises(TypeError, util.readFileAsText, 1+1j)

class TestUtilities_ConvertTextToMatrices(unittest.TestCase):
    """
    Test utilities.readFileAsText()
    """

    def test_types(self):
        """
        Make sure type errors are raised if necessary
        """
        self.assertRaises(TypeError, util.readFileAsMatrices, pathlib.Path("some/path"))
        self.assertRaises(TypeError, util.readFileAsMatrices, 1)
        self.assertRaises(TypeError, util.readFileAsMatrices, True)
        self.assertRaises(TypeError, util.readFileAsMatrices, False)
        self.assertRaises(TypeError, util.readFileAsMatrices, 1.0)
        self.assertRaises(TypeError, util.readFileAsMatrices, 1+1j)

    def test_output(self):
        """
        Make sure the output is correct
        """

        # String to convert
        teststring = """# Comment

                        ! first matrix
                        1 0
                        0 1
                        ! second matrix
                        10 3
                        1 -1
                     """
        # Correct result
        correctoutput = [ {"head": "first matrix",
                           "matrix": np.array([ [1, 0], [0, 1] ]) },
                          {"head": "second matrix",
                           "matrix": np.array([ [10, 3], [1, -1] ]) }]
        # Function output
        output = util.convertTextToMatrices(teststring)

        # Check type and identitiy
        self.assertIsInstance(util.convertTextToMatrices(teststring), list)
        for index, matrix in enumerate(output):
            self.assertIsInstance(matrix, dict)
            self.assertDictEqual(output, correctoutput[index])