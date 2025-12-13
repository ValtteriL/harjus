from conan import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake, cmake_layout, CMakeDeps


class harjusRecipe(ConanFile):
    name = "harjus"
    version = "1.0"
    package_type = "application"

    # Optional metadata
    license = "<Put the package license here>"
    author = "<Put your name here> <And your email here>"
    url = "<Package recipe repository url here, for issues about the package>"
    description = "<Description of harjus package here>"
    topics = ("<Put some tag here>", "<here>", "<and here>")

    # Binary configuration
    settings = "os", "compiler", "build_type", "arch"

    # Sources are located in the same place as this recipe, copy them to the recipe
    exports_sources = ("CMakeLists.txt", "src/*", "include/*", "tests/*")

    def requirements(self):
        self.requires("openssl/3.6.0")
        self.requires("gtest/1.17.0")
        self.requires("boost/1.89.0")
        self.requires("cpr/1.12.0")
        self.requires("libsodium/1.0.20")
        self.requires("gmp/6.3.0")
        self.requires("pcre/8.45")
        self.requires("fstack/1.25")
        self.requires("flashfix/1.0")

    def layout(self):
        cmake_layout(self)

    def generate(self):
        deps = CMakeDeps(self)
        deps.generate()
        tc = CMakeToolchain(self, generator="Ninja")
        tc.variables["CMAKE_CXX_STANDARD"] = "23"
        tc.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()
