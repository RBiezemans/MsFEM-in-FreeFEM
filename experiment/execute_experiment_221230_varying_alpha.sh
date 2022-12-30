#! /bin/bash

# To be executed from the directory where main_LIN_MPI.edp and main_CR_MPI.edp are located

# Consecutive executions of FreeFem++ code to perform experiments with different parameter values
# The parameter values are changed continuously based on the values given below
# Check that all values that are not controlled here, are as desired in the basic parameter.txt file in experiment_parameters
# The execution commands for FreeFem++ are adapted to use on the cluster of CERMICS


# Number of processors to be used
NUMBER_OF_PROC=10

LOAD_OPTION=0 #0 : first offline stage is computed for each set of parameters -- 1 : offline stage is loaded from the very first test
COMPUTE_REF=1 #0 : reference solution is computed -- 1 : reference solution is not computed

# Parameter values to be used in the tests (all will be combined)
# eg TOTEST_LARGE_N="8 16 32" to test for three different (coarse) mesh sizes
TOTEST_L="1."
TOTEST_LARGE_N="2048" 
TOTEST_LARGER_N="4096" # unused in this experiment 
TOTEST_SMALL_N="16"
TOTEST_EPS="0.0078125" # 2^-7
TOTEST_2LOGALP="-2 -3 -4 -5 -6 -7 -8 -9 -10 -11" 
TOTEST_THETA="0.15"
TOTEST_CONT="7"
TOTEST_VFFILE="advection_diffusion_direct.idp"
TOTEST_OSCOEF="3" # -- the MsFEM-lin can only be executed for the option 0
TOTEST_GLUE="dof" # either "dof" or "restrict" -- without OS, this options is automatically ignored
TOTEST_STR_DIR="1 2"
TOTEST_USE_B="1 0" # it is important to treat bubbes first, so the offline stages without bubbles can be loaded
TOTEST_TREAT_B="in_system out_system"
TOTEST_MS="1 0 2"

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
    if [ $TEST_2LOGALP = "-11" ] # the last test requires a finer reference solution (skipped here)
    then sed -i "s/N=.*/N= $TOTEST_LARGER_N/" "experiment/parameters.txt" 
    fi

    # The above loops contain all parameters related to the reference solution
    sed -i "s/treatB=.*/treatB= out_system/" "experiment/parameters.txt"
    # The reference solution does not involve any bubble computations
    cp experiment/parameters.txt parameters.txt
    for TEST_VFFILE in $TOTEST_VFFILE
        do cp variational_forms/$TEST_VFFILE vffile.idp
        break # the availibility of a vffile is only needed for compatibility with initialization, but not actually used in the computation of the reference solution
    done
    if [ $COMPUTE_REF == 0 ]
    then
        /usr/bin/mpirun -np 1 /usr/local/bin/FreeFem++-mpi main_REF.edp -v 0
    fi

    for TEST_VFFILE in $TOTEST_VFFILE; do cp variational_forms/$TEST_VFFILE vffile.idp
    for TEST_SMALL_N in $TOTEST_SMALL_N; do sed -i "s/n=.*/n= $TEST_SMALL_N/" "experiment/parameters.txt"
    for TEST_OSCOEF in $TOTEST_OSCOEF; do sed -i "s/osCoef=.*/osCoef= $TEST_OSCOEF/" "experiment/parameters.txt"
    for TEST_GLUE in $TOTEST_GLUE; do sed -i "s/glue=.*/glue= $TEST_GLUE/" "experiment/parameters.txt"
    for TEST_STR_DIR in $TOTEST_STR_DIR; do sed -i "s/strong_Dirichlet=.*/strong_Dirichlet= $TEST_STR_DIR/" "experiment/parameters.txt"
    # The above loops contain all parameters that require the computation of a new basis
    COMPUTE_BASIS=$LOAD_OPTION
    for TEST_MS in $TOTEST_MS; do sed -i "s/testMS=.*/testMS= $TEST_MS/" "experiment/parameters.txt"
    for TEST_USE_B in $TOTEST_USE_B; do sed -i "s/useB=.*/useB= $TEST_USE_B/" "experiment/parameters.txt"
    for TEST_TREAT_B in $TOTEST_TREAT_B; do sed -i "s/treatB=.*/treatB= $TEST_TREAT_B/" "experiment/parameters.txt"

        if [ $TEST_USE_B == 0 -a $TEST_TREAT_B = "out_system" ] || [ $TEST_USE_B == 1 -a ! $TEST_VFFILE = "advection_diffusion_msfem_supg.idp" ] # Not all parameter combinations are allowed
        then
            cp experiment/parameters.txt parameters.txt
            OFFLINE_MODE="compute"
            if [ $COMPUTE_BASIS == 1 ]
            then 
                OFFLINE_MODE="load"
            fi

            # MsFEM-LIN
            if [ $TEST_STR_DIR == 0 ]
            then 
                /usr/bin/mpirun -np $NUMBER_OF_PROC /usr/local/bin/FreeFem++-mpi -v 0 main_LIN_MPI.edp -o $OFFLINE_MODE
            fi
            # MsFEM-CR
            if [ ! $TEST_VFFILE = "advection_diffusion_msfem_supg.idp" ]
            then
                    /usr/bin/mpirun -np $NUMBER_OF_PROC /usr/local/bin/FreeFem++-mpi -v 0 main_CR_MPI.edp -o $OFFLINE_MODE
            fi
            
            COMPUTE_BASIS=1
            rm parameters.txt
        fi

    done done done # end of loops over bubbles and multiscale usage
    if (( $(echo "$TEST_OSCOEF < 0.1" | bc) )) # basic calculator is used for decimal arithmetic
        then break # break the loops over GLUE and STR_DIR options if no oversamling is actually used
    fi
    done done done done done # end of loops over basis specification
done done done done done done # end of loops over reference solution/physical parameters + fine mesh + vf form used
