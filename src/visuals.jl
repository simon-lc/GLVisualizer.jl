struct Visualizer
    scene::Dict{Symbol,Any}
    trans::Dict{Symbol,Any}
    names::Vector{Symbol}
    graph::SimpleDiGraph
    screen::Vector
	camera::Camera3D
end

function Visualizer(; resolution=(800,600))
    scene = Scene(
        # clear everything behind scene
        clear=true,
        # the camera struct of the scene.
        visible=true,
        resolution=resolution)

	camera = cam3d_cad!(scene)
    scene = Dict{Symbol,Any}(:root => scene)
    trans = Dict{Symbol,Any}()
    names = [:root]
    graph = SimpleDiGraph()
    add_vertex!(graph)
	# screen
	screen = Vector{Any}([open(scene, visible=false)])
    return Visualizer(scene, trans, names, graph, screen, camera)
end

function Base.open(vis::Visualizer; visible::Bool=true)
	scene = vis.scene[:root]
	screen = open(scene, visible=visible)
	vis.screen[1] = screen
	return nothing
end

function Base.open(scene::Scene; visible::Bool=true)
	if visible
		screen = display(scene)
    else
		screen = GLMakie.singleton_screen(size(scene), visible=false, start_renderloop=false)
		GLMakie.ShaderAbstractions.switch_context!(screen.glscreen)
		empty!(screen)
		insertplots!(screen, scene)
		GLMakie.display_loading_image(screen)
		Base.resize!(screen, size(scene)...)
		Makie.backend_display(screen, scene)
	end
	return screen
end

function setobject!(vis::Visualizer, parent::Symbol, name::Symbol, object;
        color=RGBA(0.3, 0.3, 0.3, 0.7))

    parent_scene = vis.scene[parent]
    child_scene = Scene(parent_scene, camera=vis.scene[:root].camera)
    vis.scene[name] = child_scene

    mesh!(child_scene, object; color=color)
    vis.trans[name] = Transformation(parent_scene)
    push!(vis.names, name)
    add_vertex!(vis.graph)

    child_id = length(vis.names)
    parent_id = findfirst(x -> x==parent, vis.names)
    add_edge!(vis.graph, parent_id, child_id)
    return nothing
end

function settransform!(vis::Visualizer, name::Symbol, x, q)
    set_translation!(vis, name, x)
    set_rotation!(vis, name, q)
    return nothing
end

function set_translation!(vis::Visualizer, name::Symbol, x)
    GLMakie.translate!(vis.scene[name], x...)
    return nothing
end

function set_rotation!(vis::Visualizer, name::Symbol, q)
    GLMakie.rotate!(vis.scene[name], q)
    return nothing
end

function set_camera!(vis::Visualizer;
        eyeposition=[1,1,1.0],
        lookat=[0,0,0.0],
        up=[0,0,1.0],
		near=0.1,
		far=100.0,
		zoom=1.0)

	camera = vis.camera

	camera.lookat[] = Vec3f(lookat)
	camera.eyeposition[] = Vec3f(eyeposition)
	camera.upvector[] = Vec3f(up)
	camera.near[] = near
	camera.far[] = far
	camera.zoom_mult[] = zoom

    update_cam!(vis.scene[:root], camera)
    return nothing
end

"""
    set_floor!(vis; x, y, z, origin, normal, color)
    adds floor to visualization
    vis::Visualizer
    x: lateral position
    y: longitudinal position
    z: vertical position
	origin:: position of the center of the floor
    normal:: unit vector indicating the normal to the floor
    color: RGBA
"""
function set_floor!(vis::Visualizer;
	    x=20.0,
	    y=20.0,
	    z=0.1,
	    origin=[0,0,0.0],
		normal=[0,0,1.0],
	    color=RGBA(0.5,0.5,0.5,1.0),
	    axis::Bool=false,
	    grid::Bool=false)
	obj = HyperRectangle(Vec(-x/2, -y/2, -z), Vec(x, y, z))
	setobject!(vis, :root, :floor, obj, color=color)

	p = origin
	q = axes_pair_to_quaternion([0,0,1.], normal)
    settransform!(vis, :floor, p, q)
    return nothing
end
