with import <nixpkgs> {};
stdenv.mkDerivation {
  name = "scrip";
  src = lib.sourceByRegex ./. ["scrip.sh"];
  buildInputs = [
    coreutils
  ];
  installPhase = ''
    mkdir -p $out/bin
    cp ./scrip.sh $out/bin/scrip
  '';
}
