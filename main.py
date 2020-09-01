#
#   EXTERNAL LIBARIES
#

# Purpose: Math
import numpy as np

#
#   DEFINE Mueller Matrices
#

# Linear Polariser (horizontal transmission)
LPH = 0.5 * np.matrix("1 1 0 0;     1 1 0 0;    0 0 0 0;    0 0 0 0")
# Linear Polariser (vertical transmission)
LPV = 0.5 * np.matrix("1 -1 0 0;     -1 1 0 0;    0 0 0 0;    0 0 0 0")

# General Linear Retarder (general form for wave plates)
# Angles in radiants
def GLR(phaseShift, axisAngle):
    cosTwoAngle = np.cos(2*axisAngle)
    sinTwoAngle = np.sin(2*axisAngle)
    cosShift = np.cos(phaseShift)
    sinShift = np.sin(phaseShift)
    waveplate = np.matrix([ [1, 0, 0, 0],
                            [0, cosTwoAngle**2 + sinTwoAngle**2 * cosShift, cosTwoAngle*sinTwoAngle*(1-cosShift), sinTwoAngle*sinShift],
                            [0, cosTwoAngle*sinTwoAngle*(1-cosShift), cosTwoAngle**2 * cosShift + sinTwoAngle**2, -cosTwoAngle*sinShift],
                            [0, -sinTwoAngle*sinShift, cosTwoAngle*sinShift, cosShift]
                        ])
    return waveplate

#
# MAIN PROGRAMM
#
def main():
    print(LPH)
    print(LPV)
    print(GLR(np.pi/2, np.pi/2))
    pass


#
#   START OF PROGRAMM
#
if __name__ == "__main__":
    main()
