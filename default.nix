with {
  inherit (import <nixpkgs> {}) stdenv;
  inherit (builtins) elemAt match readFile;
};
let
  version-regex = ".*SCRIP_VERSION=\"([0-9]\\.[0-9]\\.[0-9])\".*";
  version = elemAt (match version-regex (readFile ./bin/scrip)) 0;
in
stdenv.mkDerivation {
  name = "scrip-" + version;
  src  = ./bin;
  installPhase = ''
    mkdir -p $out/bin/
    cp ./scrip $out/bin/
  '';
}
