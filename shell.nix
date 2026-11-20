let
  sources = import ./nix/sources.nix;
  nixpkgs = import sources.nixpkgs {
    overlays = [
      (final: prev: {
        # nixpkgs doesn't ship Ruby 3.4.13 yet. Drop this override once the pin in
        # nix/sources.json ships 3.4.13 or later.
        ruby_3_4 = prev.mkRuby {
          version = prev.mkRubyVersion "3" "4" "13" "";
          hash = "sha256-0NO/PdjCJKPDt+zYFqDxssvPT4e1r8vb6R0/7xd/NRo=";
          cargoHash = "sha256-5Tp8Kth0yO89/LIcU8K01z6DdZRr8MAA0DPKqDEjIt0=";
        };
      })
    ];
  };
  mkBundlerAppDevShell = nixpkgs.callPackage (import sources.bundler-app-dev-shell) {};
in mkBundlerAppDevShell {
  buildInputs = with nixpkgs; [
    heroku
    ruby_3_4
  ];
}
