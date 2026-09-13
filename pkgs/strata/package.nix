{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  wrapGAppsHook4,
  nix-update-script,
  bubblewrap,
  cairo,
  ffmpeg,
  ffmpegthumbnailer,
  fontconfig,
  gdk-pixbuf,
  glib,
  gst_all_1,
  gtk4,
  gtksourceview5,
  imagemagick,
  libraw,
  pango,
  poppler,
  util-linux,
  xdg-terminal-exec,
}:

let
  # PATH the Bubblewrap preview helpers see; upstream hardcodes /usr/bin
  sandboxPath = lib.makeBinPath [
    imagemagick
    libraw
    ffmpeg
  ];
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "strata";
  version = "0.16.0";

  src = fetchFromGitHub {
    owner = "lgse";
    repo = "strata";
    tag = "v${finalAttrs.version}";
    hash = "sha256-/Blv1jvfZf+OEfH9K0SLVFlVR+jIhMwS4gBe1yHnX2Y=";
  };

  cargoHash = "sha256-vFp1qIoCC0mqbJ5FpXZmRbhp9XEB+WQjE653+W6m+Uo=";

  # The preview sandbox is written for an FHS host: it binds /usr, sets the
  # helper PATH to /usr/bin, and runs /usr/bin/{prlimit,ffmpegthumbnailer}.
  # Point all of that at the store, and hand gdk-pixbuf its loader cache since
  # bwrap clears the environment.
  postPatch = ''
    substituteInPlace src/sandbox.rs \
      --replace-fail '"/usr/bin",' '"${sandboxPath}", "--setenv", "GDK_PIXBUF_MODULE_FILE", "${gdk-pixbuf}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache",' \
      --replace-fail '"/usr",' '"/nix/store",' \
      --replace-fail '.arg("/usr/bin/prlimit")' '.arg("${lib.getExe' util-linux "prlimit"}")' \
      --replace-fail '"/usr/bin/ffmpegthumbnailer"' '"${lib.getExe ffmpegthumbnailer}"'
  '';

  env.STRATA_BUILD_COMMIT = finalAttrs.src.rev;

  nativeBuildInputs = [
    pkg-config
    glib
    wrapGAppsHook4
  ];

  buildInputs = [
    cairo
    fontconfig
    gdk-pixbuf
    glib
    gtk4
    gtksourceview5
    pango
    poppler
  ];

  # The suite drives real GTK widgets and Bubblewrap, neither of which the
  # build sandbox provides
  doCheck = false;

  postInstall = ''
    install -Dm644 data/io.github.lgse.Strata.desktop \
      $out/share/applications/io.github.lgse.Strata.desktop
    install -Dm644 data/icons/scalable/apps/io.github.lgse.Strata.svg \
      $out/share/icons/hicolor/scalable/apps/io.github.lgse.Strata.svg

    install -Dm644 data/io.github.lgse.Strata.FileManager1.service \
      $out/share/dbus-1/services/io.github.lgse.Strata.FileManager1.service
    substituteInPlace $out/share/dbus-1/services/io.github.lgse.Strata.FileManager1.service \
      --replace-fail /usr/bin/strata $out/bin/strata

    # Marks the install as package-managed so the in-app updater stops offering
    # to overwrite the read-only store path
    install -Dm644 /dev/stdin $out/share/strata/install-source.toml <<EOF
    manager = "Nix"
    update_command = "nixos-rebuild switch"
    EOF
  '';

  # The preview sandbox shells out to bwrap, "Open terminal here" to
  # xdg-terminal-exec; GStreamer plays the helper's raw audio frames
  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : "${
        lib.makeBinPath [
          bubblewrap
          xdg-terminal-exec
        ]
      }"
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${
        lib.makeSearchPath "lib/gstreamer-1.0" (
          with gst_all_1;
          [
            gstreamer
            gst-plugins-base
            gst-plugins-good
            gst-libav
          ]
        )
      }"
    )
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Fast, keyboard-first file manager for modern Linux desktops";
    homepage = "https://github.com/lgse/strata";
    changelog = "https://github.com/lgse/strata/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.th1nkk1d ];
    mainProgram = "strata";
    platforms = lib.platforms.linux;
  };
})
