using Base.Cartesian

function sum_diff_exp{S,T<:Real}(f, fixedImg::AbstractArray, movingImg::AbstractArray, displacements::AbstractArray{SVector{S,T}}, gridDims::NTuple)
    imageDims = size(fixedImg)
    imageDims == size(movingImg) || throw(DimensionMismatch("fixedImg and movingImg must have the same size."))
    length(imageDims) == S || throw(DimensionMismatch("Images and displacement vectors are NOT in the same dimension."))
    cost = zeros(length(displacements), gridDims...)
    # blockDims = imageDims .÷ gridDims
    blockDims = map(div, imageDims, gridDims)
    gridRange = CartesianRange(gridDims)
    𝒊₀ = first(gridRange)
    for 𝒊 in gridRange, a in eachindex(displacements)
        # offset = (𝒊 - 𝒊₀).I .* blockDims (pending 0.6)
        offset = map(*, (𝒊 - 𝒊₀).I, blockDims)
        s = zero(Float64)
        𝐤 = [0,0,0]
        𝐝 = [0,0,0]
        for 𝒋 in CartesianRange(blockDims)
            # 𝐤 = offset .+ 𝒋.I
            map!(+, 𝐤, offset)
            map!(+, 𝐤, 𝒋.I)
            # 𝐝 = 𝐤 .+ blockDims .* displacements[a]
            map!(+, 𝐝, 𝐤)
            map!(+, 𝐝, map(*, blockDims, displacements[a]))
            # if checkbounds(Bool, movingImg, 𝐝...)
            if (1 ≤ 𝐝[1] ≤ imageDims[1]) && (1 ≤ 𝐝[2] ≤ imageDims[2]) && (1 ≤ 𝐝[3] ≤ imageDims[3])
                s += e^-f(fixedImg[𝐤...] - movingImg[𝐝...])
            end
            𝐤 .= [0,0,0]
            𝐝 .= [0,0,0]
        end
        cost[a,𝒊] = s
    end
    return reshape(cost, length(displacements), prod(gridDims))
end

function sum_diff_exp2{S,T<:Real}(f, fixedImg::AbstractArray, movingImg::AbstractArray, displacements::AbstractArray{SVector{S,T}}, gridDims::NTuple)
    imageDims = size(fixedImg)
    imageDims == size(movingImg) || throw(DimensionMismatch("fixedImg and movingImg must have the same size."))
    length(imageDims) == S || throw(DimensionMismatch("Images and displacement vectors are NOT in the same dimension."))
    cost = zeros(length(displacements), gridDims...)
    # blockDims = imageDims .÷ gridDims
    blockDims = map(div, imageDims, gridDims)
    gridRange = CartesianRange(gridDims)
    𝒊₀ = first(gridRange)
    for 𝒊 in gridRange, a in eachindex(displacements)
        # offset = (𝒊 - 𝒊₀).I .* blockDims (pending 0.6)
        # offset = map(*, (𝒊 - 𝒊₀).I, blockDims)
        offsetX = (𝒊 - 𝒊₀)[1] * blockDims[1]
        offsetY = (𝒊 - 𝒊₀)[2] * blockDims[2]
        offsetZ = (𝒊 - 𝒊₀)[3] * blockDims[3]
        s = zero(Float64)
        for 𝒋 in CartesianRange(blockDims)
            # 𝐤 = offset .+ 𝒋.I
            # 𝐤 = map(+, offset, 𝒋.I)
            𝐤x = offsetX + 𝒋[1]
            𝐤y = offsetY + 𝒋[2]
            𝐤z = offsetZ + 𝒋[3]
            # 𝐝 = 𝐤 .+ blockDims .* displacements[a]
            # 𝐝 = map(+, 𝐤, map(*, blockDims, displacements[a]))
            𝐝x = 𝐤x + blockDims[1] * displacements[a][1]
            𝐝y = 𝐤y + blockDims[2] * displacements[a][2]
            𝐝z = 𝐤z + blockDims[3] * displacements[a][3]
            # if checkbounds(Bool, movingImg, 𝐝...)
            if (1 ≤ 𝐝x ≤ imageDims[1]) && (1 ≤ 𝐝y ≤ imageDims[2]) && (1 ≤ 𝐝z ≤ imageDims[3])
                s += e^-f(fixedImg[𝐤x,𝐤y,𝐤z] - movingImg[𝐝x,𝐝y,𝐝z])
            # if (1 ≤ 𝐝[1] ≤ imageDims[1]) && (1 ≤ 𝐝[2] ≤ imageDims[2]) && (1 ≤ 𝐝[3] ≤ imageDims[3])
            #     s += e^-f(fixedImg[𝐤...] - movingImg[𝐝...])
            end
        end
        cost[a,𝒊] = s
    end
    return reshape(cost, length(displacements), prod(gridDims))
end

sadexp(fixedImg, movingImg, displacements, gridDims=size(fixedImg)) = sum_diff_exp(abs, fixedImg, movingImg, displacements, gridDims)
sadexp2(fixedImg, movingImg, displacements, gridDims=size(fixedImg)) = sum_diff_exp2(abs, fixedImg, movingImg, displacements, gridDims)





@generated function sum_diff{N,Ti<:Real,Td<:Real}(f, fixedImg::AbstractArray{Ti,N}, movingImg::AbstractArray{Ti,N}, displacements::AbstractArray{SVector{N,Td}}, gridDims::NTuple)
    quote
        imageDims = size(fixedImg)
        imageDims == size(movingImg) || throw(DimensionMismatch("fixedImg and movingImg must have the same size."))
        length(imageDims) == $N || throw(DimensionMismatch("Images and displacement vectors are NOT in the same dimension."))
        # blockDims = imageDims .÷ gridDims
        blockDims = map(div, imageDims, gridDims)
        cost = zeros(length(displacements), gridDims...)
        for 𝒊 in CartesianRange(gridDims), a in eachindex(displacements)
            @nexprs $N x->offset_x = (𝒊[x] - 1) * blockDims[x]
            s = zero(Float64)
            for 𝒋 in CartesianRange(blockDims)
                @nexprs $N x->𝐤_x = offset_x + 𝒋[x]
                @nexprs $N x->𝐝_x = 𝐤_x + blockDims[x] * displacements[a][x]
                if @nall $N x->(1 ≤ 𝐝_x ≤ imageDims[x])
                    fixed = @nref $N fixedImg 𝐤
                    moving = @nref $N movingImg 𝐝
                    s += e^-f(fixed - moving)
                end
            end
            cost[a,𝒊] = s
        end
        reshape(cost, length(displacements), prod(gridDims))
    end
end
