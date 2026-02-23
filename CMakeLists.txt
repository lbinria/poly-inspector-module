cmake_minimum_required(VERSION 3.5...4.1.2)
project(diagnostic_module)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_definitions(DEBUG)
endif()

set(SALAMESH_URI "https://github.com/lbinria/salamesh.git")

# # Include local overrides if the file exists
# if(EXISTS "${CMAKE_SOURCE_DIR}/CMakeLists.local.txt")

# 	message(STATUS "Including local configuration")
# 	include("${CMAKE_SOURCE_DIR}/CMakeLists.local.txt")

# 	# add_subdirectory(${SALAMESH_URI} salamesh)
#   # set(SALAMESH_SRC "salamesh")

# else()

# endif()

include(FetchContent)
FetchContent_Declare(
salamesh
GIT_REPOSITORY "${SALAMESH_URI}"
GIT_TAG        45185f62bb8a62116fbb90dc5e589fe57ebfda69
GIT_SUBMODULES_RECURSE ON
)
FetchContent_MakeAvailable(salamesh)

set(SALAMESH_SRC "_deps/salamesh-src")


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


set(LUA_DIR "${CMAKE_BINARY_DIR}/${SALAMESH_SRC}/libs/lua-5.4.2_Win64_dll17_lib")
set(LUA_INCLUDE_DIR "${LUA_DIR}/include")

include_directories(${LUA_INCLUDE_DIR})
include_directories(diagnostic_module 
  PRIVATE 
  "${CMAKE_BINARY_DIR}/${SALAMESH_SRC}/include"
)

set(SOL_SOURCES
    ${CMAKE_BINARY_DIR}/${SALAMESH_SRC}/include/sol/sol.hpp
    ${CMAKE_BINARY_DIR}/${SALAMESH_SRC}/include/sol/config.hpp
    ${CMAKE_BINARY_DIR}/${SALAMESH_SRC}/include/sol/forward.hpp
)

link_libraries(${CMAKE_DL_LIBS} ultimaille m $<$<BOOL:${OpenMP_CXX_FOUND}>:OpenMP::OpenMP_CXX>)

add_library(diagnostic_module SHARED
  Registerer.h
  interface.cpp
  script.h
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