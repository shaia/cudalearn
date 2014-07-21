#include "cudamat.cuh"

/* ------------------------- Data copying ------------------------- */

/* Copy row slice from source to target. There is a block for every 32x32 chunk being copied. */
__global__ void kGetRowSlice(float* source, float* target, int start, int end, int width, int height)
{
	const int row = start + blockIdx.x * 32 + threadIdx.x;
	const int start_col = blockIdx.y * 32;

	const int end_col = (start_col + 32 < width) ? start_col + 32 : width;

	const int target_height = end - start;

	if (row < end)
	{
		for (int cur_col = start_col; cur_col < end_col; cur_col++)
			target[cur_col * target_height + row - start] = source[cur_col * height + row];
	}
}

__global__ void kSetRowSlice(float* source, float* target, int start, int end, int width, int height) 
{
	const int row = start + blockIdx.x * 32 + threadIdx.x;
	const int start_col = blockIdx.y * 32;

	const int end_col = (start_col + 32 < width) ? start_col + 32 : width;

	const int source_height = end - start;

	if (row < end) 
	{
		for (int cur_col = start_col; cur_col < end_col; cur_col++)
			target[cur_col * height + row] = source[cur_col * source_height + row - start];
	}
}

__global__ void kTranspose(float *odata, float *idata, int width, int height) 
{
	__shared__ float block[COPY_BLOCK_SIZE][COPY_BLOCK_SIZE + 1];

	// read the matrix tile into shared memory
	unsigned int xIndex = blockIdx.x * COPY_BLOCK_SIZE + threadIdx.x;
	unsigned int yIndex = blockIdx.y * COPY_BLOCK_SIZE + threadIdx.y;

	if ((xIndex < width) && (yIndex < height))
	{
		unsigned int index_in = yIndex * width + xIndex;

		block[threadIdx.y][threadIdx.x] = idata[index_in];
	}

	__syncthreads();

	// write the transposed matrix tile to global memory
	xIndex = blockIdx.y * COPY_BLOCK_SIZE + threadIdx.x;
	yIndex = blockIdx.x * COPY_BLOCK_SIZE + threadIdx.y;

	if ((xIndex < height) && (yIndex < width)) 
	{
		unsigned int index_out = yIndex * height + xIndex;

		odata[index_out] = block[threadIdx.x][threadIdx.y];
	}
}

/* ------------------------- Mathematical operations ------------------------- */

__global__ void kLessThan(float* mat1, float* mat2, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads) 
	{
		target[i] = mat1[i] < mat2[i];
	}
}

__global__ void kLessThanScalar(float* mat, float val, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads) 
	{
		target[i] = mat[i] < val;
	}
}

__global__ void kGreaterThan(float* mat1, float* mat2, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads) 
	{
		target[i] = mat1[i] > mat2[i];
	}
}

__global__ void kGreaterThanScalar(float* mat, float val, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads) 
	{
		target[i] = mat[i] > val;
	}
}

__global__ void kEquals(float* mat1, float* mat2, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads) 
	{
		target[i] = mat1[i] == mat2[i];
	}
}

__global__ void kEqualsScalar(float* mat, float val, float* target, unsigned int len)
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads) 
	{
		target[i] = mat[i] == val;
	}
}

__global__ void kMinimum(float* mat1, float* mat2, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads) 
	{
		target[i] = fminf(mat1[i], mat2[i]);
	}
}

__global__ void kMinimumScalar(float* mat, float val, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads) 
	{
		target[i] = fminf(mat[i], val);
	}
}

__global__ void kMaximum(float* mat1, float* mat2, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads) 
	{
		target[i] = fmaxf(mat1[i], mat2[i]);
	}
}

__global__ void kMaximumScalar(float* mat, float val, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads) 
	{
		target[i] = fmaxf(mat[i], val);
	}
}

__global__ void kMinColumnwise(float* mat, float* target, unsigned int width, unsigned int height) 
{
	__shared__ float min_vals[32];
	float cur_min = FLT_MAX;
	float val = 0;

	for (unsigned int i = threadIdx.x; i < height; i += 32)
	{
		val = mat[blockIdx.x * height + i];

		if (val < cur_min)
			cur_min = val;
	}

	min_vals[threadIdx.x] = cur_min;

	__syncthreads();

	if (threadIdx.x == 0) 
	{
		cur_min = FLT_MAX;

		for (unsigned int i = 0; i < 32; i++)
			if (min_vals[i] < cur_min)
				cur_min = min_vals[i];

		target[blockIdx.x] = cur_min;
	}
}

__global__ void kMinRowwise(float* mat, float* target, unsigned int width, unsigned int height) 
{
	__shared__ float min_vals[32];
	float cur_min = FLT_MAX;
	float val = 0;

	for (unsigned int i = threadIdx.x; i < width; i += 32)
	{
		val = mat[i * height + blockIdx.x];

		if (val < cur_min)
			cur_min = val;
	}

	min_vals[threadIdx.x] = cur_min;

	__syncthreads();

	if (threadIdx.x == 0) 
	{
		cur_min = FLT_MAX;

		for (unsigned int i = 0; i < 32; i++)
			if (min_vals[i] < cur_min)
				cur_min = min_vals[i];

		target[blockIdx.x] = cur_min;
	}
}

__global__ void kMaxColumnwise(float* mat, float* target, unsigned int width, unsigned int height)
{
	__shared__ float max_vals[32];
	float cur_max = -FLT_MAX;
	float val = 0;

	for (unsigned int i = threadIdx.x; i < height; i += 32)
	{
		val = mat[blockIdx.x * height + i];

		if (val > cur_max)
			cur_max = val;
	}

	max_vals[threadIdx.x] = cur_max;

	__syncthreads();

	if (threadIdx.x == 0)
	{
		cur_max = -FLT_MAX;

		for (unsigned int i = 0; i < 32; i++)
			if (max_vals[i] > cur_max)
				cur_max = max_vals[i];

		target[blockIdx.x] = cur_max;
	}
}

__global__ void kMaxRowwise(float* mat, float* target, unsigned int width, unsigned int height) 
{
	__shared__ float max_vals[32];
	float cur_max = -FLT_MAX;
	float val = 0;

	for (unsigned int i = threadIdx.x; i < width; i += 32) 
	{
		val = mat[i * height + blockIdx.x];

		if (val > cur_max)
			cur_max = val;
	}

	max_vals[threadIdx.x] = cur_max;

	__syncthreads();

	if (threadIdx.x == 0) 
	{
		cur_max = -FLT_MAX;

		for (unsigned int i = 0; i < 32; i++)
			if (max_vals[i] > cur_max)
				cur_max = max_vals[i];

		target[blockIdx.x] = cur_max;
	}
}

__global__ void kArgMinColumnwise(float* mat, float* target, unsigned int width, unsigned int height)
{
	__shared__ float min_vals[32];
	__shared__ unsigned int min_args[32];
	float cur_min = FLT_MAX;
	unsigned int cur_arg = 0;
	float val = 0;

	for (unsigned int i = threadIdx.x; i < height; i += 32) 
	{
		val = mat[blockIdx.x * height + i];

		if (val < cur_min) {
			cur_min = val;
			cur_arg = i;
		}
	}

	min_vals[threadIdx.x] = cur_min;
	min_args[threadIdx.x] = cur_arg;

	__syncthreads();

	if (threadIdx.x == 0)
	{
		cur_min = FLT_MAX;
		cur_arg = 0;

		for (unsigned int i = 0; i < 32; i++)
		{
			if (min_vals[i] < cur_min)
			{
				cur_min = min_vals[i];
				cur_arg = min_args[i];
			}
		}

		target[blockIdx.x] = cur_arg;
	}
}

__global__ void kArgMinRowwise(float* mat, float* target, unsigned int width, unsigned int height) 
{
	__shared__ float min_vals[32];
	__shared__ unsigned int min_args[32];
	float cur_min = FLT_MAX;
	unsigned int cur_arg = 0;
	float val = 0;

	for (unsigned int i = threadIdx.x; i < width; i += 32) 
	{
		val = mat[i * height + blockIdx.x];

		if (val < cur_min) 
		{
			cur_min = val;
			cur_arg = i;
		}
	}

	min_vals[threadIdx.x] = cur_min;
	min_args[threadIdx.x] = cur_arg;

	__syncthreads();

	if (threadIdx.x == 0)
	{
		cur_min = FLT_MAX;
		cur_arg = 0;

		for (unsigned int i = 0; i < 32; i++)
		{
			if (min_vals[i] < cur_min)
			{
				cur_min = min_vals[i];
				cur_arg = min_args[i];
			}
		}

		target[blockIdx.x] = cur_arg;
	}
}

__global__ void kArgMaxColumnwise(float* mat, float* target, unsigned int width, unsigned int height)
{
	__shared__ float max_vals[32];
	__shared__ unsigned int max_args[32];
	float cur_max = -FLT_MAX;
	unsigned int cur_arg = 0;
	float val = 0;

	for (unsigned int i = threadIdx.x; i < height; i += 32)
	{
		val = mat[blockIdx.x * height + i];

		if (val > cur_max) 
		{
			cur_max = val;
			cur_arg = i;
		}
	}

	max_vals[threadIdx.x] = cur_max;
	max_args[threadIdx.x] = cur_arg;

	__syncthreads();

	if (threadIdx.x == 0) {
		cur_max = -FLT_MAX;
		cur_arg = 0;

		for (unsigned int i = 0; i < 32; i++)
		{
			if (max_vals[i] > cur_max) 
			{
				cur_max = max_vals[i];
				cur_arg = max_args[i];
			}
		}

		target[blockIdx.x] = cur_arg;
	}
}

__global__ void kArgMaxRowwise(float* mat, float* target, unsigned int width, unsigned int height) 
{
	__shared__ float max_vals[32];
	__shared__ unsigned int max_args[32];
	float cur_max = -FLT_MAX;
	unsigned int cur_arg = 0;
	float val = 0;

	for (unsigned int i = threadIdx.x; i < width; i += 32) 
	{
		val = mat[i * height + blockIdx.x];

		if (val > cur_max) 
		{
			cur_max = val;
			cur_arg = i;
		}
	}

	max_vals[threadIdx.x] = cur_max;
	max_args[threadIdx.x] = cur_arg;

	__syncthreads();

	if (threadIdx.x == 0) {
		cur_max = -FLT_MAX;
		cur_arg = 0;

		for (unsigned int i = 0; i < 32; i++)
		{
			if (max_vals[i] > cur_max)
			{
				cur_max = max_vals[i];
				cur_arg = max_args[i];
			}
		}

		target[blockIdx.x] = cur_arg;
	}
}

__global__ void kSign(float* mat, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads) 
	{
		target[i] = mat[i] ? copysignf(1., mat[i]) : 0.;
	}
}

__global__ void kApplySigmoid(float* mat, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads) 
	{
		target[i] = 1 / (1 + __expf(-mat[i]));
	}
}


__global__ void kApplyTanh(float* mat, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;
	float mat_i, exp2x;

	for (unsigned int i = idx; i < len; i += numThreads)
	{
		mat_i = mat[i];
		exp2x = __expf(2 * mat_i);
		target[i] = 1 - 2 / (exp2x + 1);
	}
}

__global__ void kApplySoftThreshold(float* mat, float alpha, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads) 
	{
		float f = mat[i];
		target[i] = f > 0 ? max(0., f - alpha) : min(0., f + alpha);
	}
}

__global__ void kApplyAbs(float* mat, float* target, unsigned int len)
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads)
	{
		target[i] = mat[i] * ((mat[i] > 0) - (mat[i] < 0));
	}
}

__global__ void kApplyLog1PlusExp(float* mat, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;
	float mat_i;

	for (unsigned int i = idx; i < len; i += numThreads) 
	{
		mat_i = mat[i];
		if (mat_i > 0)
			target[i] = (__logf(1 + __expf(-mat_i)) + mat_i);
		else
			target[i] = __logf(1 + __expf(mat_i));
	}
}

__global__ void kLog(float* mat, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads)
	{
		target[i] = __logf(mat[i]);
	}
}

__global__ void kExp(float* mat, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads)
	{
		target[i] = __expf(mat[i]);
	}
}

__global__ void kGamma(float* mat, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads) 
	{
		target[i] = tgammaf(mat[i]);
	}
}

__global__ void kLogGamma(float* mat, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads) 
	{
		target[i] = lgammaf(mat[i]);
	}
}

__global__ void kSqrt(float* mat, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads) 
	{
		target[i] = sqrt(mat[i]);
	}
}

__global__ void kPow(float* mat, float pow, float* target, unsigned int len)
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads) 
	{
		target[i] = powf(mat[i], pow);
	}
}

__global__ void kPowMatrix(float* mat, float* pow, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads)
	{
		target[i] = powf(mat[i], pow[i]);
	}
}

__global__ void kReciprocal(float* mat, float* target, unsigned int len)
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads)
		target[i] = 1.f / mat[i];
}

__global__ void kAddColVector(float* mat, float* vec, float* tgtMat, unsigned int width, unsigned int height)
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < width * height; i += numThreads) 
	{
		tgtMat[i] = mat[i] + vec[i % height];
	}
}

__global__ void kAddRowVector(float* mat, float* vec, float* tgtMat, unsigned int width, unsigned int height) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < width * height; i += numThreads)
	{
		tgtMat[i] = mat[i] + vec[i / height];
	}
}

__global__ void kAddColMult(float* mat, float* vec, float* tgtMat, float mult, unsigned int width, unsigned int height) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < width * height; i += numThreads)
	{
		tgtMat[i] = mat[i] + mult * vec[i % height];
	}
}

__global__ void kMultByColVector(float* mat, float* vec, float* tgtMat, unsigned int width, unsigned int height)
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < width * height; i += numThreads)
	{
		tgtMat[i] = mat[i] * vec[i % height];
	}
}

__global__ void kMultByRowVector(float* mat, float* vec, float* tgtMat, unsigned int width, unsigned int height) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < width * height; i += numThreads)
	{
		tgtMat[i] = mat[i] * vec[i / height];
	}
}

__global__ void kDivByColVector(float* mat, float* vec, float* tgtMat, unsigned int width, unsigned int height)
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < width * height; i += numThreads)
	{
		tgtMat[i] = mat[i] / vec[i % height];
	}
}

__global__ void kDivByRowVector(float* mat, float* vec, float* tgtMat, unsigned int width, unsigned int height) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < width * height; i += numThreads) 
	{
		tgtMat[i] = mat[i] / vec[i / height];
	}
}

__global__ void kAdd(float* a, float* b, float* dest, unsigned int numEls)
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < numEls; i += numThreads)
	{
		dest[i] = a[i] + b[i];
	}
}

__global__ void kSubtract(float* a, float* b, float* dest, unsigned int numEls) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < numEls; i += numThreads) 
	{
		dest[i] = a[i] - b[i];
	}
}

__global__ void kDivide(float* a, float* b, float* dest, unsigned int numEls) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < numEls; i += numThreads) 
	{
		dest[i] = a[i] / b[i];
	}
}

__global__ void kMult(float* a, float* b, float* dest, unsigned int numEls) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < numEls; i += numThreads) 
	{
		dest[i] = a[i] * b[i];
	}
}

__global__ void kMultScalar(float* mat, float alpha, float* dest, unsigned int len)
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads) {
		dest[i] = alpha * mat[i];
	}
}

__global__ void kAssignScalar(float* dest, float alpha, unsigned int len)
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads)
	{
		dest[i] = alpha;
	}
}

__global__ void kDivideScalar(float* mat, float alpha, float* dest, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads) 
	{
		dest[i] = mat[i] / alpha;
	}
}

__global__ void kAddScalar(float* a, float alpha, float* dest, unsigned int numEls)
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < numEls; i += numThreads)
	{
		dest[i] = a[i] + alpha;
	}
}

__global__ void kSelectRows(float* source, float* target, float* indices, int nRowIs, int nCols, int nSourceRows)
{
	__shared__ int sourceRowIndices[32];
	const int startTargetRowI = blockIdx.x * 32;
	const int tid = threadIdx.x;
	const int localNRowIs = min(32, nRowIs - startTargetRowI);

	// cooperatively load 32 row indices
	if (tid < localNRowIs)
	{
		sourceRowIndices[tid] = int(indices[startTargetRowI + tid]);
		if (sourceRowIndices[tid]<0)
			sourceRowIndices[tid] += nSourceRows;
		if (sourceRowIndices[tid]<0 || sourceRowIndices[tid] >= nSourceRows)
			sourceRowIndices[tid] = -1;
	}
	__syncthreads();

	// copy 32 rows
	for (int i = 0; i<localNRowIs; i++)
	{
		const int targetRowI = startTargetRowI + i, sourceRowI = sourceRowIndices[i];
		for (int colI = tid; colI<nCols; colI += 32)
			target[targetRowI * nCols + colI] = sourceRowI == -1 ? (1.0 / 0.0 - 1.0 / 0.0) : source[sourceRowI * nCols + colI];
	}
}

__global__ void kSetSelectedRows(float* target, float* source, float* indices, int nRowIs, int nCols, int nTargetRows)
{
	__shared__ int targetRowIndices[32];
	const int startSourceRowI = blockIdx.x * 32;
	const int tid = threadIdx.x;
	const int localNRowIs = min(32, nRowIs - startSourceRowI);

	// cooperatively load 32 row indices
	if (tid < localNRowIs)
	{
		targetRowIndices[tid] = int(indices[startSourceRowI + tid]);
		if (targetRowIndices[tid]<0)
			targetRowIndices[tid] += nTargetRows;
		if (targetRowIndices[tid]<0 || targetRowIndices[tid] >= nTargetRows)
			targetRowIndices[tid] = -1;
	}

	__syncthreads();

	// copy 32 rows
	for (int i = 0; i<localNRowIs; i++){
		const int sourceRowI = startSourceRowI + i, targetRowI = targetRowIndices[i];
		for (int colI = tid; colI<nCols; colI += 32)
			target[targetRowI * nCols + colI] = targetRowI == -1 ? (1.0 / 0.0 - 1.0 / 0.0) : source[sourceRowI * nCols + colI];
	}
}


__global__ void kWhere(float* condition_mat, float* if_mat, float* else_mat, float* target, unsigned int len) 
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int numThreads = blockDim.x * gridDim.x;

	for (unsigned int i = idx; i < len; i += numThreads)
	{
		target[i] = condition_mat[i] ? if_mat[i] : else_mat[i];
	}
}

