using Test
using BenchmarkTools

using LinearAlgebra
using Random

using GLVisualizer

@testset "visuals"             verbose=true begin include("visuals.jl") end
