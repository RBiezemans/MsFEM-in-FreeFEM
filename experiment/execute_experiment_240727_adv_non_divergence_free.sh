#! /bin/bash

# To be executed from the directory where the MsFEM main_*.edp files are located

# Consecutive executions of FreeFem++ code to perform experiments with different parameter values
# The parameter values are changed continuously based on the values given below
# The FreeFem++ execution commands may need to be changed depending on the configuration of the computer used

# Number of processors to be used
NUMBER_OF_PROC=25

LOAD_OPTION=0 #0 : first offline stage is computed for each set of parameters -- 1 : offline stage is loaded from the very first test
COMPUTE_REF=0 #0 : reference solution is computed -- 1 : reference solution is not computed

# FEM variants to be tested: 0 if yes, 1 if no
TEST_MSFEM_LIN=0
TEST_MSFEM_CR=0
TEST_P1_LIN=0

# Parameter values to be used in the tests (all will be combined)
# eg TOTEST_LARGE_N="8 16 32" to test for three different (coarse) mesh sizes
TOTEST_PDEFILE="pde_240727_advdiff_non_divergence_free.idp"
TOTEST_VFFILE="advection_diffusion_direct.idp advection_diffusion_msfem_supg.idp advection_diffusion_p1_supg.idp" # advection_diffusion_msfem.idp advection_diffusion_p1.idp advection_diffusion_skew_symmetric.idp"
TOTEST_L="1."
TOTEST_EPS="0.0078125" # 2^-7
TOTEST_2LOGALP="2 1 0 -1 -2 -3 -4 -5 -6 -7 -8 -9 -10"
TOTEST_SWITCHLOGALPHA="-10" # value for which the mesh size TOTEST_LARGER_N should be used for the fine mesh
TOTEST_THETA="0.0"
TOTEST_CONT="7"
TOTEST_LARGE_N="2048" 
TOTEST_LARGER_N="4096"  
TOTEST_SMALL_N="16"
TOTEST_OSCOEF="0" 
TOTEST_GLUE="dof" # either "dof" or "restrict" -- without OS, this options is automatically ignored
TOTEST_STR_DIR="0" # the MsFEM-lin can only be executed for the option 0
TOTEST_USE_B="1 0" # it is important to treat bubbes first, so the offline stages without bubbles can be loaded
TOTEST_TREAT_B="in_system" # we don't consider out_system for this test
TOTEST_MS="1"

## SOME PARAMETER RULES
## - Use of bubbles must be executed before non-use: "1 0" or "0"
## - It is more efficient to use testMS before not using it
## - It is more efficient to use in_system before using out_system


##
#####################################################################################################################
## All declarations are above, below follows the execution of the MsFEM tests
#####################################################################################################################
##


cp pde_coefficients/$TOTEST_PDEFILE pdefile.idp
# LOOP OVER ALL PARAMETER VALUES AND FreeFem++ EXECUTION
for TEST_L in $TOTEST_L; do sed -i "s/L=.*/L= $TEST_L/" "experiment/parameters.txt" 
for TEST_EPS in $TOTEST_EPS; do sed -i "s/eps=.*/eps= $TEST_EPS/" "experiment/parameters.txt" 
for TEST_2LOGALP in $TOTEST_2LOGALP; do sed -i "s/2logalpha=.*/2logalpha= $TEST_2LOGALP/" "experiment/parameters.txt" 
for TEST_THETA in $TOTEST_THETA; do sed -i "s/theta=.*/theta= $TEST_THETA/" "experiment/parameters.txt" 
for TEST_CONT in $TOTEST_CONT; do sed -i "s/cont=.*/cont= $TEST_CONT/" "experiment/parameters.txt" 
for TEST_LARGE_N in $TOTEST_LARGE_N; do sed -i "s/N=.*/N= $TEST_LARGE_N/" "experiment/parameters.txt"
for TEST_SMALL_N in $TOTEST_SMALL_N; do sed -i "s/n=.*/n= $TEST_SMALL_N/" "experiment/parameters.txt"
    if [ $TEST_2LOGALP = $TOTEST_SWITCHLOGALPHA ] # the last test requires a finer reference solution
    then sed -i "s/N=.*/N= $TOTEST_LARGER_N/" "experiment/parameters.txt" 
    fi

    # The above loops contain all parameters related to the reference solution and its projection on the coarse spaces
    sed -i "s/treatB=.*/treatB= out_system/" "experiment/parameters.txt"
    # The reference solution does not involve any bubble computations
    cp experiment/parameters.txt parameters.txt
    for TEST_VFFILE in $TOTEST_VFFILE
        do cp variational_forms/$TEST_VFFILE vffile.idp
        break # the vffile is needed to define the variational formulation for the reference solution
    done
    if [ $COMPUTE_REF == 0 ]
    then
        /usr/bin/mpirun -np 1 ~/etienne/freefem/bin/FreeFem++-mpi main_REF.edp -v 0
        ~/etienne/freefem/bin/FreeFem++ main_REF_projections.edp -v 0 -ng
        ~/etienne/freefem/bin/FreeFem++ miscellaneous/compute_norms_oble.edp -v 0 -ng
    fi

    for TEST_VFFILE in $TOTEST_VFFILE; do cp variational_forms/$TEST_VFFILE vffile.idp
    for TEST_OSCOEF in $TOTEST_OSCOEF; do sed -i "s/osCoef=.*/osCoef= $TEST_OSCOEF/" "experiment/parameters.txt"
    for TEST_STR_DIR in $TOTEST_STR_DIR; do sed -i "s/strong_Dirichlet=.*/strong_Dirichlet= $TEST_STR_DIR/" "experiment/parameters.txt"
    for TEST_GLUE in $TOTEST_GLUE; do sed -i "s/glue=.*/glue= $TEST_GLUE/" "experiment/parameters.txt"
    # The above loops contain all parameters that require the computation of a new basis
    COMPUTE_BASIS=$LOAD_OPTION
    for TEST_MS in $TOTEST_MS; do sed -i "s/testMS=.*/testMS= $TEST_MS/" "experiment/parameters.txt"
    for TEST_USE_B in $TOTEST_USE_B; do sed -i "s/useB=.*/useB= $TEST_USE_B/" "experiment/parameters.txt"
    for TEST_TREAT_B in $TOTEST_TREAT_B; do sed -i "s/treatB=.*/treatB= $TEST_TREAT_B/" "experiment/parameters.txt"

        if [ $TEST_USE_B == 0 -a $TEST_TREAT_B = "out_system" ] || [ $TEST_USE_B == 1 -a ! $TEST_VFFILE = "advection_diffusion_msfem_supg.idp" -a ! $TEST_VFFILE = "advection_diffusion_p1_supg.idp" ] # Not all parameter combinations are allowed
        then
            cp experiment/parameters.txt parameters.txt
            OFFLINE_MODE="compute"
            if [ $COMPUTE_BASIS == 1 ]
            then 
                OFFLINE_MODE="load"
            fi

            # MsFEM-LIN
            if [ $TEST_MSFEM_LIN -a $TEST_STR_DIR == 0 ] && [[ $TEST_VFFILE != *p1* ]]
            then 
                /usr/bin/mpirun -np $NUMBER_OF_PROC ~/etienne/freefem/bin/FreeFem++-mpi -v 0 main_LIN_MPI.edp -o $OFFLINE_MODE
            fi

            # MsFEM-CR
            if [ $TEST_MSFEM_CR -a ! $TEST_VFFILE = "advection_diffusion_msfem_supg.idp" ] && [[ $TEST_VFFILE != *p1* ]]
            then
                /usr/bin/mpirun -np $NUMBER_OF_PROC ~/etienne/freefem/bin/FreeFem++-mpi -v 0 main_CR_MPI.edp -o $OFFLINE_MODE
            fi 
            
            # P1 FEM Lagrange
            if [ $TEST_P1_LIN -a $TEST_STR_DIR == 0 -a $TEST_USE_B == 0 -a $TEST_MS == 0 -a $TEST_OSCOEF == 0 ] && [[ $TEST_VFFILE == *p1* ]]
            then
                /usr/bin/mpirun -np $NUMBER_OF_PROC ~/etienne/freefem/bin/FreeFem++-mpi -v 0 main_P1_LIN_MPI.edp -o "compute"
            fi
            
            COMPUTE_BASIS=1
        fi

    done done done # end of loops over bubbles and multiscale usage
    if (( $(echo "$TEST_OSCOEF < 0.1" | bc) )) # basic calculator is used for decimal arithmetic
        then break # break the loop over GLUE option if no oversamling is actually used
    fi
    done done done done # end of loops over basis specification
done done done done done done done # end of loops over reference solution/physical parameters + fine mesh + vf form used
