using JSON

using URIParser
a = JSON.parsefile("./example.gltf")
a = joinpath(dirname(@__FILE__), "example.gltf")

b = URI(a)
f = open(b.path, "r")

close(f)

a = joinpath(dirname(abspath("example.gltf")), "example.bin")

macro gl(x)
    esc(quote
        type $x
         a
         function $x(a)
             new(a)
         end
        end
    end)
end

@gl gnimuc

methods(gnimuc)

a = macroexpand( :(@gl gnimuc) )

xdump(gnimuc)
