{
  lib,
  nix2container,
  dockerTools,
  runCommand,
  nodejs,
  frontend,
  port ? 3000,
}:
let
  # Nest all layers so that prior layers are dependencies of later layers.
  # This way, we should avoid redundant dependencies.
  foldImageLayers =
    let
      mergeToLayer =
        priorLayers: component:
        assert builtins.isList priorLayers;
        assert builtins.isAttrs component;
        let
          layer = nix2container.buildLayer (
            component
            // {
              layers = priorLayers;
            }
          );
        in
        priorLayers ++ [ layer ];
    in
    layers: lib.foldl mergeToLayer [ ] layers;

  frontendApp = runCommand "frontend-app" { } ''
    mkdir -p $out/app
    cp -r ${frontend}/. $out/app/
  '';
  frontendVar = runCommand "frontend-var" { } ''
    mkdir -p $out/var/cache/mirror-frontend
  '';
in
nix2container.buildImage {
  name = "mirror-frontend";
  tag = "latest";

  copyToRoot = [
    dockerTools.caCertificates
    frontendApp
    frontendVar
  ];

  layers =
    let
      layerDefs = [
        { deps = [ frontend ]; }
        { deps = [ nodejs ]; }
      ];
    in
    foldImageLayers layerDefs;

  config = {
    WorkingDir = "/app";
    Cmd = [
      "${nodejs}/bin/node"
      "/app/server.js"
    ];
    Env = [
      "NODE_ENV=production"
      "HOST=0.0.0.0"
      "PORT=${toString port}"
      "NIXPKGS_NEXTJS_CACHE_DIR=/var/cache/mirror-frontend"
    ];
    ExposedPorts = {
      "${toString port}/tcp" = { };
    };
  };

}
