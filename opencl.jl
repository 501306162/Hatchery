using OpenCL

srcDir = dirname(Base.source_path())

kernelSource = readstring(joinpath(srcDir, "contract.cl"))

device, ctx, queue = cl.create_compute_context()



prg  = cl.Program(ctx, source=kernelSource) |> cl.build!
mmul = cl.Kernel(prg, "contract")



d = cl.devices()

cl.num_platforms()

cl.info(d[], :max_work_group_size)
cl.info(d[2], :max_work_group_size)
cl.info(d[], :max_work_item_dims)
cl.info(d[2], :max_work_item_dims)
cl.info(d[], :local_mem_size)
cl.info(d[2], :local_mem_size)
cl.info(d[], :max_compute_units)
cl.info(d[2], :max_compute_units)
cl.info(d[], :max_work_item_size)
cl.info(d[2], :max_work_item_size)






a = rand(Float32, 50_000)
b = rand(Float32, 50_000)



a_buff = cl.Buffer(Float32, ctx, (:r, :copy), hostbuf=a)
b_buff = cl.Buffer(Float32, ctx, (:r, :copy), hostbuf=b)
c_buff = cl.Buffer(Float32, ctx, :w, length(a))

p = cl.Program(ctx, source=sum_kernel) |> cl.build!
k = cl.Kernel(p, "contract")

queue(k, size(a), nothing, a_buff, b_buff, c_buff)

r = cl.read(queue, c_buff)







function contract{Tv<:Real,N,Ti<:NTuple}(𝑻::BlockedTensor{Tv,N,Ti,4}, 𝐕::Matrix)
    𝐌 = zeros(𝐕)
    for idx in 𝑻.idxs
        i, j = idx
        si, sj = zeros(size(𝑻.vals,1)), zeros(size(𝑻.vals,1))
        vi = 𝐕[:,i]
        vj = 𝐕[:,j]
        for b = 1:size(𝑻.vals, 2)
            for a = 1:size(𝑻.vals, 1)
                si[a] += 𝑻.vals[a,b] * vj[b]
                sj[b] += 𝑻.vals[a,b] * vi[a]
            end
        end


        𝐌[:,i] .+= si
        𝐌[:,j] .+= sj
    end
    return 𝐌
end
