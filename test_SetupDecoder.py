#
#   UNITTESTS
#
import unittest

from SetupDecoder import SetupDecoder

#
#   EXTERNAL LIBARIES
#
import numpy as np
import math

class TestSetupDecoder_UnitMatrix(unittest.TestCase):
    """
    Test the unitMatrix method in SetupDecoder
    """

    def test_output(self):
        """
        Check if the output is correct
        """
        self.assertEqual( SetupDecoder.unityMatrix(SetupDecoder).tolist(), np.matrix("1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1").tolist() )

class TestSetupDecoder_GeneralLinearRetarder(unittest.TestCase):
    """
    Test the generalLinearRetarder method in TestSetupDecoder
    """

    def glr(self, theta, delta):
        """
        Build mueller matrix for general linear retarder
        Takes degrees as argument!
        """
        t = math.radians(theta)
        d = math.radians(delta)
        return  np.matrix([ [1, 0                                           , 0                                             , 0                     ],
                            [0, np.cos(2*t)**2 + np.sin(2*t)**2 * np.cos(d) , np.cos(2*t)*np.sin(2*t)*(1-np.cos(d))         , np.sin(2*t)*np.sin(d) ],
                            [0, np.cos(2*t)*np.sin(2*t)*(1-np.cos(d))       , np.cos(2*t)**2 * np.cos(d) + np.sin(2*t)**2   , -np.cos(2*t)*np.sin(d)],
                            [0, -np.sin(2*t)*np.sin(d)                      , np.cos(2*t)*np.sin(d)                         , np.cos(d)             ]        ])

    def test_output(self):
        """
        Check if the output is correct
        """

        # Check if function returns correct answer for various inputs in degrees
        for t in [0, 30, 45, 60, 90, 135, 180, 210, 225, 240, 270, 315, 360]:
            for d in [0, 30, 45, 60, 90, 135, 180, 210, 225, 240, 270, 315, 360]:
                    self.assertEqual( SetupDecoder.generalLinearRetarder(SetupDecoder, t, d).tolist(), self.glr(t, d).tolist() )

    def test_values(self):
        """
        Make sure value errors are raised if necessary
        """

        self.assertRaises(ValueError, SetupDecoder.generalLinearRetarder, SetupDecoder, "string", "string")
        self.assertRaises(ValueError, SetupDecoder.generalLinearRetarder, SetupDecoder, "True", "False")
        self.assertRaises(ValueError, SetupDecoder.generalLinearRetarder, SetupDecoder, "False", "True")

    def test_types(self):
        """
        Make sure type errors are raised if necessary
        """

        self.assertRaises(TypeError, SetupDecoder.generalLinearRetarder, SetupDecoder, [1,1], [1,1])
        self.assertRaises(TypeError, SetupDecoder.generalLinearRetarder, SetupDecoder, True, False)
        self.assertRaises(TypeError, SetupDecoder.generalLinearRetarder, SetupDecoder, 1+1j, 1+1j)

class TestSetupDecoder_LinearHorizontalPolariser(unittest.TestCase):
    """
    Test the linearHorizontalPolariser method in TestSetupDecoder
    """

    def lhp(self, theta):
        """
        Build mueller martrix for linear horizontal polariser
        Takes degrees as argument!
        """
        t = math.radians(theta)

        return 0.5 * np.matrix([ [1              , np.cos(2*t)       , -np.sin(2*t)      , 0],
                                 [np.cos(2*t)    , (np.cos(4*t)+1)/2 , -np.sin(4*t)/2    , 0],
                                 [-np.sin(2*t)   , -np.sin(4*t)/2    , (-np.cos(4*t)+1)/2, 0],
                                 [0              , 0                 , 0                 , 0]    ])

    def test_output(self):
        """
        Check if output is correct
        """

        # Check if function returns correct answer for various inputs in degrees
        for t in [0, 30, 45, 60, 90, 135, 180, 210, 225, 240, 270, 315, 360]:

            # Convert matrices into 1d-lists and check every element
            for program, tester in zip( SetupDecoder.linearHorizontalPolariser(SetupDecoder, t).ravel().tolist()[0], self.lhp(t).ravel().tolist()[0] ):
                self.assertAlmostEqual( program, tester )

            # Check sizes
            self.assertEqual( SetupDecoder.linearHorizontalPolariser(SetupDecoder, t).shape, self.lhp(t).shape )

    def test_values(self):
        """
        Make sure value errors are raised if necessary
        """

        self.assertRaises(ValueError, SetupDecoder.linearHorizontalPolariser, SetupDecoder, "string")
        self.assertRaises(ValueError, SetupDecoder.linearHorizontalPolariser, SetupDecoder, "True")
        self.assertRaises(ValueError, SetupDecoder.linearHorizontalPolariser, SetupDecoder, "False")

    def test_types(self):
        """
        Make sure type errors are raised if necessary
        """

        self.assertRaises(TypeError, SetupDecoder.linearHorizontalPolariser, SetupDecoder, [1,1])
        self.assertRaises(TypeError, SetupDecoder.linearHorizontalPolariser, SetupDecoder, True)
        self.assertRaises(TypeError, SetupDecoder.linearHorizontalPolariser, SetupDecoder, 1+1j)
