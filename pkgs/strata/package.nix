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
  squashfs-tools,
  util-linux,
  xdg-terminal-exec,
  # RAR extraction and CBR covers compile in RARLAB's non-free UnRAR source
  enableUnfree ? false,
}:

let
  # PATH the Bubblewrap preview helpers see; upstream hardcodes /usr/bin
  sandboxPath = lib.makeBinPath [
    imagemagick
    libraw
    ffmpeg
    ffmpegthumbnailer
    squashfs-tools
    util-linux
  ];
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "strata";
  version = "0.21.0";

  src = fetchFromGitHub {
    owner = "lgse";
    repo = "strata";
    tag = "v${finalAttrs.version}";
    hash = "sha256-RSTEgtfDYYGxXef1J22NMGpmgjObg3T6APZqfSyfNPY=";
  };

  cargoHash = "sha256-0nMfswOfyXiwIWF0Xne61jGwPdU/gMo6Wt6JGZEfrJw=";

  buildNoDefaultFeatures = !enableUnfree;

  # bwrap is looked up in fixed system dirs rather than PATH, so add its store
  # dir there. The STRATA_SANDBOX_* build vars deliberately don't cover this
  # lookup (docs/preview-sandbox.md)
  postPatch = ''
    substituteInPlace src/trusted_command.rs \
      --replace-fail '"/run/current-system/sw/bin",' '"/run/current-system/sw/bin", "${bubblewrap}/bin",'
  '';

  # The preview sandbox defaults to an FHS host (/usr bind, /usr/bin PATH,
  # /usr/bin/prlimit) and bwrap clears the environment, so point it at the store
  env = {
    STRATA_BUILD_COMMIT = finalAttrs.src.rev;
    STRATA_SANDBOX_PATH = sandboxPath;
    STRATA_SANDBOX_ROOT = "/nix/store";
    STRATA_SANDBOX_PRLIMIT = lib.getExe' util-linux "prlimit";
    STRATA_SANDBOX_GDK_PIXBUF_MODULE_FILE = "${gdk-pixbuf}/${gdk-pixbuf.binaryDir}/loaders.cache";
  };

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
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-libav
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

    # Portal backend for org.freedesktop.impl.portal.FileChooser. Upstream
    # installs this per-user from the app; on NixOS it belongs in the package so
    # xdg.portal.extraPortals can pick it up
    install -Dm644 data/portal/strata.portal \
      $out/share/xdg-desktop-portal/portals/strata.portal
    install -Dm644 data/portal/org.freedesktop.impl.portal.desktop.strata.service.in \
      $out/share/dbus-1/services/org.freedesktop.impl.portal.desktop.strata.service
    substituteInPlace $out/share/dbus-1/services/org.freedesktop.impl.portal.desktop.strata.service \
      --replace-fail @STRATA_EXECUTABLE@ $out/bin/strata

    # Marks the install as package-managed so the in-app updater stops offering
    # to overwrite the read-only store path
    echo 'manager = "Nix"' | install -Dm644 /dev/stdin $out/share/strata/install-source.toml
  '';

  # "Open terminal here" shells out to xdg-terminal-exec
  preFixup = ''
    gappsWrapperArgs+=(--prefix PATH : "${lib.makeBinPath [ xdg-terminal-exec ]}")
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Fast, keyboard-first file manager for modern Linux desktops";
    homepage = "https://github.com/lgse/strata";
    changelog = "https://github.com/lgse/strata/releases/tag/v${finalAttrs.version}";
    license = with lib.licenses; [ mit ] ++ lib.optionals enableUnfree [ unfreeRedistributable ];
    maintainers = [ lib.maintainers.th1nkk1d ];
    mainProgram = "strata";
    platforms = lib.platforms.linux;
  };
})
