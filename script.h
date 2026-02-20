#pragma once

#include <GLFW/glfw3.h>
#include <imgui.h>

// Salamesh core
#include <app_interface.h>
#include <script.h>
#include <input_states.h>
#include <models/model.h>
#include <models/volume_model.h>
#include <models/surface_model.h>
#include <renderers/line_renderer.h>
#include <element.h>
// Ultimaille
#include <ultimaille/all.h>
// ImGui
#include "imgui.h"
#include "imgui_internal.h"
// Std
#include <iostream>
#include <set>

// Get the radius of a point in world-space cartesian coordinates
// Given its point size in pixel screen-space coordinates
float getRadius(glm::mat4 &pvm, glm::vec3 worldPos, float pointSize, glm::vec2 &viewport) {
	
	// ---- 1. Project point to screen ----
	// Clip space
	glm::vec4 clip = pvm * glm::vec4(worldPos, 1.0);
	// Compute screen pos (2D) in pixel of center of point
	glm::vec4 ndc = clip / clip.w;
	glm::vec2 screen = (glm::vec2{ndc.x, ndc.y} * 0.5f + 0.5f) * viewport;

	// ---- 2. Move point by half of point size ----
	screen.x += pointSize * .5f;

	// ---- 3. Unproject offset point to world space ----
	// Back to NDC
	glm::vec2 ndcOff = screen / viewport * 2.f - 1.f;
	// Inverse of perspective division, return to clip space
	glm::vec4 clipOff = glm::vec4(ndcOff * clip.w, clip.z, clip.w);
	// Back to world space (homogeneous coordinates)
	glm::mat4 invPVM = glm::inverse(pvm);
	glm::vec4 worldPosOff = invPVM * clipOff;
	// Homogeneous coordinates to Cartesian coordinates
	worldPosOff /= worldPosOff.w;

	// Above can be replaced by
	// worldPosOff = glm::unProject(screen, vm, p, viewport);

	// ---- 4. Compute distance between point and offset point in world-space cartesian coordinates ----
	// return glm::distance(glm::vec3(worldPosOff), worldPos);
	float dist = glm::distance(glm::vec3(worldPosOff), worldPos);
	return 0.577 * dist;
}

std::vector<float> getRadiuses(IApp &app, Model &model) {
	auto &triModel = model.as<TriModel>();
	auto &m = triModel.getMesh();

	float pointSize = model.getPointsRenderer().getPointSize();

	// Compute PVM matrix
	glm::mat4 modelMat = glm::mat4(1.0f);
	modelMat = glm::translate(modelMat, model.getPosition());
	auto pvm = app.getCurrentCamera().getProjectionMatrix() * app.getCurrentCamera().getViewMatrix() * modelMat;
	// TODO important here seems wrong, app.getSurface().width / app.getSurface().height
	// glm::vec2 viewport = { app.getWidth(), app.getHeight() };
	glm::vec2 viewport = { app.getSurfaceWidth(), app.getSurfaceHeight() };

	std::vector<float> radiuses(m.nverts());
	for (auto &v : m.iter_vertices()) {
		radiuses[v] = getRadius(pvm, sl::um2glm(v.pos()), pointSize, viewport);
	}

	return radiuses;
}

void iterate_vertices(Model &model, std::function<void(vec3, int)> f) {
	auto &triModel = model.as<TriModel>();
	auto &m = triModel.getMesh();	

	for (auto &v : m.iter_vertices())
		f(v.pos(), v);
}

std::vector<sol::table> get_vertices(Model &model, sol::this_state s) {
	std::vector<sol::table> verts;
	sol::state_view lua(s);

	auto &triModel = model.as<TriModel>();
	auto &m = triModel.getMesh();

	for (auto &v : m.iter_vertices()) {
		int vi = v;
		sol::table t = lua.create_table();
		t["pos"] = v.pos();
		t["index"] = vi;
		verts.push_back(t);
	}
	return verts;
}

void debugLines(IApp &app, Model &model, std::vector<float> &radiuses) {

	auto renderer = app.addRenderer("LineRenderer", "debug_line_renderer");

	if (!renderer) {
		return;
	}

	auto &lr = renderer->as<LineRenderer>();

	auto &triModel = model.as<TriModel>();
	auto &m = triModel.getMesh();	

	lr.clearLines();
	
	for (auto &v : m.iter_vertices()) {
		// Push lines for debug
		lr.addLine({sl::um2glm(v.pos()), sl::um2glm(v.pos()) + glm::vec3(radiuses[v], 0.f, 0.f), {1.f, 0.f, 0.f}});
		lr.addLine({sl::um2glm(v.pos()), sl::um2glm(v.pos()) + glm::vec3(-radiuses[v], 0.f, 0.f), {1.f, 0.f, 0.f}});
		lr.addLine({sl::um2glm(v.pos()), sl::um2glm(v.pos()) + glm::vec3(0.f, radiuses[v], 0.f), {1.f, 0.f, 0.f}});
		lr.addLine({sl::um2glm(v.pos()), sl::um2glm(v.pos()) + glm::vec3(0.f, -radiuses[v], 0.f), {1.f, 0.f, 0.f}});
		lr.addLine({sl::um2glm(v.pos()), sl::um2glm(v.pos()) + glm::vec3(0.f, 0.f, radiuses[v]), {1.f, 0.f, 0.f}});
		lr.addLine({sl::um2glm(v.pos()), sl::um2glm(v.pos()) + glm::vec3(0.f, 0.f, -radiuses[v]), {1.f, 0.f, 0.f}});

		glm::vec3 color{1.f, 0.3f, 1.f};
		glm::vec3 c = sl::um2glm(v.pos());
		float r = radiuses[v];
		
		// Define the 8 corners of the cube
		glm::vec3 corners[8] = {
			c + glm::vec3(-r, -r, -r),  // 0: bottom-left-back
			c + glm::vec3( r, -r, -r),  // 1: bottom-right-back
			c + glm::vec3( r,  r, -r),  // 2: top-right-back
			c + glm::vec3(-r,  r, -r),  // 3: top-left-back
			c + glm::vec3(-r, -r,  r),  // 4: bottom-left-front
			c + glm::vec3( r, -r,  r),  // 5: bottom-right-front
			c + glm::vec3( r,  r,  r),  // 6: top-right-front
			c + glm::vec3(-r,  r,  r)   // 7: top-left-front
		};
		
		// Draw 12 edges (4 bottom, 4 top, 4 vertical)
		// Bottom face (z = -r)
		lr.addLine({corners[0], corners[1], color});
		lr.addLine({corners[1], corners[2], color});
		lr.addLine({corners[2], corners[3], color});
		lr.addLine({corners[3], corners[0], color});
		
		// Top face (z = +r)
		lr.addLine({corners[4], corners[5], color});
		lr.addLine({corners[5], corners[6], color});
		lr.addLine({corners[6], corners[7], color});
		lr.addLine({corners[7], corners[4], color});
		
		// Vertical edges
		lr.addLine({corners[0], corners[4], color});
		lr.addLine({corners[1], corners[5], color});
		lr.addLine({corners[2], corners[6], color});
		lr.addLine({corners[3], corners[7], color});
	}

	lr.push();
}

std::vector<std::vector<long>> test(Model &model, std::vector<float> &radiuses) {

	auto &triModel = model.as<TriModel>();
	auto &m = triModel.getMesh();	

	// Init hbox
	HBoxes3 hbox;

	std::vector<BBox3> bboxes;
	for (auto &v : m.iter_vertices()) {
		BBox3 bb;
		bb.add(v.pos() - vec3{radiuses[v], radiuses[v], radiuses[v]});
		bb.add(v.pos() + vec3{radiuses[v], radiuses[v], radiuses[v]});
		bboxes.push_back(bb);
	}

	hbox.init(bboxes);

	// Highlight degenerated points
	PointAttribute<float> pointHl;
	pointHl.bind("_highlight", triModel.getSurfaceAttributes(), triModel.getMesh());
	pointHl.fill(0.f);

	std::vector<std::set<long>> pointOverlaps(m.nverts());
	int nOverlaps = 0;



	for (auto &a : m.iter_vertices()) {
		
		BBox3 bbox;
		bbox.add(a.pos() - vec3{radiuses[a], radiuses[a], radiuses[a]});
		bbox.add(a.pos() + vec3{radiuses[a], radiuses[a], radiuses[a]});
		std::vector<int> results;
		hbox.intersect(bbox, results);

		if (results.size() <= 1)
			continue;

		// bool isOverlaps = false;
		for (auto &b : results) {
			if (b == a) continue;

			pointHl[a] = 1.f;
			pointHl[b] = 1.f;
			pointOverlaps[a].insert(b);
			pointOverlaps[b].insert(a);
			// isOverlaps = true;
		}
		
		// if (isOverlaps)
		// 	++nOverlaps;

	}

	triModel.setHighlight(ElementKind::POINTS_ELT);


	std::vector<std::vector<long>> tablePointOverlaps;
	for (auto &x : pointOverlaps) {
		std::vector<long> overlaps;
		
		for (auto y : x) {
			overlaps.push_back(y);
		}
		tablePointOverlaps.push_back(overlaps);
	}

	return tablePointOverlaps;
}