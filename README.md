# Raman Scattering Of Linear Polarised Light

This python3 script simulates the behaviour of linear and fully polarised light with the mueller formalism and stokes vectors. The simulation contains the raman scattering process with a custom sample and the optical elements like like attenuating filters, wave plates and linear retarders. The polarisation state and polarisation change of the scattered laser light is simulated as matrix multiplication of stokes vectors (polarisation state) and mueller matrices (polarisation change due to optical elements or sample).

The program needs a file with instructions and a file with the raman tensors of the sample. The instructions file describes the experimental setup that shall be simulated. The syntax is assembly like and described below. The raman tensors are stored in a seperate file with a specific format and coordinate system also described below.

## Planned Features

* Monte-Caro-simulation to derive raman tensors for solutions from the molecular raman tensor
* Implementation of raman tensors with automatic conversion from molecular coordinate system to labratory coordinate system

## Usage

The simulation is started by typing `python3 main.py PATH_TO_INPUT_FILE`. The command `python3 main.py -h` echos a help text. This command prints the following output:
```
$ python3 main.py -h
usage: main.py [-h] [-v] [-l LOGFILE] inputfile

This program simulates the influence of a raman active sample and the optical
elements of the measurement setup on the polarisation of the laser. The
calculation are performed with the mueller calculus and stokes vectors.

positional arguments:
  inputfile             text file containing the labratory setup that needs to
                        be simulated. Details are given in the README.

optional arguments:
  -h, --help            show this help message and exit
  -v, --verbose         runs programm and shows status and error messages
  -l LOGFILE, --logfile LOGFILE
                        defines path and name of a custom .log file.
                        Default=./muellersimulation.log

Author: Jonas Eichhorn; License: MIT; Date: Sep.2020
```

## The Input Files

There are two input file the simulation needs: the input file and the raman tensor file. The input file is also called the instruction file.

### Instruction File

The instruction file is structured like assembly code. It describes the labratory setup with all optical elements, initial light polarisation and sample. Every instruction needs to be written in its own line and the instruction and its arguments are seperated by a space. The following instructions are implemented.

instruction | optical element             | number of arguments | describtion
:----------:|:---------------------------:|:-------------------:|:----------:
`LSR s`     | initial laser polarisation  | 4                   | This instruction defines the initial polarisation state of the laser and takes four float numbers as input: s<sub>0</sub>, s<sub>1</sub>, s<sub>2</sub> and s<sub>3</sub>. The input must be a valid stokes vector for a linear, fully polarised state. The sqare sum of the last three components must equal the square of the first component. The first component must be zero or positve and the last component must be zero. For more details research stokes parameters. If the instruction is not used, the stokes vector defaults to zero and every call of `LSR` overrides the current state of the simulation.
`GLR θ δ`   | general linear retarder     | 2                   | This element is the generalised form of a wave plate and takes the two angles θ and δ in degrees as input. δ characterises the phase shift between E<sub>x</sub> and E<sub>y</sub> and θ is the angle between the fast axis of the GLR and the x-axis of the labratory coordinate system.
`HWP θ`     | half wave plate             | 1                   | Shortcut for `GLR θ 180`.
`QWP θ`     | quarter wave plate          | 1                   | Shortcut for `GLR θ 90`.
`LHP θ`     | linear horizontal polariser | 1                   | This polariser accepts the optional angle θ in degrees. θ rotates the linear polariser in the x-y-plane of the labratory coordinate system counter-clockwise. θ defaults to zero and aligns the polariser with the x-axis of the labratory coordinate system.
`LVP θ`     | linear vertical polariser   | 1                   | This polariser accepts the optional angle θ in degrees. θ rotates the linear polariser in the x-y-plane of the labratory coordinate system counter-clockwise. θ defaults to zero and aligns the polariser with the y-axis of the labratory coordinate system.
`SMP`       | raman scattering sample     | 0                   | UNDER CONSTRUCTION (ACTS AS UNITY MATRIX FOR NOW)
`FLR t`     | attenuating filter          | 1                   | The attenuating filter accepts the transmission t as argument. t must be a value between zero and one (including both) and describes the percentage of light that can pass the filter.
`NOP`       | no operation                | 0                   | Returns unity matrix.
`#`         | comment                     | ∞                   | This instruction ignores all its arguments and will cause the simulation to perform a `NOP`.

The following example might help to make the syntax clearer.
```
# This is a comment
# Initialise polarisation horazontally
LSR 1 1 0 0
# Measure the sample
SMP
# Observe only the vertical polarised part
LVP
# Reduce laser intensity
FLR 0.25
# END OF SIMULATION
```
### Raman Tensor File

UNDER CONSTRUCTION
