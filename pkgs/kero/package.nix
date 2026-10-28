{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  buildGoModule,
  go_1_27,
  autoPatchelfHook,
  wrapGAppsHook3,
  nix-update-script,
  cairo,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  glib-networking,
  gtk-layer-shell,
  gtk3,
  harfbuzz,
  libayatana-appindicator,
  libepoxy,
  libGL,
  libsecret,
  libsoup_3,
  libx11,
  pango,
  webkitgtk_4_1,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kero";
  version = "2.1.24";

  # Built from source for the patch only; libghostty-vt and the fonts still
  # come from the release tarball, which `mygo build` would otherwise fetch
  app = (buildGoModule.override { go = go_1_27; }) {
    pname = "kero-app";
    inherit (finalAttrs) version;

    src = fetchFromGitHub {
      owner = "egoist";
      repo = "kero";
      tag = "v${finalAttrs.version}";
      hash = "sha256-ZWMMiHapkRJwn6RgwJ8ZWn4Ud/V5zJSeSiolAPchlNw=";
    };

    vendorHash = "sha256-NCKPSQ7q91ZdcucbGSGs7kraW4YaSmQ6c0Q59lfvWmY=";
    subPackages = [ "." ];
    # No minimize, maximize or close buttons: niri has no use for them
    postPatch = ''
      substituteInPlace platform.go \
        --replace-fail '!ownControls || w == nil' 'true'
    '';
    doCheck = false;

    # What `mygo build` links in
    ldflags = [
      "-s"
      "-w"
      "-X github.com/egoist/mygo.production=1"
      "-X github.com/egoist/mygo.packageName=Kero"
      "-X github.com/egoist/mygo.packageVersion=${finalAttrs.version}"
      "-X github.com/egoist/mygo.packageIdentifier=sh.kero"
    ];
  };

  src = fetchurl {
    url = "https://github.com/egoist/kero/releases/download/v${finalAttrs.version}/kero-${finalAttrs.version}-linux-amd64.tar.gz";
    hash = "sha256-0cnrSBKKa8nG3vMvVmIYy7mNtKGsAR6o08Q1RuYnBIQ=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook3
  ];

  buildInputs = [
    cairo
    gdk-pixbuf
    glib
    glib-networking
    gtk3
    harfbuzz
    libsoup_3
    webkitgtk_4_1
  ];

  # The Go binary dlopens GTK, WebKit, GL and the tray library at runtime
  runtimeLibs = lib.makeLibraryPath [
    cairo
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk-layer-shell
    gtk3
    harfbuzz
    libayatana-appindicator
    libepoxy
    libGL
    libsecret
    libsoup_3
    libx11
    pango
    webkitgtk_4_1
  ];

  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    # kero loads libghostty-vt.so and re-executes itself as the kerod daemon
    # from its own directory, so the real binary stays next to the library
    install -Dm755 -t $out/lib/kero libghostty-vt.so
    install -Dm755 ${finalAttrs.app}/bin/kero $out/lib/kero/kero
    cp -r fonts $out/lib/kero/

    install -Dm644 kero.png $out/share/pixmaps/kero.png
    install -Dm644 kero.desktop $out/share/applications/kero.desktop

    runHook postInstall
  '';

  preFixup = ''
    makeWrapper $out/lib/kero/kero $out/bin/kero \
      "''${gappsWrapperArgs[@]}" \
      --set GTK_USE_PORTAL 1 \
      --prefix LD_LIBRARY_PATH : "$runtimeLibs"
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Native terminal app for running coding agents in sessions that outlive the window";
    homepage = "https://kero.sh";
    changelog = "https://github.com/egoist/kero/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = [ lib.maintainers.th1nkk1d ];
    mainProgram = "kero";
    platforms = [ "x86_64-linux" ];
  };
})
