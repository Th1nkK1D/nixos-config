{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  python3,
  nix-update-script,
  cairo,
  dbus,
  fontconfig,
  gdk-pixbuf,
  glib,
  glib-networking,
  gtk3,
  libsoup_3,
  webkitgtk_4_1,
  open-pencil-mcp,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "open-pencil-desktop";
  version = "0.17.0";

  src = fetchurl {
    url = "https://github.com/open-pencil/open-pencil/releases/download/v${finalAttrs.version}/OpenPencil_${finalAttrs.version}_amd64.deb";
    hash = "sha256-fuxRsdxJUZWrTCp4N4TetZfQXI10zUZK860wa0TIXI0=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
    (python3.withPackages (ps: [ ps.brotli ]))
  ];

  buildInputs = [
    cairo
    dbus
    fontconfig
    gdk-pixbuf
    glib
    glib-networking
    gtk3
    libsoup_3
    webkitgtk_4_1
  ];

  installPhase = ''
    runHook preInstall

    cp -r usr $out

    # WebKitGTK rasterizes CSS url() cursors at 1x, so the SVG tool cursors
    # (hand, pen, pencil, comment) come out pixelated on scaled outputs. Use
    # their named fallbacks (grab, grabbing, crosshair) from the cursor theme.
    # The fix has to go into the minified frontend embedded in the binary; the
    # script fails the build once upstream code no longer matches
    python3 ${./patch-assets.py} $out/bin/OpenPencil \
      'function (\w+)\((\w+),(\w+),(\w+),(\w+)\)\{return`url\("\$\{\w+\(\2\)\}"\) \$\{\3\} \$\{\4\}, \$\{\5\}`\}' \
      'function \1(\2,\3,\4,\5){return \5}'

    substituteInPlace $out/share/applications/OpenPencil.desktop \
      --replace-fail "Categories=" "Categories=Graphics;VectorGraphics;"

    # The desktop entry claims these types but the deb never defines them, so
    # *.fig resolves to XFig. Magic tells Figma apart: raw files start with
    # fig-kiwi, exports are zips whose first entry is canvas.fig (outranking
    # the generic zip magic at 60)
    install -Dm644 /dev/stdin $out/share/mime/packages/open-pencil.xml <<'EOF'
    <?xml version="1.0" encoding="UTF-8"?>
    <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
      <mime-type type="application/x-figma">
        <comment>Figma design</comment>
        <glob pattern="*.fig"/>
        <magic priority="70">
          <match type="string" value="fig-kiwi" offset="0"/>
          <match type="string" value="PK\003\004" offset="0">
            <match type="string" value="canvas.fig" offset="30"/>
          </match>
        </magic>
      </mime-type>
      <mime-type type="application/x-pencil-pen">
        <comment>OpenPencil design</comment>
        <glob pattern="*.pen"/>
      </mime-type>
    </mime-info>
    EOF

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(--prefix PATH : ${lib.makeBinPath [ open-pencil-mcp ]})
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Open-source design editor for .fig and .pen files with built-in AI";
    homepage = "https://openpencil.dev";
    changelog = "https://github.com/open-pencil/open-pencil/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = [ lib.maintainers.th1nkk1d ];
    mainProgram = "OpenPencil";
    platforms = [ "x86_64-linux" ];
  };
})
