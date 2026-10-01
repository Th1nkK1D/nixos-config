{
  lib,
  buildNpmPackage,
  fetchurl,
  nix-update-script,
}:

buildNpmPackage (finalAttrs: {
  pname = "open-pencil-mcp";
  version = "0.15.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/@open-pencil/mcp/-/mcp-${finalAttrs.version}.tgz";
    hash = "sha256-aiuhdooII8/w0mBa9M0VGZUs5bbOnic+8ugtc+l5E2M=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-4Etsv8ByLETFT5bUCZ0FS2cg0AOdYy0/tNMfZ7Gt9r8=";
  npmFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;

  passthru.updateScript = nix-update-script { extraArgs = [ "--generate-lockfile" ]; };

  meta = {
    description = "MCP server for OpenPencil desktop automation";
    homepage = "https://github.com/open-pencil/open-pencil/tree/main/packages/mcp";
    changelog = "https://github.com/open-pencil/open-pencil/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.th1nkk1d ];
    mainProgram = "openpencil-mcp";
  };
})
