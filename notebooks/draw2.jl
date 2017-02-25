function meshgrid(quiverMatrix)
    r, c = size(quiverMatrix)
    𝐗 = [i for i in 1:r, j in 1:c]
    𝐘 = [j for i in 1:r, j in 1:c]
    Δ𝐗 = [ 𝐯[1] for 𝐯 in quiverMatrix]
    Δ𝐘 = [ 𝐯[2] for 𝐯 in quiverMatrix]
    return 𝐗+Δ𝐗, 𝐘+Δ𝐘
end

# Plots.jl recipe
@userplot DisplacementField

@recipe function f(disField::DisplacementField; xyInv=false)
    if length(disField.args) != 2 || !(typeof(disField.args[1]) <: AbstractMatrix) || !(typeof(disField.args[2]) <: AbstractMatrix)
        error("DisplacementField should be given two matrices.  Got: $(typeof(disField.args))")
    end
    𝐗, 𝐘 = disField.args
    itpX = interpolate(𝐗, BSpline(Cubic(Natural())), OnGrid())
    itpY = interpolate(𝐘, BSpline(Cubic(Natural())), OnGrid())

    r, c = size(𝐗)

    𝐗 = itpX[1:r,1:c]
    𝐘 = itpY[1:r,1:c]

    # default
    size --> (400,400)
    grid --> false
    ticks --> 1:r

    legend := false

    for i = 1:r
        @series xyInv ? (𝐗[i,:], 𝐘[i,:]) : (𝐘[i,:], 𝐗[i,:])
    end

    for j = 1:c
        @series xyInv ? (𝐗[:,j], 𝐘[:,j]) : (𝐘[:,j], 𝐗[:,j])
    end
end
