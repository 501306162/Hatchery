using Interpolations
itptype = Constant()

upDims = (6,6)
downDims = (3,3)

a = [1 2 3;
     2 3 4;
     3 4 5]

upknots = ntuple(x->linspace(1, upDims[x], downDims[x]), 2)
upitp = interpolate(upknots, a, Gridded(itptype))
upitp[1:6,1:6]



downknots = ntuple(x->linspace(1, downDims[x], upDims[x]), 2)
downitp = interpolate(downknots, upitp[1:upDims[1], 1:upDims[2]], Gridded(itptype))

downitp[1:downDims[1], 1:downDims[2]] == a

upitp[1:6, 1:6]

fixed = upitp[1:6, 1:6]

moving = copy(fixed)

# moving[1:2,1:2] = 5.0
# moving[5:6,5:6] = 1.0

moving[1,1] = 5.0
moving[6,6] = 1.0

moving


movingDownitp = interpolate(downknots, moving, Gridded(itptype))

movingDown = movingDownitp[1:3, 1:3]

a

using FixedSizeArrays

D = [Vec(1,1) Vec(0,0) Vec(0,0);
     Vec(0,0) Vec(0,0) Vec(0,0);
     Vec(0,0) Vec(0,0) Vec(-1,-1)] .* Vec()

Ditp = interpolate(upknots, D, Gridded(itptype))

Ditp[1:6, 1:6]

Ditp = 5/2*Ditp[1:6, 1:6]


movingitp = interpolate(moving, BSpline(Linear()), OnGrid())

movingitp

warp = zeros(6,6)
for 𝒊 in CartesianRange((6,6))
    𝐝 = Vec(𝒊.I...) + Ditp[𝒊]
    warp[𝒊] = movingitp[𝐝...]
end

warp








fixed









b = interpolate(downknots, warp, Gridded(Linear()))

b[1:3,1:3]




a
