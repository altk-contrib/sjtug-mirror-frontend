{
  lib,
  stdenv,
  importPnpmLock,
  iplConfigHook,
  makeBinaryWrapper,
  pnpm,
  nodejs,
  name ? "",
  version ? "0-unstable",
}:
stdenv.mkDerivation (finalAttrs: {
  pname = name;
  inherit version;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.intersection (lib.fileset.fromSource (lib.sources.cleanSource ./.)) (
      lib.fileset.unions [
        ./public
        ./src
        ./.eslintrc.json
        ./LICENSE
        ./next.config.mjs
        ./package.json
        ./pnpm-lock.yaml
        ./postcss.config.cjs
        ./README.md
        ./tsconfig.json
      ]
    );
  };

  nativeBuildInputs = [
    iplConfigHook
    makeBinaryWrapper
    pnpm
    nodejs
  ];

  mitmCache = importPnpmLock {
    inherit (finalAttrs) pname version;

    lockFile = ./pnpm-lock.yaml;

    manualEntries = { };
  };

  preBuild = ''
    # patch Next.js file-system-cache to use NIXPKGS_NEXTJS_CACHE_DIR

    # source file
    substituteInPlace node_modules/next/dist/server/lib/incremental-cache/file-system-cache.js \
      --replace-fail 'this.serverDistDir = ctx.serverDistDir;' \
                     'this.serverDistDir = require("path").join((process.env.NIXPKGS_NEXTJS_CACHE_DIR || "/var/cache/${name}"), "${name}");'

    # bundled runtimes
    substituteInPlace node_modules/next/dist/compiled/next-server/server.runtime.prod.js \
      --replace-fail 'this.serverDistDir=e.serverDistDir' \
                     'this.serverDistDir=(process.env.NIXPKGS_NEXTJS_CACHE_DIR||"/var/cache/${name}")+"/${name}"'
  '';

  buildPhase = ''
    runHook preBuild

    export NEXT_TELEMETRY_DISABLED=1 
    pnpm rebuild --pending --reporter append-only
    pnpm run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    cp -r .next/standalone/. $out
    cp -r public $out/public
    makeWrapper "${lib.getExe nodejs}" $out/bin/${name} \
      --set-default PORT 3000 \
      --set-default HOSTNAME 0.0.0.0 \
      --set-default NIXPKGS_NEXTJS_CACHE_DIR /var/cache/${name} \
      --add-flags "$out/server.js"

    runHook postInstall
  '';
})
