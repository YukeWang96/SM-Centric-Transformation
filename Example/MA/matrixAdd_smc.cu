/**
 * Naive Example of Matrix Addition
 *
 */

/**
 * Matrix multiplication: C = A + B.
 */

// System includes
#include <stdio.h>
#include <assert.h>

// CUDA runtime
#include <cuda_runtime.h>

// Helper functions and utilities to work with CUDA
#include <helper_functions.h>
#include <helper_cuda.h>

/* SMC change: One line added */
#include "../../smc.h"

/**
 * Matrix addition (CUDA Kernel) on the device: C = A + B
 * w is matrix width, h is matrix height
 */
__global__ void
matrixAddCUDA(float *C, float *A, float *B, int w, int h,
	      dim3 __SMC_orgGridDim, int __SMC_workersNeeded, int *__SMC_workerCount, int * __SMC_newChunkSeq, int * __SMC_seqEnds) /* SMC change: six extra parameters added to the call at the end */
{

   __SMC_Begin   /* SMC change: a line added  */

    /* SMC change: replacing the usage of blockIdx.x and blockIdx.y with references to __SMC_chunkID */
    // Block index
    //int bx = blockIdx.x;
    //int by = blockIdx.y;
     int bx = (int)fmodf((float)__SMC_chunkID, (float)__SMC_orgGridDim.x);
   int by = (int)(__SMC_chunkID/__SMC_orgGridDim.x);

    
    // Thread local index
    int txl = threadIdx.x;
    int tyl = threadIdx.y;

    // Thread global index
    int tx = txl+bx*blockDim.x;
    int ty = tyl+by*blockDim.y;
    int glbIdx = ty*w+tx;

    int maxidx = w*h-1;
    if (glbIdx<0 || glbIdx>maxidx){
      printf("Error: glbIdx is %d.\n", glbIdx);
    }
    else{
      // Do addition
      C[glbIdx] = A[glbIdx] + B[glbIdx];
    }

    __SMC_End   /* SMC change: a line added */
}

void constantInit(float *data, int size)
{
    for (int i = 0; i < size; ++i)
    {
      data[i] = (float)rand()/RAND_MAX;
    }
}

int matrixAdd_gold(float *A, float *B, float*C, int size){
  for (int i=0;i<size;i++)
    C[i] = A[i] + B[i];
  return 0;
}

/**
 * A wrapper that calls the GPU kernel
 */
int matrixAdd(int block_size, int w, int h)
{
    // Allocate host memory for matrices A and B
  unsigned int sz = w*h;
  unsigned int mem_size = sizeof(float) * sz;
  float *h_A = (float *)malloc(mem_size);
  float *h_B = (float *)malloc(mem_size);
  float *h_C = (float *) malloc(mem_size);
  
    // Initialize host memory
    constantInit(h_A, sz);
    constantInit(h_B, sz);

    // Allocate device memory
    float *d_A, *d_B, *d_C;
    cudaError_t error;
    error = cudaMalloc((void **) &d_A, mem_size);
    error = cudaMalloc((void **) &d_B, mem_size);
    error = cudaMalloc((void **) &d_C, mem_size);
    
    // copy host memory to device
    error = cudaMemcpy(d_A, h_A, mem_size, cudaMemcpyHostToDevice);

    if (error != cudaSuccess)
    {
        printf("cudaMemcpy (d_A,h_A) returned error %s (code %d), line(%d)\n", cudaGetErrorString(error), error, __LINE__);
        exit(EXIT_FAILURE);
    }

    error = cudaMemcpy(d_B, h_B, mem_size, cudaMemcpyHostToDevice);

    if (error != cudaSuccess)
    {
        printf("cudaMemcpy (d_B,h_B) returned error %s (code %d), line(%d)\n", cudaGetErrorString(error), error, __LINE__);
        exit(EXIT_FAILURE);
    }

    // Setup execution parameters
    dim3 threads(block_size, block_size);

    /* SMC change: here, the call to grid() was removed, instead, this new variable is created based on the parameters in that original call */
    dim3 __SMC_orgGridDim(w / threads.x, h / threads.y);
	  
    printf("Computing result using CUDA Kernel...\n");

    /* SMC change: a line added */
    __SMC_init();

    /* SMC change: added four parameters to the call at the end */
    matrixAddCUDA<<< grid, threads >>>(d_C, d_A, d_B, w, h, __SMC_orgGridDim, __SMC_workersNeeded, __SMC_workerCount, __SMC_newChunkSeq, __SMC_seqEnds); /* SMC change:five extra parameters are used at the end*/

    printf("done\n");

    cudaDeviceSynchronize();

    // Allocate CUDA events that we'll use for timing
    cudaEvent_t start;
    error = cudaEventCreate(&start);

    if (error != cudaSuccess)
    {
        fprintf(stderr, "Failed to create start event (error code %s)!\n", cudaGetErrorString(error));
        exit(EXIT_FAILURE);
    }

    cudaEvent_t stop;
    error = cudaEventCreate(&stop);

    if (error != cudaSuccess)
    {
        fprintf(stderr, "Failed to create stop event (error code %s)!\n", cudaGetErrorString(error));
        exit(EXIT_FAILURE);
    }

    // Copy result from device to host
    error = cudaMemcpy(h_C, d_C, mem_size, cudaMemcpyDeviceToHost);

    if (error != cudaSuccess)
    {
        printf("cudaMemcpy (h_C,d_C) returned error %s (code %d), line(%d)\n", cudaGetErrorString(error), error, __LINE__);
        exit(EXIT_FAILURE);
    }

    /* check the result correctness */
    float g_sum = 0, c_sum=0;
    for (int i=0;i<w*h;i++)       g_sum += h_C[i];
    matrixAdd_gold(h_A, h_B, h_C, w*h);
    for (int i=0;i<w*h;i++)       c_sum += h_C[i];    
    if (abs(g_sum - c_sum)<1e-10){
      printf("Pass...\n");
    }
    else{
      printf("Fail: %f vs. %f.\n", g_sum, c_sum);
    }
    
    // Clean up memory
    free(h_A);
    free(h_B);
    free(h_C);
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);

    return 0;
}


/**
 * Program main
 */
int main(int argc, char **argv)
{
    printf("[Matrix Addition Using CUDA] - Starting...\n");

    if (checkCmdLineFlag(argc, (const char **)argv, "help") ||
        checkCmdLineFlag(argc, (const char **)argv, "?"))
    {
        printf("      -w=Width -h=Height (Width x Height of Matrix)\n");
        printf("  Note: w and h should be multiples of 32, and neither shall exceed 1024.\n");

        exit(EXIT_SUCCESS);
    }

    int block_size = 32;

    int w=1024;
    int h=1024;

    // width of Matrix A
    if (checkCmdLineFlag(argc, (const char **)argv, "w"))
    {
        w = getCmdLineArgumentInt(argc, (const char **)argv, "w");
    }

    // height of Matrix A
    if (checkCmdLineFlag(argc, (const char **)argv, "h"))
    {
        h = getCmdLineArgumentInt(argc, (const char **)argv, "h");
    }

    if (w>1024 || h>1024 || fmod(w,32) || fmod(h,32))
    {
      printf("Error: w and h should be multiples of 32, and neither shall exceed 1024.\n");
      exit(EXIT_FAILURE);
    }

    printf("block_size=%d, matrix width=%d, matrix height=%d\n", block_size, w,h);

    int matrix_result = matrixAdd(block_size, w, h);
      
    exit(matrix_result);
}
