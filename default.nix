with {
  inherit (import <nixpkgs> {}) makeWrapper runCommand;
};
runCommand "scrip" { buildInputs = [ makeWrapper ]; }
''
  makeWrapper ${./scrip.sh} $out/bin/scrip
''
