{
  lib,
  buildNpmPackage,
  fetchurl,
  nix-update-script,
}:

buildNpmPackage (finalAttrs: {
  pname = "open-pencil-cli";
  version = "0.15.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/@open-pencil/cli/-/cli-${finalAttrs.version}.tgz";
    hash = "sha256-b2q1zMjR8SYlts7SS3WHduyG+GSUwfT+Ha2RmwghyFo=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-30IEE+FeNBg4Ixp9vws9LhpdBJbOXAwi6gybXaH6g4E=";
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
