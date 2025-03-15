#!/bin/bash

# Define the variations for matrix size, kernel size, and number of threads
matrix_sizes=(256 512 1024 4096)  # Matrix sizes (A)
kernel_sizes=(3 5 7 9)            # Kernel sizes (B)
num_threads=(1 2 4 8 16 32)       # Number of threads (C)

# Compile the programs
gcc conv.c -o conv
gcc conv-openmp.c -o conv-openmp -fopenmp

# Loop through all combinations of matrix size and kernel size
for matrix_size in "${matrix_sizes[@]}"; do
    for kernel_size in "${kernel_sizes[@]}"; do
        # Print message for non-OpenMP program
        echo "Running non-OpenMP convolution for matrix size ${matrix_size}x${matrix_size}, kernel size ${kernel_size}..."
        
        # Run the non-OpenMP version (once per matrix size and kernel size)
        ./conv "mat-${matrix_size}.txt" "ker-${kernel_size}.txt" "ans-${matrix_size}-${kernel_size}.txt"
        
        # Loop through the number of threads for the OpenMP version
        for threads in "${num_threads[@]}"; do
            # Print message for OpenMP program
            echo "Running OpenMP convolution for matrix size ${matrix_size}x${matrix_size}, kernel size ${kernel_size}, using ${threads} threads..."
            
            # Run the OpenMP version
            OMP_NUM_THREADS=${threads} ./conv-openmp "mat-${matrix_size}.txt" "ker-${kernel_size}.txt" "ans-${matrix_size}-${kernel_size}.txt"
        done
    done
done
