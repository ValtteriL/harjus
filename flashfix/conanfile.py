from conan import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake, cmake_layout, CMakeDeps


class flashfixRecipe(ConanFile):
    name = "flashfix"
    version = "1.0"
    package_type = "library"

    # Optional metadata
    license = "<Put the package license here>"
    author = "<Put your name here> <And your email here>"
    url = "<Package recipe repository url here, for issues about the package>"
    description = "<Description of flashfix package here>"
    topics = ("<Put some tag here>", "<here>", "<and here>")

    # Binary configuration
    settings = "os", "compiler", "build_type", "arch"
    options = {"shared": [True, False], "fPIC": [True, False]}
    default_options = {"shared": True, "fPIC": True}

    # Sources are located in the same place as this recipe, copy them to the recipe
    exports_sources = (
        "CMakeLists.txt",
        "src/*",
        "include/*",
        "test/*",
        "spec/*",
        "config.h",
    )

    def requirements(self):
        self.requires("gcc/15.1.0")
        self.requires("zlib/1.3.1")
        self.requires("openssl/3.6.0")
        self.requires("jansson/2.14")
        self.requires("fstack/1.25")
        self.requires("libpcap/1.10.5")
        self.requires("elfutils/0.190")

    def tool_requirements(self):
        self.tool_requires("cmake/4.2.1")
        self.tool_requires("ninja/1.13.2")

    def layout(self):
        cmake_layout(self)

    def generate(self):
        deps = CMakeDeps(self)
        deps.generate()
        tc = CMakeToolchain(self, generator="Ninja")
        tc.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()

    def package_info(self):
        self.cpp_info.libs = ["flashfix"]
