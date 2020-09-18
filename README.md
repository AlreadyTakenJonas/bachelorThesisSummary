# Raman Scattering Of Linear Polarised Light With PolaRam

The program PolaRam simulates the behaviour of linear and fully polarised light with the mueller formalism and stokes vectors. The simulation contains the raman scattering process with a custom sample and the optical elements like like attenuating filters, wave plates and linear retarders. The polarisation state and polarisation change of the scattered laser light is simulated as matrix multiplication of stokes vectors (polarisation state) and mueller matrices (polarisation change due to optical elements or sample).

The program needs a file with instructions and a file with the raman tensors of the sample. The instructions file describes the experimental setup that shall be simulated. The syntax is assembly like and described below. The raman tensors are stored in a seperate file with a specific format and coordinate system also described below.

The sub-program carrying out the simulation is called `polaram simulate`. There are two more sub-programs helping with data and file conversion: `polaram convert`and `polaram extract`. More information below.

Table of Contents
=================

   * [Raman Scattering Of Linear Polarised Light With PolaRam](#raman-scattering-of-linear-polarised-light-with-polaram)
   * [simulate: Simulation of Raman Scattering Of Linear Polarised Light](#simulate-simulation-of-raman-scattering-of-linear-polarised-light)
      * [Usage](#usage)
      * [The Input Files](#the-input-files)
         * [Instruction File](#instruction-file)
         * [Raman Tensor File](#raman-tensor-file)

# simulate: Simulation Of Raman Scattering Of Linear Polarised Light

The simulation works by describing the state of the polarisation as a four dimensional stokes vector *S* and every optical element and the sample as 4x4 mueller matrices *M*. Applying *M* to *S* will give the new state of the system when the light interacts with the optical element. Every command in the input file descibes a mueller matrix that will be applied to the system one after another. The `LSR` command is special, because it describes the initial stokes vector.

The simulation takes the raman tensor describing the sample as 3x3 matrix. Therefore the raman tensor is not compatible with the mueller formalism. To solve this problem the raman tensor will be transformed into a mueller matrix. The transformation will be explained in a seperate pdf-file (WORK IN PROGRESS).
It is possible to pass multiple raman tensors to the simulation at once. There is a raman tensor for every vibrational mode of the sample and all of them can be simulated in parallel. Make sure to give each raman tensor a describtive title in the raman tensor file. More details about the input files are given below.

This simulation is only looking at raman scattering at an angle of 180°. And at the current moment does it only support light with a polarisation grade *Π* of one. Circular polarisation can't be simulated in combination with the raman scattering process. All other optical elements do support circular polarisation.
These assumptions are the basis of the raman-tensor-to-mueller-matrix-conversion described in a seperate pdf-file (WORK IN PROGRESS). Details and definitions of the coordinate systems are given in a seperate pdf-file (WORK IN PROGRESS).

## Planned Features
+ Implement conversion of 3x3 raman tensor into 4x4 mueller matrix

## Usage

The simulation is started by typing `polaram simulate PATH_TO_INPUT_FILE`. The command `polaram simulate -h` echos a help text. This command prints the following output:
```
$ polaram simulate -h
usage: polaram simulate [-h] [-v] [-l LOGFILE] [-m MATRIXFILE] [-o OUTPUTFILE]
                        [-c [COMMENT [COMMENT ...]]]
                        inputfile

This program simulates the influence of a raman active sample and the optical
elements of the measurement setup on the polarisation of the laser. The
calculations are performed with the mueller calculus and stokes vectors.

positional arguments:
  inputfile             text file containing the labratory setup that needs to
                        be simulated. Details are given in the README.

optional arguments:
  -h, --help            show this help message and exit
  -v, --verbose         runs programm and shows status and error messages
  -l LOGFILE, --log LOGFILE
                        defines path and name of a custom .log file.
                        Default=PROGRAMPATH/log/muellersimulation.log
  -m MATRIXFILE, --matrix MATRIXFILE
                        text file containing the raman matrices of the sample
                        in the labratory cordinate system. Details are given
                        in the README.
  -o OUTPUTFILE, --output OUTPUTFILE
                        path to output file.
                        Default=PROGRAMMPATH/res/muellersimulation.txt
  -c [COMMENT [COMMENT ...]], --comment [COMMENT [COMMENT ...]]
                        comment that will be added to the output file
```
The simulation will print its results in a file and on the screen. The file can be specified by the `-o/--output` option.

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
`SMP`       | raman scattering sample     | 0                   | This command will cause the simulation program to use the raman tensors given via CLI in the next simulation step. If none is given, the unity matrix will be read from file `PolaRam/unitmatrix.txt`. WIP: The raman tensor will be converted into a mueller matrix.
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

The raman tensor file contains all matrices, that describe the raman scattering properties of every mode of the sample. It may contain comment lines, marked with `#`, and 3x3 matrices. Comments will be ignored. Anything else will cause the program to misbehave or raise an exception. Matrices are written as four lines of code. The first line marks the beginning of the matrix with the `!` character. The following character will be saved as descriptive name of the matrix. The other three lines contain the rows of the raman tensor. Every line must contain three elements seperated by a space.
A valid tensor file might look like this:
```
# Some descriptive comment

! v_1 = 216.2523/cm
-0.00634609 -0.0166743   0.02670877
-0.0166743  -0.03183306  0.0195725 
 0.02670877  0.0195725   0.03817915

! v_2 = 216.2523/cm
-0.05350382  0.00476986 -0.00417874
 0.00476986  0.01253425 -0.07968738
-0.00417874 -0.07968738  0.04096966
```

# convert: Matrix Transformation Between Molecular And Labratory Coordinate System

The sub-command `convert` will run a Monte-Carlo-Simulation on a list of 3x3 matrices given via CLI. The purpose of the simulation is the conversion of a raman tensor from the molecular coordinate system - which can be calculated by Gaussian and similar programs - into the labratory coordinate system of the Mueller-Simulation the `simulate` program performs. It is assumed that the sample is in a solved state so that each molecule is free to rotate. The effective raman tensor incoming light will experience is therefore the mean of all possible rotations of the molecular raman tensor. The Monte-Carlo-Simulation will calculate this mean by rotating the molecular raman tensor by random angles.

## Planned Features
+ Self-check of the simulation by comparing the depolarisation ratio *ρ* 

## Usage

The conversion is started by typing `polaram convert PATH_TO_TENSOR_FILE`. The command `polaram convert -h` echos a help text. This command prints the following output:
```
$ polaram convert -h
usage: polaram convert [-h] [-v] [-l LOGFILE] [-i ITERATIONLIMIT]
                       [-o OUTPUTFILE] [-c [COMMENT [COMMENT ...]]]
                       [-p PROCESSCOUNT] [-s CHUNKSIZE]
                       tensorfile

Converts raman tensors from the molecular coordinate system into the raman
matrix of a solution in the labratory coordinate system via a monte carlo
simulation.

positional arguments:
  tensorfile            text file containing the raman tensors that will be
                        converted. Details are given in the README.

optional arguments:
  -h, --help            show this help message and exit
  -v, --verbose         runs programm and shows status and error messages
  -l LOGFILE, --log LOGFILE
                        defines path and name of a custom .log file.
                        Default=PROGRAMPATH/log/convertRamanTensor.log
  -i ITERATIONLIMIT, --iterations ITERATIONLIMIT
                        number of iterations the simulation will calculate.
                        Default = 1000000
  -o OUTPUTFILE, --output OUTPUTFILE
                        path to output file.
                        Default=PROGRAMMPATH/res/labratoryTensor.txt
  -c [COMMENT [COMMENT ...]], --comment [COMMENT [COMMENT ...]]
                        comment that will be added to the output file
  -p PROCESSCOUNT, --processes PROCESSCOUNT
                        number of processes that compute in parallel.
                        Default=2
  -s CHUNKSIZE, --cunksize CHUNKSIZE
                        Length of array each subprocess is given to calculate.
                        Default=500
```
The conversion will print the results as a file and on screen in the same format as the input file. This format can be understood by the `simulate` sub-program.

The important parameter of the Monte-Carlo-Simulation are the chunk size, the process count and the iteration limit. The simulation should run reasonably fast with the default settings, but they can be adjusted via the CLI.
+ The iteration limit determines the amount of random rotations the simulation will do to determine the labratory raman matrix. The higher the iteration limit the longer it will compute and the better is the accuracy of the result.
+ Multi-processing was implemented to increase the computation speed. The process count sets the amount of processes computing the matrix rotations in parallel. In addition to these subprocesses the main process does its part. The main process takes the results of the subprocesses and adds them up. Increasing the process count will increase the computation speed. However, if the are not enough processor cores to match the number of running processes, the computation speed might decrease.
+ The cunk size is also a feature of the multi-processing. The simulation will be prepared by creating a generator containing random rotation angles for every iteration of the simulation. The cunk size determines how many of these random rotation angles will be passed to each subprocess at once. The chunk size is a compromise between the time it takes to pipe the data between processes and to the time it takes to start a new one. Changing the chunk size might increase or decrease the computation speed.

## The Input File
The input file for the `convert` sub-program is the same as the format of the [raman tensor file](#raman-tensor-file) the `simulate` command expects.
