from conan import ConanFile
from conan.tools.scm import Git


class BasicConanfile(ConanFile):
    name = "fstack"
    version = "1.25"
    description = "A basic recipe"
    license = "<Your project license goes here>"
    homepage = "http://www.f-stack.org/"

    # Check the documentation for the rest of the available attributes

    def source(self):
        git = Git(self)
        git.clone(url="https://github.com/F-Stack/f-stack.git", target=".")
        git.checkout("v1.25")

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

        # build f-stack library
        self.run("make", cwd=f"{self.source_folder}/lib")

        # build f-stack-mt lib and echo example
        self.run("make echo", cwd=f"{self.source_folder}/adapter/micro_thread")

    # The actual creation of the package, once it's built, is done in the package() method.
    # Using the copy() method from tools.files, artifacts are copied
    # from the build folder to the package folder
    def package(self):

        fstack_build_dir = f"{self.source_folder}/lib"

        include_dir = f"{self.package_folder}/include"
        lib_dir = f"{self.package_folder}/lib"
        bin_dir = f"{self.package_folder}/bin"
        etc_dir = f"{self.package_folder}/etc"

        # Create necessary directories
        self.run(f"mkdir -p {include_dir}")
        self.run(f"mkdir -p {lib_dir}")
        self.run(f"mkdir -p {bin_dir}")
        self.run(f"mkdir -p {etc_dir}")

        # Install f-stack
        self.run(
            f"make install PREFIX={self.package_folder} F-STACK_CONF={self.package_folder}/etc/f-stack.conf",
            cwd=f"{fstack_build_dir}",
        )

        mt_build_dir = f"{self.source_folder}/adapter/micro_thread"

        # Install f-stack-mt artifacts
        self.run(f"cp echo {bin_dir}/", cwd=mt_build_dir)
        self.run(f"cp libmt.a {lib_dir}/", cwd=mt_build_dir)
        self.run(f"cp -r *.h {include_dir}/", cwd=mt_build_dir)
