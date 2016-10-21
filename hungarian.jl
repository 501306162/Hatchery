function hungarian{T<:Real}(input::Array{T,2})
    A = copy(input)
    Adims = size(A)
    # preliminaries
    # "no lines are covered;"
    rowCovered = falses(Adims[1])
    columnCovered = falses(Adims[2])

    # "no zeros are starred or primed."
    # we can use a sparse matrix Zs to store these three kinds of markers:
    # 0 => ordinary zero
    # 2 => starred zero
    # 3 => primed zero
    # (TODO: use @enum instead of hard-coded integer)
    Zs = spzeros(Int, Adims...)

    # "consider a row of the matrix A;
    #  subtract from each element in this row the smallest element of this row.
    #  do the same for each row."
    # it's succinct to implement this using broadcasting.
    A .-= minimum(A, 2)

    # "then consider each column of the resulting matrix and subtract from each
    #  column its smallest entry."
    A .-= minimum(A, 1)

    # "consider a zero Z of the matrix;"
    for ii in CartesianRange(Adims)
        # "if there is no starred zero in its row and none in its column, star Z.
        #  repeat, considering each zero in the matrix in turn;"
        if A[ii]==0
            Zs[ii] = 1
            if !( any(Zs[ii[1],:] .== 2) || any(Zs[:,ii[2]] .== 2) )
                Zs[ii] = 2
                # "then cover every column containing a starred zero."
                columnCovered[ii[2]] = true
            end
        end
    end

    # looping
    deep = [0, 0, 0]
    stepNum = 1
    while stepNum != 0
        if stepNum == 1
            deep[1] += 1
            stepNum = step1!(A, Zs, rowCovered, columnCovered)
        elseif stepNum == 2
            deep[2] += 1
            stepNum = step2!(Zs, rowCovered, columnCovered)
        elseif stepNum == 3
            deep[3] += 1
            stepNum = step3!(A, Zs, rowCovered, columnCovered)
        end
    end
    @show deep
    return Zs
end

function step1!{T<:Real}(A::Array{T,2},
                Zs::SparseMatrixCSC{Int,Int},
                rowCovered::BitArray{1},
                columnCovered::BitArray{1}
               )
    Adims = size(A)
    # step 1
    zeroCoveredNum = 0
    total0 = length(find(A.==0))
    # "repeat until all zeros are covered."
    while zeroCoveredNum < total0
        zeroCoveredNum = 0
        for ii in CartesianRange(Adims)
            # "choose a non-covered zero and prime it, consider the row containing it."
            if A[ii]==0
                if columnCovered[ii[2]] == false && rowCovered[ii[1]] == false
                    Zs[ii] = 3
                    # "if there is a starred zero Z in this row"
                    columnZ = findfirst(Zs[ii[1],:] .== 2)
                    if columnZ != 0
                        # "cover this row and uncover the column of Z"
                        rowCovered[ii[1]] = true
                        columnCovered[columnZ] = false
                    else
                        # "if there is no starred zero in this row,
                        #  go at once to step 2."
                        return stepNum = 2
                    end
                else
                    # this zero is covered
                    zeroCoveredNum += 1
                end
            end
        end
    end
    # "go to step 3."
    return stepNum = 3
end

function step2!(Zs::SparseMatrixCSC{Int,Int},
                rowCovered::BitArray{1},
                columnCovered::BitArray{1}
               )
    ZsDims = size(Zs)
    rows = rowvals(Zs)
    # step 2
    sequence = Int[]
    flag = false
    # "there is a sequence of alternating primed and starred zeros, constructed
    #  as follows:"
    # "let Z₀ denote the uncovered 0′.[there is only one.]"
    for c = 1:ZsDims[2], i in nzrange(Zs, c)
        r = rows[i]
        # note that Z₀ is an **uncovered** 0′
        if Zs[r,c] == 3 && columnCovered[c] == false && rowCovered[r] == false
            # push Z₀(uncovered 0′) into the sequence
            push!(sequence, sub2ind(ZsDims, r, c))
            # "let Z₁ denote the 0* in the Z₀'s column.(if any)"
            # find 0* in Z₀'s column
            for j in nzrange(Zs, c)
                Z₁r = rows[j]
                if Zs[Z₁r, c] == 2
                    # push Z₁(0*) into the sequence
                    push!(sequence, sub2ind(ZsDims, Z₁r, c))
                    # set sequence continue flag => true
                    flag = true
                    break
                end
            end
            break
        end
    end
    # "let Z₂ denote the 0′ in Z₁'s row(there will always be one)."
    # "let Z₃ denote the 0* in the Z₂'s column."
    # "continue until the sequence stops at a 0′ Z₂ⱼ, which has no 0* in its column."
    while flag
        flag = false
        r = ind2sub(ZsDims, sequence[end])[1]
        # find Z₂ in Z₃'s row
        for c = 1:ZsDims[2]
            if Zs[r,c] == 3
                # push Z₂ into the sequence
                push!(sequence, sub2ind(ZsDims, r, c))
                # find 0* in Z₂'s column
                for j in nzrange(Zs, c)
                    Z₃r = rows[j]
                    if Zs[Z₃r, c] == 2
                        # push Z₃(0*) into the sequence
                        push!(sequence, sub2ind(ZsDims, Z₃r, c))
                        # set sequence continue flag => true
                        flag = true
                        break
                    end
                end
                break
            end
        end
    end

    # "unstar each starred zero of the sequence;"
    for i = 2:2:length(sequence)-1
        Zs[sequence[i]] = 1
    end

    # "and star each primed zero of the sequence."
    for i = 1:2:length(sequence)
        Zs[sequence[i]] = 2
    end

    for c = 1:ZsDims[2], i in nzrange(Zs, c)
        r = rows[i]
        # "erase all primes;"
        if Zs[r,c] == 3
            Zs[r,c] = 1
        end
        # "and cover every column containing a 0*."
        if Zs[r,c] == 2
            columnCovered[c] = true
        end
    end

    # "uncover every row"
    rowCovered[:] = false

    # "if all columns are covered, the starred zeros form the desired independent set."
    if all(columnCovered)
        return stepNum = 0
    else
        # "otherwise, return to step 1."
        return stepNum = 1
    end
end

function step3!{T<:Real}(A::Array{T,2},
                         Zs::SparseMatrixCSC{Int,Int},
                         rowCovered::BitArray{1},
                         columnCovered::BitArray{1}
                        )
    # step 3 (Step C)
    # "let h denote the smallest uncovered element of the matrix;"
    h = minimum(A[!rowCovered,!columnCovered])

    # "add h to each covered row;"
    A[rowCovered,:] += h

    # "then subtract h from each uncovered column."
    A[:,!columnCovered] -= h

    # "return to step 1."
    return stepNum = 1
end
