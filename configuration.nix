# sh <(curl -L https://nixos.org/nix/install)
# nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
# ./result/bin/darwin-installer
# Go through installer, put this file where you want it
# darwin-rebuild switch -I darwin-config=${HOME}/wherever/you/put/it/configuration.nix
# There will probably be errors :)

{ config, pkgs, lib, ... }:
let
  username = "novafacing";
  name = "chaos";
  # fenix = import
  #   (fetchTarball "https://github.com/nix-community/fenix/archive/main.tar.gz")
  #   { };
  fisa-code = pkgs.callPackage ({ lib, stdenvNoCC, fetchFromGitHub }:
    stdenvNoCC.mkDerivation rec {
      pname = "fisa-code";
      version = "1.0";
      src = fetchFromGitHub {
        owner = "sainnhe";
        repo = "icursive-nerd-font";
        rev = "623feb6815753c5679ef4111fb137b8dae4fb983";
        hash = "sha256-NJjyOsDCQ+QmCMlP6ZwBOBdEcKqRQdevUIilWr21snU=";
      };

      installPhase = ''
        runHook preInstall
        install -m444 -Dt $out/share/fonts/truetype dist/*/*.ttf
        runHook postInstall
      '';

      meta = with lib; {
        homepage = "https://github.com/sainnhe/icursive-nerd-font";
        description = "Patched Nerd Fonts";
        longDescription = "Patched Nerd Fonts";
        platforms = platforms.all;
      };
    }) { };
  sold = pkgs.callPackage ({ lib, stdenv, fetchFromGitHub, cmake, mimalloc
    , ninja, openssl, zlib, testers }:

    stdenv.mkDerivation rec {
      name = "mold";
      pname = "mold";

      src = fetchFromGitHub {
        owner = "bluewhalesystems";
        repo = "sold";
        rev = "ab4245a0919c16775c9d497dfa3f03330bda733b";
        hash = "sha256-hAxxnXy7OodIu5rSGlZImktd8ucNLauDeSgGsbaOIps=";
      };

      nativeBuildInputs = [ cmake ninja ];

      buildInputs = [ openssl zlib ]
        ++ lib.optionals (!stdenv.isDarwin) [ mimalloc ];

      postPatch = ''
        sed -i CMakeLists.txt -e '/.*set(DEST\ .*/d'
      '';

      cmakeFlags = [ "-DMOLD_USE_SYSTEM_MIMALLOC:BOOL=ON" ];

      env.NIX_CFLAGS_COMPILE =
        toString (lib.optionals stdenv.isDarwin [ "-faligned-allocation" ]);

      meta = with lib; {
        description = "A faster drop-in replacement for existing Unix linkers";
        longDescription = ''
          mold is a faster drop-in replacement for existing Unix linkers. It is
          several times faster than the LLVM lld linker. mold is designed to
          increase developer productivity by reducing build time, especially in
          rapid debug-edit-rebuild cycles.
        '';
        homepage = "https://github.com/rui314/mold";
        changelog = "https://github.com/rui314/mold/releases/tag/v${version}";
        license = licenses.agpl3Plus;
        maintainers = with maintainers; [ azahi nitsky ];
        platforms = platforms.unix;
      };
    }) { };
  stateVersion = 4;
in let
  home-packages = [
    # fenix.default.toolchain
    # fenix.rust-analyzer
    pkgs.asciinema
    pkgs.autoconf
    pkgs.autoconf-archive
    pkgs.automake
    pkgs.coreutils
    pkgs.cmake
    pkgs.dmenu
    pkgs.fd
    pkgs.ffmpeg
    (lib.hiPrio pkgs.gcc)
    pkgs.id3v2
    pkgs.imagemagick
    pkgs.jdk17
    pkgs.gradle
    pkgs.kitty
    pkgs.libconfig
    pkgs.libev
    pkgs.libiconv
    pkgs.libslirp
    pkgs.libtool
    pkgs.nodejs_20
    pkgs.openssl
    # Use system clang
    # pkgs.llvmPackages_16.clang
    # pkgs.llvmPackages_16.compiler-rt
    # pkgs.llvmPackages_16.libclang
    # pkgs.llvmPackages_16.libcxx
    # pkgs.llvmPackages_16.libcxxabi
    # pkgs.llvmPackages_16.libllvm
    # pkgs.llvmPackages_16.libunwind
    # pkgs.llvmPackages_16.lld
    # pkgs.llvmPackages_16.lldb
    # pkgs.llvmPackages_16.openmp
    pkgs.meson
    pkgs.nasm
    pkgs.nil
    pkgs.ninja
    pkgs.nixfmt
    pkgs.nssTools
    pkgs.openssl
    pkgs.p7zip
    pkgs.pcre
    pkgs.pcre2
    pkgs.pixman
    pkgs.pkg-config
    pkgs.python311Full
    pkgs.silver-searcher
    pkgs.sqlite
    pkgs.tidal-dl
    pkgs.vscode
    pkgs.wget
    pkgs.podman
    pkgs.qemu
    pkgs.yq
    sold
  ];
in {
  imports = [ <home-manager/nix-darwin> ];
  documentation = {
    enable = false;
    doc = { enable = false; };
    info = { enable = false; };
    man = { enable = false; };
  };
  environment = {
    darwinConfig = "$HOME/config/configuration.nix";
    etc = {
      "sudoers.d/10-nix-commands" = {
        text = let yabai = "${pkgs.yabai}/bin/yabai";
        in let hash = builtins.hashFile "sha256" "${yabai}";
        in "${username} ALL=(root) NOPASSWD: sha256:${hash} ${yabai} --load-sa";
      };
    };
    systemPackages = [
      # Use system frameworks
      # pkgs.darwin.apple_sdk.frameworks.System
      # pkgs.darwin.apple_sdk.frameworks.Security
      # pkgs.darwin.apple_sdk.frameworks.CoreFoundation
      # pkgs.darwin.apple_sdk.frameworks.CoreServices
      # pkgs.darwin.apple_sdk.frameworks.CoreData
      # pkgs.darwin.apple_sdk.frameworks.Foundation
      # pkgs.darwin.apple_sdk.frameworks.Kernel
      # pkgs.darwin.apple_sdk.frameworks.MetalKit
      # pkgs.darwin.apple_sdk.frameworks.OpenCL
      # pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
    ];
    systemPath = [ ];
    shellAliases = { };
    variables = { 
    };
  };
  fonts = {
    fontDir = { enable = true; };
    fonts = [ pkgs.font-awesome fisa-code pkgs.nerdfonts ];
  };
  users = {
    users = {
      ${username} = {
        name = "${username}";
        home = "/Users/${username}";
      };
    };
  };
  home-manager = {
    useGlobalPkgs = true;
    users = {
      ${username} = { lib, pkgs, ... }: {
        manual = { manpages = { enable = false; }; };
        programs = {
          zsh = {
            enable = true;
            enableAutosuggestions = true;
            enableCompletion = true;
            enableSyntaxHighlighting = true;
            enableVteIntegration = true;
            envExtra = ''
                [[ -o login ]] && export PATH='/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:''${PATH}'
                if [ -e '/nix/var/nix/profiles/etc/profile.d/nix-daemon.sh' ]; then
                . '/nix/var/nix/profiles/etc/profile.d/nix-daemon.sh'
                fi
                [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
                export NIX_PATH="''${NIX_PATH}:darwin-config=/Users/${username}/config/configuration.nix:/Users/${username}/.nix-defexpr/channels"
                export PATH="''${PATH}:''${HOME}/install/bin/"
                export PATH="''${PATH}:''${HOME}/.nix-profile/bin/"
                export PKG_CONFIG_PATH="''${PKG_CONFIG_PATH}:${pkgs.openssl.dev}/lib/pkgconfig/"
            '';
            history = {
              ignoreDups = true;
              extended = true;
              save = 1000000;
              share = true;
              size = 1000000;
            };
            initExtra = "";
            oh-my-zsh = {
              enable = true;
              extraConfig = "";
              plugins = [ "git" "python" "rust" "extract" "sudo" ];
            };
            plugins = [{
              name = "z";
              src = pkgs.fetchFromGitHub {
                owner = "rupa";
                repo = "z";
                rev = "master";
                sha256 = "sha256-4jMHh1GVRdFNjUjiPH94vewbfLcah7Agu153zjVNE14=";
              };
            }];
          };
          atuin = {
            enable = true;
            enableZshIntegration = true;
            flags = [ ];
            settings = {
              db_path = "~/.history.db";
              key_path = "~/.atuin-key";
              session_path = "~/.atuin-key";
              dialect = "us";
              auto_sync = false;
              sync_frequency = "5m";
              sync_address = "https://api.atuin.sh";
              search_mode = "fuzzy";
              inline_height = 20;
              style = "compact";
              show_preview = true;
              exit_mode = "return-query";
              history_filter = [ "chpasswd" ];
            };
          };
          bat = { enable = true; };
          bottom = { enable = true; };
          command-not-found = {

          };
          feh = { enable = true; };
          gh = {
            enable = true;
            settings = { git_protocol = "ssh"; };
          };
          git = {
            enable = true;
            aliases = {
              status = "status --sort --branch";
              ignore = "update-index --assume-unchanged";
              unignore = "update-index --no-assume-unchanged";
              ignored = ''!git ls-files -v | grep "^[[:lower:]]"'';
              grog =
                "log --graph --abbrev-commit --decorate --all --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(dim white) - %an%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n %C(white)%s%C(reset)'";

            };
            delta = {
              enable = true;
              options = { };
            };
            extraConfig = {
              init = { defaultBranch = "main"; };

              "filter \"lfs\"" = {
                required = true;
                clean = "git-lfs clean -- %f";
                smudge = "git-lfs smudge -- %f";
                process = "git-lfs filter-process";
              };
            };
            ignores = [ ".DS_STORE" ];
            userName = "novafacing";
            userEmail = "rowanbhart@gmail.com";
          };
          go = {
            enable = true;

          };
          gpg = { enable = true; };
          jq = { enable = true; };
          kitty = {
            enable = true;
            darwinLaunchOptions = [ ];
            environment = { };
            extraConfig = "";
            font = {
              name = "Fisa Code";
              size = 12.0;
            };
            settings = {
              disable_ligatures = "tab cursor";
              scrollback_lines = 100000;
              enable_audio_bell = "no";
              term = "xterm";
              allow_remote_control = "yes";
              # Colorscheme
              background = "#32302f";
              foreground = "#d4be98";
              cursor = "#89b482";
              selection_foreground = "#32302f";
              selection_background = "#d4be98";
              color0 = "#32302f";
              color8 = "#d4be98";
              # red
              color1 = "#ea6962";
              # light red
              color9 = "#fb4934";
              # green
              color2 = "#a9b665";
              # light green
              color10 = "#6c782e";
              # yellow
              color3 = "#d8a657";
              # light yellow
              color11 = "#e78a4e";
              # blue
              color4 = "#7daea3";
              # light blue
              color12 = "#45707a";
              # magenta
              color5 = "#d3869b";
              # light magenta
              color13 = "#945e80";
              # cyan
              color6 = "#89b482";
              # lighy cyan
              color14 = "#4c7a5d";
              # light gray
              color7 = "#928474";
              # dark gray
              color15 = "#665c54";
            };
            shellIntegration = { enableZshIntegration = true; };
          };
          lsd = {
            enable = true;
            enableAliases = true;
            settings = {
              date = "relative";
              ignore-globs = [ ".git" ];
            };
          };
          neovim = {
            enable = true;
            defaultEditor = true;
            extraConfig = "";
            plugins = with pkgs.vimPlugins;
              [

              ];
            viAlias = true;
            vimAlias = true;
            vimdiffAlias = true;
            withNodeJs = true;
            withPython3 = true;
          };
          nix-index = {
            enable = true;
            enableZshIntegration = true;
          };
          pandoc = { enable = true; };
          ssh = {
            enable = true;
            compression = true;
            controlMaster = "auto";
            matchBlocks = {
              grobot = {
                hostname = "192.168.0.2";
                user = "grobot";

              };
	      zalera = {
	      	hostname = "192.168.0.177";
		user = "novafacing";
	      };
	      shemhazi = {
	      	hostname = "192.168.0.181";
		user = "novafacing";
	      };
	      rhart-desk = {
	      	hostname = "192.168.0.16";
		user = "rhart";
	      };
            };
            includes = [
               "/Users/${username}/.ssh/config.work"
            ];
          };
          starship = {
            enable = true;
            enableZshIntegration = true;
            settings = {

              "$schema" = "https://starship.rs/config-schema.json";
              format = ''
                [╭─](fg:#5a524c)$directory$git_branch$git_status$git_metrics$time$username$hostname$python$status$fill
                [╰─ϕ ](fg:#5a524c)'';

              command_timeout = 500;

              add_newline = false;

              python = { format = "[ 🐍$virtualenv $version](bg:#282828)"; };

              git_metrics = {
                format =
                  "([+$added](fg:#89b482 bg:#7c6f64)[-$deleted](fg:#ea6962 bg:#7c6f64))[ ](fg:#d8a657 bg:#7c6f64)";
                disabled = false;
              };

              git_branch = {
                format =
                  "[ on $symbol$branch(:$remote_branch)](fg:#ddc7a1 bg:#7c6f64)";
              };
              git_status = {
                format = "[ $all_status$ahead_behind ](fg:#ddc7a1 bg:#7c6f64)";
                ahead = "⇡\${count}";
                diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
                behind = "⇣\${count}";
              };

              directory = {
                format =
                  "[](fg:#89b482)[ $path ](fg:#282828 bg:#89b482)[](bg:#7c6f64 fg:#89b482)";
              };
              fill = {
                symbol = "·";
                style = "fg:#46413e";
              };

              status = {
                format =
                  "[ ](bg:#282828)[$status ](bg:#282828)[](fg:#89b482 bg:#282828)[](fg:#282828)";
                disabled = false;
                success_symbol = "✓";
              };

              hostname = {
                format = "[@$hostname](bg:#504945)[](fg:#504945 bg:#282828)";
                ssh_only = false;
              };

              username = {
                show_always = true;
                format = "[$user](bg:#504945)";
                disabled = false;
              };

              time = {
                format =
                  "[ $time ](bg:#7c6f64 fg:#45403d)[](fg:#7c6f64 bg:#504945)";
                disabled = false;
              };
            };
          };
          vscode = {
            enable = true;
            enableExtensionUpdateCheck = false;
            enableUpdateCheck = false;
            package = pkgs.vscode;
            extensions = [
              pkgs.vscode-extensions.bierner.markdown-mermaid
              pkgs.vscode-extensions.christian-kohler.path-intellisense
              pkgs.vscode-extensions.dotjoshjohnson.xml
              pkgs.vscode-extensions.eamodio.gitlens
              # pkgs.vscode-extensions.edwinkofler.vscode-assorted-languages
              pkgs.vscode-extensions.esbenp.prettier-vscode
              # pkgs.vscode-extensions.exodiusstudios.comment-anchors
              pkgs.vscode-extensions.formulahendry.auto-rename-tag
              pkgs.vscode-extensions.github.copilot
              pkgs.vscode-extensions.github.vscode-pull-request-github
              # pkgs.vscode-extensions.inferrinizzard.prettier-sql-vscode
              pkgs.vscode-extensions.james-yu.latex-workshop
              # pkgs.vscode-extensions.janisdd.vscode-edit-csv
              pkgs.vscode-extensions.jebbs.plantuml
              # pkgs.vscode-extensions.karunamurti.tera
              pkgs.vscode-extensions.llvm-vs-code-extensions.vscode-clangd
              # pkgs.vscode-extensions.maelvalais.autoconf
              # pkgs.vscode-extensions.mesonbuild.mesonbuild
              pkgs.vscode-extensions.ms-azuretools.vscode-docker
              pkgs.vscode-extensions.ms-python.python
              pkgs.vscode-extensions.ms-python.vscode-pylance
              pkgs.vscode-extensions.ms-toolsai.jupyter
              pkgs.vscode-extensions.ms-toolsai.jupyter-keymap
              pkgs.vscode-extensions.ms-toolsai.jupyter-renderers
              pkgs.vscode-extensions.ms-toolsai.vscode-jupyter-cell-tags
              pkgs.vscode-extensions.ms-toolsai.vscode-jupyter-slideshow
              # pkgs.vscode-extensions.ms-vscode-remote.remote-containers
              pkgs.vscode-extensions.ms-vscode-remote.remote-ssh
              # pkgs.vscode-extensions.ms-vscode-remote.remote-ssh-edit
              # pkgs.vscode-extensions.ms-vscode-remote.remote-wsl
              # pkgs.vscode-extensions.ms-vscode-remote.vscode-remote-extensionpack
              pkgs.vscode-extensions.ms-vscode.cmake-tools
              # pkgs.vscode-extensions.ms-vscode.cpptools
              pkgs.vscode-extensions.ms-vscode.hexeditor
              # pkgs.vscode-extensions.ms-vscode.remote-explorer
              # pkgs.vscode-extensions.ms-vscode.remote-server
              pkgs.vscode-extensions.naumovs.color-highlight
              # pkgs.vscode-extensions.npclaudiu.vscode-gn
              # pkgs.vscode-extensions.perkovec.emoji
              pkgs.vscode-extensions.pkief.material-icon-theme
              # pkgs.vscode-extensions.pnp.polacode
              pkgs.vscode-extensions.redhat.java
              pkgs.vscode-extensions.redhat.vscode-yaml
              # pkgs.vscode-extensions.richie5um2.vscode-sort-json
              pkgs.vscode-extensions.rust-lang.rust-analyzer
    	      # fenix.rust-analyzer-vscode-extension
              # pkgs.vscode-extensions.sainnhe.gruvbox-material
              pkgs.vscode-extensions.serayuzgur.crates
              pkgs.vscode-extensions.tamasfe.even-better-toml
              pkgs.vscode-extensions.twxs.cmake
              # pkgs.vscode-extensions.vadimcn.vscode-lldb
              # pkgs.vscode-extensions.vgalaktionov.moonscript
              pkgs.vscode-extensions.vscodevim.vim
              pkgs.vscode-extensions.yzhang.markdown-all-in-one
            ];
            keybindings = [
              {
                key = "Ctrl+l";
                command = "workbench.action.focusRightGroup";
              }
              {
                key = "Ctrl+k Ctrl+right";
                command = "-workbench.action.focusRightGroup";
              }
              {
                key = "Ctrl+h";
                command = "workbench.action.focusLeftGroup";
              }
              {
                key = "Ctrl+k Ctrl+left";
                command = "-workbench.action.focusLeftGroup";
              }
              {
                key = "Ctrl+shift+\\";
                command = "-workbench.action.terminal.focusTabs";
                when =
                  "terminalFocus && terminalHasBeenCreated || terminalFocus && terminalProcessSupported || terminalHasBeenCreated && terminalTabsFocus || terminalProcessSupported && terminalTabsFocus";
              }
              {
                key = "Ctrl+k";
                command = "workbench.action.focusActiveEditorGroup";
              }
              {
                key = "Ctrl+o";
                command = "workbench.action.files.openFolder";
                when = "true";
              }
              {
                key = "Ctrl+j";
                command = "-workbench.action.togglePanel";
              }
              {
                key = "Ctrl+j";
                command = "-extension.vim_Ctrl+j";
                when =
                  "editorTextFocus && vim.active && vim.use<C-j> && !inDebugRepl";
              }
              {
                key = "Ctrl+j";
                command = "workbench.action.terminal.focus";
              }
              {
                key = "Ctrl+shift+k";
                command = "workbench.action.files.showOpenedFileInNewWindow";
                when = "emptyWorkspaceSupport";
              }
              {
                key = "Ctrl+k o";
                command = "-workbench.action.files.showOpenedFileInNewWindow";
                when = "emptyWorkspaceSupport";
              }
              {
                key = "Ctrl+l";
                command = "workbench.action.terminal.focusNextPane";
                when =
                  "terminalFocus && terminalHasBeenCreated || terminalFocus && terminalProcessSupported";
              }
              {
                key = "alt+down";
                command = "-workbench.action.terminal.focusNextPane";
                when =
                  "terminalFocus && terminalHasBeenCreated || terminalFocus && terminalProcessSupported";
              }
              {
                key = "Ctrl+h";
                command = "workbench.action.terminal.focusPreviousPane";
                when =
                  "terminalFocus && terminalHasBeenCreated || terminalFocus && terminalProcessSupported";
              }
              {
                key = "alt+left";
                command = "-workbench.action.terminal.focusPreviousPane";
                when =
                  "terminalFocus && terminalHasBeenCreated || terminalFocus && terminalProcessSupported";
              }
              {
                key = "Ctrl+o";
                command = "-workbench.action.files.openFile";
                when = "true";
              }
            ];
            userSettings = {
              "[c]" = {
                "editor.defaultFormatter" =
                  "llvm-vs-code-extensions.vscode-clangd";
              };
              "[cpp]" = {
                "editor.defaultFormatter" =
                  "llvm-vs-code-extensions.vscode-clangd";
              };
              "[html]" = {
                "editor.defaultFormatter" = "vscode.html-language-features";
              };
              "[java]" = { "editor.defaultFormatter" = "redhat.java"; };
              "[javascript]" = {
                "editor.defaultFormatter" = "esbenp.prettier-vscode";
              };
              "[json]" = {
                "editor.defaultFormatter" = "vscode.json-language-features";
              };
              "[jsonc]" = {
                "editor.defaultFormatter" = "esbenp.prettier-vscode";
              };
              "[markdown]" = {
                "editor.defaultFormatter" = "yzhang.markdown-all-in-one";
              };
              "[nix]" = { "editor.defaultFormatter" = "jnoortheen.nix-ide"; };
              "[plaintext]" = {
                "editor.unicodeHighlight.ambiguousCharacters" = false;
                "editor.unicodeHighlight.invisibleCharacters" = false;
              };
              "[rust]" = {
                "editor.defaultFormatter" = "rust-lang.rust-analyzer";
              };
              "[sql]" = { "editor.defaultFormatter" = "mtxr.sqltools"; };
              "[toml]" = {
                "editor.defaultFormatter" = "tamasfe.even-better-toml";
              };
              "[typescript]" = {
                "editor.defaultFormatter" = "esbenp.prettier-vscode";
              };
              "C_Cpp.clang_format_fallbackStyle" =
                "{Language =        Cpp, BasedOnStyle =  LLVM, AccessModifierOffset = -4, AlignAfterOpenBracket = Align, AlignArrayOfStructures = None, AlignConsecutiveMacros = None, AlignConsecutiveAssignments = None, AlignConsecutiveBitFields = None, AlignConsecutiveDeclarations = None, AlignEscapedNewlines = Right, AlignOperands =   Align, AlignTrailingComments = true, AllowAllArgumentsOnNextLine = true, AllowAllConstructorInitializersOnNextLine = true, AllowAllParametersOfDeclarationOnNextLine = true, AllowShortEnumsOnASingleLine = true, AllowShortBlocksOnASingleLine = Never, AllowShortCaseLabelsOnASingleLine = false, AllowShortFunctionsOnASingleLine = All, AllowShortLambdasOnASingleLine = All, AllowShortIfStatementsOnASingleLine = Never, AllowShortLoopsOnASingleLine = false, AlwaysBreakAfterDefinitionReturnType = None, AlwaysBreakAfterReturnType = None, AlwaysBreakBeforeMultilineStrings = false, AlwaysBreakTemplateDeclarations = MultiLine, BinPackArguments = true, BinPackParameters = true, BraceWrapping = {,   AfterCaseLabel =  false,   AfterClass =      false,   AfterControlStatement = Never,   AfterEnum =       false,   AfterFunction =   false,   AfterNamespace =  false,   AfterObjCDeclaration = false,   AfterStruct =     false,   AfterUnion =      false,   AfterExternBlock = false,   BeforeCatch =     false,   BeforeElse =      false,   BeforeLambdaBody = false,   BeforeWhile =     false,   IndentBraces =    false,   SplitEmptyFunction = true,   SplitEmptyRecord = true,   SplitEmptyNamespace = true, }; BreakBeforeBinaryOperators = None, BreakBeforeConceptDeclarations = true, BreakBeforeBraces = Attach, BreakBeforeInheritanceComma = false, BreakInheritanceList = BeforeColon, BreakBeforeTernaryOperators = true, BreakConstructorInitializersBeforeComma = false, BreakConstructorInitializers = BeforeColon, BreakAfterJavaFieldAnnotations = false, BreakStringLiterals = true, ColumnLimit =     88, CompactNamespaces = false, ConstructorInitializerAllOnOneLineOrOnePerLine = false, ConstructorInitializerIndentWidth = 4, ContinuationIndentWidth = 4, Cpp11BracedListStyle = true, DeriveLineEnding = true, DerivePointerAlignment = false, DisableFormat =   false, EmptyLineAfterAccessModifier = Never, EmptyLineBeforeAccessModifier = LogicalBlock, ExperimentalAutoDetectBinPacking = false, FixNamespaceComments = true, IncludeBlocks =   Preserve, IncludeIsMainRegex = '(Test)?$', IncludeIsMainSourceRegex = '', IndentAccessModifiers = false, IndentCaseLabels = true, IndentCaseBlocks = false, IndentGotoLabels = true, IndentPPDirectives = None, IndentExternBlock = AfterExternBlock, IndentRequires =  false, IndentWidth =     4, IndentWrappedFunctionNames = false, InsertTrailingCommas = None, JavaScriptQuotes = Leave, JavaScriptWrapImports = true, KeepEmptyLinesAtTheStartOfBlocks = true, LambdaBodyIndentation = Signature, MacroBlockBegin = '', MacroBlockEnd =   '', MaxEmptyLinesToKeep = 1, NamespaceIndentation = None, ObjCBinPackProtocolList = Auto, ObjCBlockIndentWidth = 2, ObjCBreakBeforeNestedBlockParam = true, ObjCSpaceAfterProperty = false, ObjCSpaceBeforeProtocolList = true, PenaltyBreakAssignment = 2, PenaltyBreakBeforeFirstCallParameter = 19, PenaltyBreakComment = 300, PenaltyBreakFirstLessLess = 120, PenaltyBreakString = 1000, PenaltyBreakTemplateDeclaration = 10, PenaltyExcessCharacter = 1000000, PenaltyReturnTypeOnItsOwnLine = 60, PenaltyIndentedWhitespace = 0, PointerAlignment = Right, PPIndentWidth =   -1, ReferenceAlignment = Pointer, ReflowComments =  true, ShortNamespaceLines = 1, SortIncludes =    CaseSensitive, SortJavaStaticImport = Before, SortUsingDeclarations = true, SpaceAfterCStyleCast = false, SpaceAfterLogicalNot = false, SpaceAfterTemplateKeyword = true, SpaceBeforeAssignmentOperators = true, SpaceBeforeCaseColon = false, SpaceBeforeCpp11BracedList = false, SpaceBeforeCtorInitializerColon = true, SpaceBeforeInheritanceColon = true, SpaceBeforeParens = ControlStatements, SpaceAroundPointerQualifiers = Default, SpaceBeforeRangeBasedForLoopColon = true, SpaceInEmptyBlock = false, SpaceInEmptyParentheses = false, SpacesBeforeTrailingComments = 1, SpacesInAngles =  Never, SpacesInConditionalStatement = false, SpacesInContainerLiterals = true, SpacesInCStyleCastParentheses = false, SpacesInLineCommentPrefix = {,   Minimum =         1,   Maximum =         1, }; SpacesInParentheses = false, SpacesInSquareBrackets = false, SpaceBeforeSquareBrackets = false, BitFieldColonSpacing = Both, Standard =        Latest, TabWidth =        4, UseCRLF =         false, UseTab =          Never}";
              "C_Cpp.clang_format_sortIncludes" = true;
              "C_Cpp.default.cppStandard" = "c++20";
              "C_Cpp.default.cStandard" = "c17";
              "C_Cpp.dimInactiveRegions" = false;
              "C_Cpp.formatting" = "clangFormat";
              "C_Cpp.inactiveRegionBackgroundColor" = "#3c3836";
              "C_Cpp.intelliSenseEngine" = "disabled";
              "clangd.arguments" = [ "--enable-config" ];
              "clangd.checkUpdates" = true;
              "clangd.path" = "/usr/bin/clangd";
              "cmake.configureOnOpen" = true;
              "color-highlight.languages" = [ "*" ];
              "color-highlight.markerType" = "dot-after";
              "debug.internalConsoleOptions" = "neverOpen";
              "debug.onTaskErrors" = "debugAnyway";
              "editor.acceptSuggestionOnEnter" = "off";
              "editor.autoClosingQuotes" = "never";
              "editor.bracketPairColorization.enabled" = true;
              "editor.cursorBlinking" = "smooth";
              "editor.cursorStyle" = "block";
              "editor.defaultFormatter" = "ms-python.python";
              "editor.fontFamily" = "Fisa Code";
              "editor.fontLigatures" = true;
              "editor.fontSize" = 16;
              "editor.formatOnPaste" = true;
              "editor.formatOnSave" = true;
              "editor.guides.bracketPairs" = true;
              "editor.guides.highlightActiveBracketPair" = true;
              "editor.guides.highlightActiveIndentation" = "always";
              "editor.inlineSuggest.enabled" = true;
              "editor.renderWhitespace" = "all";
              "editor.rulers" = [ 88 ];
              "editor.stickyScroll.enabled" = true;
              "editor.suggestSelection" = "first";
              "editor.tokenColorCustomizations" = {
                "textMateRules" = [
                  {
                    "name" = "comment";
                    "scope" = [ "comment" ];
                    "settings" = { "fontStyle" = "italic"; };
                  }
                  {
                    "name" = "Keyword Storage";
                    "scope" = [ "keyword" "keyword.control" "storage" ];
                    "settings" = { "fontStyle" = "italic"; };
                  }
                ];
              };
              "explorer.confirmDelete" = false;
              "explorer.confirmDragAndDrop" = false;
              "explorer.fileNesting.enabled" = true;
              "explorer.fileNesting.expand" = false;
              "extensions.ignoreRecommendations" = true;
              "files.exclude" = {
                "**/.classpath" = true;
                "**/.factorypath" = true;
                "**/.project" = true;
                "**/.settings" = true;
              };
              "files.maxMemoryForLargeFilesMB" = 8192;
              "files.refactoring.autoSave" = true;
              "github.copilot.enable" = {
                "*" = true;
                "markdown" = false;
                "plaintext" = false;
                "yaml" = false;
              };
              "github.copilot.editor.enableAutoCompletions" = true;
              "github.copilot.editor.enableCodeActions" = false;
              "githubPullRequests.createOnPublishBranch" = "never";
              "githubPullRequests.remotes" = [ "origin" ];
              "gruvboxMaterial.colorfulSyntax" = true;
              "gruvboxMaterial.italicKeywords" = true;
              "gruvboxMaterial.lightPalette" = "material";
              "gruvboxMaterial.lightContrast" = "soft";
              "gruvboxMaterial.lightSelection" = "yellow";
              "gruvboxMaterial.darkPalette" = "material";
              "gruvboxMaterial.darkContrast" = "soft";
              "gruvboxMaterial.darkCursor" = "yellow";
              "gruvboxMaterial.darkSelection" = "green";
              "java.codeGeneration.generateComments" = true;
              "java.completion.guessMethodArguments" = true;
              "java.jdt.ls.java.home" = "/usr/lib/jvm/java-17-openjdk-amd64";
              "java.jdt.ls.vmargs" = ''
                -XX:+UseParallelGC -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -Dsun.zip.disableMemoryMapping=true -Xmx1G -Xms100m -javaagent:"/home/novafacing/.vscode/extensions/gabrielbb.vscode-lombok-1.0.1/server/lombok.jar"'';
              "javascript.updateImportsOnFileMove.enabled" = "always";
              "keyboard.dispatch" = "keyCode";
              "latex-workshop.latex.recipe.default" = "lastUsed";
              "latex-workshop.latex.recipes" = [
                {
                  "name" = "lualatex ➞ bibtex ➞ lualatex × 2";
                  "tools" = [ "lualatex" "bibtex" "lualatex" "lualatex" ];
                }
                {
                  "name" = "Just pdflatex";
                  "tools" = [ "pdflatex" ];
                }
                {
                  "name" = "Just lualatex";
                  "tools" = [ "lualatex" ];
                }
                {
                  "name" = "latexmk 🔃";
                  "tools" = [ "latexmk" ];
                }
                {
                  "name" = "latexmk (latexmkrc)";
                  "tools" = [ "latexmk_rconly" ];
                }
                {
                  "name" = "latexmk (lualatex)";
                  "tools" = [ "lualatexmk" ];
                }
                {
                  "name" = "pdflatex ➞ bibtex ➞ pdflatex × 2";
                  "tools" = [ "pdflatex" "bibtex" "pdflatex" "pdflatex" ];
                }
                {
                  "name" = "Compile Rnw files";
                  "tools" = [ "rnw2tex" "latexmk" ];
                }
                {
                  "name" = "Compile Jnw files";
                  "tools" = [ "jnw2tex" "latexmk" ];
                }
                {
                  "name" = "tectonic";
                  "tools" = [ "tectonic" ];
                }
              ];
              "latex-workshop.latex.tools" = [
                {
                  "args" = [
                    "-synctex=1"
                    "-shell-escape"
                    "-interaction=nonstopmode"
                    "-file-line-error"
                    "%DOCFILE%"
                  ];
                  "command" = "lualatex";
                  "name" = "lualatex";
                }
                {
                  "args" = [
                    "-synctex=1"
                    "-shell-escape"
                    "-interaction=nonstopmode"
                    "-file-line-error"
                    "%DOCFILE%"
                  ];
                  "command" = "pdflatex";
                  "name" = "pdflatex";
                }
                {
                  "args" = [
                    "-synctex=1"
                    "-interaction=nonstopmode"
                    "-file-line-error"
                    "%DOCFILE%"
                  ];
                  "command" = "xelatex";
                  "name" = "xelatex";
                }
                {
                  "args" = [ "%DOCFILE%" ];
                  "command" = "bibtex";
                  "name" = "bibtex";
                }
              ];
              "latex-workshop.view.pdf.invertMode.enabled" = "always";
              "nix.serverPath" = "nil";
              "nix.formatterPath" = "nixfmt";
              "notebook.cellToolbarLocation" = {
                "default" = "right";
                "jupyter-notebook" = "left";
              };
              "prettier.documentSelectors" = [ "*.js" "*.ts" "*.html" "*.css" ];
              "prettier.printWidth" = 88;
              "prettier.tabWidth" = 4;
              "prettier.trailingComma" = "all";
              "prettier.vueIndentScriptAndStyle" = true;
              "python.defaultInterpreterPath" = "python3";
              "python.formatting.provider" = "black";
              "python.languageServer" = "Pylance";
              "python.linting.mypyEnabled" = true;
              "python.linting.pylintEnabled" = true;
              "redhat.telemetry.enabled" = false;
              "rust-analyzer.check.command" = "clippy";
              "rust-analyzer.cargo.extraEnv" = {
                "CARGO_PROFILE_RUST_ANALYZER_INHERITS" = "dev";
              };
              "rust-analyzer.cargo.extraArgs" = [ "--profile" "rust-analyzer" ];
              "security.workspace.trust.untrustedFiles" = "open";
              "settingsSync.ignoredSettings" =
                [ "-python.formatting.blackPath" ];
              "sqltools.completionLanguages" = [ ];
              "sqltools.highlightQuery" = false;
              "sqltools.useNodeRuntime" = true;
              "telemetry.telemetryLevel" = "off";
              "terminal.external.linuxExec" = "kitty";
              "terminal.integrated.cursorBlinking" = true;
              "terminal.integrated.customGlyphs" = false;
              "terminal.integrated.defaultProfile.linux" = "zsh";
              "terminal.integrated.detectLocale" = "on";
              "terminal.integrated.drawBoldTextInBrightColors" = false;
              "terminal.integrated.enableMultiLinePasteWarning" = false;
              "terminal.integrated.fontFamily" = "Fisa Code";
              "terminal.integrated.fontSize" = 16;
              "terminal.integrated.gpuAcceleration" = "on";
              "terminal.integrated.inheritEnv" = true;
              "terminal.integrated.scrollback" = 100000;
              "terminal.integrated.shellIntegration.enabled" = true;
              "typescript.updateImportsOnFileMove.enabled" = "always";
              "vim.easymotion" = true;
              "vim.easymotionDimBackground" = true;
              "vim.easymotionDimColor" = "#7c6f64";
              "vim.easymotionMarkerBackgroundColor" = "#45403d";
              "vim.easymotionMarkerFontWeight" = "bold";
              "vim.easymotionMarkerForegroundColorOneChar" = "#d3869b";
              "vim.easymotionMarkerForegroundColorTwoCharFirst" = "#d8a657";
              "vim.easymotionMarkerForegroundColorTwoCharSecond" = "#e78a4e";
              "vim.hlsearch" = true;
              "vim.normalModeKeyBindingsNonRecursive" = [
                {
                  "after" = [ "<leader>" "<leader>" "<leader>" "b" "d" "w" ];
                  "before" = [ "t" ];
                }
                {
                  "before" = [ "g" "n" ];
                  "after" = [ ];
                  "commands" = [{ "command" = "editor.action.marker.next"; }];
                }
              ];
              "vim.smartRelativeLine" = true;
              "vim.statusBarColorControl" = false;
              "vim.statusBarColors.commandlineinprogress" =
                [ "#32302f" "#89b482" ];
              "vim.statusBarColors.normal" = [ "#32302f" "#d8a657" ];
              "vim.statusBarColors.insert" = [ "#32302f" "#d3869b" ];
              "vim.statusBarColors.replace" = [ "#32302f" "#e78a4e" ];
              "vim.statusBarColors.searchinprogressmode" =
                [ "#32302f" "#89b482" ];
              "vim.statusBarColors.visual" = [ "#32302f" "#7daea3" ];
              "vim.statusBarColors.visualblock" = [ "#32302f" "#7daea3" ];
              "vim.statusBarColors.visualline" = [ "#32302f" "#7daea3" ];
              "vim.statusBarColors.easymotioninputmode" =
                [ "#32302f" "#e78a4e" ];
              "vim.statusBarColors.easymotionmode" = [ "#32302f" "#e78a4e" ];
              "vim.textwidth" = 88;
              "window.menuBarVisibility" = "toggle";
              "window.restoreWindows" = "none";
              "window.zoomLevel" = -1.5;
              "workbench.colorCustomizations" = {
                "editorBracketHighlight.foreground1" = "#ea6962";
                "editorBracketHighlight.foreground2" = "#d3869b";
                "editorBracketHighlight.foreground3" = "#e78a4e";
                "editorBracketHighlight.foreground4" = "#a9b665";
                "editorBracketHighlight.foreground5" = "#bd6f3e";
                "editorBracketHighlight.foreground6" = "#89b482";
                "editorStickyScroll.background" = "#3c3836";
                "editorStickyScrollHover.background" = "#46413e";
                "statusBar.background" = "#32302f";
                "statusBar.debuggingBackground" = "#32302f";
                "statusBar.debuggingForeground" = "#d8a657";
                "statusBar.foreground" = "#d8a657";
                "statusBar.noFolderBackground" = "#32302f";
              };
              "workbench.colorTheme" = "Gruvbox Material Dark";
              "workbench.editorAssociations" = {
                "*.ipynb" = "jupyter-notebook";
              };
              "workbench.editor.tabSizing" = "fixed";
              "workbench.iconTheme" = "material-icon-theme";
              "workbench.sideBar.location" = "right";
              "workbench.startupEditor" = "none";
              "color-highlight.enable" = true;
              "color-highlight.matchWords" = true;
              "editor.minimap.enabled" = false;
            };
          };
        };

        home = {
          file = {
            cargo-config-toml = {
              target = ".cargo/config.toml";
              enable = true;
              text = ''
                [target.aarch64-apple-darwin]
                linker = "/usr/bin/clang"
                rustflags = [
                    "-C",
                    "link-arg=--ld-path=${sold}/bin/ld64.mold",
                ]
                
                [net]
                git-fetch-with-cli = true
              '';
            };
          };
          stateVersion = "23.05";
          packages = home-packages;
          activation = {
            unaliasApplications = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
              (lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
                echo "Un-Linking Home Manager applications..." 2>&1
                app_path="$HOME/Applications/Home Manager Apps"
                rm -rf "$app_path"
              '');
            aliasApplications = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (let
              apps = pkgs.buildEnv {
                name = "home-manager-applications";
                paths = home-packages;
                pathsToLink = "/Applications";
              };
            in lib.hm.dag.entryAfter [ "linkGeneration" ] ''
              echo "Linking Home Manager applications..." 2>&1
              app_path="$HOME/Applications/Home Manager Apps"
              tmp_path="$(mktemp -dt "home-manager-applications.XXXXXXXXXX")" || exit 1
              ${pkgs.fd}/bin/fd \
                  -t l -d 1 . ${apps}/Applications \
                  -x $DRY_RUN_CMD /Users/${username}/install/bin/mkalias -L {} "$tmp_path/{/}"
              $DRY_RUN_CMD rm -rf "$app_path"
              $DRY_RUN_CMD mv "$tmp_path" "$app_path"
            '');
          };
        };
        services = { };
      };
    };
  };
  networking = {
    computerName = "${name}";
    hostName = "${name}";
  };
  nix = {
    nixPath = [
      { darwin-config = "$HOME/config/configuration.nix"; }
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
    extraOptions = ''
      auto-optimise-store = true
      experimental-features = nix-command flakes
      system = aarch64-darwin
      extra-platforms = x86_64-darwin aarch64-darwin
    '';
  };
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = false;
    };
    overlays = [ ];
  };
  programs = { };
  services = {
    nix-daemon = {
      enable = true;
      logFile = "/var/log/nix-daemon.log";
    };
    skhd = {
      enable = true;
      skhdConfig = ''
                cmd - h: yabai -m window --focus west
                cmd - l: yabai -m window --focus east
                cmd - j: yabai -m window --focus south
                cmd - k: yabai -m window --focus north
                cmd - 1: yabai -m space --focus 1
                cmd - 2: yabai -m space --focus 2
                cmd - 3: yabai -m space --focus 3
                cmd - 4: yabai -m space --focus 4
                cmd - 5: yabai -m space --focus 5
                cmd - 6: yabai -m space --focus 6
                cmd + shift - 1: yabai -m window --space 1
                cmd + shift - 2: yabai -m window --space 2
                cmd + shift - 3: yabai -m window --space 3
                cmd + shift - 4: yabai -m window --space 4
                cmd + shift - 5: yabai -m window --space 5
                cmd + shift - 6: yabai -m window --space 6
                rcmd - e: yabai -m window --insert east
                rcmd - v: yabai -m window --insert south
                rcmd - f: yabai -m window --toggle zoom-fullscreen
                cmd + shift - q: yabai -m window --close
                cmd - return: ${pkgs.kitty}/bin/kitty --single-instance -d ~
                cmd - n: yabai -m window --toggle float
        	cmd - d: ${pkgs.dmenu}/bin/dmenu
                :: resize @ : yabai -m config active_window_border_color 0xffa9b665
                cmd - r; resize
                resize < escape ; default
                resize < h: yabai -m window --resize left:-20:0 ; yabai -m window --resize right:-20:0
                resize < l: yabai -m window --resize right:20:0 ; yabai -m window --resize left:20:0
                resize < j: yabai -m window --resize bottom:0:20 ; yabai -m window --resize top:0:20
                resize < k: yabai -m window --resize top:0:-20 ; yabai -m window --resize bottom:0:-20
      '';
    };
    yabai = {
      enable = true;
      enableScriptingAddition = true;
      config = {
        debug_output = "on";
        layout = "bsp";
        window_gap = 8;
        top_padding = 8;
        bottom_padding = 8;
        left_padding = 8;
        right_padding = 8;
        mouse_modifier = "fn";
        mouse_action1 = "resize";
        mouse_action2 = "move";
        focus_follows_mouse = "autofocus";
        mouse_follows_focus = "on";
        window_topmost = "off";
        window_shadow = "float";
      };
      extraConfig = ''
        yabai -m space --create
        yabai -m space --create
        yabai -m space --create
        yabai -m space --create
        yabai -m space --create
        yabai -m space --create
        echo "Yabai configuration loaded..."
      '';
    };
  };
  # Nix-darwin does not link installed applications to the user environment. This means apps will not show up
  # in spotlight; and when launched through the dock they come with a terminal window. This is a workaround.
  # Upstream issue = https://github.com/LnL7/nix-darwin/issues/214
  system = {
    activationScripts = {
      applications = {
        text = lib.mkForce ''
          echo "setting up ~/Applications..." >&2
          applications="$HOME/Applications"
          nix_apps="$applications/Nix Apps"

          # Needs to be writable by the user so that home-manager can symlink into it
          if ! test -d "$applications"; then
              mkdir -p "$applications"
              chown ${username} = "$applications"
              chmod u+w "$applications"
          fi

          # Delete the directory to remove old links
          rm -rf "$nix_apps"
          mkdir -p "$nix_apps"
          find ${config.system.build.applications}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
              while read src; do
                  # Spotlight does not recognize symlinks; it will ignore directory we link to the applications folder.
                  # It does understand MacOS aliases though; a unique filesystem feature. Sadly they cannot be created
                  # from bash (as far as I know); so we use the oh-so-great Apple Script instead.
                  /usr/bin/osascript -e "
                      set fileToAlias to POSIX file \"$src\" 
                      set applicationsFolder to POSIX file \"$nix_apps\"
                      tell application \"Finder\"
                          make alias file to fileToAlias at applicationsFolder
                          # This renames the alias; 'mpv.app alias' -> 'mpv.app'
                          set name of result to \"$(rev <<< "$src" | cut -d'/' -f1 | rev)\"
                      end tell
                  " 1>/dev/null
              done
        '';
      };
      postUserActivation = {
        text =
          "  /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u\n";
      };
    };
    stateVersion = stateVersion;
    defaults = {
      NSGlobalDomain = {
        AppleEnableMouseSwipeNavigateWithScrolls = false;
        AppleEnableSwipeNavigateWithScrolls = false;
        AppleICUForce24HourTime = false;
        AppleInterfaceStyle = "Dark";
        AppleInterfaceStyleSwitchesAutomatically = false;
        AppleScrollerPagingBehavior = true;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        AppleShowScrollBars = "Always";
        AppleWindowTabbingMode = "manual";
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticWindowAnimationsEnabled = false;
        NSDocumentSaveNewDocumentsToCloud = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSScrollAnimationEnabled = true;
        NSTableViewDefaultSizeMode = 1;
        NSTextShowsControlCharacters = true;
        NSUseAnimatedFocusRing = false;
        NSWindowResizeTime = null;
        PMPrintingExpandedStateForPrint = false;
        _HIHideMenuBar = false;
        "com.apple.keyboard.fnState" = false;
        "com.apple.mouse.tapBehavior" = null;
        "com.apple.sound.beep.feedback" = 1;
        "com.apple.springing.delay" = null;
        "com.apple.springing.enabled" = true;
        "com.apple.swipescrolldirection" = true;
        "com.apple.trackpad.enableSecondaryClick" = true;
        "com.apple.trackpad.scaling" = 1.0;
        "com.apple.trackpad.trackpadCornerClickBehavior" = 1;
      };
      spaces = { spans-displays = false; };
      screencapture = {
        disable-shadow = true;
        location = "/Users/${username}/screenshots";
        type = "png";
      };
      trackpad = {
        Clicking = false;
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = true;
      };
      universalaccess = {
        closeViewScrollWheelToggle = true;
        reduceTransparency = true;
      };
      CustomUserPreferences = {
        NSGlobalDomain = { WebkitDeveloperExtras = true; };
        "com.apple.Safari" = {
          UniversalSearchEnabled = false;
          SupressSearchSuggestions = false;
          WebKitTabToLinksPreferenceKey = true;
          ShowFullURLInSmartSearchField = true;
          AutoOpenSafeDownloads = false;
          ShowFavoritesBar = true;
          IncludeInternalDebugMenu = true;
          IncludeDevelopMenu = true;
          WebKitDeveloperExtrasEnabledPreferenceKey = true;
          WebContinuousSpellCheckingEnabled = true;
          WebAutomaticSpellingCorrectionEnabled = false;
        };
        "com.apple.AdLib" = { allowApplePersonalizedAdvertising = false; };
        "com.apple.SoftwareUpdate" = { AutomaticCheckEnabled = true; };
        "com.apple.ImageCapture" = { disableHotPlug = true; };
        "com.apple.commerce" = { AutoUpdate = false; };

      };
    };
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };
  };
}
