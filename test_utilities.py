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
        self.assertRaises(TypeError, util.convertTextToMatrices, pathlib.Path("test_utilities.py"))
        self.assertRaises(TypeError, util.convertTextToMatrices, 1)
        self.assertRaises(TypeError, util.convertTextToMatrices, True)
        self.assertRaises(TypeError, util.convertTextToMatrices, False)
        self.assertRaises(TypeError, util.convertTextToMatrices, 1.0)
        self.assertRaises(TypeError, util.convertTextToMatrices, 1+1j)

    def test_output(self):
        """
        Make sure the output is correct
        """

        # String to convert
        teststring = """# Comment

                        ! first matrix
                        1 0 0
                        0 1 0
                        0 0 1
                        ! second matrix
                        10 3 0
                        1 -1 0
                        0  0 0
                     """
        #print("\n\n" + teststring + "\n\n")
        # Correct result
        correctoutput = [ {"head": "first matrix",
                           "matrix": np.array([ [1, 0, 0], [0, 1, 0], [0, 0, 1] ]) },
                          {"head": "second matrix",
                           "matrix": np.array([ [10, 3, 0], [1, -1, 0], [0, 0, 0] ]) }]

        # Function output
        output = util.convertTextToMatrices(teststring)

        # Check type and identitiy
        self.assertIsInstance(output, list)
        for index, matrix in enumerate(output):
            self.assertIsInstance(matrix, dict)
            self.assertEqual(matrix["head"], correctoutput[index]["head"])
            self.assertEqual(matrix["matrix"].any(), correctoutput[index]["matrix"].any())

class TestUtilities_FindSummands(unittest.TestCase):
    """
    Test utilities.findSummands()
    """

    def test_types(self):
        """
        Make sure type errors are raised
        """
        self.assertRaises(TypeError, util.findSummands, "s", 1)
        self.assertRaises(TypeError, util.findSummands, 1.0, 1)
        self.assertRaises(TypeError, util.findSummands, False, 1)
        self.assertRaises(TypeError, util.findSummands, 1+1j, 1)
        self.assertRaises(TypeError, util.findSummands, [1,1], 1)
        self.assertRaises(TypeError, util.findSummands, (1,1), 1)
        self.assertRaises(TypeError, util.findSummands, 1, "s")
        self.assertRaises(TypeError, util.findSummands, 1, 1.0)
        self.assertRaises(TypeError, util.findSummands, 1, False)
        self.assertRaises(TypeError, util.findSummands, 1, 1+1j)
        self.assertRaises(TypeError, util.findSummands, 1, [1,1])
        self.assertRaises(TypeError, util.findSummands, 1, (1,1))

    def test_values(self):
        """
        Make sure value errors are raised
        """
        self.assertRaises(ValueError, util.findSummands, 0, 1)
        self.assertRaises(ValueError, util.findSummands, -1, 1)
        self.assertRaises(ValueError, util.findSummands, 1, -1)
        self.assertRaises(ValueError, util.findSummands, 1, 0)

    def test_output(self):
        """
        Make sure output works correct
        """
        for i in range(1,21):
            for j in range(1,21):
                result = util.findSummands(i,j)

                # Check type
                self.assertIsInstance(result, list)
                for elem in result:
                    self.assertIsInstance(elem, int)

                # Check sum
                self.assertEqual(sum(result), i)
