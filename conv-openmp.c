#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <string.h>
#include <omp.h>
#include <immintrin.h> // For aligned memory allocation

// For debugging
void test();

void loadPaddedMatrix(int *P, int *M, int w, int k);
void conv(int* M, int w, int* K, int k, int* C);

void loadPaddedMatrix(int *P, int *M, int w, int k) {
    // Pad width
    int pw = k/2;
    // Padded Matrix Width
    int pmw = w + 2*pw;

    for (int i = 0; i < w; ++i) {
        for (int j = 0; j < w; ++j) {
            P[(i+pw)*pmw + (j+pw)] = M[i*w + j];
        }
    }
}

/*
 * M: a w by w input matrix
 * K: a k by k input matrix
 * C: a w by w output matrix containing the result of
 *    padded convolution of M and K
 */
void conv(int* M, int w, int* K, int k, int* C) {
    // Pad width pw
    int pw = k/2;
    // Padded Matrix Width pmw
    int pmw = w + 2*pw;

    // Padded Matrix P
    int *P;
    posix_memalign((void**)&P, 64, sizeof(int) * pmw * pmw);
    memset(P, 0, pmw * pmw * sizeof(int));
    loadPaddedMatrix(P, M, w, k);

    // Block size (tunable parameter)
    int blockSize = 32;

    // Convolution with blocking and reduction
    #pragma omp parallel for collapse(2) schedule(dynamic)
    for (int ii = 0; ii < w; ii += blockSize) {
        for (int jj = 0; jj < w; jj += blockSize) {
            for (int i = ii; i < ii + blockSize && i < w; ++i) {
                for (int j = jj; j < jj + blockSize && j < w; ++j) {
                    // dot product of the part of the matrix with the kernel.
                    int dp = 0;
                    for (int a = 0; a < k; ++a) {
                        for (int b = 0; b < k; ++b) {
                            dp += P[(i+a)*pmw + j+b] * K[a*k + b];
                        }
                    }
                    C[i*w + j] = dp;
                }
            }
        }
    }

    free(P);
}

int* readMatrix(const char* file_path, int* w) {
    FILE* mat_file = fopen(file_path, "r");

    fscanf(mat_file, "%d", w);
    int* M = malloc(sizeof(int) * (*w) * (*w));

    int idx = 0;
    while (fscanf(mat_file, "%d", &M[idx++]) != EOF);

    fclose(mat_file);
    return M;
}

bool verify(const char* ans_path, int* C, int w) {
    FILE* ans_file = fopen(ans_path, "r");
    if (!ans_file) {
        fprintf(stderr, "Invalid answer file\n");
        exit(1);
    }

    int ans_w;
    fscanf(ans_file, "%d", &ans_w);
    if (ans_w != w) return false;

    int idx = 0;
    int num;
    while (fscanf(ans_file, "%d", &num) != EOF) {
        if (C[idx++] != num) return false;
    }

    fclose(ans_file);
    return true;
}

int main(int argc, char* argv[]) {
    if (argc < 4) {
        fprintf(stderr, "Usage: %s MATRIX KERNEL ANSWER\n", argv[0]);
        return 1;
    }

    // For testing
    // test();

    // Inputs are always square matrices.
    int w, k; // w ranged from 256x256 to 4096x4096
    int* M = readMatrix(argv[1], &w);
    int* K = readMatrix(argv[2], &k);
    int* C = malloc(sizeof(int) * w * w);

    struct timespec beg, end;
    clock_gettime(CLOCK_MONOTONIC, &beg);
    conv(M, w, K, k, C);
    clock_gettime(CLOCK_MONOTONIC, &end);

    if (verify(argv[3], C, w)) {
        double elapsed_time = (end.tv_sec - beg.tv_sec) * 1e6 + (end.tv_nsec - beg.tv_nsec) / 1e3;
        printf("Correct!\nElapsed time: %.2lf us\n", elapsed_time);
    } else {
        puts("Wrong!");
    }

    free(M);
    free(K);
    free(C);
    return 0;
}