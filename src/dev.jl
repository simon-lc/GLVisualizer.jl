include("visuals.jl")
include("depth.jl")

resolution0 = (600, 600)
vis = GLVisualizer1220(resolution=resolution0)
open(vis)

set_floor!(vis)
object1 = HyperRectangle(Vec(0,0,0), Vec(0.2, 0.9, 1))
object2 = HyperRectangle(Vec(0,0,0), Vec(0.6, 0.2, 2.0))

setobject!(vis, :root, :object1, object1, color=RGBA(0,0,1,0.4))
setobject!(vis, :object1, :object2, object2, color=RGBA(1,0,0,0.4))

eyeposition0 = [0,2,5.0]
lookat0 = [1,00,00]
up0 = [0,0,1.0]
set_camera!(vis;
		eyeposition=eyeposition0,
		lookat=lookat0,
		up=up0,
		far=100.0,
		near=0.1,
		zoom=1.0,
		)

settransform!(vis, :object1, [0,0,1.0], Makie.Quaternion(0,0,0,1.0))
settransform!(vis, :object1, [0,0,1.0], Makie.Quaternion(sqrt(2)/2,0,0,sqrt(2)/2))
settransform!(vis, :object1, [0,0,1.0], Makie.Quaternion(1,0,0,0.0))

depth_color = depth_buffer(vis)
maximum(depth_color)
minimum(depth_color)

depth_color = depth_buffer!(depth_color, vis)
maximum(depth_color)
minimum(depth_color)

px0 = 160
py0 = 160
depth0 = rotr90(depth_color)[py0, px0]
fovy0 = 45.0

pc0 = depthpixel_to_camera(px0, py0, depth0, resolution0, fovy0)
pw0 = depthpixel_to_world(px0, py0, depth0, resolution0, fovy0, eyeposition0, lookat0, up0)

pixel1 = HyperSphere(Point{3}(0,0,0.0), 0.007)
# setobject!(vis, :root, Symbol(:pixel, counter), pixel1, color=RGBA(0.0,0.0,0.0,1.0))
# settransform!(vis, Symbol(:pixel,counter), pw0, Makie.Quaternion(0,0,0,1.0))

linear_depth_color = (depth_color .- minimum(depth_color)) ./ (maximum(depth_color) - minimum(depth_color))
point_depth_color = deepcopy(linear_depth_color)

counter = 0
for j = 0:14
	for i = 0:14
		counter += 1
		@show counter
		px0 = 100 + 32i
		py0 = 100 + 32j
		point_depth_color[px0 .+ (-3:3), py0 .+ (-3:3)] .= 1
		depth0 = depth_color[px0, py0]

		pw0 = depthpixel_to_world(px0, py0, depth0, resolution0, fovy0, eyeposition0, lookat0, up0)

		pixel1 = HyperSphere(Point{3}(0,0,0.0), 0.025)
		setobject!(vis, :root, Symbol(:pixel, counter), pixel1, color=RGBA(0.0,0.0,0.0,1.0))
		settransform!(vis, Symbol(:pixel,counter), pw0, Makie.Quaternion(0,0,0,1.0))
		@show pc0
		@show pw0
	end
end

Plots.plot(Gray.(1 .- linear_depth_color))
Plots.plot(Gray.(1 .- rotl90(point_depth_color)))
linear_depth_color
maximum(depth_color)
minimum(depth_color)
maximum(linear_depth_color)
minimum(linear_depth_color)
