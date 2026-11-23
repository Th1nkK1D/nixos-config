{
  lib,
  buildNpmPackage,
  fetchurl,
  nix-update-script,
}:

buildNpmPackage (finalAttrs: {
  pname = "open-pencil-cli";
  version = "0.17.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/@open-pencil/cli/-/cli-${finalAttrs.version}.tgz";
    hash = "sha256-sM5YRLdI6Q4uLo5IMPuPus+Y/Wib7RYIoR7xsw5Rges=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-Z9ElUyScQAThEdbyi91NRoFgTvWCgxnD1lezYpLvZA4=";
  npmFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;

  passthru.updateScript = nix-update-script { extraArgs = [ "--generate-lockfile" ]; };

  meta = {
    description = "Inspect, analyze, script, and export .fig and .pen files from the terminal";
    homepage = "https://openpencil.dev";
    changelog = "https://github.com/open-pencil/open-pencil/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.th1nkk1d ];
    mainProgram = "openpencil";
  };
})
