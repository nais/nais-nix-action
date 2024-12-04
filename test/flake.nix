{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
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

      in {
        apps = [
          {
            name = "app1";
            image = mkImage "app1";
            sbom = mkSbom "app1" self.apps.app1.image;
            spec = mkSpec "app1" self.apps.app1.image;
          }
          {
            name = "app2";
            image = mkImage "app2";
            sbom = mkSbom "app2" self.apps.app2.image;
            spec = mkSpec "app2" self.apps.app2.image;
          }
          {
            name = "app3";
            image = mkImage "app3";
            sbom = mkSbom "app3" self.apps.app3.image;
            spec = mkSpec "app3" self.apps.app3.image;
          }
        ];
      });
}
