{
  lib,
  buildNpmPackage,
  fetchurl,
  nix-update-script,
}:

buildNpmPackage (finalAttrs: {
  pname = "open-pencil-mcp";
  version = "0.16.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/@open-pencil/mcp/-/mcp-${finalAttrs.version}.tgz";
    hash = "sha256-xQFGsaUvFOF4Xvq0aOfUMjH7kgKpk/vl8JM0HN2BsZA=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-KiMfGlR6wPrizc/LTkLPTpyeH8qd4QlRbi6DI16nCUQ=";
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
