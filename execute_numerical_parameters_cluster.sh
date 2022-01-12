#! /bin/bash

# Consecutive executions of FreeFem++ code to perform experiments with different parameter values
# The parameter values are changed by continuously changing the parameter files from experiment_parameters
# The execution commands for FreeFem++ are adapted to use on the cluster of CERMICS

# The tests executed here are supposed to change numerical parameters, but not the physical onces
# since the reference solution is computed only once
# Make sure the first runs use bubble functions, so all other methods can be loaded


# FreeFem++ EXECUTION
NUMBER_OF_TESTS=6 #actually, the real number of tests (per type) minus 1
NUMBER_OF_PROC=8

cp "experiment_parameters/testMS_0_wB/parameters_0.txt" parameters.txt 
/usr/bin/mpirun -np 1 /usr/local/bin/FreeFem++-mpi main_REF.edp

for NUM in $(seq 0 $NUMBER_OF_TESTS)
do 
    cp "experiment_parameters/testMS_0_wB/parameters_$NUM.txt" parameters.txt
    /usr/bin/mpirun -np $NUMBER_OF_PROC /usr/local/bin/FreeFem++-mpi main_LIN_MPI.edp -o compute
    /usr/bin/mpirun -np $NUMBER_OF_PROC /usr/local/bin/FreeFem++-mpi main_LINOS_MPI.edp -o compute
    /usr/bin/mpirun -np $NUMBER_OF_PROC /usr/local/bin/FreeFem++-mpi main_CR_MPI.edp -o compute
    /usr/bin/mpirun -np $NUMBER_OF_PROC /usr/local/bin/FreeFem++-mpi main_CROS_MPI.edp -o compute
done

for TEST_TYPE in "testMS_1_wB testMS_0_nB testMS_0_wB"
    for NUM in $(seq 0 $NUMS)
    do 
        cp "experiment_parameters/$TEST_TYPE/parameters_$NUM.txt" parameters.txt
        /usr/bin/mpirun -np $NUMBER_OF_PROC /usr/local/bin/FreeFem++-mpi main_LIN_MPI.edp -o load
        /usr/bin/mpirun -np $NUMBER_OF_PROC /usr/local/bin/FreeFem++-mpi main_LINOS_MPI.edp -o load
        /usr/bin/mpirun -np $NUMBER_OF_PROC /usr/local/bin/FreeFem++-mpi main_CR_MPI.edp -o load
        /usr/bin/mpirun -np $NUMBER_OF_PROC /usr/local/bin/FreeFem++-mpi main_CROS_MPI.edp -o load
    done
done
