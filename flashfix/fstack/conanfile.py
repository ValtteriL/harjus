from conan import ConanFile
from conan.tools.files import get


class BasicConanfile(ConanFile):
    name = "fstack"
    version = "1.25"
    description = "A basic recipe"
    license = "<Your project license goes here>"
    homepage = "http://www.f-stack.org/"

    # Check the documentation for the rest of the available attributes

    def source(self):
        get(
            self,
            "https://github.com/F-Stack/f-stack/archive/refs/tags/v1.25.zip",
            strip_root=True,
            sha256="ad7292d7156fbe37493face33df149e508915a3289b957133921173bec671d79",
        )

    # The requirements method allows you to define the dependencies of your recipe
    def requirements(self):
        self.requires("openssl/3.6.0")
        self.requires("pcre/8.45")
        self.requires("zlib/1.3.1")
        self.requires("libnuma/2.0.19")

    # The build_requirements() method is functionally equivalent to the requirements() one,
    # being executed just after it. It's a good place to define tool requirements,
    # dependencies necessary at build time, not at application runtime
    def build_requirements(self):
        # Each call to self.tool_requires() will add the corresponding build requirement
        # Uncommenting this line will add the cmake >=3.15 build dependency to your project
        # self.requires("cmake/[>=3.15]")
        pass

    # The purpose of generate() is to prepare the build, generating the necessary files, such as
    # Files containing information to locate the dependencies, environment activation scripts,
    # and specific build system files among others
    def generate(self):
        pass

    # This method is used to build the source code of the recipe using the desired commands.
    def build(self):
        self.run("make", cwd=f"{self.source_folder}/lib")

    # The actual creation of the package, once it's built, is done in the package() method.
    # Using the copy() method from tools.files, artifacts are copied
    # from the build folder to the package folder
    def package(self):
        self.run(
            "make install PREFIX={}".format(self.package_folder),
            cwd=f"{self.source_folder}/lib",
        )
