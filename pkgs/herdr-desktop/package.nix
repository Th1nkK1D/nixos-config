{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  callPackage,
  writeShellScript,
  zig_0_16,
  autoPatchelfHook,
  makeWrapper,
  pkg-config,
  clang,
  nix-update-script,
  herdr-core,
  fontconfig,
  freetype,
  libGL,
  libxcb,
  libxkbcommon,
  vulkan-loader,
  wayland,
  # Default shell for new terminals; unset keeps the caller's $SHELL
  shell ? null,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "herdr-desktop";
  version = "0.1.6";

  src = fetchFromGitHub {
    owner = "herdrdev";
    repo = "herdr-app";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-yAX5LXDNjq1lTBiFRTprukrVLSMpBoa3b+tTjRSPg/0=";
  };

  # Start Agent runs `$SHELL -ic '"$@"; exec "$0" -i'`, which fish rejects
  patches = [ ./fish-agent-launch.patch ];

  cargoHash = "sha256-kvj1pbtdZA5pEQ2l9VRXwB1i8BL51DYCsxO1wxLRe0k=";

  nativeBuildInputs = [
    autoPatchelfHook
    clang
    makeWrapper
    pkg-config
    rustPlatform.bindgenHook
    zig_0_16
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    fontconfig
    freetype
    libxcb
    libxkbcommon
    wayland
  ];

  # winit and wgpu dlopen these
  runtimeDependencies = [
    libGL
    libxkbcommon
    vulkan-loader
    wayland
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

  # Mirrors scripts/install-linux. The app looks for hc on PATH
  postInstall = ''
    wrapProgram $out/bin/herdr-app \
      --prefix PATH : ${lib.makeBinPath [ herdr-core ]}${lib.optionalString (shell != null) " \\\n      --set SHELL ${lib.getExe shell}"}

    install -Dm644 assets/icons/herdr-ui-icon-clean.svg \
      $out/share/icons/hicolor/scalable/apps/herdr-app.svg
    install -Dm644 /dev/stdin $out/share/applications/herdr-app.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=Herdr
    Comment=Terminals and coding agents that keep running
    Exec=herdr-app
    Icon=herdr-app
    Terminal=false
    Categories=Development;
    StartupWMClass=herdr-app
    EOF
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Native app for terminals and coding agents that keep running";
    homepage = "https://herdr.dev";
    changelog = "https://github.com/herdrdev/herdr-app/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.asl20;
    maintainers = [ lib.maintainers.th1nkk1d ];
    mainProgram = "herdr-app";
    platforms = lib.platforms.linux;
  };
})
