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
  wakatime-cli,
  webkitgtk_4_1,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kero";
  version = "2.1.36";

  # Built from source for the patches only; libghostty-vt and the fonts still
  # come from the release tarball, which `mygo build` would otherwise fetch
  app = (buildGoModule.override { go = go_1_27; }) {
    pname = "kero-app";
    inherit (finalAttrs) version;

    src = fetchFromGitHub {
      owner = "egoist";
      repo = "kero";
      tag = "v${finalAttrs.version}";
      hash = "sha256-JSJ4u76cEjiHf9UMvQk+Ey5y3K3a1T6o71o+mz0crS8=";
    };

    patches = [
      # The sidebar finds the agent a sandbox such as `nono run -- claude` launches.
      # Unreleased as of 2.1.36: drop this once a release includes it
      ./agent-after-launcher.patch
      # WakaTime heartbeats through wakatime-cli (when on PATH) for files opened,
      # edited and saved in the viewer
      ./wakatime.patch
    ];

    # MyGo is a vendored module, so patch its copy after vendoring (keeps vendorHash).
    # Unreleased as of 2.1.36: drop this once Kero pins a MyGo with Astro highlighting
    preBuild = ''
      chmod -R u+w vendor/github.com/egoist/mygo
      patch -p1 -d vendor/github.com/egoist/mygo < ${./mygo-astro.patch}
    '';

    vendorHash = "sha256-F8xtFCh48EVyLIBJAjORvbh15TFb7Kp6bm5UbC+bmKQ=";
    subPackages = [ "." ];
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
    hash = "sha256-axNwftgYlgqycxtiLBpTv0EI5ZZ8/w9c9U6I/i0e6Ho=";
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

    install -d $out/share/kero/skills/kero
    HOME=$TMPDIR ${finalAttrs.app}/bin/kero skill show > $out/share/kero/skills/kero/SKILL.md

    install -Dm644 kero.png $out/share/pixmaps/kero.png
    install -Dm644 kero.desktop $out/share/applications/kero.desktop

    runHook postInstall
  '';

  preFixup = ''
    makeWrapper $out/lib/kero/kero $out/bin/kero \
      "''${gappsWrapperArgs[@]}" \
      --set-default KERO_WINDOW_CONTROLS 0 \
      --suffix PATH : ${lib.makeBinPath [ wakatime-cli ]} \
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
