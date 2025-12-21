from conan import ConanFile
from conan.tools.scm import Git
from conan.tools.gnu import PkgConfigDeps


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
        
        # Patch Makefile to exclude __STDC_EMBED_* macros from filtered_predefined_macros.h
        # This is needed for GCC 15+ which defines these C23 macros as built-ins
        self.run(
            "sed -i 's/__STDC__ __STDC_HOSTED__ __STDC_VERSION__/__STDC__ __STDC_HOSTED__ __STDC_VERSION__ __STDC_EMBED_EMPTY__ __STDC_EMBED_FOUND__ __STDC_EMBED_NOT_FOUND__/' mk/kern.pre.mk"
        )

    def generate(self):
        pkg_config = PkgConfigDeps(self)
        pkg_config.generate()

    # The requirements method allows you to define the dependencies of your recipe
    def requirements(self):
        self.requires("gcc/15.1.0")
        self.requires("openssl/3.6.0")
        self.requires("pcre/8.45")
        self.requires("zlib/1.3.1")
        self.requires("libnuma/2.0.19")
        self.requires("jansson/2.14")
        self.requires("libnl/3.9.0")
        self.requires("elfutils/0.190")
        self.requires("libpcap/1.10.5")

    # This method is used to build the source code of the recipe using the desired commands.
    def build(self):

        # Collect all dependency include/lib paths
        incs = []
        libs = []
        for dep in self.dependencies.values():
            incs.extend(dep.cpp_info.includedirs)
            libs.extend(dep.cpp_info.libdirs)

        inc_flags = " ".join(f"-I{p}" for p in incs)
        lib_flags = " ".join(f"-L{p}" for p in libs)

        inc_flags += " -Wno-unused-result"
        inc_flags += " -fPIC"

        self.run(
            f"make CONF_CFLAGS='{inc_flags}'",
            cwd=self.fstack_build_dir,
        )

        # build f-stack-mt lib
        self.run(
            f"make FF_PATH=../..",
            cwd=self.mt_build_dir,
        )

        # build f-stack tools
        self.run(
            f"PKG_CONFIG_PATH={self.source_folder}:$PKG_CONFIG_PATH make DEBUG_FLAGS='{inc_flags} {lib_flags}'",
            cwd=self.tools_build_dir,
        )

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
        self.run(f"cp libmt.a {lib_dir}/", cwd=self.mt_build_dir)
        self.run(f"cp -r *.h {include_dir}/", cwd=self.mt_build_dir)

        # Install f-stack tools
        self.run(f"mkdir -p {bin_dir}/f-stack")
        self.run(f"make install PREFIX_BIN={bin_dir}", cwd=self.tools_build_dir)

    def package_info(self):
        self.cpp_info.libs = ["fstack", "mt"]
        self.cpp_info.resdirs = ["etc"]
