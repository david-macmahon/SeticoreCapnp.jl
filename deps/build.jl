using Conda

try
    Conda.add("pycapnp")
catch
    orig_pip_interop = Conda.pip_interop()
    try
        Conda.pip_interop(true)
        Conda.pip("install", "pycapnp")
    catch
        Conda.pip_interop(orig_pip_interop)
        rethrow()
    end
end
