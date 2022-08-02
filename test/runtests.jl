using Test
using BenchmarkTools

using LinearAlgebra
using Random

using GLVisualizer

ENV["DISPLAY"] = ":0"

@testset "visuals"             verbose=true begin include("visuals.jl") end
