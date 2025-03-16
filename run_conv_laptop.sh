#!/bin/bash

# Define the variations for matrix size, kernel size, and number of threads
matrix_sizes=(256 512 1024 4096)  # Matrix sizes
kernel_sizes=(3 5 7 9)            # Kernel sizes
num_threads=(1 2 4)       # Number of threads
num_runs=100                      # Number of times to repeat each test

# Output file for collecting data
output_file="execution_times_dynamic(local).csv"

# Create a header for the CSV file
echo "Matrix Size,Kernel Size,Threads,Run ID,Execution Time (Seconds)" > $output_file

# Compile the programs
gcc conv.c -o conv
gcc conv-openmp.c -o conv-openmp -fopenmp

# Loop through all combinations of matrix size and kernel size
for matrix_size in "${matrix_sizes[@]}"; do
    for kernel_size in "${kernel_sizes[@]}"; do
        # Run the non-OpenMP version 100 times
        for run_id in $(seq 1 $num_runs); do
            echo "Running non-OpenMP: Matrix ${matrix_size}x${matrix_size}, Kernel ${kernel_size}, Run ${run_id}..."
            
            # Collect execution time
            exec_time=$(./conv "mat-${matrix_size}.txt" "ker-${kernel_size}.txt" "ans-${matrix_size}-${kernel_size}.txt" | grep "Time taken" | awk '{print $4}')

            # Append the result to the CSV file
            echo "${matrix_size}x${matrix_size},${kernel_size},1,${run_id},${exec_time}" >> $output_file
        done

        # Run the OpenMP version for different thread counts 100 times each
        for threads in "${num_threads[@]}"; do
            for run_id in $(seq 1 $num_runs); do
                echo "Running OpenMP: Matrix ${matrix_size}x${matrix_size}, Kernel ${kernel_size}, Threads ${threads}, Run ${run_id}..."
                
                # Collect execution time
                exec_time=$(OMP_NUM_THREADS=${threads} ./conv-openmp "mat-${matrix_size}.txt" "ker-${kernel_size}.txt" "ans-${matrix_size}-${kernel_size}.txt" | grep "Time taken" | awk '{print $4}')

                # Append the result to the CSV file
                echo "${matrix_size}x${matrix_size},${kernel_size},${threads},${run_id},${exec_time}" >> $output_file
            done
        done
    done
done

echo "Execution times have been saved to $output_file"