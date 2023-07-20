# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ stdenv
, bash
, nix
, boost
, nlohmann_json
, pkg-config
, xmessage
}: let
  filt = name: type: let
    ignores = ["result" "out" ".git" ".gitignore" ".ccls" ".ccls-cache" "bin"];
    isObj   = ( builtins.match ( ".*\\.o" ) name ) != null;
  in ( ! isObj ) && ( ! ( builtins.elem ( baseNameOf name ) ignores ) );
in stdenv.mkDerivation {
  pname                 = "nix-xmessage";
  version               = "0.1.0";
  src                   = builtins.path { path = ./.; filter = filt; };
  nativeBuildInputs     = [pkg-config];
  buildInputs           = [nix nix.dev boost nlohmann_json];
  propagatedBuildInputs = [bash nix xmessage];
  dontConfigure         = true;
  #libExt                = stdenv.hostPlatform.extensions.sharedLibrary;
  libExt = ".so";
  buildPhase            = ''
    $CXX                                                         \
      -shared                                                    \
      -fPIC                                                      \
      -I${nix.dev}/include                                       \
      -I${boost.dev}/include                                     \
      -I${nlohmann_json}/include                                 \
      -include ${nix.dev}/include/nix/config.h                   \
      $(pkg-config --libs --cflags nix-main nix-store nix-expr)  \
      -o "lib$pname$libExt"                                      \
      ./*.cc                                                     \
    ;
  '';
  installPhase = ''
    mkdir -p "$out/bin" "$out/libexec";
    mv "./lib$pname$libExt" "$out/libexec/lib$pname$libExt";
    cat <<EOF >"$out/bin/$pname"
    #! ${bash}/bin/bash
    # A wrapper around Nix that includes the \`libscrape' plugin.
    # First we add runtime executables to \`PATH', then pass off to Nix.
    for p in \$( <"$out/nix-support/propagated-build-inputs"; ); do
      if [[ -d "\$p/bin" ]]; then PATH="\$PATH:\$p/bin"; fi
    done
    export PATH;
    export XMESSAGE="$PATH:${xmessage}/bin/xmessage";
    exec "${nix}/bin/nix" --plugin-files "$out/libexec/lib$pname$libExt" "\$@";
    EOF
    chmod +x "$out/bin/$pname";
  '';
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
