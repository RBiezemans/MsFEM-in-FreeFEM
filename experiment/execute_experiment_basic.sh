#! /bin/bash

# To be executed from the directory where main_LIN_MPI.edp and main_CR_MPI.edp are located

# Consecutive executions of FreeFem++ code to perform experiments with different parameter values
# The parameter values are changed continuously based on the values given below
# Check that all values that are not controlled here, are as desired in the basic parameter.txt file in experiment_parameters
# The execution commands for FreeFem++ are adapted to use on the cluster of CERMICS


# Number of processors to be used
NUMBER_OF_PROC=2

# Parameter values to be used in the tests (all will be combined)
# eg TOTEST_LARGE_N="8 16 32" to test for three different (coarse) mesh sizes
TOTEST_L="1."
TOTEST_LARGE_N="100" 
TOTEST_LARGER_N="500" 
TOTEST_SMALL_N="4"
TOTEST_EPS="25"
TOTEST_2LOGALP="-2"
TOTEST_THETA="0.15"
TOTEST_CONT="7"
TOTEST_OSCOEF="1.2"
TOTEST_STR_DIR="0"
TOTEST_USE_B="1 0" # it is important to treat bubbes first, so the offline stages without bubbles can be loaded
TOTEST_TREAT_B="in_system out_system"
TOTEST_ADV_MS="1"
TOTEST_MS="0"

## SOME PARAMETER RULES
## - Usage of bubbles must be executed before non-usage: "1 0" or "0"
## - It is more efficient to use testMS before not using it
## - It is more efficient to use in_system before using out_system


# LOOP OVER ALL PARAMETER VALUES AND FreeFem++ EXECUTION
for TEST_L in $TOTEST_L; do sed -i "s/L=.*/L= $TEST_L/" "experiment/parameters.txt" 
for TEST_EPS in $TOTEST_EPS; do sed -i "s/eps=.*/eps= $TEST_EPS/" "experiment/parameters.txt" 
for TEST_2LOGALP in $TOTEST_2LOGALP; do sed -i "s/2logalpha=.*/2logalpha= $TEST_2LOGALP/" "experiment/parameters.txt" 
for TEST_THETA in $TOTEST_THETA; do sed -i "s/theta=.*/theta= $TEST_THETA/" "experiment/parameters.txt" 
for TEST_CONT in $TOTEST_CONT; do sed -i "s/cont=.*/cont= $TEST_CONT/" "experiment/parameters.txt" 
for TEST_LARGE_N in $TOTEST_LARGE_N; do sed -i "s/N=.*/N= $TEST_LARGE_N/" "experiment/parameters.txt"
    if [ $TEST_2LOGALP = "-8" ] # the last test requires a finer reference solution (skipped here)
    then sed -i "s/N=.*/N= $TOTEST_LARGER_N/" "experiment/parameters.txt" 
    fi

    # The above loops contain all parameters related to the reference solution
    sed -i "s/treatB=.*/treatB= out_system/" "experiment/parameters.txt"
    # The reference solution does not involve any bubble computations
    cp experiment/parameters.txt parameters.txt
    /usr/bin/mpirun -np 1 /usr/local/bin/FreeFem++-mpi main_REF.edp -v 0
    
    for TEST_SMALL_N in $TOTEST_SMALL_N; do sed -i "s/n=.*/n= $TEST_SMALL_N/" "experiment/parameters.txt" 
    for TEST_OSCOEF in $TOTEST_OSCOEF; do sed -i "s/osCoef=.*/osCoef= $TEST_OSCOEF/" "experiment/parameters.txt" 
    for TEST_STR_DIR in $TOTEST_STR_DIR; do sed -i "s/strong_Dirichlet=.*/strong_Dirichlet= $TEST_STR_DIR/" "experiment/parameters.txt" 
    for TEST_ADV_MS in $TOTEST_ADV_MS; do sed -i "s/advMS=.*/advMS= $TEST_ADV_MS/" "experiment/parameters.txt" 
    # The above loops contain all parameters that require the computation of a new basis
    COMPUTE_BASIS=0
    for TEST_MS in $TOTEST_MS; do sed -i "s/testMS=.*/testMS= $TEST_MS/" "experiment/parameters.txt" 
    for TEST_USE_B in $TOTEST_USE_B; do sed -i "s/useB=.*/useB= $TEST_USE_B/" "experiment/parameters.txt" 
    for TEST_TREAT_B in $TOTEST_TREAT_B; do sed -i "s/treatB=.*/treatB= $TEST_TREAT_B/" "experiment/parameters.txt" 

        if [ $TEST_USE_B == 0 -a $TEST_TREAT_B = "out_system" ] || [ $TEST_USE_B == 1 ] # Not all parameter combinations are allowed
        then
            cp experiment/parameters.txt parameters.txt

            if [ $COMPUTE_BASIS == 0 ]
            then 
                /usr/bin/mpirun -np $NUMBER_OF_PROC /usr/local/bin/FreeFem++-mpi -v 0 main_LIN_MPI.edp -o compute
                /usr/bin/mpirun -np $NUMBER_OF_PROC /usr/local/bin/FreeFem++-mpi -v 0 main_CR_MPI.edp -o compute
                COMPUTE_BASIS=1
            else
                /usr/bin/mpirun -np $NUMBER_OF_PROC /usr/local/bin/FreeFem++-mpi -v 0 main_LIN_MPI.edp -o load
                /usr/bin/mpirun -np $NUMBER_OF_PROC /usr/local/bin/FreeFem++-mpi -v 0 main_CR_MPI.edp -o load
            fi
            rm parameters.txt
        fi

    done done done done done done done # end of loops over numerical parameters
done done done done done done # end of loops over reference solution/physical parameters + fine mesh

# Compress results into zip files
cd results/
zip zip_Lin_short err_Lin_MPI* solCoarse_Lin_MPI*
zip zip_LinOS_short err_LinOS_MPI* solCoarse_LinOS_MPI*
zip zip_CR_short err_CR_MPI* solCoarse_CR_MPI*
zip zip_CROS_short err_CROS_MPI* solCoarse_CROS_MPI*


# zip -r zip_Lin_all *Lin_MPI*
# zip -r zip_LinOS_all *LinOS_MPI*
# zip -r zip_CR_all *CR_MPI*
# zip -r zip_CROS_all *CROS_MPI*