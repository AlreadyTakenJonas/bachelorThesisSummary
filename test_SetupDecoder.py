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
    Test the linearHorizontalPolariser method in SetupDecoder
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


class TestSetupDecoder_LinearVerticalPolariser(unittest.TestCase):
    """
    Test the linearVerticalPolariser method in SetupDecoder
    """

    def lvp(self, theta):
        """
        Build mueller martrix for linear vertical polariser
        Takes degrees as argument!
        Returns the matrix of a linear horizontal polariser with an angle of theta+90°
        """
        t = math.radians(theta + 90)

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
            for program, tester in zip( SetupDecoder.linearVerticalPolariser(SetupDecoder, t).ravel().tolist()[0], self.lvp(t).ravel().tolist()[0] ):
                self.assertAlmostEqual( program, tester )

            # Check sizes
            self.assertEqual( SetupDecoder.linearVerticalPolariser(SetupDecoder, t).shape, self.lvp(t).shape )

    def test_values(self):
        """
        Make sure value errors are raised if necessary
        """

        self.assertRaises(ValueError, SetupDecoder.linearVerticalPolariser, SetupDecoder, "string")
        self.assertRaises(ValueError, SetupDecoder.linearVerticalPolariser, SetupDecoder, "True")
        self.assertRaises(ValueError, SetupDecoder.linearVerticalPolariser, SetupDecoder, "False")

    def test_types(self):
        """
        Make sure type errors are raised if necessary
        """

        self.assertRaises(TypeError, SetupDecoder.linearVerticalPolariser, SetupDecoder, [1,1])
        self.assertRaises(TypeError, SetupDecoder.linearVerticalPolariser, SetupDecoder, True)
        self.assertRaises(TypeError, SetupDecoder.linearVerticalPolariser, SetupDecoder, 1+1j)


class TestSetupDecoder_InitialStokesVector(unittest.TestCase):
    """
    Test the initialStokesVector method in SetupDecoder
    """

    def sv(self, s0, s1, s2, s3):
        """
        Build stokes vector
        """
        return np.array([s0, s1, s2, s3])/s0

    def test_output(self):
        """
        Check if output is correct
        """

        for s0 in [-10, -7, -5, 0, 5, 7, 10]:
            for s1 in [-10, -7, -5, 0, 5, 7, 10]:
                for s2 in [-10, -7, -5, 0, 5, 7, 10]:
                    for s3 in [-10, -7, -5, 0, 5, 7, 10]:
                        self.assertAlmostEqual( SetupDecoder.initialStokesVector(SetupDecoder, s0, s1, s2, s3).all(), self.sv(s0, s1, s2, s3).all() )

    def test_values(self):
        # TODO
        pass

    def test_types(self):
        # TODO
        pass
