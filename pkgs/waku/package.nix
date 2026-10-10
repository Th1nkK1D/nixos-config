{
  lib,
  rustPlatform,
  fetchFromGitHub,
  autoPatchelfHook,
  bun,
  coreutils,
  curl,
  pkg-config,
  nix-update-script,
  fontconfig,
  freetype,
  libGL,
  libx11,
  libxcb,
  libxi,
  libxkbcommon,
  libxtst,
  vulkan-loader,
  wayland,
}:

let
  # Computer-use host: the pinned Cua SDK with Waku's native host entrypoints
  # appended to its ABI module (scripts/cua-host.ts)
  cuaVersion = "0.28.0";
  cuaSrc = fetchFromGitHub {
    owner = "trycua";
    repo = "cua";
    tag = "cua-driver-rs-v${cuaVersion}";
    sparseCheckout = [
      "libs/cua-driver/rust"
      "libs/cua-driver/contract"
      "libs/cua-driver/wayland-helper"
    ];
    hash = "sha256-3ZlKyb+eJblAxCFBRIM0q4zdKOw76zQO7Pv1ipEqbXI=";
  };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "waku";
  version = "0.1.20";

  src = fetchFromGitHub {
    owner = "egoist";
    repo = "waku";
    tag = "v${finalAttrs.version}";
    hash = "sha256-722A+14mI5HheG/NngWrty/wXQ0esq/4dhA6PeqOw8s=";
  };

  cargoHash = "sha256-9uNvTZ3BOgdWv4FH8FfGKPTzt5kqOwGb4J55ZgE+808=";

  # Usage refresh and Amp cancellation shell out to fixed FHS paths
  postPatch = ''
    substituteInPlace crates/waku-core/src/usage.rs \
      --replace-fail '"/usr/bin/curl"' '"${lib.getExe curl}"'
    substituteInPlace crates/waku-core/src/driver/amp.rs \
      --replace-fail '"/bin/kill"' '"${lib.getExe' coreutils "kill"}"'
  '';

  passthru.cuaDriverSdk = rustPlatform.buildRustPackage {
    pname = "cua-driver-sdk";
    version = cuaVersion;
    src = cuaSrc;
    sourceRoot = "${cuaSrc.name}/libs/cua-driver/rust";

    cargoHash = "sha256-Z+g9L1q2fKbkYk/yVsXzXyayfttFA0e2MFVEcrltZaI=";

    postPatch = ''
      cat ${finalAttrs.src}/resources/computer-use/cua-host.rs >> crates/cua-driver-sdk/src/abi.rs
    '';

    cargoBuildFlags = [
      "--package"
      "cua-driver-sdk"
    ];

    nativeBuildInputs = [ pkg-config ];

    buildInputs = [
      libx11
      libxcb
      libxi
      libxtst
    ];

    doCheck = false;
  };

  cargoBuildFlags = lib.concatMap (bin: [
    "--bin"
    bin
  ]) [
    "waku"
    "waku_js_repl"
    "waku-daemon"
    "waku_computer_use"
  ];

  nativeBuildInputs = [
    autoPatchelfHook
    bun
    pkg-config
  ];

  buildInputs = [
    fontconfig
    freetype
    libx11
    libxcb
    libxi
    libxkbcommon
    wayland
  ];

  # wgpu and GPUI dlopen these
  runtimeDependencies = [
    libGL
    vulkan-loader
    wayland
  ];

  doCheck = false;

  # Mirrors scripts/bundle-linux.sh minus the updater and its self-update
  # marker. The app finds waku-daemon and the computer-use helper next to its
  # own executable, so everything stays in bin
  postInstall = ''
    cp ${finalAttrs.passthru.cuaDriverSdk}/lib/libcua_driver_sdk.so $out/bin/

    install -Dm644 resources/linux/sh.waku.desktop $out/share/applications/sh.waku.desktop
    install -Dm644 website/public/app-icon.png $out/share/icons/hicolor/256x256/apps/sh.waku.png
    install -Dm644 LICENSE $out/share/licenses/waku/LICENSE

    mkdir -p $out/share/waku/computer-use
    cp -r ${cuaSrc}/libs/cua-driver/wayland-helper $out/share/waku/computer-use/
    install -Dm644 -t $out/share/waku/computer-use \
      resources/computer-use/pi-extension.ts resources/computer-use/CUA-LICENSE
    bun scripts/cua-api.ts $out/bin/waku_computer_use \
      $out/share/waku/skills/waku-computer-use/SKILL.md
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Native app for all your coding agents";
    homepage = "https://waku.sh";
    changelog = "https://github.com/egoist/waku/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.gpl3Only;
    maintainers = [ lib.maintainers.th1nkk1d ];
    mainProgram = "waku";
    platforms = lib.platforms.linux;
  };
})
