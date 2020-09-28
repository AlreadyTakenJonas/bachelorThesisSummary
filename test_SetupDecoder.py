#
#   UNITTESTS
#
import unittest

# Import class that shall be tested and create an instance of it
from SetupDecoder import SetupDecoder
SetupDecoder = SetupDecoder()

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
        self.assertEqual( SetupDecoder.unitMatrix().tolist(), np.array([ [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1] ]).tolist() )
        self.assertTrue( type( SetupDecoder.unitMatrix() ) is np.ndarray )

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
        return  np.array([  [1, 0                                           , 0                                             , 0                     ],
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
                    self.assertEqual( SetupDecoder.generalLinearRetarder(t, d).tolist(), self.glr(t, d).tolist() )
                    self.assertTrue( type( SetupDecoder.generalLinearRetarder(t, d) ) is np.ndarray )

    def test_values(self):
        """
        Make sure value errors are raised if necessary
        """

        self.assertRaises(ValueError, SetupDecoder.generalLinearRetarder, "string", "string")
        self.assertRaises(ValueError, SetupDecoder.generalLinearRetarder, "True", "False")
        self.assertRaises(ValueError, SetupDecoder.generalLinearRetarder, "False", "True")

    def test_types(self):
        """
        Make sure type errors are raised if necessary
        """

        self.assertRaises(TypeError, SetupDecoder.generalLinearRetarder, [1,1], [1,1])
        self.assertRaises(TypeError, SetupDecoder.generalLinearRetarder, True, False)
        self.assertRaises(TypeError, SetupDecoder.generalLinearRetarder, 1+1j, 1+1j)

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

        return 0.5 * np.array([  [1              , np.cos(2*t)       ,  np.sin(2*t)      , 0],
                                 [np.cos(2*t)    , (np.cos(4*t)+1)/2 ,  np.sin(4*t)/2    , 0],
                                 [np.sin(2*t)    , np.sin(4*t)/2     , (-np.cos(4*t)+1)/2, 0],
                                 [0              , 0                 , 0                 , 0]    ])

    def test_output(self):
        """
        Check if output is correct
        """

        # Check if function returns correct answer for various inputs in degrees
        for t in [0, 30, 45, 60, 90, 135, 180, 210, 225, 240, 270, 315, 360]:

            # Convert matrices into 1d-lists and check every element
            for program, tester in zip( SetupDecoder.linearHorizontalPolariser(t).ravel().tolist(), self.lhp(t).ravel().tolist() ):
                self.assertAlmostEqual( program, tester )

            # Check sizes
            self.assertEqual( SetupDecoder.linearHorizontalPolariser(t).shape, self.lhp(t).shape )

            # Check type
            self.assertTrue( type(SetupDecoder.linearHorizontalPolariser(t) ) is np.ndarray )

    def test_values(self):
        """
        Make sure value errors are raised if necessary
        """

        self.assertRaises(ValueError, SetupDecoder.linearHorizontalPolariser, "string")
        self.assertRaises(ValueError, SetupDecoder.linearHorizontalPolariser, "True")
        self.assertRaises(ValueError, SetupDecoder.linearHorizontalPolariser, "False")

    def test_types(self):
        """
        Make sure type errors are raised if necessary
        """

        self.assertRaises(TypeError, SetupDecoder.linearHorizontalPolariser, [1,1])
        self.assertRaises(TypeError, SetupDecoder.linearHorizontalPolariser, True)
        self.assertRaises(TypeError, SetupDecoder.linearHorizontalPolariser, 1+1j)


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

        return 0.5 * np.array([  [1              , np.cos(2*t)       , np.sin(2*t)       , 0],
                                 [np.cos(2*t)    , (np.cos(4*t)+1)/2 , np.sin(4*t)/2     , 0],
                                 [np.sin(2*t)    , np.sin(4*t)/2     , (-np.cos(4*t)+1)/2, 0],
                                 [0              , 0                 , 0                 , 0]    ])

    def test_output(self):
        """
        Check if output is correct
        """

        # Check if function returns correct answer for various inputs in degrees
        for t in [0, 30, 45, 60, 90, 135, 180, 210, 225, 240, 270, 315, 360]:

            # Convert matrices into 1d-lists and check every element
            for program, tester in zip( SetupDecoder.linearVerticalPolariser(t).ravel().tolist(), self.lvp(t).ravel().tolist() ):
                self.assertAlmostEqual( program, tester )

            # Check sizes
            self.assertEqual( SetupDecoder.linearVerticalPolariser(t).shape, self.lvp(t).shape )

            # Check type
            self.assertTrue( type(SetupDecoder.linearVerticalPolariser(t) ) is np.ndarray )

    def test_values(self):
        """
        Make sure value errors are raised if necessary
        """

        self.assertRaises(ValueError, SetupDecoder.linearVerticalPolariser, "string")
        self.assertRaises(ValueError, SetupDecoder.linearVerticalPolariser, "True")
        self.assertRaises(ValueError, SetupDecoder.linearVerticalPolariser, "False")

    def test_types(self):
        """
        Make sure type errors are raised if necessary
        """

        self.assertRaises(TypeError, SetupDecoder.linearVerticalPolariser, [1,1])
        self.assertRaises(TypeError, SetupDecoder.linearVerticalPolariser, True)
        self.assertRaises(TypeError, SetupDecoder.linearVerticalPolariser, 1+1j)


class TestSetupDecoder_InitialStokesVector(unittest.TestCase):
    """
    Test the initialStokesVector method in SetupDecoder
    """

    def sv(self, s0, s1, s2, s3):
        """
        Build stokes vector
        """
        vector = np.array([s0, s1, s2, s3])
        if s0 != 0:
            vector = vector/s0

        return vector

    def test_output(self):
        """
        Check if output is correct
        """

        for s0 in [0, 5, 7, 10]:
            for s1 in [-10, -7, -5, 0, 5, 7, 10]:
                for s2 in [-10, -7, -5, 0, 5, 7, 10]:
                    for s3 in [-10, -7, -5, 0, 5, 7, 10]:

                        # Make sure to only input physical meaningful values
                        if s0**2 >= (s1**2 + s2**2 + s3**2):
                            self.assertAlmostEqual(SetupDecoder.initialStokesVector(s0, s1, s2, s3).all(), self.sv(s0, s1, s2, s3).all(), msg = "Input: (" + str(s0) + "," + str(s1) + "," + str(s2) + "," + str(s3) + ")")

                            self.assertTrue( type( SetupDecoder.initialStokesVector(s0, s1, s2, s3) ) is np.ndarray )

    def test_values(self):
        """
        Make sure value errors are raised if necessary
        """

        self.assertRaises(ValueError, SetupDecoder.initialStokesVector, "string", "string", "string", "string")
        self.assertRaises(ValueError, SetupDecoder.initialStokesVector, "True", "True", "True", "True")
        self.assertRaises(ValueError, SetupDecoder.initialStokesVector, "False", "False", "False", "False")
        self.assertRaises(ValueError, SetupDecoder.initialStokesVector, -1, 0, 0, 0)
        self.assertRaises(ValueError, SetupDecoder.initialStokesVector, 1, 10, 0, 0)

    def test_types(self):
        """
        Make sure type errors are raised if necessary
        """

        self.assertRaises(TypeError, SetupDecoder.initialStokesVector, [1,1,1,1])
        self.assertRaises(TypeError, SetupDecoder.initialStokesVector, True, True, True, True)
        self.assertRaises(TypeError, SetupDecoder.initialStokesVector, 1+1j, 1+1j, 1+1j, 1+1j)


class TestSetupDecoder_attenuatingFilter(unittest.TestCase):
    """
    Test the attenuatingFilter method in SetupDecoder
    """

    def flr(self, transmission):
        """
        Build mueller matrix for filters
        """
        return transmission * np.array([ [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1] ])

    def test_output(self):
        """
        Make sure output is correct
        """

        for t in [0, 0.1, 0.2, 0.5, 0.7, 1]:
            self.assertEqual( SetupDecoder.attenuatingFilter(t).tolist(), self.flr(t).tolist() )
            self.assertTrue( type(SetupDecoder.attenuatingFilter(t)) is np.ndarray )

    def test_values(self):
        """
        Make sure a value error is raised if necessary
        """

        self.assertRaises(ValueError, SetupDecoder.attenuatingFilter, "string")
        self.assertRaises(ValueError, SetupDecoder.attenuatingFilter, "True")
        self.assertRaises(ValueError, SetupDecoder.attenuatingFilter, "False")
        self.assertRaises(ValueError, SetupDecoder.attenuatingFilter, -1)
        self.assertRaises(ValueError, SetupDecoder.attenuatingFilter,  2)

    def test_types(self):
        """
        Make sure type errors are raised if necessary
        """

        self.assertRaises(TypeError, SetupDecoder.attenuatingFilter, 1+1j)
        self.assertRaises(TypeError, SetupDecoder.attenuatingFilter, True)
        self.assertRaises(TypeError, SetupDecoder.attenuatingFilter, [1,1])


class TestSetupDecoder_HalfWavePlate(unittest.TestCase):
    """
    Test the halfWavePlate method in SetupDecoder
    """

    def hwp(self, theta):
        """
        Build mueller matrix
        Angles are passed as degrees!
        """

        t = math.radians(theta)

        return np.array([   [1,	        0	,       0	    ,    0],
                            [0,	 np.cos(4*t),	 np.sin(4*t),	 0],
                            [0,	 np.sin(4*t),	-np.cos(4*t),	 0],
                            [0,	        0	,       0	    ,   -1]  ])

    def test_output(self):
        """
        Make sure output is correct
        """

        for t in [0, 30, 45, 60, 90, 135, 180, 210, 225, 240, 270, 315, 360]:

            # Convert matrices into 1d-lists and check every element
            for program, tester in zip( SetupDecoder.halfWavePlate(t).ravel().tolist(), self.hwp(t).ravel().tolist() ):
                self.assertAlmostEqual( program, tester )

            # Check sizes
            self.assertEqual( SetupDecoder.halfWavePlate(t).shape, self.hwp(t).shape )

            # Check type
            self.assertTrue( type(SetupDecoder.halfWavePlate(t)) is np.ndarray )

    def test_values(self):
        """
        Make sure value errors are raised if necessary
        """

        self.assertRaises(ValueError, SetupDecoder.halfWavePlate, "string")
        self.assertRaises(ValueError, SetupDecoder.halfWavePlate, "True")
        self.assertRaises(ValueError, SetupDecoder.halfWavePlate, "False")

    def test_type(self):
        """
        Make sure type errors are raised if necessary
        """

        self.assertRaises(TypeError, SetupDecoder.halfWavePlate, [1,1])
        self.assertRaises(TypeError, SetupDecoder.halfWavePlate, True)
        self.assertRaises(TypeError, SetupDecoder.halfWavePlate, False)
        self.assertRaises(TypeError, SetupDecoder.halfWavePlate, 1+1j)

class TestSetupDecoder_QuarterWavePlate(unittest.TestCase):
    """
    Test the quarterWavePlate method in SetupDecoder
    """

    def qwp(self, theta):
        """
        Build mueller matrix
        Angles are passed as degrees!
        """

        t = math.radians(theta)

        return np.array([   [1,	             0      ,	              0   ,	            0],
                            [0,	(np.cos(4*t)+1)/2   ,	     np.sin(4*t)/2,   np.sin(2*t)],
                            [0,	    np.sin(4*t)/2   ,	(-np.cos(4*t)+1)/2,	 -np.cos(2*t)],
                            [0,	     -np.sin(2*t)   ,	       np.cos(2*t),	            0]  ])

    def test_output(self):
        """
        Make sure output is correct
        """

        for t in [0, 30, 45, 60, 90, 135, 180, 210, 225, 240, 270, 315, 360]:

            # Convert matrices into 1d-lists and check every element
            for program, tester in zip( SetupDecoder.quarterWavePlate(t).ravel().tolist(), self.qwp(t).ravel().tolist() ):
                self.assertAlmostEqual( program, tester )

            # Check sizes
            self.assertEqual( SetupDecoder.quarterWavePlate(t).shape, self.qwp(t).shape )

            # Check type
            self.assertTrue( type(SetupDecoder.quarterWavePlate(t)) is np.ndarray )

    def test_values(self):
        """
        Make sure value errors are raised if necessary
        """

        self.assertRaises(ValueError, SetupDecoder.quarterWavePlate, "string")
        self.assertRaises(ValueError, SetupDecoder.quarterWavePlate, "True")
        self.assertRaises(ValueError, SetupDecoder.quarterWavePlate, "False")

    def test_type(self):
        """
        Make sure type errors are raised if necessary
        """

        self.assertRaises(TypeError, SetupDecoder.quarterWavePlate, [1,1])
        self.assertRaises(TypeError, SetupDecoder.quarterWavePlate, True)
        self.assertRaises(TypeError, SetupDecoder.quarterWavePlate, False)
        self.assertRaises(TypeError, SetupDecoder.quarterWavePlate, 1+1j)

class TestSetupDecoder_RotateMatrix(unittest.TestCase):
    """
    Test the rotateMatrix method in SetupDecoder
    """

    def rotate(self, angle, matrix):
        """
        Rotate matrix by a certain angle in degrees
        """

        # Convert angle to radians
        a = math.radians(angle)
        # Declare rotation matrix
        rotationMatrix = lambda angle : np.array([  [1, 0               , 0              , 0],
                                                    [0, np.cos(2*angle) ,-np.sin(2*angle), 0],
                                                    [0, np.sin(2*angle) , np.cos(2*angle), 0],
                                                    [0, 0               , 0              , 1]   ])

        return rotationMatrix(a) @ matrix @ rotationMatrix(-a)

    def test_output(self):
        """
        Make sure the output is correct
        """

        # Build matrix to rotate
        m = np.array([ [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1] ])

        for a in [0, 30, 45, 60, 90, 135, 180, 210, 225, 240, 270, 315, 360, -30, -45, -60, -90, -135, -180, -210, -225, -240, -270, -315, -360]:

            # Convert matrices into 1d-lists and check every element
            for program, tester in zip( SetupDecoder.rotateMatrix(a, m).ravel().tolist(), self.rotate(a, m).ravel().tolist() ):
                self.assertAlmostEqual( program, tester )

            # Check sizes
            self.assertEqual( SetupDecoder.rotateMatrix(a, m).shape, self.rotate(a, m).shape )

            # Check type
            self.assertTrue( type(SetupDecoder.rotateMatrix(a, m)) is np.ndarray )

    def test_values(self):
        """
        Make sure value errors are raised if necessary
        """

        self.assertRaises(ValueError, SetupDecoder.rotateMatrix, 0, np.array([ [1, 0, 0], [0, 1, 0], [0, 0, 1] ]))
        self.assertRaises(ValueError, SetupDecoder.rotateMatrix, 0, np.array([ [1, 0, 0, 0, 0], [0, 1, 0, 0, 0], [0, 0, 1, 0, 0], [0, 0, 0, 1, 0], [0, 0, 0, 0, 1] ]))

    def test_types(self):
        """
        Make sure type errors are raised if necessary
        """

        self.assertRaises(TypeError, SetupDecoder.rotateMatrix, 1+1j,       np.array([ [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1] ]))
        self.assertRaises(TypeError, SetupDecoder.rotateMatrix, "string",   np.array([ [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1] ]))
        self.assertRaises(TypeError, SetupDecoder.rotateMatrix, True,       np.array([ [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1] ]))
        self.assertRaises(TypeError, SetupDecoder.rotateMatrix, False,      np.array([ [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1] ]))
        self.assertRaises(TypeError, SetupDecoder.rotateMatrix, "True",     np.array([ [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1] ]))
        self.assertRaises(TypeError, SetupDecoder.rotateMatrix, "False",    np.array([ [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1] ]))
        self.assertRaises(TypeError, SetupDecoder.rotateMatrix, [1,1],      np.array([ [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1] ]))
        self.assertRaises(TypeError, SetupDecoder.rotateMatrix, 0, np.matrix([ [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1] ]))
        self.assertRaises(TypeError, SetupDecoder.rotateMatrix, 0, 0)
        self.assertRaises(TypeError, SetupDecoder.rotateMatrix, 0, "string")
        self.assertRaises(TypeError, SetupDecoder.rotateMatrix, 0, "True")
        self.assertRaises(TypeError, SetupDecoder.rotateMatrix, 0, "False")
        self.assertRaises(TypeError, SetupDecoder.rotateMatrix, 0, True)
        self.assertRaises(TypeError, SetupDecoder.rotateMatrix, 0, False)
        self.assertRaises(TypeError, SetupDecoder.rotateMatrix, 0, 1.0)
        self.assertRaises(TypeError, SetupDecoder.rotateMatrix, 0, 1+1j)

class TestSetupDecoder_Decode(unittest.TestCase):
    """
    Test the decode method in SetupDecoder
    """

    # Test input file to test decode functions with wrong parameters
    valueErrorInput = """GLR string string
                         GLR True True
                         GLR False False
                         GLR 1+1j 1+1j
                         GLR [1,1] [1,1]
                         LHP string
                         LHP True
                         LHP False
                         LHP 1+1j
                         LHP [1,1]
                         LVP string
                         LVP True
                         LVP False
                         LVP 1+1j
                         LVP [1,1]
                         LSR string string string string
                         LSR True True True True
                         LSR False False False False
                         LSR 1+1j 1+1j 1+1j 1+1j
                         LSR [1,1] [1,1] [1,1] [1,1]
                         LSR -1 0 0 0
                         LSR 0 1 1 1
                         FLR string
                         FLR True
                         FLR False
                         FLR -1
                         FLR 2
                         HWP string
                         HWP True
                         HWP False
                         QWP string
                         QWP True
                         QWP False
                      """.splitlines()
    # Remove empty lines and leading white spaces
    valueErrorInput = [line.lstrip() for line in valueErrorInput if line.lstrip()]

    # Test input file to test decode functions with wrong number of parameters
    typeErrorInput = """GLR 0
                        GLR 0 0 0
                        LHP 0 0
                        LVP 0 0
                        LSR 0 0 0
                        LSR 0 0 0 0 0
                        FLR
                        FLR 0 0
                        HWP 0 0
                        HWP
                        QWP 0 0
                        QWP
                        NOP 0
                     """.splitlines()
    # Remove empty lines and leading white spaces
    typeErrorInput = [line.lstrip() for line in typeErrorInput if line.lstrip()]

    def test_keys(self):
        """
        Make sure key errrors are raised if necessary
        """

        self.assertRaises(KeyError, SetupDecoder.decode, "FakeCommand")

    def test_values(self):
        """
        Make sure value error are raised if necessary
        """

        self.assertRaises(ValueError, SetupDecoder.decode, "")
        self.assertRaises(ValueError, SetupDecoder.decode, "     ")

        for line in self.valueErrorInput:
            with self.assertRaises(ValueError, msg = "No error while testing SetupDecoder.decode('" + line + "')"):
                SetupDecoder.decode(line)

    def test_types(self):
        """
        Make sure type error are raised if necessary
        """

        self.assertRaises(TypeError, SetupDecoder.decode, 1)
        self.assertRaises(TypeError, SetupDecoder.decode, 1.0)
        self.assertRaises(TypeError, SetupDecoder.decode, True)
        self.assertRaises(TypeError, SetupDecoder.decode, False)
        self.assertRaises(TypeError, SetupDecoder.decode, 1+1j)
        self.assertRaises(TypeError, SetupDecoder.decode, ["str", "str"])
        self.assertRaises(TypeError, SetupDecoder.decode, [1, 1])

        for line in self.typeErrorInput:
            with self.assertRaises(TypeError, msg = "No error while testing SetupDecoder.decode('" + line + "')"):
                SetupDecoder.decode(line)
