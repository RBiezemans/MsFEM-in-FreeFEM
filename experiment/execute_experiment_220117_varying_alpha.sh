#! /bin/bash

# To be executed from the directory where main_LIN_MPI.edp and main_CR_MPI.edp are located

# Consecutive executions of FreeFem++ code to perform experiments with different parameter values
# The parameter values are changed by continuously based on the values given below
# Check that all values that are not controlled here, are as desired in the basic parameter.txt file in experiment_parameters
# The execution commands for FreeFem++ are adapted to use on the cluster of CERMICS


# Number of processors to be used
NUMBER_OF_PROC=8

# Parameter values to be used in the tests (all will be combined)
# eg TOTEST_LARGE_N="8 16 32" to test for three different (coarse) mesh sizes
TOTEST_L="1."
TOTEST_LARGE_N="2048" # 2^11
TOTEST_SMALL_N="16"
TOTEST_EPS="0.0078125" # 2^-7
TOTEST_2LOGALP="0.25 0.125 0.0625 0.03125 0.015625 0.0078125 0.00390625" # 2^-2 ... 2^-8
TOTEST_THETA="0.125"
TOTEST_CONT="7"
TOTEST_OSCOEF="2."
TOTEST_STR_DIR="0"
TOTEST_USE_B="1 0" # it is important to treat bubbes first, so the offline stages without bubbles can be loaded
TOTEST_ADV_MS="1"
TOTEST_MS="0 1"


# LOOP OVER ALL PARAMETER VALUES AND FreeFem++ EXECUTION
for TEST_L in $TOTEST_L; do sed -i "s/L=.*/L= $TEST_L/" "experiment/parameters.txt" 
for TEST_EPS in $TOTEST_EPS; do sed -i "s/eps=.*/eps= $TEST_EPS/" "experiment/parameters.txt" 
for TEST_2LOGALP in $TOTEST_2LOGALP; do sed -i "s/2logalpha=.*/2logalpha= $TEST_2LOGALP/" "experiment/parameters.txt" 
for TEST_THETA in $TOTEST_THETA; do sed -i "s/theta=.*/theta= $TEST_THETA/" "experiment/parameters.txt" 
for TEST_CONT in $TOTEST_CONT; do sed -i "s/cont=.*/cont= $TEST_CONT/" "experiment/parameters.txt" 
for TEST_LARGE_N in $TOTEST_LARGE_N; do 
    if [ $TEST_2LOGALP = "0.00390625" ] # the last test requires a finer reference solution
    then sed -i "s/N=.*/N= $TEST_LARGE_N/" "experiment/parameters.txt" 
    fi

    # The above loops contain all parameters related to the reference solution
    cp experiment/parameters.txt parameters.txt
    /usr/bin/mpirun -np 1 /usr/local/bin/FreeFem++-mpi main_REF.edp -v 0
    
    for TEST_SMALL_N in $TOTEST_SMALL_N; do sed -i "s/n=.*/n= $TEST_SMALL_N/" "experiment/parameters.txt" 
    for TEST_OSCOEF in $TOTEST_OSCOEF; do sed -i "s/osCoef=.*/osCoef= $TEST_OSCOEF/" "experiment/parameters.txt" 
    for TEST_STR_DIR in $TOTEST_STR_DIR; do sed -i "s/strong_Dirichlet=.*/strong_Dirichlet= $TEST_STR_DIR/" "experiment/parameters.txt" 
    for TEST_USE_B in $TOTEST_USE_B; do sed -i "s/useB=.*/useB= $TEST_USE_B/" "experiment/parameters.txt" 
    for TEST_ADV_MS in $TOTEST_ADV_MS; do sed -i "s/advMS=.*/advMS= $TEST_ADV_MS/" "experiment/parameters.txt" 
    for TEST_MS in $TOTEST_MS; do sed -i "s/testMS=.*/testMS= $TEST_MS/" "experiment/parameters.txt" 

        cp experiment/parameters.txt parameters.txt

        if [ $TEST_USE_B = "1" ]
        then 
            /usr/bin/mpirun -np $NUMBER_OF_PROC /usr/local/bin/FreeFem++-mpi main_LIN_MPI.edp -o compute -v 0
            # /usr/bin/mpirun -np $NUMBER_OF_PROC /usr/local/bin/FreeFem++-mpi main_CR_MPI.edp -o compute -v 0
        else 
            /usr/bin/mpirun -np $NUMBER_OF_PROC /usr/local/bin/FreeFem++-mpi main_LIN_MPI.edp -o load -v 0
            # /usr/bin/mpirun -np $NUMBER_OF_PROC /usr/local/bin/FreeFem++-mpi main_CR_MPI.edp -o load -v 0
        fi
        rm parameters.txt

    done done done done done done # end of loops over numerical parameters
done done done done done done # end of loops over reference solution/physical parameters + fine mesh
