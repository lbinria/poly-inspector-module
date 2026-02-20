local diagnostic_overlap_view_path = "diagnostic/overlap-view"
local view_debug_line = true

function init()
	-- If debug, just load toy model
	if app.is_debug then 
		-- app:load_model("assets/catorus_tri.geogram", "bob")
		app:load_model("assets/catorus_quad.geogram", "cat")
		-- app:load_model("assets/simple_poly.geogram", "poly")
	end
end

function setup_gfx() 
	if (not app.has_models) or app.navigation_path_string ~= diagnostic_overlap_view_path then
		return
	end

	local model = app.model
	model.points.visible = true
end

function unset_gfx() 
	if (not app.has_models) or app.navigation_path_string == diagnostic_overlap_view_path then
		return
	end
	
	-- Get current model
	local model = app.model
	model.points.visible = false
	model:unset_highlight(ElementKind.POINTS_ELT)
	
	-- Remove debug gizmos
	if app.is_debug then 
		app:remove_renderer("debug_line_renderer")
	end
end

function navigation_path_changed(old_nav_path, new_nav_path)
	-- Setup gfx
	if not (old_nav_path[1] == "diagnostic" and old_nav_path[2] == "overlap-view") and new_nav_path[1] == "diagnostic" and new_nav_path[2] ==  "overlap-view" then
		setup_gfx()
	end
	-- Unsetup gfx 
	if not (new_nav_path[1] == "diagnostic" and new_nav_path[2] == "overlap-view") and old_nav_path[1] == "diagnostic" and old_nav_path[2] ==  "overlap-view" then
		unset_gfx()
	end
end

function selected_model_changed(old_name, new_name)

end

function layout_gui() 
	return {
		["Toolbar##tool_bar_diagnostic"] = "tool_bar"
	}
end


function draw_diagnostic_gui()
	if imgui.Button("Exit") then
		-- Change nav path
		app.navigation_path = {}
	end

	local model = app.model

	local sel_point_size, new_point_size = imgui.SliderFloat("Point size", model.points.size, 0, 50)
	if (sel_point_size) then 
		model.points.size = new_point_size
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

	if app.navigation_path_string == diagnostic_overlap_view_path then 
		imgui.BeginDisabled()
	end

	local has_changed = false
	if imgui.Button("View overlap") then 
		app.navigation_path = {"diagnostic", "overlap-view"}
		has_changed = true
	end

	if not has_changed and app.navigation_path_string == diagnostic_overlap_view_path then 
		imgui.EndDisabled()
	end

	if app.navigation_path_string == diagnostic_overlap_view_path then
		draw_diagnostic_gui()
	end

	imgui.End()

	if points_overlaps and app.input_state.vertex.any_hovered then 
		draw_overlap_tooltip()
	end

end

local interval = 0.
function update(dt)
	if app.navigation_path_string ~= diagnostic_overlap_view_path then 
		return
	end

	-- Compute 3D radiuses of points from point size in pixels
	local radiuses = get_radiuses(app, app.model)
	
	-- Display debug lines that shows computed radiuses of points
	if app.is_debug then 
		interval = interval + dt 
		
		if interval > 0.2 then 
			debug_lines(app, app.model, radiuses)
			interval = 0.
		end
	end 

	points_overlaps = test(app.model, radiuses)



end

-- function draw_debug_lines(radiuses)
-- 	local renderer = app:add_renderer("LineRenderer", "debug_line_renderer")
-- 	if not renderer then 
-- 		return
-- 	end

-- 	local lr = renderer:as("LineRenderer")
-- 	lr:clear_lines()

-- 	iterate_vertices(app.model, function(p, v)
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

-- 	-- local verts = get_vertices(app.model)
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