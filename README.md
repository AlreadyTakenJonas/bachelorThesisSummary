# Raman Scattering Of Linear Polarised Light With PolaRam

The program PolaRam simulates the behaviour of polarised light with the mueller formalism and stokes vectors. The simulation contains the raman scattering process with a custom sample and the optical elements like attenuating filters, wave plates and linear retarders. The polarisation state and polarisation change of the scattered laser light is simulated as matrix multiplication of stokes vectors (polarisation state) and mueller matrices (polarisation change due to optical elements or sample). Due to mathematical issues this simulation does only support linear and completely polarised light in combination with the raman scattering process. More information on that in the [section](#instruction-file) below. 

The program needs a file with instructions and a file with the raman tensors of the sample. The instructions file describes the experimental setup that shall be simulated. The syntax is assembly like and described below. The raman tensors are stored in a seperate file with a specific format and coordinate system also described below.

The sub-program carrying out the simulation is called `polaram simulate`. There are two more sub-programs helping with data and file conversion: `polaram convert`and `polaram extract`. More information below.

Table of Contents
=================
   * [Raman Scattering Of Linear Polarised Light With PolaRam](#raman-scattering-of-linear-polarised-light-with-polaram)
   * [Table of Contents](#table-of-contents)
   * [simulate: Simulation Of Raman Scattering Of Linear Polarised Light](#simulate-simulation-of-raman-scattering-of-linear-polarised-light)
      * [Usage](#usage)
      * [The Input Files](#the-input-files)
         * [Instruction File](#instruction-file)
         * [Raman Mueller Matrix File](#raman-mueller-matrix-file)
   * [convert: Matrix Transformation Between Molecular And Labratory Coordinate System](#convert-matrix-transformation-between-molecular-and-labratory-coordinate-system)
      * [Usage](#usage-1)
      * [The Input File](#the-input-file)
   * [extract: Reading Log-Files Of Quantum Calculations](#extract-reading-log-files-of-quantum-calculations)
      * [Usage](#usage-2)
      * [The Input File](#the-input-file-1)
   * [Supplementary code: utilities and SetupDecoder](#supplementary-code-utilities-and-setupdecoder)

# simulate: Simulation Of Raman Scattering Of Linear Polarised Light

The simulation works by describing the state of the polarisation as a four dimensional stokes vector *S* and every optical element and the sample as 4x4 mueller matrices *M*. Applying *M* to *S* will give the new state of the system when the light interacts with the optical element. Every command in the input file descibes a mueller matrix that will be applied to the system one after another. The `LSR` command is special, because it describes the initial stokes vector.

The simulation takes the raman mueller matrix describing the sample as 4x4 matrix. However, this matrix is unknown, but the raman tensor can be calculated or measured. The raman tensor is a 3x3 matrix and therefore not compatible with the mueller formalism. To solve this problem the raman tensor will be transformed into a mueller matrix. The `convert` subprogram will handle this transformation. Due to the mathematics behind the transformation the program is not able to describe the raman scattering process for light that is circular polarised or with a polarisation grade below one. The transformation and its assumptions will be explained in a seperate [pdf-file](./ramanMuellerMatrix.pdf).
It is possible to pass multiple raman mueller matrices to the simulation at once. There is a raman tensor for every vibrational mode of the sample and all of them can be simulated in parallel. Make sure to give each raman mueller matrix a describtive title in the raman mueller matrix file. More details about the input files are given below.

This simulation is only looking at raman scattering in transmission. And at the current moment does it only support light with a polarisation grade *Π* of one. Circular polarisation can't be simulated in combination with the raman scattering process. All other optical elements do support circular polarisation.
These assumptions are the basis of the raman-tensor-to-mueller-matrix-conversion described in a seperate [pdf-file](./ramanMuellerMatrix.pdf). Details and definitions of the coordinate systems are also given in the seperate [pdf-file](./ramanMuellerMatrix.pdf).

In order to simulate a solution of a molecule and not only a single molecule, use the `convert` command. It derives a mean raman mueller matrix for molecules in solution from the raman tensor of a single molecule. The raman tensor for the single molecule can be computed by quantum calculation programs like Gaussian. Details are given in the sections about the `convert` sub-program.

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
`SMP`       | raman scattering sample     | 0                   | This command will cause the simulation program to use the raman mueller matrices, given via CLI, in the next simulation step. If none is given, the unit matrix will be read from the file `PolaRam/unitmatrix.txt`. This instruction is not compatible with circular polarised light and light with a polarisation grade below one. For more details on the math behind it see the seperate [pdf-file](./ramanMuellerMatrix.pdf).
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
### Raman Mueller Matrix File

The raman mueller matrix file contains all matrices, that describe the raman scattering properties of every mode of the sample. It may contain comment lines, marked with `#`, and 4x4 matrices. Comments will be ignored. Anything else will cause the program to misbehave or raise an exception. Matrices are written as five lines of code. The first line marks the beginning of the matrix with the `!` character. The following characters will be saved as descriptive name of the matrix. The other four lines contain the rows of the raman mueller matrix. Every line must contain four elements seperated by a space.
A valid matrix file might look like this:
```
# Some descriptive comment

! v_1 = 216.2523/cm
-0.00634609 -0.0166743   0.02670877 0.
-0.0166743  -0.03183306  0.0195725  0.
 0.02670877  0.0195725   0.03817915 0.
 0.          0.          0.         0.

! v_2 = 216.2523/cm
-0.05350382  0.00476986 -0.00417874 0.
 0.00476986  0.01253425 -0.07968738 0.
-0.00417874 -0.07968738  0.04096966 0.
 0.          0.          0.         0.
```
The subprogram `convert` will create such a file. `convert` uses 3x3 raman tensors of molecules to calculate the mueller matrix equivalent of a whole solution of the molecules.

# convert: Matrix Transformation Between Molecular And Labratory Coordinate System

The sub-command `convert` will run a Monte-Carlo-Simulation on a list of 3x3 matrices given via CLI. The purpose of the simulation is the conversion of a raman tensor from the molecular coordinate system - which can be calculated by Gaussian and similar programs - into the labratory coordinate system of the Mueller-Simulation the `simulate` program performs. In addition to the coordinate system conversion, the program will convert the raman tensors into the mueller matrix formalism. It is assumed that the sample is in a solved state so that each molecule is free to rotate. The effective raman mueller matrix incoming light will experience is therefore the mean of all possible rotations of the molecular raman tensor. The Monte-Carlo-Simulation will calculate this mean by rotating the molecular raman tensor by random angles.

There are a few things to keep in mind, to understand the way this simulation is implemented: The random rotations are implemented with James Arvo's Algorithm "Fast Random Rotation Matrices" to ensure a uniform distribution of the rotations. The math is described in his [paper](./jamesArvoAlgorithm.pdf). Furthermore it is not possible to calculate the mean raman tensor of all possible rotations. The raman scattering process is linear and therefore a mean raman tensor should describe a solution, but the simulation and the matrix validation (described in the next paragraph) look at the intensity of the light, not the electrical field vectors. The relationship between electrical fiel and intensity is not linear and therefore is a mean of the raman tensors a bad describtion of a raman active solution. That is the reason why the raman tensor will be converted into a mueller matrix after its been rotated randomly. The mueller matrix are defined by the light intensities and not the electrical fields. The raman scattering process described in the mueller formalism is linear; even when considering the light's intensity. Therefore does the mean over all mueller matrices describe the behaviour of a raman active solution correctly.

The validation of the monte-carlo-simulation is done by comparing the depolarisation ratio *ρ* of the initial raman tensor and the final mueller matrix. The monte-carlo-simulation may not change the depolarisation ratio. The depolarisation ratio is calculated in two different ways. Both are described by Richard N. Zare in "Angular Momentum" (ISBN 0-471-85892-7), p. 129. The depolarisation ratio of the initial raman tensor is calculated by determining its eigenvalues. The eigenvalues are used to get the anisotropic and isotropic part of the polarisability. Theses two measures are combined into the depolarisation ratio of the molecule. The depolarisation ratio of the final mueller matrix is calculated by comparing the light polarisation before and after the raman scattering process.

## Usage

The conversion is started by typing `polaram convert PATH_TO_TENSOR_FILE`. The command `polaram convert -h` echos a help text. This command prints the following output:
```
$ polaram convert -h
usage: polaram convert [-h] [-v] [-l LOGFILE] [-i ITERATIONLIMIT]
                       [-o OUTPUTFILE] [-c [COMMENT [COMMENT ...]]]
                       [-p PROCESSCOUNT] [-s CHUNKSIZE] [-t THRESHOLD]
                       tensorfile

Converts raman tensors from the molecular coordinate system into the raman
mueller matrix of a solution in the labratory coordinate system via a monte
carlo simulation.

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
                        Default=PROGRAMMPATH/res/labratoryMuellerMatrix.txt
  -c [COMMENT [COMMENT ...]], --comment [COMMENT [COMMENT ...]]
                        comment that will be added to the output file
  -p PROCESSCOUNT, --processes PROCESSCOUNT
                        number of processes that compute in parallel.
                        Default=2
  -s CHUNKSIZE, --cunksize CHUNKSIZE
                        length of array each subprocess is given to calculate.
                        Default=500
  -t THRESHOLD, --threshold THRESHOLD
                        number of digits the depolarisation ratio before and
                        after the monte-carlo-simulation must match for the
                        result to pass validation. Default=2
```
The conversion will print the results as a file and on screen in the same format as the input file. This format can be understood by the `simulate` sub-program.

The important parameter of the Monte-Carlo-Simulation are the chunk size, the process count, the threshold and the iteration limit. The simulation should run reasonably fast with the default settings, but they can be adjusted via the CLI.
+ The iteration limit determines the amount of random rotations the simulation will do to determine the labratory raman matrix. The higher the iteration limit the longer it will compute and the better is the accuracy of the result.
+ Multi-processing was implemented to increase the computation speed. The process count sets the amount of processes computing the matrix rotations in parallel. In addition to these subprocesses the main process does its part. The main process takes the results of the subprocesses and adds them up. Increasing the process count will increase the computation speed. However, if the are not enough processor cores to match the number of running processes, the computation speed might decrease.
+ The cunk size is also a feature of the multi-processing. The simulation will be prepared by creating a generator containing random rotation angles for every iteration of the simulation. The cunk size determines how many of these random rotation angles will be passed to each subprocess at once. The chunk size is a compromise between the time it takes to pipe the data between processes and to the time it takes to start a new one. Changing the chunk size might increase or decrease the computation speed.
+ The threshold is used for the simulation validation. It is a positive integer. The depolarisation ratio will be rounded to *threshold* digits before the final and intial depolarisation ratios are compared. The higher the threshold, the longer needs the simulation to run in order to pass the validation. Don't set the threshold to high. The results of the simulation will be deleted, if the validation fails.

## The Input File
The input file for the `convert` sub-program is the same as the format of the [raman tensor file](#raman-tensor-file) the `simulate` command expects.

# extract: Reading Log-Files Of Quantum Calculations

The program will read a LOG-file created by Gaussian's freqency calculations. Other programs are not supported. The code can be adjusted if needed, but it is not planned to do so. The program was only tested for Gaussian16 output, but other versions of Gaussian should propably work. Details are given in the section [The Input File](#the-input-file-1). It will also read the meta data at the beginning and the frequencies of the vibrational modes. These information will be added to the output file. More over the program will check if Gaussian marked the frequencies with a `-`-sign to make sure that the structure of the molecule was optimised before performing the frequency analysis.

## Usage
The conversion is started by typing `polaram extract PATH_TO_LOG_FILE`. The command `polaram extract -h` echos a help text. This command prints the following output:
```
$ polaram extract -h
usage: polaram extract [-h] [-v] [-l LOGFILE] [-o OUTPUTFILE]
                       [-c [COMMENT [COMMENT ...]]]
                       gaussianfile

This program reads gaussian log files of frequency calculations and writes the
raman tensors into a text file that can be read by the other scripts. Tested
for Gaussian16. Raman tensors are not put into the log file by default. See
the readMe for details.

positional arguments:
  gaussianfile          the log file of a gaussian frequency calculation

optional arguments:
  -h, --help            show this help message and exit
  -v, --verbose         runs programm and shows status and error messages
  -l LOGFILE, --log LOGFILE
                        defines path and name of a custom .log file.
                        Default=PROGRAMPATH/log/extractGaussianTensor.log
  -o OUTPUTFILE, --output OUTPUTFILE
                        path to output file.
                        Default=PROGRAMPATH/res/molecularTensor.txt
  -c [COMMENT [COMMENT ...]], --comment [COMMENT [COMMENT ...]]
                        comment that will be added to the output file
```
The program will print the results as a file and on screen in the format of the [matrix files](#raman-tensor-file) the other subcommands expect.

## The Input File

The program supports only Gaussian LOG-files and it's only been tested in Gaussian16 LOG-files. However, the code should be adaptable to different file-types. The program scans the input file for four keywords:
+ The `LOGFILE_KEYWORD` makes sure that the file is a Gaussian LOG-file. It also makes sure that the file contains a raman frequency analysis with the corresponding raman tensors. `LOGFILE_KEYWORD = 'freq(raman, printderivatives)'`.
+ The `TENSOR_KEYWORD` marks the beginning of each raman tensor in the file.`TENSOR_KEYWORD = 'Polarizability derivatives wrt mode'`.
+ The `FREQUENCY_KEYWORD` marks all rows in the file's summary table containing the frequencies of the vibrational modes. They will be added to the raman tensors as descriptive title. `FREQUENCY_KEYWORD = 'Frequencies -- '`.
+ The `METADATA_KEYWORD` marks the beginning of the meta data. Gaussian adds information about the used calculation method, basis set and more to the LOG-file.  The program adds these information to the output file. `METADATA_KEYWORD = "******************************************\n Gaussian"`.

An example of files the `extract` can process are given in the [gaussian](gaussian/) directory. Following example shows how the output file is generated from the input file. The number of the vibrational mode and its frequency are included in the description of each tensor.

Extract from input file:
```
[...]
J. B. Foresman, and D. J. Fox, Gaussian, Inc., Wallingford CT, 2016.

******************************************
Gaussian 16:  EM64W-G16RevB.01 16-Dec-2017
               10-Sep-2020 
******************************************
%nprocshared = 6
Will use up to    6 processors via shared memory.
%chk=C:\Users\no83wec\Documents\BA_projektmodul\2020_09_10\water\water.chk
---------------------------------------------------------------
# freq(raman, printderivatives) b3lyp/6-31+G* geom=connectivity
---------------------------------------------------------------
1/10=4,30=1,38=1,57=2/1,3;
[...]
Dipole derivative wrt mode   1: -4.88694D-14  3.35287D-14  9.87113D+00
Polarizability derivatives wrt mode          1
                1             2             3 
     1  -0.911413D-01  0.000000D+00  0.000000D+00
     2   0.000000D+00  0.310911D+00  0.000000D+00
     3   0.000000D+00  0.000000D+00 -0.449127D+00
Vibrational polarizability contributions from mode   1       0.0000000       0.0000000       0.9487761
Vibrational hyperpolarizability contributions from mode   1       0.0000000       0.0000000      -4.8132681
IFr=  0 A012= 0.79D-01 0.28D+01 0.46D+00 Act= 0.33D+01 DepolP= 0.65D+00 DepolU= 0.79D+00
Dipole derivative wrt mode   2:  2.93067D-14  2.91767D-13 -2.45888D+00
Polarizability derivatives wrt mode          2
                1             2             3 
     1   0.215860D+00  0.000000D+00  0.000000D+00
     2   0.000000D+00  0.210041D+01  0.000000D+00
     3   0.000000D+00  0.000000D+00  0.119512D+01
Vibrational polarizability contributions from mode   2       0.0000000       0.0000000       0.0116544
Vibrational hyperpolarizability contributions from mode   2       0.0000000       0.0000000      -0.6315934
IFr=  0 A012= 0.18D+02 0.53D+02 0.88D+01 Act= 0.80D+02 DepolP= 0.11D+00 DepolU= 0.20D+00
Dipole derivative wrt mode   3:  7.66275D-13  7.28298D+00  2.95897D-12
Polarizability derivatives wrt mode          3
                1             2             3 
     1   0.000000D+00  0.000000D+00  0.000000D+00
     2   0.000000D+00  0.000000D+00 -0.137193D+01
     3   0.000000D+00 -0.137193D+01  0.000000D+00
Vibrational polarizability contributions from mode   3       0.0000000       0.0957547       0.0000000
[...]
and normal coordinates:
                     1                      2                      3
                    A1                     A1                     B2
Frequencies --   1662.4606              3736.4454              3860.9646
Red. masses --      1.0834                 1.0445                 1.0829
Frc consts  --      1.7642                 8.5913                 9.5109
IR Inten    --     97.4391                 6.0461                53.0418
Raman Activ --      3.2991                80.3041                39.5259
Depolar (P) --      0.6513                 0.1106                 0.7500
Depolar (U) --      0.7888                 0.1991                 0.8571
 Atom  AN      X      Y      Z        X      Y      Z        X      Y      Z
    1   8     0.00   0.00  -0.07     0.00   0.00   0.05     0.00  -0.07   0.00
    2   1     0.00   0.42   0.56     0.00   0.59  -0.39     0.00   0.56  -0.43
    3   1     0.00  -0.42   0.56     0.00  -0.59  -0.39     0.00   0.56   0.43
[...]
```
Resulting output file:
```
$ polaram extract gaussian/WATER.LOG
# Raman tensors calculated by Gaussian
# Gaussian .LOG-file: gaussian/WATER.LOG

# Gaussian calculation settings:
# ******************************************
# Gaussian 16:  EM64W-G16RevB.01 16-Dec-2017
# 10-Sep-2020
# ******************************************
# %nprocshared = 6
# Will use up to    6 processors via shared memory.
# %chk=C:\Users\no83wec\Documents\BA_projektmodul\2020_09_10\water\water.chk
# ---------------------------------------------------------------
# # freq(raman, printderivatives) b3lyp/6-31+G* geom=connectivity
# ---------------------------------------------------------------

! v_1 = 1662.4606/cm
-0.0911413  0.         0.
 0.         0.310911   0.
 0.         0.        -0.449127

! v_2 = 3736.4454/cm
0.21586 0.      0.
0.      2.10041 0.
0.      0.      1.19512

! v_3 = 3860.9646/cm
 0.       0.       0.
 0.       0.      -1.37193
 0.      -1.37193  0.
```

# Supplementary code: `utilities` and `SetupDecoder`

`SetupDecoder.py` and `utilities.py` contain code that is used by the commands discussed above. The `SetupDecoder` is a class that is only used by the `simulate` command. Its purpose is to convert an instruction from the [input file](#instruction-file) into a mueller matrix. It uses a dictionary to look a given instruction up and calls the corresponding function. The functions will create the mueller matrices from templates or create the initial stokes vectors by using the arguments passed with the instruction. The returned results will passed to the `simulate` program, which in return will pass a new instruction to the `SetupDecoder`.

The `utilities` module contains a more varied assembly of functions. This module is used by all other python scripts for various applications. There are functions defining new data types for the command line interface argparse. These functions enable the cli to parse text as valid file paths, positive integers or interpret a list of strings as a single sentences. Furthermore there are functions to convert a raman tensor into a mueller matrix. The mathematical details are given in a seperate [pdf-file](./ramanMuellerMatrix.pdf). Reading and parsing the content of files is also implemented in this module. Text files can be read and interpreted as input files for the sub-programs or as gaussian .LOG-file.
