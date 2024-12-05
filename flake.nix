{
  description = "Helper functions for NAIS flake apps";
  outputs = { self, nixpkgs }: {
    lib = {
      analyzeNaisAppsToFile = { registry, project, team }:
        apps:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          firstSystem = builtins.head (builtins.attrNames apps);
          appsForSystem = apps.${firstSystem};
          makeAppInfo = name: app: {
            inherit name;
            has_spec = app ? spec;
            has_sbom = app ? sbom;
            image_address = "${registry}/${project}/${team}/${name}";
          };
          analysis =
            builtins.attrValues (builtins.mapAttrs makeAppInfo appsForSystem);
        in pkgs.writeText "nais-analysis.json" (builtins.toJSON analysis);
    };
  };
}
