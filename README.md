# MsFEM in FreeFEM
*Non-intrusive implementation of Multiscale Finite Element Methods using FreeFEM*

The MsFEM is an efficient method to solve strongly heterogeneous partial differential equations (PDEs) on a coarse mesh that does not resolve the microscopic variations of the coefficients of the PDE. 
Is relies on precomputed localized basis functions that do resolve the fine-scale variations of the coefficients and then couples these functions through a global (Petrov-)Galerkin formulation of the global problem. 

In this project we implement the MsFEM in [FreeFEM](https://freefem.org/) covering the variants with linear and with Crouzeix-Raviart type local boundary conditions with and without oversampling.
We do so providing FreeFEM macros that can be used to easily build your own MsFEM project. 
In particular, this project implements the *non-intrusive* version of the MsFEM introduced in [this paper](http://doi.org/10.1016/j.jcp.2023.111914) and developed more extensively in [this paper](http://doi.org/10.5802/crmeca.178).
This MsFEM strategy avoids the explicit computation of new basis functions (but rather introduces the concept of *numerical correctors*) to ease the implementation in existing finite element software.

## Features of the project
- FreeFEM macros for the variants of the MsFEM with [linear](http://doi.org/10.1006/jcph.1997.5682) and [Crouzeix-Raviart](10.1007/s11401-012-0755-7) type local boundary conditions, with and without oversampling (see the general framework developed [here](http://doi.org/10.5802/crmeca.178)).
- Possibility to cover general linear second-order PDEs with user-specified PDE for the construction of the basis functions.
- Sequential and parallel compatibility.

## Getting started

You need a working [installation of FreeFEM](https://doc.freefem.org/introduction/installation.html). The code in this repository was developed under version [FreeFEM v4.7](https://github.com/FreeFem/FreeFem-sources/releases/tag/v4.7).

Download this project to the directory of your choice (`msfem_directory`).
When you `cd` to `msfem_directory`, you can launch the FreeFEM `main` files in this directory directly under FreeFEM. 

For example, to launch the MsFEM with linear local boundary conditions, run the [main_LIN.edp](main_LIN.edp) file as follows:
```
FreeFem++ main_LIN.edp
```
For its parallelized counterpart [main_LIN_MPI.edp](main_LIN_MPI.edp), run FreeFem++-mpi under mpirun with the following command:
```
mpirun -np [number_of_processes] FreeFem++-mpi main_LIN_MPI.edp
```
Any `main` file includes [init.idp](msfem_blocks/init.idp), which requires the presence of the [parameters.txt](parameterst.txt), [pdefile.idp](pdefile.idp) and [vffile.idp](vffile.idp) files in the `msfem_directory`.
Find information on how to tune the MsFEM in the [wiki](https://github.com/RBiezemans/MsFEM-in-FreeFEM/wiki).

## Contributing
Feel free to submit your issues or pull requests if you want to contribute to this project.
To test that your changes are compatible with all main files of the current version of the project and the various  you can run the bash files [execute_test_sequential.sh](experiment/execute_test_sequential.sh) and [execute_test_parallel.sh](experiment/execute_test_parallel.sh) from the `msfem_directory`. 
Should permission to execute these be denied, first do
```
chmod +x experiment/execute_test_sequential.sh
```
and similarly for [execute_test_parallel.sh](experiment/execute_test_parallel.sh).