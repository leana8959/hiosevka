{
  description = "A customized nerd font of Iosevka, with Haskell and ML ligatures";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixunstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    nixunstable,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
      unstable = import nixunstable {inherit system;};
    in let
      mkNerdFont = font:
        pkgs.stdenv.mkDerivation {
          # credits:
          # https://github.com/NixOS/nixpkgs/issues/44329#issuecomment-1231189572
          # https://github.com/NixOS/nixpkgs/issues/44329#issuecomment-1544597422
          name = "${font.name}-NerdFont";
          src = font;
          nativeBuildInputs = [unstable.nerd-font-patcher pkgs.parallel];
          buildPhase = ''
            mkdir -p nerd-font
            find \( -name \*.ttf -o -name \*.otf \) | parallel nerd-font-patcher \
                {} \
                --name {/.}-NF \
                --use-single-width-glyphs \
                --careful \
                --complete \
                --quiet \
                --no-progressbars \
                --outputdir nerd-font
          '';
          installPhase = ''
            fontdir="$out"/share/fonts/truetype
            install -d "$fontdir"
            install nerd-font/* "$fontdir"
          '';
        };

      hiosevka = let
        pname = "hiosevka";
      in
        (pkgs.iosevka.overrideAttrs (_: {inherit pname;}))
        .override {
          set = pname;
          # https://github.com/be5invis/Iosevka/blob/main/doc/custom-build.md
          # Use `term` spacing to avoid dashed arrow issue
          # https://github.com/ryanoasis/nerd-fonts/issues/1018
          privateBuildPlan = ''
            [buildPlans.${pname}]
            family = "hIosekva"
            spacing = "term"
            serifs = "sans"

            [buildPlans.${pname}.ligations]
            inherits = "haskell"
            enables = [
                "brst",  # (* *)
                "logic", # \/ /\
                "lteq-separate", # <=
                "gteq-separate", # >=
            ]
            disables = [
                "lteq", # <=
                "gteq", # >=
            ]

            [buildPlans.${pname}.variants.design]
            capital-z = 'straight-serifless-with-crossbar'
            capital-q = 'crossing'
            lower-lambda = 'tailed-turn'
            seven = 'straight-serifless-crossbar'
            number-sign = 'slanted'
            ampersand = "upper-open"
            dollar = 'open'
            percent = 'rings-continuous-slash-also-connected'
          '';
        };
    in rec {
      formatter = pkgs.alejandra;

      packages = {
        inherit hiosevka;
        hiosekva-nerd-font = mkNerdFont hiosevka;
      };

      defaultPackage = packages.hiosekva-nerd-font;

      devShell = pkgs.mkShell {
        packages = [unstable.nerd-font-patcher];
      };
    });
}
