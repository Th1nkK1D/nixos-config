{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "browse";
  version = "0.1.5";

  src = fetchFromGitHub {
    owner = "anomalyco";
    repo = "browse";
    tag = "v${finalAttrs.version}";
    hash = "sha256-BIzCe/atioMcWg+UvuXeEpijh6CHIXe5tPpR5L0JYcU=";
  };

  sourceRoot = "${finalAttrs.src.name}/rust";

  cargoHash = "sha256-IDAIKwDYSnNjqS6bUV7b+vS4wjYa1UNOGChIhYK/MHA=";

  cargoBuildFlags = [
    "--package"
    "browse"
  ];

  nativeBuildInputs = [ makeWrapper ];

  # Needs a real Chromium and network
  doCheck = false;

  # The store is read-only, so the self-updater can never replace the binary
  postInstall = ''
    wrapProgram $out/bin/browse --set-default OPENCODE_BROWSER_AUTO_UPDATE off
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Let AI agents use your real browser: an MCP server and a Chromium extension";
    homepage = "https://github.com/anomalyco/browse";
    changelog = "https://github.com/anomalyco/browse/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.th1nkk1d ];
    mainProgram = "browse";
    platforms = lib.platforms.linux;
  };
})
