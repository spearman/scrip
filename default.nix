with import <nixpkgs> {};
stdenv.mkDerivation {
  name = "scrip";
  src = ./.;
  buildInputs = [
    coreutils
  ];
  installPhase = ''
    mkdir -p $out/bin
    cp ./scrip.sh $out/bin/scrip
  '';
}
