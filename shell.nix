let
  sources = import ./nix/sources.nix;
  nixpkgs = import sources.nixpkgs {
    overlays = [
      (final: prev: {
        # nixpkgs doesn't ship Ruby 4.0.10 yet. Drop this override once the pin in
        # nix/sources.json ships 4.0.10 or later.
        ruby_4_0 = prev.mkRuby {
          version = prev.mkRubyVersion "4" "0" "10" "";
          hash = "sha256-tT7vM3H6XT47dDQO3NAV8G1diFOWjU5TmlJk/OQe2fE=";
          cargoHash = "sha256-z7NwWc4TaR042hNx0xgRkh/BQEpEJtE53cfrN0qNiE0=";
        };
      })
    ];
  };
  mkBundlerAppDevShell = nixpkgs.callPackage (import sources.bundler-app-dev-shell) {};
in mkBundlerAppDevShell {
  buildInputs = with nixpkgs; [
    heroku
    ruby_4_0
  ];
}
