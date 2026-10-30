{
  lib,
  rustPlatform,
  fetchFromGitHub,
  callPackage,
  writeShellScript,
  zig_0_16,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "herdr-core";
  version = "0.1.13";

  src = fetchFromGitHub {
    owner = "herdrdev";
    repo = "herdr-core";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-KkxFLXDIXDBvmfAbFeEgSoYjtxGK/P1exq5SDoTemFY=";
  };

  cargoHash = "sha256-cDmfmZOPBXc5R/pp3qWDLL0B1KMw/Dc7Ef1KhJGYADg=";

  nativeBuildInputs = [
    rustPlatform.bindgenHook
    zig_0_16
  ];

  # The build script runs `zig build` for libghostty-vt, which can't fetch
  # its dependencies in the sandbox
  env.ZIG = writeShellScript "zig" ''
    if [ "$1" = build ]; then
      set -- "$@" --system ${callPackage "${finalAttrs.src}/vendor/ghostty/build.zig.zon.nix" { }}
    fi
    exec ${lib.getExe zig_0_16} "$@"
  '';

  # Zig is only for the build script, not a Zig project
  dontUseZigBuild = true;
  dontUseZigCheck = true;
  dontUseZigInstall = true;

  preBuild = ''
    export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-global-cache
  '';

  doCheck = false;

  postInstall = ''
    ln -s herdr-core $out/bin/hc
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Terminal runtime for coding agents that keeps them running after the window closes";
    homepage = "https://herdr.dev/core/";
    changelog = "https://github.com/herdrdev/herdr-core/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    maintainers = [ lib.maintainers.th1nkk1d ];
    mainProgram = "hc";
    platforms = lib.platforms.linux;
  };
})
