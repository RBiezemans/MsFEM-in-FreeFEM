# MsFEM in FreeFEM
*Non-intrusive implementation of MsFEMs using FreeFEM*

The multiscale finite element method (MsFEM) solves PDEs with highly oscillatory coefficients on a course mesh. It does so by precomputing basis functions for a Galerkin (or other) approximation. These basis functions are adapted to the variations of the coefficients. 

We wish to avoid the computation *new basis functions* because their integration into some existing finite element architecture can be laborious. It is described in [this paper](https://arxiv.org/abs/2204.06852) how effective coefficients can be computed that lead to a PDE that can be solved directly by a finite element method with *standard basis functions* on the coarse mesh. This repository provides [FreeFEM](https://freefem.org/) scripts that implement various MsFEMs in the "non-intrusive" way proposed in the paper.

## Launching the MsFEM scripts

You need an [installation of FreeFEM](https://doc.freefem.org/introduction/installation.html). The code in this repository was developed under version [v4.7](https://github.com/FreeFem/FreeFem-sources/releases/tag/v4.7).
Then download this repository to your desired `working_directory`. Open a terminal and `cd` to `working_directory`. On the commmand line, any of the `main` files of this repository can then be run with, e.g. for [main_LIN.edp](main_LIN.edp):
```
FreeFem++ main_LIN.edp
```
For its parallelized counter part [main_LIN_MPI.edp](main_LIN_MPI.edp) one runs FreeFem++-mpi under mpirun with the following command:
```
mpirun -np [number_of_processes] FreeFem++-mpi main_LIN_MPI.edp
```

## Tuning the MsFEM
### The PDE to be solved
The scripts are currcently devised to solve a 2nd order PDE on a 2D square with a scalar-valued diffusion coefficient `$\nu$`, an advection field `$(b_x,b_y)$` and reaction term `$\sigma$`. The values taken by these coefficients can be adapted in the script [init.idp](msfem_blocks/init.idp). They are defined and can be changed, respectively, in the variables called `nu`, `bx`, `by` and `sigma`. The source term of the PDE can be any function defined in the variable `fRHS` in [init.idp](msfem_blocks/init.idp).

### Choice of local boundary conditions
Numerical correctors can locally be computed with either affine boundary conditions (this is done in the script [local_problems_LIN.idp](msfem_blocks/local_problems_LIN.idp)) upon running [main_LIN.edp](main_LIN.edp) or Crouzeix-Raviart-type boundary conditions ([local_problems_CR.idp](msfem_blocks/local_problems_CR.idp)) upon running [main_CR.edp](main_CR.edp). 
Both constructions can be executed with oversampling ([local_problems_LIN_OS.idp](msfem_blocks/local_problems_LIN_OS.idp), [local_problems_CR_OS.idp](msfem_blocks/local_problems_CR_OS.idp)) upon choosing an oversampling ratio (`osCoef`, see [Parameters](#parameters)) that is larger than the threshold `osThr` defined in [init.idp](msfem_blocks/init.idp). For oversampling methods, two options to glue the basis functions across mesh elements can be chosen (see [Parameters](#parameters)).

### Parameters
In the `working_directory`, the file [parameters.txt](parameters.txt) is used to choose parameters related to the PDE and the MsFEM: 
- `L` (the length/width of the computational domain)
- `N` (number of squares in the construction of the fine mesh)
- `n` (number of squares in the construction of the coarse mesh)
- `eps` (`$\varepsilon$`) 
- `2logalpha` (`$\log_2(\alpha)$`, `$\alpha$` being the factor in front of the diffusion coefficient `$\nu$`)
- `theta` (angle of the constant advection field w.r.t. the $x$-axis in % of `$2\pi$`)
- `cont` (contrast of the diffusion coefficient `$\nu$`)
- `osCoef` (homothety ratio for the construction of oversampling patches)
- `glue` (glue option for MsFEM basis function in the case of oversampling)
- `strong_Drichlet` (option for the usage of strong Dirichlet boundary conditions in the MsFEM-CR. This is not supported yet)
- `useB` (option to indicate wether or not to use bubbles)
- `treatB` (option to differentiate between various ways to include bubble functions in the approximation)
- `testMS` (option to decide what type of test functions are used in the MsFEM)

More details on the options and usage of these parameters are provided in the header of [init.idp](msfem_blocks/init.idp).

### Defining the local and global variational formulations
The `working_drectory` must contain a script named [vffile.idp](vffile.idp). This file defines the bilinear forms of the local problems (used to compute the numerical correctors), for the global problem (coupling the MsFEM basis functions; before the construction of an effective scheme) and for the reference solution. Various examples are provided in the folder [variational_forms](variational_forms). In particular, the script [vffile_blank.idp](variational_forms/vffile_blank.idp) provides an empty version that can be tuned to the user's needs. More explanation is also available in this blank file.

## Comparison of intrusive and non-intrusive MsFEM
FreeFEM++ contains all functionalities to develop the traditional intrusive MsFEM as well as, of course, the non-intrusive MsFEM variant. To illustrate the differences between the two, a traditional MsFEM script in FreeFEM++ can be found [here](miscellaneous/compare_intrusive_vs_non_intrusive/msfem_diffusion_intrusive.edp) and it can be compared to the non-intrusive MsFEM in [this script](miscellaneous/compare_intrusive_vs_non_intrusive/msfem_diffusion_non_intrusive.edp).

### Reproducing the results of the [paper](https://arxiv.org/abs/2204.06852)
To reproduce the results in the [paper](https://arxiv.org/abs/2204.06852) that introduces the non-intrusive MsFEM, the correct PDE must be defined in [init.idp](msfem_blocks/init.idp). This must be done manually. The correct definitions are:

```
func nu=alpha*(1+cont*cos(pi/eps*x)^2*sin(pi/eps*y)^2);
```
for the diffusion coefficient;
```
real bx=0;
real by=0;
func sigma=0;
```
for the other coefficients of the PDE;
```
func fRHS=sin(x)*sin(y);
string rhsDescription = "-- Tests for RHS f = sin(x)sin(y) --";
```
for the right-hand side.
*The preprint erroneously states that `fRHS=sin(x)*cos(y)` was used.*

With the above definitions, all tests are reproduced by executing [this shell script](experiment/execute_experiment_arxiv_220414.sh). Note that this will execute the parallel version of the MsFEM code distributed over 10 processes. The shell script must be launched from the directory where the `main_*` files are located. Execution is done as follows:
```
./experiment/execute_experiment_arxiv_220414.sh
```
Should permission to execute this script be denied, first do
```
chmod +x experiment/execute_experiment_arxiv_220414.sh 
```

Finally, once all computations are finalized, the numerical solutions provided by the intrusive and non-intrusive MsFEM can be compared by running [this FreeFEM script](miscellaneous/compare_intrusive_vs_non_intrusive/testMS_compare.edp).