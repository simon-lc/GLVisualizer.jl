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
end

function depth_buffer!(depth::Matrix, vis::GLVisualizer1220)
    (vis.screen[1] == nothing) && open(vis)
    depthbuffer!(vis.screen[1], depth)
	# depth buffer return a value between [0,1] correspoding to distances between [camera.near, camera.far]

	# rescaling
	near_i = 1 / vis.camera.near.val
	far_i = 1 / vis.camera.far.val
	depth .= 1 ./ (near_i .+ depth .* (far_i - near_i))
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
	lx = depth * tan(2π*fovx/360 / 2)
	ly = depth * tan(2π*fovy/360 / 2)

	# x, y positions in the depth plane
	x = αx * lx
	y = αy * ly
	# The z axis is directed towards the back of the camera when y points upwards and x points to the right
	return [x, y, -depth]
end

function camera_to_world(pc, eyeposition, lookat, up)
	# z axis = look_direction
	z = normalize(eyeposition - lookat)
	# y axis = up
	y = up - (up'*z)*z
	y = normalize(y)
	# x axis = y × z
	x = normalize(cross(y, z))
	# rotation matrix
	wRc = [x y z]
	pw = wRc * pc + eyeposition
	return pw
end

function depthpixel_to_world(px, py, depth, resolution, fovy, eyeposition, lookat, up)
	pc = depthpixel_to_camera(px, py, depth, resolution, fovy)
	pw = camera_to_world(pc, eyeposition, lookat, up)
	return pw
end
