using DataFrames

dfx = DataFrame(A=rand(1000), B=rand(1000))

@show dfx

print(dfx)

showall(dfx)
