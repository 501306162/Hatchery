__kernel void contract(
    const int idxDim,
    const int labelNum,
    const int valsDim1,
    const int valsDim2,
    __global float* idxI,
    __global float* idxJ,
    __global float* vals,
    __global float* V,
    __global float* M,
    __local float* vi,
    __local float* vj)
{
    int a, b, k;
    int idxID = get_global_id(0);

    float si[1024];
    float sj[1024];

    int localID = get_local_id(0);
    int localSize = get_local_size(0);

    int i = idxI[idxID];
    int j = idxJ[idxID];

    for (k=localID; k<labelNum; k+=localSize) {
        vi[k] = V[i*labelNum+k];
        vj[k] = V[j*labelNum+k];
    }
    barrier(CLK_LOCAL_MEM_FENCE);

    if (idxID < idxDim) {
        for (a = 0; a < valsDim1; a++) {
            for (b = 0; b < valsDim2; b++) {
                si[a] += vals[a*valsDim1+b] * vj[b];
                sj[b] += vals[a*valsDim2+b] * vi[a];
            }
        }
        for (k=0; k<labelNum; k++) {
            M[i*labelNum+k] = si[k];
            M[j*labelNum+k] = sj[k];
        }
    }
}
