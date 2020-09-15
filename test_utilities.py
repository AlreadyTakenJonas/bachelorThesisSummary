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

class TestUtilities_ElectricalFieldToStokes(unittest.TestCase):
    """
    Test utilities.electricalFieldToStokes
    """
    def test_types(self):
        """
        Make sure type errors are raised
        """
        with self.assertRaises(TypeError):
            util.electricalFieldToStokes([1])
            util.electricalFieldToStokes(1)
            util.electricalFieldToStokes((1))
            util.electricalFieldToStokes(np.array(["s", "s", "s"]))
            util.electricalFieldToStokes(np.array([True, True, True]))
            util.electricalFieldToStokes(np.array([1+1j, 1+1j, 1+1j]))
            util.electricalFieldToStokes(np.array([1,1]))
            util.electricalFieldToStokes(np.array([1,1,1,1]))

    def test_values(self):
        """
        Make sure value errors are raised
        """
        # Electrical field along z-axis should raise an error
        self.assertRaises(ValueError, util.electricalFieldToStokes, np.array([1, 1, 1]))

    def test_output(self):
        """
        Make sure output is correct
        """
        # Define correct output
        stokes = lambda Ex, Ey : np.array([ Ex**2 + Ey**2,
                                            Ex**2 - Ey**2,
                                            2*Ex*Ey      ,
                                            0               ]).tolist()

        # Test function
        for i in [(0,0), (1,1), (1,0), (0,1), (-1,1), (1,-1), (-1,-1), (0,-1), (-1,0), (0.5,0.8), (0.2,1.2)]:
            test = np.array([i[0], i[1], 0])
            self.assertListEqual( util.electricalFieldToStokes(test).tolist(), stokes(i[0], i[1]) )

class TestUtilities_StokesToElectricalField(unittest.TestCase):
    """
    Test utilities.stokesToElectricalField
    """
    def test_types(self):
        """
        Make sure type errors are raised
        """
        with self.assertRaises(TypeError):
            util.stokesToElectricalField([1])
            util.stokesToElectricalField(1)
            util.stokesToElectricalField((1))
            util.stokesToElectricalField(np.array(["s", "s", "s", "s"]))
            util.stokesToElectricalField(np.array([True, True, True, True]))
            util.stokesToElectricalField(np.array([1+1j, 1+1j, 1+1j, 1+1j]))
            util.stokesToElectricalField(np.array([1,1,1]))
            util.stokesToElectricalField(np.array([1,1,1,1.1]))

    def test_values(self):
        """
        Make sure value errors are raised
        """
        # Circular polarised light can't be converted
        self.assertRaises(ValueError, util.stokesToElectricalField, np.array([2, 1, 1, 1]))
        # The polarisation grade can't be greater than one
        self.assertRaises(ValueError, util.stokesToElectricalField, np.array([0, 1, 1, 0]))
        # There is no formula to convert parially polarised light with a diagonially polarised component
        self.assertRaises(ValueError, util.stokesToElectricalField, np.array([1, 0.5, 0.5, 0]))

    def test_output(self):
        """
        Make sure output is correct
        """
        # Define conversion for polarisation along x- and y-axis
        convertSimpleCase = lambda stokes: np.array([ np.sqrt( 0.5 * (stokes[0] + stokes[1]) ),
                                                      np.sqrt( 0.5 * (stokes[0] - stokes[1]) ),
                                                                        0                       ])
        # Define conversion for polarisation along x-, y-axis and 45°/135° angle
        convertComplexCase = lambda stokes: np.array([      stokes[2] / np.sqrt( 2*(stokes[0] - stokes[1]) )  ,
                                                       abs( stokes[2] / np.sqrt( 2*(stokes[0] + stokes[1]) ) ),
                                                                                0                               ])

        # Define positive values to plug in function
        valuesPositive = [0, 0.2, 0.5, 0.7, 1, 1.2, 1.5, 1.7, 2]
        # Create list containing all elements of valuesPositive twice. One positive and one negative copy
        values         = [y for x in [[-i, i] for i in valuesPositive] for y in x]
        # Plug all values that raise no exception into function
        for s0 in valuesPositive:
            for s1 in values:
                for s2 in values:
                    stokes = np.array([s0, s1, s2, 0])

                    if s2 != 0 and s0**2 == s1**2 + s2**2:
                        # Test for light with diagonal polarisation component
                        self.assertListEqual(util.stokesToElectricalField(stokes).tolist(), convertComplexCase(stokes).tolist())
                    elif s2 == 0 and s0**2 >= s1**2 + s2**2:
                        # Test for light with no diagonal polarisation component
                        self.assertListEqual(util.stokesToElectricalField(stokes).tolist(), convertSimpleCase(stokes).tolist())

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
