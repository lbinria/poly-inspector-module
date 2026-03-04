local diagnostic_overlap_view_path = "diagnostic/overlap-view"
local view_debug_line = true

function init()
	-- If debug, just load toy model
	if app.is_debug then 
		app:load_model("assets/catorus_tri.geogram", "cat")
		-- app:load_model("assets/catorus_quad.geogram", "cat")
		-- app:load_model("assets/simple_poly.geogram", "poly")
	end

	print("Script imgui context ID: " .. tostring(imgui.CtxId()))
	
end

function setup_gfx() 
	if (not app.has_models) or app.navigation_path:str() ~= diagnostic_overlap_view_path then
		return
	end

	local model = app.model
	model.points.visible = true
	model.mesh.size = 1
end

function unset_gfx(model)
	if not model then
		return
	end
	
	model.points.visible = false
	model.mesh.size = 0
	model:unset_highlight(ElementKind.POINTS_ELT)
	
	-- Remove debug gizmos
	if app.is_debug then 
		app:remove_renderer("debug_line_renderer")
	end
end

function navigation_path_changed(old_nav_path, new_nav_path)
	-- Setup gfx
	if not (old_nav_path:str() == "diagnostic/overlap-view") and new_nav_path:str() == "diagnostic/overlap-view" then
		setup_gfx()
	end
	-- Unsetup gfx 
	if not (new_nav_path:str() == "diagnostic/overlap-view") and old_nav_path:str() == "diagnostic/overlap-view" then
		unset_gfx(app.model)
	end
end

function selected_model_changed(old_name, new_name)
	if old_name == new_name then 
		return 
	end
	unset_gfx(app:get_model(old_name))
	app.navigation_path = ""
end

function layout_gui() 
	return {
		["Toolbar##tool_bar_diagnostic"] = "tool_bar"
	}
end

local real_time_compute = false
function draw_diagnostic_gui()
	local model = app.model

	imgui.Text("Selected model: " .. app.selected_model)
	imgui.Text("N verts: " .. tostring(model.nverts))

	local sel_point_size, new_point_size = imgui.SliderFloat("Point size", model.points.size, 0, 50)
	if (sel_point_size) then 
		model.points.size = new_point_size
	end

	-- local sel_real_time_compute, new_real_time_compute = imgui.Checkbox("Real time compute", real_time_compute)
	-- if (sel_real_time_compute) then 
	-- 	real_time_compute = new_real_time_compute
	-- end

	if not real_time_compute then
		if imgui.Button("Compute") then
			compute()
		end
	end


	if imgui.Button("Exit") then
		-- Change nav path
		unset_gfx(app.model)
		app.navigation_path = ""
	end


end

function draw_overlap_tooltip()

	local v = app.input_state.vertex.hovered
	local overlaps = points_overlaps[v + 1]

	if not overlaps then 
		return 
	end
	
	imgui.BeginToolTip()
	-- for _, overlap in ipairs(overlaps) do
	-- end
	imgui.Text("Vertex " .. v .. " overlaps " .. tostring(#overlaps) .. " vertices: ")

	for i=1,#overlaps do
		imgui.Text(tostring(overlaps[i]))
	end
	
	imgui.EndToolTip()

end

function draw_gui()

	if not app.has_models then
		return
	end

	imgui.Begin("Toolbar##tool_bar_diagnostic")

	if app.navigation_path:str() == diagnostic_overlap_view_path then 
		imgui.BeginDisabled()
	end

	local has_changed = false
	if imgui.Button("View overlap") then 
		app.navigation_path = "diagnostic/overlap-view"
		has_changed = true
	end

	if not has_changed and app.navigation_path:str() == diagnostic_overlap_view_path then 
		imgui.EndDisabled()
	end

	if app.navigation_path:str() == diagnostic_overlap_view_path then
		draw_diagnostic_gui()
	end

	imgui.End()

	if points_overlaps and app.input_state.vertex.any_hovered then 
		draw_overlap_tooltip()
	end
end

function compute()
	-- Compute 3D radiuses of points from point size in pixels
	local radiuses = poly_inspector.get_radiuses(app, app.model)
	
	-- Display debug lines that shows computed radiuses of points
	if app.is_debug then  
		poly_inspector.debug_lines(app, app.model, radiuses)
	end 

	points_overlaps = poly_inspector.compute_overlaps(app.model, radiuses)
end

local interval = 0.
function update(dt)
	if app.navigation_path:str() ~= diagnostic_overlap_view_path then 
		return
	end

	interval = interval + dt
	if interval < 0.1 then
		return
	end

	interval = 0
	if real_time_compute then 
		compute()
	end

end

function mouse_button(button, action, mods)

	if app.input_state.mouse.dbl_buttons[1] then
		local mesh_input_state = app.input_state.mesh
		if mesh_input_state.any_hovered then 
			local hovered_name = app:get_model_name_by_index(mesh_input_state.hovered)
			app:focus(hovered_name)
		end
	
	end
end

-- function draw_debug_lines(radiuses)
-- 	local renderer = app:add_renderer("LineRenderer", "debug_line_renderer")
-- 	if not renderer then 
-- 		return
-- 	end

-- 	local lr = renderer:as("LineRenderer")
-- 	lr:clear_lines()

-- 	poly_inspector.iterate_vertices(app.model, function(p, v)
-- 		-- Push lines for debug
-- 		local gp = vec3{p.x, p.y, p.z}

-- 		lr:add_lines({
-- 			Line{a = gp, b = gp + vec3{radiuses[v], 0., 0.}, color = vec3{1., 0., 0.}},
-- 			Line{a = gp, b = gp - vec3{radiuses[v], 0., 0.}, color = vec3{1., 0., 0.}},
-- 			Line{a = gp, b = gp + vec3{0., radiuses[v], 0.}, color = vec3{1., 0., 0.}},
-- 			Line{a = gp, b = gp - vec3{0., radiuses[v], 0.}, color = vec3{1., 0., 0.}},
-- 			Line{a = gp, b = gp + vec3{0., 0., radiuses[v]}, color = vec3{1., 0., 0.}},
-- 			Line{a = gp, b = gp - vec3{0., 0., radiuses[v]}, color = vec3{1., 0., 0.}}
-- 		})

-- 	end)

-- 	-- local verts = poly_inspector.get_vertices(app.model)
-- 	-- for i=1,#verts do
-- 	-- 	local p, v = verts[i].pos, verts[i].index
-- 	-- 	-- Push lines for debug
-- 	-- 	local gp = vec3{p.x, p.y, p.z}
-- 	-- 	lr:add_line(Line{a = gp, b = gp + vec3{radiuses[v], 0., 0.}, color = vec3{1., 0., 0.}})
-- 	-- 	lr:add_line(Line{a = gp, b = gp - vec3{radiuses[v], 0., 0.}, color = vec3{1., 0., 0.}})
-- 	-- 	lr:add_line(Line{a = gp, b = gp + vec3{0., radiuses[v], 0.}, color = vec3{1., 0., 0.}})
-- 	-- 	lr:add_line(Line{a = gp, b = gp - vec3{0., radiuses[v], 0.}, color = vec3{1., 0., 0.}})
-- 	-- 	lr:add_line(Line{a = gp, b = gp + vec3{0., 0., radiuses[v]}, color = vec3{1., 0., 0.}})
-- 	-- 	lr:add_line(Line{a = gp, b = gp - vec3{0., 0., radiuses[v]}, color = vec3{1., 0., 0.}})
-- 	-- end

-- 	lr:push()
-- end