{ lib, beamPackages, overrides ? (x: y: {}) }:

let
  buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;
  buildMix = lib.makeOverridable beamPackages.buildMix;
  buildErlangMk = lib.makeOverridable beamPackages.buildErlangMk;

  self = packages // (overrides self packages);

  packages = with beamPackages; with self; {
    bunt = buildMix rec {
      name = "bunt";
      version = "1.0.0";

      src = fetchHex {
        pkg = "bunt";
        version = "${version}";
        sha256 = "dc5f86aa08a5f6fa6b8096f0735c4e76d54ae5c9fa2c143e5a1fc7c1cd9bb6b5";
      };

      beamDeps = [];
    };

    castore = buildMix rec {
      name = "castore";
      version = "1.0.11";

      src = fetchHex {
        pkg = "castore";
        version = "${version}";
        sha256 = "e03990b4db988df56262852f20de0f659871c35154691427a5047f4967a16a62";
      };

      beamDeps = [];
    };

    certifi = buildRebar3 rec {
      name = "certifi";
      version = "2.12.0";

      src = fetchHex {
        pkg = "certifi";
        version = "${version}";
        sha256 = "ee68d85df22e554040cdb4be100f33873ac6051387baf6a8f6ce82272340ff1c";
      };

      beamDeps = [];
    };

    credo = buildMix rec {
      name = "credo";
      version = "1.7.11";

      src = fetchHex {
        pkg = "credo";
        version = "${version}";
        sha256 = "56826b4306843253a66e47ae45e98e7d284ee1f95d53d1612bb483f88a8cf219";
      };

      beamDeps = [ bunt file_system jason ];
    };

    decimal = buildMix rec {
      name = "decimal";
      version = "2.3.0";

      src = fetchHex {
        pkg = "decimal";
        version = "${version}";
        sha256 = "a4d66355cb29cb47c3cf30e71329e58361cfcb37c34235ef3bf1d7bf3773aeac";
      };

      beamDeps = [];
    };

    dialyxir = buildMix rec {
      name = "dialyxir";
      version = "1.4.5";

      src = fetchHex {
        pkg = "dialyxir";
        version = "${version}";
        sha256 = "b0fb08bb8107c750db5c0b324fa2df5ceaa0f9307690ee3c1f6ba5b9eb5d35c3";
      };

      beamDeps = [ erlex ];
    };

    dotenv_parser = buildMix rec {
      name = "dotenv_parser";
      version = "2.0.1";

      src = fetchHex {
        pkg = "dotenv_parser";
        version = "${version}";
        sha256 = "f00780ad69e9089bd9b782e88d3e8110141dff0c54577b6c3735cef6925e4272";
      };

      beamDeps = [];
    };

    erlex = buildMix rec {
      name = "erlex";
      version = "0.2.7";

      src = fetchHex {
        pkg = "erlex";
        version = "${version}";
        sha256 = "3ed95f79d1a844c3f6bf0cea61e0d5612a42ce56da9c03f01df538685365efb0";
      };

      beamDeps = [];
    };

    ex_aws = buildMix rec {
      name = "ex_aws";
      version = "2.5.8";

      src = fetchHex {
        pkg = "ex_aws";
        version = "${version}";
        sha256 = "8f79777b7932168956c8cc3a6db41f5783aa816eb50de356aed3165a71e5f8c3";
      };

      beamDeps = [ hackney jason mime req telemetry ];
    };

    ex_aws_cloudwatch = buildMix rec {
      name = "ex_aws_cloudwatch";
      version = "2.0.4";

      src = fetchHex {
        pkg = "ex_aws_cloudwatch";
        version = "${version}";
        sha256 = "faa5e5ba809c083b0460cc843b5082b200bb37d2abb25becb62c314b2796ae58";
      };

      beamDeps = [ ex_aws ];
    };

    file_system = buildMix rec {
      name = "file_system";
      version = "1.1.0";

      src = fetchHex {
        pkg = "file_system";
        version = "${version}";
        sha256 = "bfcf81244f416871f2a2e15c1b515287faa5db9c6bcf290222206d120b3d43f6";
      };

      beamDeps = [];
    };

    finch = buildMix rec {
      name = "finch";
      version = "0.19.0";

      src = fetchHex {
        pkg = "finch";
        version = "${version}";
        sha256 = "fc5324ce209125d1e2fa0fcd2634601c52a787aff1cd33ee833664a5af4ea2b6";
      };

      beamDeps = [ mime mint nimble_options nimble_pool telemetry ];
    };

    hackney = buildRebar3 rec {
      name = "hackney";
      version = "1.20.1";

      src = fetchHex {
        pkg = "hackney";
        version = "${version}";
        sha256 = "fe9094e5f1a2a2c0a7d10918fee36bfec0ec2a979994cff8cfe8058cd9af38e3";
      };

      beamDeps = [ certifi idna metrics mimerl parse_trans ssl_verify_fun unicode_util_compat ];
    };

    hpax = buildMix rec {
      name = "hpax";
      version = "1.0.2";

      src = fetchHex {
        pkg = "hpax";
        version = "${version}";
        sha256 = "2f09b4c1074e0abd846747329eaa26d535be0eb3d189fa69d812bfb8bfefd32f";
      };

      beamDeps = [];
    };

    idna = buildRebar3 rec {
      name = "idna";
      version = "6.1.1";

      src = fetchHex {
        pkg = "idna";
        version = "${version}";
        sha256 = "92376eb7894412ed19ac475e4a86f7b413c1b9fbb5bd16dccd57934157944cea";
      };

      beamDeps = [ unicode_util_compat ];
    };

    jason = buildMix rec {
      name = "jason";
      version = "1.4.4";

      src = fetchHex {
        pkg = "jason";
        version = "${version}";
        sha256 = "c5eb0cab91f094599f94d55bc63409236a8ec69a21a67814529e8d5f6cc90b3b";
      };

      beamDeps = [ decimal ];
    };

    libgraph = buildMix rec {
      name = "libgraph";
      version = "0.16.0";

      src = fetchHex {
        pkg = "libgraph";
        version = "${version}";
        sha256 = "41ca92240e8a4138c30a7e06466acc709b0cbb795c643e9e17174a178982d6bf";
      };

      beamDeps = [];
    };

    metrics = buildRebar3 rec {
      name = "metrics";
      version = "1.0.1";

      src = fetchHex {
        pkg = "metrics";
        version = "${version}";
        sha256 = "69b09adddc4f74a40716ae54d140f93beb0fb8978d8636eaded0c31b6f099f16";
      };

      beamDeps = [];
    };

    mime = buildMix rec {
      name = "mime";
      version = "2.0.6";

      src = fetchHex {
        pkg = "mime";
        version = "${version}";
        sha256 = "c9945363a6b26d747389aac3643f8e0e09d30499a138ad64fe8fd1d13d9b153e";
      };

      beamDeps = [];
    };

    mimerl = buildRebar3 rec {
      name = "mimerl";
      version = "1.3.0";

      src = fetchHex {
        pkg = "mimerl";
        version = "${version}";
        sha256 = "a1e15a50d1887217de95f0b9b0793e32853f7c258a5cd227650889b38839fe9d";
      };

      beamDeps = [];
    };

    mint = buildMix rec {
      name = "mint";
      version = "1.7.1";

      src = fetchHex {
        pkg = "mint";
        version = "${version}";
        sha256 = "fceba0a4d0f24301ddee3024ae116df1c3f4bb7a563a731f45fdfeb9d39a231b";
      };

      beamDeps = [ castore hpax ];
    };

    mox = buildMix rec {
      name = "mox";
      version = "1.2.0";

      src = fetchHex {
        pkg = "mox";
        version = "${version}";
        sha256 = "c7b92b3cc69ee24a7eeeaf944cd7be22013c52fcb580c1f33f50845ec821089a";
      };

      beamDeps = [ nimble_ownership ];
    };

    mutex = buildMix rec {
      name = "mutex";
      version = "3.0.0";

      src = fetchHex {
        pkg = "mutex";
        version = "${version}";
        sha256 = "ad5e0035b2f230e5048304bfba7bc746e614cb2a0f92054300532283ed53261d";
      };

      beamDeps = [];
    };

    nimble_options = buildMix rec {
      name = "nimble_options";
      version = "1.1.1";

      src = fetchHex {
        pkg = "nimble_options";
        version = "${version}";
        sha256 = "821b2470ca9442c4b6984882fe9bb0389371b8ddec4d45a9504f00a66f650b44";
      };

      beamDeps = [];
    };

    nimble_ownership = buildMix rec {
      name = "nimble_ownership";
      version = "1.0.1";

      src = fetchHex {
        pkg = "nimble_ownership";
        version = "${version}";
        sha256 = "3825e461025464f519f3f3e4a1f9b68c47dc151369611629ad08b636b73bb22d";
      };

      beamDeps = [];
    };

    nimble_pool = buildMix rec {
      name = "nimble_pool";
      version = "1.1.0";

      src = fetchHex {
        pkg = "nimble_pool";
        version = "${version}";
        sha256 = "af2e4e6b34197db81f7aad230c1118eac993acc0dae6bc83bac0126d4ae0813a";
      };

      beamDeps = [];
    };

    parse_trans = buildRebar3 rec {
      name = "parse_trans";
      version = "3.4.1";

      src = fetchHex {
        pkg = "parse_trans";
        version = "${version}";
        sha256 = "620a406ce75dada827b82e453c19cf06776be266f5a67cff34e1ef2cbb60e49a";
      };

      beamDeps = [];
    };

    poison = buildMix rec {
      name = "poison";
      version = "6.0.0";

      src = fetchHex {
        pkg = "poison";
        version = "${version}";
        sha256 = "bb9064632b94775a3964642d6a78281c07b7be1319e0016e1643790704e739a2";
      };

      beamDeps = [ decimal ];
    };

    propcheck = buildMix rec {
      name = "propcheck";
      version = "1.4.1";

      src = fetchHex {
        pkg = "propcheck";
        version = "${version}";
        sha256 = "e1b088f574785c3c7e864da16f39082d5599b3aaf89086d3f9be6adb54464b19";
      };

      beamDeps = [ libgraph proper ];
    };

    proper = buildRebar3 rec {
      name = "proper";
      version = "1.4.0";

      src = fetchHex {
        pkg = "proper";
        version = "${version}";
        sha256 = "18285842185bd33efbda97d134a5cb5a0884384db36119fee0e3cfa488568cbb";
      };

      beamDeps = [];
    };

    req = buildMix rec {
      name = "req";
      version = "0.5.8";

      src = fetchHex {
        pkg = "req";
        version = "${version}";
        sha256 = "d7fc5898a566477e174f26887821a3c5082b243885520ee4b45555f5d53f40ef";
      };

      beamDeps = [ finch jason mime ];
    };

    ssl_verify_fun = buildRebar3 rec {
      name = "ssl_verify_fun";
      version = "1.1.7";

      src = fetchHex {
        pkg = "ssl_verify_fun";
        version = "${version}";
        sha256 = "fe4c190e8f37401d30167c8c405eda19469f34577987c76dde613e838bbc67f8";
      };

      beamDeps = [];
    };

    telemetry = buildRebar3 rec {
      name = "telemetry";
      version = "1.3.0";

      src = fetchHex {
        pkg = "telemetry";
        version = "${version}";
        sha256 = "7015fc8919dbe63764f4b4b87a95b7c0996bd539e0d499be6ec9d7f3875b79e6";
      };

      beamDeps = [];
    };

    telemetry_metrics = buildMix rec {
      name = "telemetry_metrics";
      version = "1.0.0";

      src = fetchHex {
        pkg = "telemetry_metrics";
        version = "${version}";
        sha256 = "f23713b3847286a534e005126d4c959ebcca68ae9582118ce436b521d1d47d5d";
      };

      beamDeps = [ telemetry ];
    };

    telemetry_metrics_cloudwatch = buildMix rec {
      name = "telemetry_metrics_cloudwatch";
      version = "1.0.0";

      src = fetchHex {
        pkg = "telemetry_metrics_cloudwatch";
        version = "${version}";
        sha256 = "d8d92d7df02e6060e535877729072b88a3eca0f2cfc0cfdf290355c4d1a702fc";
      };

      beamDeps = [ ex_aws_cloudwatch telemetry_metrics ];
    };

    telemetry_poller = buildRebar3 rec {
      name = "telemetry_poller";
      version = "1.1.0";

      src = fetchHex {
        pkg = "telemetry_poller";
        version = "${version}";
        sha256 = "9eb9d9cbfd81cbd7cdd24682f8711b6e2b691289a0de6826e58452f28c103c8f";
      };

      beamDeps = [ telemetry ];
    };

    unicode_util_compat = buildRebar3 rec {
      name = "unicode_util_compat";
      version = "0.7.0";

      src = fetchHex {
        pkg = "unicode_util_compat";
        version = "${version}";
        sha256 = "25eee6d67df61960cf6a794239566599b09e17e668d3700247bc498638152521";
      };

      beamDeps = [];
    };

    websockex = buildMix rec {
      name = "websockex";
      version = "0.4.3";

      src = fetchHex {
        pkg = "websockex";
        version = "${version}";
        sha256 = "95f2e7072b85a3a4cc385602d42115b73ce0b74a9121d0d6dbbf557645ac53e4";
      };

      beamDeps = [];
    };
  };
in self

