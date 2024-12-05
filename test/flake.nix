{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nais-helpers.url = "path:/Users/carl/source/nais-2/nais-nix-action";

  outputs = { self, nixpkgs, nais-helpers, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        mkImage = name:
          pkgs.dockerTools.buildImage {
            inherit name;
            tag = "latest";
            config = { Cmd = [ "${pkgs.hello}/bin/hello" ]; };
          };

        mkSbom = name: image:
          pkgs.runCommand "${name}-sbom.json" { } ''
            echo '{"name": "${name}", "dependencies": ["hello"]}' > $out
          '';

        mkSpec = name: image:
          pkgs.writeText "${name}-spec.yaml" ''
            apiVersion: nais.io/v1alpha1
            kind: Application
            metadata:
              name: ${name}
              namespace: my-namespace
            spec:
              image: ${image.imageName}:${image.imageTag}
              port: 8080
          '';

        buildApp = name: {
          image = mkImage name;
          sbom = mkSbom name (mkImage name);
          spec = mkSpec name (mkImage name);
        };
        apps = {
          app1 = buildApp "app1";
          app2 = buildApp "app2";
          app3 = buildApp "app3";
        };
      in {
        packages = {
          analysis = nais-helpers.lib.analyzeNaisAppsToFile {
            registry = "europe-north1-docker.pkg.dev";
            project = "my-project";
            team = "my-team";
          } { ${system} = apps; };
          naisApps = apps;
        };
      });
}
