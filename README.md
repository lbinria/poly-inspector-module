## Module features

 - Visualise point overlaps

## Configuration (Optional)

If you want to use the local API of app rather than the one hosted on git: 

 - create `CMakeLists.local.txt` at the root of the module
 - put `set(SALAMESH_URI "/your/path/to/salamesh")` in this file

## How to compile

In directory

`cmake -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build --parallel 8`

## How to run

### 1. Test module

Just run

`./build/_deps/salamesh-build/salamesh`

### 2. Add this module to your app modules list

Go to app directory and add the module to `modules` array in `settings.json`:

```json
{
	"modules": [
		...
		"/path/to/poly-inspector-module/build"
	]
}
```

The app will load this module on startup.