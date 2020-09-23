#
#   UNITTESTS
#
import unittest

# Check if object is a generator
import types

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

    def test_index(self):
        """
        Make sure index errors are raised if necessary
        """
        self.assertRaises(IndexError, util.convertTextToMatrices, "!matrix\n  0 1\n 0 1")

    def test_values(self):
        """
        Make sure value errors are raised if necessary
        """
        self.assertRaises(ValueError, util.convertTextToMatrices, "!matrix\n 1 0 0 0\n 0 1 0 0\n 0 0 1 0\n 0 0 0 1")

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

class TestUtilities_FindEntries(unittest.TestCase):
    """
    Test utilities.findEntries()
    """
    def test_types(self):
        """
        Make sure type errors are raised
        """
        with self.assertRaises(TypeError):
            list(util.findEntries("string", False))
            list(util.findEntries("string", ["string"]))
            list(util.findEntries("string", 1))
            list(util.findEntries("string", 1.0))
            list(util.findEntries("string", 1+1j))
            list(util.findEntries("string", ("string")))

            list(util.findEntries(False, "string"))
            list(util.findEntries(["string"], "string"))
            list(util.findEntries(1, "string"))
            list(util.findEntries(1.0, "string"))
            list(util.findEntries(1+1j, "string"))
            list(util.findEntries(("string"), "string"))

            list(util.findEntries("string", "string", lines = "string"))
            list(util.findEntries("string", "string", lines = 1.0))
            list(util.findEntries("string", "string", lines = 1+1j))
            list(util.findEntries("string", "string", lines = [1]))
            list(util.findEntries("string", "string", lines = (1)))
            list(util.findEntries("string", "string", lines = True))

            list(util.findEntries("string", "string", returnKeyword = "string"))
            list(util.findEntries("string", "string", returnKeyword = 1.0))
            list(util.findEntries("string", "string", returnKeyword =  1+1j))
            list(util.findEntries("string", "string", returnKeyword =  [True]))
            list(util.findEntries("string", "string", returnKeyword =  (True)))

    def test_values(self):
        """
        Make sure value errors are raised
        """
        with self.assertRaises(ValueError):
            list(util.findEntries("string", "string", lines = 0))
            list(util.findEntries("string", "string", lines = -1))

    def test_output(self):
        """
        Make sure output is correct
        """

        # Define test input parameter
        test_string = """Lorem ipsum
                         Lorem ipsum Polarizability derivatives wrt mode          2
                                    1             2             3
                         1   0.215860D+00  0.000000D+00  0.000000D+00
                        Lorem ipsum"""
        test_keyword = "Polarizability derivatives wrt mode"
        test_lines = 3
        test_returnKeyword = False

        # Define correct output (correct output will be type generator not list!)
        correct_output = [ ["2", "1             2             3", "1   0.215860D+00  0.000000D+00  0.000000D+00"] ]
        # Compute output
        test_output = util.findEntries(test_string, test_keyword, lines = test_lines, returnKeyword = test_returnKeyword)

        # Test output
        self.assertIsInstance(test_output, types.GeneratorType)
        self.assertListEqual(list(test_output), correct_output)
