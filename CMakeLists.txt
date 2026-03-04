cmake_minimum_required(VERSION 3.5...4.1.2)
project(diagnostic_module)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)

# Needed if you want to use "app.is_debug"
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_definitions(DEBUG)
endif()

# Include local overrides if the file exists
if(EXISTS "${CMAKE_SOURCE_DIR}/CMakeLists.local.txt")

  # Local include
	message(STATUS "Including local configuration")
	include("${CMAKE_SOURCE_DIR}/CMakeLists.local.txt")

  # Add salamesh as subdir
	add_subdirectory(${SALAMESH_URI} salamesh)
  # Source dir is the directory we point on local
  set(salamesh_SOURCE_DIR ${SALAMESH_URI})

else()

  # Fetch for git
  set(SALAMESH_URI "https://github.com/lbinria/salamesh.git")

  include(FetchContent)
  FetchContent_Declare(
    salamesh
    GIT_REPOSITORY "${SALAMESH_URI}"
    GIT_TAG        a91384386921d3b9a2dfe4d653dab74374e82e64
    GIT_SUBMODULES_RECURSE ON
  )
  FetchContent_MakeAvailable(salamesh)

endif()



message(STATUS "Salamesh src directory: ${salamesh_SOURCE_DIR}")

# Add salamesh directory as include
include_directories(${salamesh_SOURCE_DIR}/core)
# Link to salamesh core
link_libraries(salamesh_core)

# Include ImGui directory from salamesh
include_directories(${salamesh_SOURCE_DIR}/include/imgui)


set(IMGUI_SOURCES
  ${salamesh_SOURCE_DIR}/include/imgui/imgui.cpp
  ${salamesh_SOURCE_DIR}/include/imgui/imgui.h

  ${salamesh_SOURCE_DIR}/include/imgui/imgui_demo.cpp
  ${salamesh_SOURCE_DIR}/include/imgui/imgui_draw.cpp
  ${salamesh_SOURCE_DIR}/include/imgui/imgui_widgets.cpp
  ${salamesh_SOURCE_DIR}/include/imgui/imgui_tables.cpp

  ${salamesh_SOURCE_DIR}/include/imgui/backends/imgui_impl_glfw.h
  ${salamesh_SOURCE_DIR}/include/imgui/backends/imgui_impl_glfw.cpp
  ${salamesh_SOURCE_DIR}/include/imgui/backends/imgui_impl_opengl3.h
  ${salamesh_SOURCE_DIR}/include/imgui/backends/imgui_impl_opengl3.cpp
  ${salamesh_SOURCE_DIR}/include/imgui/backends/imgui_impl_opengl3_loader.h
)

# TODO condition for WIN / Linux, because we cannot use find_package on windows
find_package(Lua REQUIRED)


# Include Ultimaille directory from salamesh to have consistent versions
include_directories(diagnostic_module
  PRIVATE
    "${CMAKE_BINARY_DIR}/_deps/ultimaille-src"
)


set(LUA_DIR "${salamesh_SOURCE_DIR}/libs/lua-5.4.2_Win64_dll17_lib")
set(LUA_INCLUDE_DIR "${LUA_DIR}/include")

include_directories(${LUA_INCLUDE_DIR})
include_directories(diagnostic_module 
  PRIVATE 
  "${salamesh_SOURCE_DIR}/include"
)

set(SOL_SOURCES
    ${salamesh_SOURCE_DIR}/include/sol/sol.hpp
    ${salamesh_SOURCE_DIR}/include/sol/config.hpp
    ${salamesh_SOURCE_DIR}/include/sol/forward.hpp
)

link_libraries(${CMAKE_DL_LIBS} ultimaille m $<$<BOOL:${OpenMP_CXX_FOUND}>:OpenMP::OpenMP_CXX>)

add_library(diagnostic_module SHARED
  script.h
  interface.cpp
  ${IMGUI_SOURCES}
  ${SOL_SOURCES}
)

message("CMAKE_CURRENT_BINARY_DIR=" ${CMAKE_CURRENT_BINARY_DIR})

# Get the build directory of the fetched content
get_property(salamesh_build_dir DIRECTORY ${salamesh_SOURCE_DIR} PROPERTY BINARY_DIR)
message(STATUS "Salamesh build directory: ${salamesh_build_dir}")

# Generate JSON settings file after build
file(WRITE ${salamesh_build_dir}/settings.json "
{
	\"modules\": [
		\"${CMAKE_CURRENT_BINARY_DIR}\",
		\"modules/module_menubar\"
	]
}
")

# Copy systematically script.lua file to output build dir when build
if (MSVC)
  add_custom_target(copy-resources ALL
      COMMAND ${CMAKE_COMMAND} -E copy ${PROJECT_SOURCE_DIR}/script.lua ${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/ 
      COMMENT "Copying script to ${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/"
  )
else()
  add_custom_target(copy-resources ALL
      COMMAND ${CMAKE_COMMAND} -E copy ${PROJECT_SOURCE_DIR}/script.lua ${CMAKE_CURRENT_BINARY_DIR}/
      COMMENT "Copying script to ${CMAKE_CURRENT_BINARY_DIR}/"
  )
endif()