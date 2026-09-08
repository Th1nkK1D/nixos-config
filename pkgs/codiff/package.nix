{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeShellWrapper,
  installShellFiles,
  imagemagick,
  nodejs,
  nix-update-script,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libgbm,
  libGL,
  libxkbcommon,
  libxkbfile,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxcb,
  nspr,
  nss,
  pango,
  systemdLibs,
  xdg-utils,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "codiff";
  version = "1.13.0";

  src = fetchurl {
    url = "https://github.com/nkzw-tech/codiff/releases/download/v${finalAttrs.version}/codiff_${finalAttrs.version}_amd64.deb";
    hash = "sha256-CpPYk+E826dUnQJ+GGdROKsnX2SxOmgr/+l6ex3GrU4=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeShellWrapper
    installShellFiles
    imagemagick
    nodejs
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libgbm
    libxkbcommon
    libxkbfile
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
    nspr
    nss
    pango
    (lib.getLib stdenv.cc.cc)
    systemdLibs
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib,share/applications,share/icons/hicolor/1024x1024/apps}

    cp -r usr/lib/codiff $out/lib/codiff
    rm -r $out/lib/codiff/resources/app/node_modules/node-pty/prebuilds/{darwin,win32}-*

    # Hide the menu bar on Linux like other platforms; press Alt to reveal it
    substituteInPlace $out/lib/codiff/resources/app/electron/main.cjs \
      --replace-fail "autoHideMenuBar: process.platform !== 'linux'," "autoHideMenuBar: true,"

    # Upstream pins exact model ids that never float to newer releases; pass the
    # Claude CLI's aliases instead so the picker follows the current models
    substituteInPlace $out/lib/codiff/resources/app/electron/claude.cjs \
      --replace-fail "          claudeModel," "          claudeModel.replace(/^claude-(opus|sonnet|haiku).*\$/, '\$1')," \
      --replace-fail "label: 'Best: Claude Opus 4.8'," "label: 'Best: Claude Opus'," \
      --replace-fail "label: 'Balanced: Claude Sonnet 4.6'," "label: 'Balanced: Claude Sonnet'," \
      --replace-fail "label: 'Fast: Claude Haiku 4.5'," "label: 'Fast: Claude Haiku',"

    install -Dm644 usr/share/pixmaps/codiff.png \
      $out/share/icons/hicolor/1024x1024/apps/codiff.png
    # hicolor's index.theme lists no 1024x1024 directory, so spec-compliant icon
    # loaders never find the upstream pixmap
    mkdir -p $out/share/icons/hicolor/512x512/apps
    magick usr/share/pixmaps/codiff.png -resize 512x512 \
      $out/share/icons/hicolor/512x512/apps/codiff.png
    install -Dm644 usr/share/applications/codiff.desktop \
      $out/share/applications/codiff.desktop
    substituteInPlace $out/share/applications/codiff.desktop \
      --replace-fail "GenericName=codiff" "GenericName=Diff Viewer" \
      --replace-fail "Name=codiff" "Name=Codiff" \
      --replace-fail "Categories=GNOME;GTK;Utility;" "Categories=Development;RevisionControl;"

    # Upstream's Linux package only exposes the Electron binary, so the
    # node-only flags handled by bin/codiff.js are lost. Mirror the macOS
    # terminal helper: run those through Electron in Node mode, launch the
    # app for everything else.
    makeShellWrapper $out/lib/codiff/codiff $out/lib/codiff/codiff-node \
      --set ELECTRON_RUN_AS_NODE 1 \
      --add-flags "$out/lib/codiff/resources/app/bin/codiff.js"
    makeShellWrapper $out/lib/codiff/codiff $out/lib/codiff/codiff-app \
      --unset ELECTRON_RUN_AS_NODE \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libGL ]}" \
      --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH" \
      --suffix PATH : "${lib.makeBinPath [ xdg-utils ]}" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"

    cat > $out/bin/codiff <<EOF
    #!${stdenv.shell}
    for arg in "\$@"; do
      case "\$arg" in
        --help|-h|--version|-v|--share|--public|--completions|--completions=*|--walkthrough-guide)
          exec $out/lib/codiff/codiff-node "\$@"
          ;;
      esac
    done
    exec $out/lib/codiff/codiff-app "\$@"
    EOF
    chmod +x $out/bin/codiff

    runHook postInstall
  '';

  # The bundled Electron is not runnable until autoPatchelf has run in fixup,
  # so generate completions with the build-time Node instead
  postInstall = ''
    installShellCompletion --cmd codiff \
      --bash <(node $out/lib/codiff/resources/app/bin/codiff.js --completions bash) \
      --fish <(node $out/lib/codiff/resources/app/bin/codiff.js --completions fish) \
      --zsh <(node $out/lib/codiff/resources/app/bin/codiff.js --completions zsh)
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Minimal local diff viewer for reviewing and committing Git changes";
    homepage = "https://github.com/nkzw-tech/codiff";
    changelog = "https://github.com/nkzw-tech/codiff/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = [ lib.maintainers.th1nkk1d ];
    mainProgram = "codiff";
    platforms = [ "x86_64-linux" ];
  };
})
