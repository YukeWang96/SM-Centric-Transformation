CXX = nvcc

all: matrixMul_org matrixMul_smc

matrixMul_org: Example/MM/matrixMul_org.cu
	$(CXX) Example/MM/matrixMul_org.cu -o matrixMul_org -I/usr/local/cuda/samples/common/inc/

matrixMul_smc: Example/MM/matrixMul_smc.cu smc.cpp
	$(CXX) Example/MM/matrixMul_smc.cu -o matrixMul_smc -I/usr/local/cuda/samples/common/inc/

.PHONY:
test_org:
	./matrixMul_org
test_smc:
	./matrixMul_smc
clean:
	rm -rf *.out matrixMul_org matrixMul_smc