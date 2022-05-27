# MsFEM in FreeFEM
*Non-intrusive implementations of MsFEM in FreeFEM*

The multiscale finite element method (MsFEM) solves PDEs with highly oscillatory coefficients on a course mesh. It does so by precomputing basis functions for a Galerkin (or other) approximation. These basis functions are adapted to the variations of the coefficients. 

We wish to avoid the computation *new basis functions* because their integration into some existing finite element architecture can be laborious. It is described in [this paper](https://arxiv.org/abs/2204.06852) how effective coefficients can be computed that lead to a PDE that can directly be solved by a finite element method with *standard basis functions* on the coarse mesh. This repository provides [FreeFEM](https://freefem.org/) scripts that implement various MsFEMs in the 'non-intrusive' way proposed in the paper.

## Launching the MsFEM scripts

You need an [installation of FreeFEM](https://doc.freefem.org/introduction/installation.html). The code in this repository was developed under version [v4.7](https://github.com/FreeFem/FreeFem-sources/releases/tag/v4.7).
Then download this repository to your desired `working_directory`. Open a terminal and `cd` to `working_directory`. On commmand line, any of the `main` files of this repository can then be run with, e.g. for `main_LIN.edp`:
```
FreeFEM++ main_LIN.edp
```
For its parallelized counter part `main_LIN_MPI.edp` one runs FreeFem++-mpi within mpirun as follows:
```
mpirun -np [number_of_processes] FreeFem++-mpi main_LIN_MPI.edp
```
