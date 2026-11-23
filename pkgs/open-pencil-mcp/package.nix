{
  lib,
  buildNpmPackage,
  fetchurl,
  nix-update-script,
}:

buildNpmPackage (finalAttrs: {
  pname = "open-pencil-mcp";
  version = "0.17.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/@open-pencil/mcp/-/mcp-${finalAttrs.version}.tgz";
    hash = "sha256-TJjKOdSP5S/3ISpP7B1KtkCjx7FGOmis0CDfaXiV07o=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-OrG6TSChUDRyx9cx+2T++rpUg2Vt7Xt/htVjjqg+PLs=";
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
