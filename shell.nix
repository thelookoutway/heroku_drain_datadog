let
  overlay = self: super: {
    # Ruby 2.6.5
    ruby_2_6_5 = (import (builtins.fetchTarball {
      url = https://github.com/NixOS/nixpkgs-channels/archive/fcc8660d359d2c582b0b148739a72cec476cfef5.tar.gz;
    }) {}).ruby;

    # Bundler 1.17.3
    bundler_1_17_3 = (import (builtins.fetchTarball {
      url = https://github.com/NixOS/nixpkgs-channels/archive/fcc8660d359d2c582b0b148739a72cec476cfef5.tar.gz;
    }) {}).bundler.override({
      ruby = self.ruby_2_6_5;
    });
  };

  nixpkgs = import (builtins.fetchTarball {
    url = https://releases.nixos.org/nixpkgs/nixpkgs-20.09pre242076.fd457ecb6cc/nixexprs.tar.xz;
  }) {
    overlays = [ overlay ];
  };
in nixpkgs.mkShell {
  buildInputs = with nixpkgs; [
    bundler_1_17_3
    ruby_2_6_5
  ];
}
