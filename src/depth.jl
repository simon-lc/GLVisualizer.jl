function depthbuffer!(screen::GLMakie.Screen, depth=Matrix{Float32}(undef, size(screen.framebuffer.buffers[:depth])))
    GLMakie.ShaderAbstractions.switch_context!(screen.glscreen)
    GLMakie.render_frame(screen, resize_buffers=false) # let it render
    GLMakie.glFinish() # block until opengl is done rendering
    source = screen.framebuffer.buffers[:depth]
    @assert size(source) == size(depth)
    GLMakie.GLAbstraction.bind(source)
    GLMakie.GLAbstraction.glGetTexImage(source.texturetype, 0, GLMakie.GL_DEPTH_COMPONENT, GLMakie.GL_FLOAT, depth)
    GLMakie.GLAbstraction.bind(source, 0)
    return depth
end

function depth_buffer(vis::GLVisualizer1220)
    depth = depthbuffer!(vis.screen[1])
	depth_rescaling!(depth, vis)
end

function depth_buffer!(depth::Matrix, vis::GLVisualizer1220)
    (vis.screen[1] == nothing) && open(vis)
    depthbuffer!(vis.screen[1], depth)
	depth_rescaling!(depth, vis)
end

function depth_rescaling!(depth::Matrix, vis::GLVisualizer1220)
	# open GL does not use a linear scaling for the depth pixel value:
	# https://learnopengl.com/Advanced-OpenGL/Depth-testing
	near_i = 1 / vis.camera.near.val
	far_i = 1 / vis.camera.far.val
	depth .= 1 ./ (near_i .+ depth .* (far_i - near_i))
	return depth
end

function depthpixel_to_camera(p1, p2, depth, resolution, fovy)
	r1, r2 = resolution
	# pixel coordinate rescaled from -1 to 1
	αx = + (p1 * 2 / r1 - 1 / r1 - 1.0)
	αy = + (p2 * 2 / r2 - 1 / r2 - 1.0)

	# coordinate of the pixel in the camera frame
	# the pixel belongs to a plane 'depth plane' located at distance = depth from the camera.
	# l = half-size of the image projected on the depth plane.
	fovx = fovy * r1/r2
	# fovx = fovy / (r1/r2)
	lx = depth * tan(2π*fovx/360 / 2)
	ly = depth * tan(2π*fovy/360 / 2)

	# x, y positions in the depth plane
	x = αx * lx
	y = αy * ly
	# The z axis is directed towards the back of the camera when y points upwards and x points to the right
	return [x, y, -depth]
end

function camera_to_world(pc, eyeposition, lookat, upvector)
	# z axis = look_direction
	z = normalize(eyeposition - lookat)
	# y axis = upvector
	y = upvector - (upvector'*z)*z
	@assert norm(y) > 0.0
	y = normalize(y)
	# x axis = y × z
	x = normalize(cross(y, z))
	# rotation matrix
	wRc = [x y z]
	pw = wRc * pc + eyeposition
	return pw
end

function depthpixel_to_world(px, py, depth, resolution, fovy, eyeposition, lookat, upvector)
	pc = depthpixel_to_camera(px, py, depth, resolution, fovy)
	pw = camera_to_world(pc, eyeposition, lookat, upvector)
	return pw
end

function depthpixel_to_world!(coordinates::Matrix, depth::Matrix, p1::Vector, p2::Vector, vis::GLVisualizer1220)
	# coordinates: a matrix of size 3 × (n1 * n2)
	# p1 are the pixel coordinates along the 1st dimension of the depth image
	# p2 are the pixel coordinates along the 2nd dimension of the depth image

	# extract camera info
	camera = vis.camera
	eyeposition = camera.eyeposition.val
	lookat = camera.lookat.val
	upvector = camera.upvector.val
	fovy = camera.fov.val
	resolution = vis.scene[:root].camera.resolution.val

	# assert correct dimensions
	n1 = length(p1)
	n2 = length(p2)
	@assert size(coordinates, 2) == n1 * n2

	# convert pixel coordinates and depth inormation to 3D coordinates in the camera frame
	depthpixel_to_camera!(coordinates, depth, p1, p2, resolution, fovy)

	# convert 3D coordinates in the camera frame to the world frame
	camera_to_world!(coordinates, eyeposition, lookat, upvector)
	return nothing
end

function depthpixel_to_camera!(coordinates::Matrix, depth::Matrix, p1::Vector, p2::Vector, resolution, fovy)
	# assert correct dimensions
	n1 = length(p1)
	n2 = length(p2)
	@assert size(coordinates, 2) == n1 * n2

	r1, r2 = resolution
	# pixel coordinate rescaled from -1 to 1
	αx = + (p1 .* 2 / r1 .- 1 / r1 .- 1.0)
	αy = + (p2 .* 2 / r2 .- 1 / r2 .- 1.0)

	# field of view along x and y axes of the camera
	fovx = fovy * r1 / r2

	# coordinate of the pixel in the camera frame
	# the pixel belongs to a plane 'depth plane' located at distance = depth from the camera.
	# l = half-size of the image projected on the depth plane.
	tanx = tan(2π*fovx/360 / 2)
	tany = tan(2π*fovy/360 / 2)

	ind = 0
	for (j,jj) in enumerate(p2)
		for (i,ii) in enumerate(p1)
			ind += 1
			# x, y positions in the depth plane
			coordinates[1, ind] = αx[i] * tanx * depth[ii, jj]
			coordinates[2, ind] = αy[j] * tany * depth[ii, jj]
			coordinates[3, ind] = - depth[ii, jj]
		end
	end
	# lx = depth * tan(2π*fovx/360 / 2)
	# ly = depth * tan(2π*fovy/360 / 2)
	# x = αx * lx
	# y = αy * ly

	# The z axis is directed towards the back of the camera when y points upwards and x points to the right
	# return [x, y, -depth]
	return nothing
end

function camera_to_world!(coordinates::Matrix, eyeposition, lookat, upvector)
	# z axis = look_direction
	z = normalize(deepcopy(eyeposition) - lookat)
	# y axis = upvector
	y = upvector - (upvector'*z)*z
	# we need an upvector that is not aligned with the look direction
	@assert norm(y) > 0.0
	y = normalize(y)
	# x axis = y × z
	x = normalize(cross(y, z))
	# rotation matrix from caemra to world
	wRc = [x y z]

	for i = 1:size(coordinates, 2)
		coordinates[:, i] .= deepcopy(wRc) * coordinates[:, i] + deepcopy(eyeposition)
	end
	return nothing
end
