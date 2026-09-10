{ pkgs, inputs, ... }:
let
  rPackagesList = with pkgs.rPackages; [
    ggbeeswarm
    jsonlite
    languageserver
    RPostgres
    tidyverse
    unglue
  ];
  rWithPackages = pkgs.rWrapper.override { packages = rPackagesList; };
  arkWithPackages = pkgs.ark.override { R = rWithPackages; };
  system = pkgs.stdenv.hostPlatform.system;
  llmAgents = inputs.llm-agents.packages.${system};
  helium = inputs.helium.packages.${system}.default.override {
    # Upstream passes this flag through a shell-expansion idiom, but
    # wrapGAppsHook3 builds a makeBinaryWrapper that never expands it, so the
    # browser silently falls back to XWayland and never sees the output scale.
    flags = [ "--ozone-platform-hint=auto" ];
  };
  spicedSpotify = inputs.spicetify-nix.lib.mkSpicetify pkgs {
    theme = inputs.spicetify-nix.legacyPackages.${system}.themes.ziro;
    colorScheme = "green-dark";
  };
  zenBrowser = inputs.zen-browser.packages.${system}.default;
in
{
  environment.sessionVariables.JUPYTER_PATH = pkgs.jupyter-kernel.create {
    definitions = {
      ark = (pkgs.r-ark-kernel.override { ark = arkWithPackages; }).definition;
      deno = {
        displayName = "deno";
        argv = [
          "${pkgs.deno}/bin/deno"
          "jupyter"
          "--kernel"
          "--conn"
          "{connection_file}"
        ];
        language = "typescript";
        logo32 = null;
        logo64 = null;
      };
    };
  };

  users = {
    users.lkz = {
      isNormalUser = true;
      description = "Withee Poositasai";
      extraGroups = [
        "adbusers"
        "docker"
        "input"
        "kvm"
        "networkmanager"
        "render"
        "wheel"
        "video"
      ];
      packages =
        with pkgs;
        [
          act
          android-studio
          android-tools
          arkWithPackages
          authenticator
          bat
          beekeeper-studio
          beeper
          blanket
          bruno
          bun
          caddy
          chezmoi
          chromium
          cloudflared
          codiff
          curtail
          dankcalendar
          decibels
          deno
          dig
          dive
          fastfetch
          fd
          ffmpeg
          ffmpegthumbnailer
          figma-agent
          fzf
          gcc
          gh
          ghostty
          gimp
          gitleaks
          gnome-font-viewer
          gnome-network-displays
          gnome-text-editor
          gnome-themes-extra
          gnumake
          grim
          grc
          gthumb
          helium
          httpie
          hunspell
          hunspellDicts.en_US
          hunspellDicts.th_TH
          image_optim
          imagemagick
          inetutils
          jdk
          jq
          kamal
          kdePackages.qtdeclarative
          keybase-gui
          kooha
          krita
          libinput
          libmtp
          libnotify
          libreoffice
          libsecret
          libwebp
          lumen
          (mailspring.overrideAttrs (
            finalAttrs: previousAttrs: {
              # No full desktop environment: keyring backend can't be auto-detected
              # https://community.getmailspring.com/t/password-management-error/199
              postFixup = (previousAttrs.postFixup or "") + ''
                wrapProgram $out/bin/mailspring \
                  --add-flags '--password-store="gnome-libsecret"'
              '';
            }
          ))
          micro
          nautilus
          nginx-language-server
          nil
          nixd
          nixfmt
          nodejs_24
          nvidia-container-toolkit
          obsidian
          ouch
          packet
          papers
          parallel
          pdfarranger
          pnpm
          (python3.withPackages (
            ps: with ps; [
              ipykernel
              matplotlib
              notebook
              numpy
              pandas
            ]
          ))
          ripgrep
          rWithPackages
          satty
          (scrcpy.overrideAttrs (
            finalAttrs: previousAttrs: {
              # Remove unused console desktop file and fix render black screen issue
              # https://github.com/Genymobile/scrcpy/issues/3229
              postInstall = previousAttrs.postInstall + ''
                rm $out/share/applications/scrcpy-console.desktop
                sed -i 's/\\\\\$SHELL -i -c scrcpy/scrcpy --render-driver=opengles2/g' $out/share/applications/scrcpy.desktop
              '';
            }
          ))
          share-preview
          showtime
          skills
          slack
          spicedSpotify
          uv
          # Patch Vesktop desktop entry for firejail wrap
          (pkgs.makeDesktopItem {
            name = "vesktop";
            desktopName = "Vesktop";
            exec = "vesktop %U";
            icon = "${pkgs.vesktop}/share/icons/hicolor/256x256/apps/vesktop.png";
            startupWMClass = "Vesktop";
            genericName = "Internet Messenger";
            categories = [
              "Network"
              "InstantMessaging"
              "Chat"
            ];
            mimeTypes = [ "x-scheme-handler/discord" ];
          })
          video-trimmer
          wakatime-cli
          waydroid-helper
          wget
          wl-clipboard
          wl-mirror
          xwayland-satellite
          zed-editor
          zenBrowser
          zoom-us
          zotero
        ]
        ++ (with llmAgents; [
          agent-browser
          ax
          claude-code
          claude-desktop
          herdr
          (
            (kandev-desktop.override {
              kandevRuntime = (kandev.override { claudeSupport = true; }).overrideAttrs (previousAttrs: {
                # Editor discovery looks for `zed`, nixpkgs only ships `zeditor`
                postPatch = previousAttrs.postPatch + ''
                  substituteInPlace apps/backend/internal/editors/discovery/editors.json \
                    --replace-fail '"command": "zed",' '"command": "zeditor",'
                '';
              });
            }).overrideAttrs
            (previousAttrs: {
              # Hide menu bar and title bar by default, no upstream toggle
              postPatch = previousAttrs.postPatch + ''
                substituteInPlace apps/desktop/src-tauri/src/main.rs \
                  --replace-fail '.menu(build_menu)' ""
                substituteInPlace apps/desktop/src-tauri/tauri.conf.json \
                  --replace-fail '"resizable": true,' '"resizable": true, "decorations": false,'
              '';
            })
          )
          mindwalk
          # (pi.overrideAttrs (
          #   finalAttrs: previousAttrs: {
          #     # Save npm extension in pi agent folder instead of global
          #     postFixup = ''
          #       wrapProgram $out/bin/pi \
          #         --set NPM_CONFIG_PREFIX "/home/lkz/.pi/agent/.npm/" \
          #     '';
          #   }
          # ))
          rtk
        ]);
    };
  };
}
