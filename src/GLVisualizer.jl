module GLVisualizer

using BenchmarkTools
using Colors
using GLMakie
using GeometryBasics
using LinearAlgebra
using Makie
using Plots
using Random
using Graphs

include("utils.jl")
include("transform.jl")
include("visuals.jl")
include("depth.jl")

export
    Visualizer,
    depthbuffer!,
    depth_buffer,
    depth_buffer!,
    depth_rescaling!


end
