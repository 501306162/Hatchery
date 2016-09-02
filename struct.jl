using Cxx

type Contained
    x::Cint
    y::Cint
    z::Cint
end

cxx"""
    struct contained {
        int x;
        int y;
        int z;
    };
    struct mystruct {
        int n;
        contained* arr;
    };
    mystruct* mk_mystruct(int n, contained* arr){
        struct mystruct ms;
        ms.n = n;
        ms.arr = arr;
        struct mystruct* ptr = &ms;
        return ptr;
    }
    contained* mk_mystruct2(int n, contained* arr){
        arr->x = n;
        return arr;
    }
    """

foo = Contained(4,2,3)
arr = pointer_from_objref(foo)
out = icxx"mk_mystruct(1, (contained* )$arr);"
bar = out
icxx"$out->n;"
bar = icxx"$out->arr;"
icxx"$bar->x;"
icxx"$bar->y;"
icxx"$bar->z;"
