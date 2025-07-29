{
  description = "Dev shell with Ruby 3.3.6 built from source + yt-dlp and tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        ruby_3_3_6 = pkgs.stdenv.mkDerivation rec {
          pname = "ruby";
          version = "3.3.6";

          src = pkgs.fetchurl {
            url = "https://cache.ruby-lang.org/pub/ruby/3.3/ruby-${version}.tar.gz";
            sha256 = "sha256-jcSP/68nD4bxAZBT8o5R5NpMzjKjZ2CgYDqa7mfX/Y0=";
          };

          nativeBuildInputs = with pkgs; [ autoconf bison pkg-config ];
          buildInputs = with pkgs; [ openssl libffi zlib libyaml readline gmp ];

          configureFlags = [
            "--enable-shared"
            "--with-opt-dir=${pkgs.openssl.dev}:${pkgs.zlib.dev}:${pkgs.libyaml.dev}"
          ];

          preConfigure = "autoconf";

          meta = with pkgs.lib; {
            description = "Ruby programming language";
            homepage = "https://www.ruby-lang.org";
            license = licenses.ruby;
            platforms = platforms.unix;
          };
        };

        yt-dlp = pkgs.stdenv.mkDerivation {
          pname = "yt-dlp";
          version = "2025.06.30";

          src = pkgs.fetchurl {
            url = "https://github.com/yt-dlp/yt-dlp/releases/download/2025.06.30/yt-dlp";
            sha256 = "sha256-lfUqomm9SN4Tr/4IYL5vR0V8b2r/EkIQFBAPV/YhQQ4=";
          };

          dontUnpack = true;

          installPhase = ''
            mkdir -p $out/bin
            cp $src $out/bin/yt-dlp
            chmod +x $out/bin/yt-dlp
          '';
        };

      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            ruby_3_3_6
            yt-dlp
            zsh
            pkg-config
            libyaml
            openssl
            zlib
            sqlite
            ffmpeg
            vips
            python3
            glib
            cairo
            gobject-introspection
            pango
            jemalloc
            glib
            watchman
          ];

          shellHook = ''
            export GI_TYPELIB_PATH="${pkgs.gobject-introspection}/lib/girepository-1.0''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"
            export GEM_HOME="$PWD/.local/gems"
            export GEM_PATH="$GEM_HOME"
            export PATH="$GEM_HOME/bin:$PATH"

            export BUNDLE_PATH="$GEM_HOME"
            export BUNDLE_BIN="$GEM_HOME/bin"
            export BUNDLE_DISABLE_SHARED_GEMS=true

            mkdir -p "$GEM_HOME" "$BUNDLE_BIN"

            echo "🐚 Welcome to almaktabah dev shell!"
            ruby --version
            yt-dlp --version
            exec zsh
          '';
        };
      });
}
