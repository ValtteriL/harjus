from conan import ConanFile
from conan.tools.scm import Git


class BasicConanfile(ConanFile):
    name = "fstack"
    version = "1.25"
    description = "A basic recipe"
    license = "<Your project license goes here>"
    homepage = "http://www.f-stack.org/"

    # build directories
    fstack_build_dir = f"lib"
    mt_build_dir = f"adapter/micro_thread"
    tools_build_dir = f"tools"

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

    # This method is used to build the source code of the recipe using the desired commands.
    def build(self):

        # build f-stack library
        self.run("make", cwd=self.fstack_build_dir)

        # build f-stack-mt lib and echo example
        self.run("make echo", cwd=self.mt_build_dir)

        # build f-stack tools
        self.run("make", cwd=self.tools_build_dir)

    # The actual creation of the package, once it's built, is done in the package() method.
    # Using the copy() method from tools.files, artifacts are copied
    # from the build folder to the package folder
    def package(self):

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
            cwd=self.fstack_build_dir,
        )

        # Install f-stack-mt artifacts
        self.run(f"cp echo {bin_dir}/", cwd=self.mt_build_dir)
        self.run(f"cp libmt.a {lib_dir}/", cwd=self.mt_build_dir)
        self.run(f"cp -r *.h {include_dir}/", cwd=self.mt_build_dir)

        # Install f-stack tools
        self.run(f"mkdir -p {bin_dir}/f-stack")
        self.run(f"make install PREFIX_BIN={bin_dir}", cwd=self.tools_build_dir)

    def package_info(self):
        self.cpp_info.libs = ["fstack", "mt"]
        self.cpp_info.resdirs = ["etc"]
