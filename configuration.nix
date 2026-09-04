{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
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
  spicedSpotify = inputs.spicetify-nix.lib.mkSpicetify pkgs {
    theme = inputs.spicetify-nix.legacyPackages.${system}.themes.ziro;
    colorScheme = "green-dark";
  };
in
{

  boot = {
    blacklistedKernelModules = [ "nouveau" ];
    # Disable eDP PSR: panel freezes on lock/lid-close wake with 780M (Hawk Point)
    # https://slimbook.com/en/forum/questions-and-answers-from-the-slimbook-user-community-1/question/screen-artifacts-and-glitches-with-amd-radeon-780m-and-debian-kernels-9756
    # 0x10 PSR | 0x400 Panel Replay - both default-on for DCN 3.1.4 (780M).
    # 0x200 PSR-SU and 0x800 IPS are no-ops here: PSR-SU is hard-disabled
    # upstream since 6.18, IPS is DCN 3.5+ only.
    kernelParams = [ "amdgpu.dcdebugmask=0x410" ];
    initrd = {
      luks.devices."luks-6b985d7e-f11a-4a4f-a606-f28b6a565c2e".device =
        "/dev/disk/by-uuid/6b985d7e-f11a-4a4f-a606-f28b6a565c2e";
      systemd.enable = true;
    };
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };

  documentation.nixos.enable = false;

  environment = {
    sessionVariables = {
      JUPYTER_PATH = pkgs.jupyter-kernel.create {
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
      NIXOS_OZONE_WL = 1;
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_QPA_PLATFORMTHEME = "gtk3";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      # Force Niri/Wayland to build the primary session on your Integrated AMD GPU
      # Path must match `ls /dev/dri/by-path/` exactly: 63:00.0 (hex), not 63:0.0
      WLR_DRM_DEVICES = "/dev/dri/by-path/pci-0000:63:00.0-card";
    };
  };

  fonts = {
    enableDefaultPackages = true;
    fontconfig = {
      defaultFonts = {
        serif = [
          "IBM Plex Sans Thai Looped"
          "IBM Plex Serif"
        ];
        sansSerif = [
          "IBM Plex Sans Thai Looped"
          "IBM Plex Sans"
        ];
        monospace = [ "IBM Plex Mono" ];
      };
    };
    fontDir.enable = true;
    packages = with pkgs; [
      cozette
      ibm-plex
      iosevka
      ioskeley-mono.condensed-unhinted
      nerd-fonts."m+"
      noto-fonts
      noto-fonts-color-emoji
      sarabun-font
    ];
  };

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = false;
      settings = {
        General.Experimental = true;
        Policy.AutoEnable = true;
      };
    };
    graphics.enable = true;
    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      open = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      powerManagement = {
        enable = true;
        finegrained = true;
      };
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        # NixOS bus IDs are DECIMAL. lspci prints hex.
        # nvidia at lspci 01:00.0 -> decimal PCI:1:0:0
        # amdgpu at lspci 63:00.0 -> hex 0x63 = decimal 99 -> PCI:99:0:0
        nvidiaBusId = "PCI:1:0:0";
        amdgpuBusId = "PCI:99:0:0";
      };
    };
    nvidia-container-toolkit.enable = true;
  };

  home-manager = {
    backupFileExtension = "backup";
    users.lkz =
      { pkgs, ... }:
      let
        # Blocks until the DMS tray host is actually on the session bus.
        # Exits 0 on timeout so a broken DMS never blocks app startup.
        # Absolute paths on purpose: an unresolved `seq` would expand to an empty
        # loop and exit 0 instantly, silently reintroducing the race.
        waitSniWatcher = pkgs.writeShellScript "wait-sni-watcher" ''
          for ((i = 0; i < 150; i++)); do
            ${pkgs.systemd}/bin/busctl --user status org.kde.StatusNotifierWatcher >/dev/null 2>&1 && exit 0
            ${pkgs.coreutils}/bin/sleep 0.2
          done
          exit 0
        '';
      in
      {
        home = {
          stateVersion = "25.11";
          file = {
            # Apply default dark style to KDE app
            ".config/kdeglobals".text = ''
              [Colors:Window]
              BackgroundNormal=30,30,30
              ForegroundNormal=230,230,230
              [Colors:View]
              BackgroundNormal=35,35,35
              ForegroundNormal=230,230,230
              [Colors:Button]
              BackgroundNormal=45,45,45
              ForegroundNormal=230,230,230
              [General]
              ColorScheme=BreezeDark
            '';
            # Missing autostart app on DMS tray workaround
            # https://github.com/AvengeMedia/DankMaterialShell/issues/1073#issuecomment-4312776159
            # After=dms.service alone is not enough: dms.service is Type=dbus on
            # org.freedesktop.Notifications, so it goes active once the Go daemon
            # claims that name, but org.kde.StatusNotifierWatcher is owned by the
            # quickshell child and appears ~1-2s later. Electron apps that check
            # for the watcher only once (Slack, Mailspring) lose that race and
            # silently never register a tray item.
            ".config/systemd/user/app-@autostart.service.d/override.conf".text = ''
              [Unit]
              After=dms.service

              [Service]
              ExecStartPre=${waitSniWatcher}
            '';
          };
        };
        dconf = {
          enable = true;
          settings = {
            "dev/deedles/Trayscale".tray-icon = true;
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
            };
          };
        };
        gtk = {
          enable = true;
          gtk3.extraConfig.gtk-decoration-layout = "menu:";
          gtk4.theme = {
            name = "Adwaita-dark";
          };
          theme = {
            name = "Adwaita-dark";
          };
          iconTheme = {
            name = "Papirus";
            package = pkgs.papirus-icon-theme.override {
              color = "nordic";
            };
          };
          font = {
            name = "IBM Plex Sans Thai";
            size = 11;
            package = pkgs.ibm-plex;
          };
        };
        qt = {
          enable = true;
          platformTheme.name = "kvantum";
          style.name = "kvantum";
        };
        home = {
          packages = with pkgs; [
            libsForQt5.qtstyleplugin-kvantum
            kdePackages.qtstyleplugin-kvantum
          ];
          pointerCursor = {
            enable = true;
            name = "Posy_Cursor_Black";
            package = pkgs.posy-cursors;
            size = 30;
            gtk.enable = true;
            x11.enable = true;
          };
        };
        nixpkgs = {
          config.allowUnfree = true;
        };
        programs = {
          fish = {
            enable = true;
            interactiveShellInit = ''
              set fish_greeting
            '';
            plugins = [
              {
                name = "colored-man-pages";
                src = pkgs.fishPlugins.colored-man-pages.src;
              }
              {
                name = "done";
                src = pkgs.fishPlugins.done.src;
              }
              {
                name = "fzf-fish";
                src = pkgs.fishPlugins.fzf-fish.src;
              }
              {
                name = "forgit";
                src = pkgs.fishPlugins.forgit.src;
              }
              {
                name = "grc";
                src = pkgs.fishPlugins.grc.src;
              }
              {
                name = "pisces";
                src = pkgs.fishPlugins.pisces.src;
              }
              {
                name = "puffer";
                src = pkgs.fishPlugins.puffer.src;
              }
              {
                name = "sponge";
                src = pkgs.fishPlugins.sponge.src;
              }
            ];
          };
          git = {
            enable = true;
            settings = {
              credential.helper = "${pkgs.git.override { withLibsecret = true; }}/bin/git-credential-libsecret";
              init.defaultBranch = "main";
              pull.rebase = true;
              push.autoSetupRemote = true;
              user = {
                name = "Th1nkK1D";
                email = "witheep@gmail.com";
              };
            };
            signing.format = "openpgp";
          };
          starship.enable = true;
          # vscodium = {
          #   enable = true;
          #   profiles.default.extensions =
          #     with pkgs.vscode-extensions;
          #     [
          #       anthropic.claude-code
          #       biomejs.biome
          #       catppuccin.catppuccin-vsc
          #       catppuccin.catppuccin-vsc-icons
          #       dbaeumer.vscode-eslint
          #       docker.docker
          #       jnoortheen.nix-ide
          #       ms-python.python
          #       oxc.oxc-vscode
          #       prettier.prettier-vscode
          #       streetsidesoftware.code-spell-checker
          #       svelte.svelte-vscode
          #       reditorsupport.r
          #       reditorsupport.r-syntax
          #       vue.volar
          #       wakatime.vscode-wakatime
          #     ]
          #     ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          #       {
          #         name = "flow-icons";
          #         publisher = "thang-nm";
          #         version = "2.0.9";
          #         hash = "sha256-oTkkKVdddCOsMQZ3j1Ouo84zrR/iAltJecjHVf5v0Zg=";
          #       }
          #       {
          #         name = "mayukaithemevsc";
          #         publisher = "gulajavaministudio";
          #         version = "3.3.0";
          #         hash = "sha256-t+T752IOtr7NYXegB1vihWWM7Ioe4a8TicWSnx8mXyI=";
          #       }
          #       {
          #         name = "ultra-instinct-theme";
          #         publisher = "juanlias";
          #         version = "1.0.1";
          #         hash = "sha256-lSLpN2ls/0HoLCF1QDQys0g6CqgDbm1tXkM9mIhvDbg=";
          #       }
          #     ];
          # };
        };
        services = {
          syncthing = {
            enable = true;
            tray.enable = true;
          };
          hyprpolkitagent.enable = true;
          udiskie = {
            enable = true;
            tray = "never";
          };
        };
      };
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "th_TH.UTF-8";
      LC_IDENTIFICATION = "th_TH.UTF-8";
      LC_MEASUREMENT = "th_TH.UTF-8";
      LC_MONETARY = "th_TH.UTF-8";
      LC_NAME = "th_TH.UTF-8";
      LC_NUMERIC = "th_TH.UTF-8";
      LC_PAPER = "th_TH.UTF-8";
      LC_TELEPHONE = "th_TH.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  networking = {
    hostName = "Polygon-NX";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        3000
        4000
        5000
        5173
        8000
        8080
        9300 # Packet
        57621 # Spotify
      ];
      # Packet
      allowedUDPPorts = [
        5353
        5355
      ];
      # KDE Connect
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
    };
  };

  nix = {
    # Make `nix-shell -p`, `nix run nixpkgs#...` and <nixpkgs> resolve to the flake's pinned nixpkgs
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    channel.enable = false;
  };
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    download-attempts = 10;
    stalled-download-timeout = 120;
    connect-timeout = 15;
    substituters = [ "https://cache.nixos-cuda.org" ];
    trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
  };

  nixpkgs = {
    config = {
      allowAliases = false;
      allowBroken = true;
      allowUnfree = true;
      android_sdk.accept_license = true;
      cudaSupport = true;
      permittedInsecurePackages = [
        "electron-40.10.5"
      ];
    };
    overlays = [
      (final: prev: {
        # Not in nixpkgs yet, copied from local nixpkgs dcal branch
        dankcalendar = final.callPackage ./pkgs/dankcalendar/package.nix { };

        # Curtail shells out to `scour` for SVG, but the nixpkgs wrapper only puts
        # the JPEG/PNG/WebP tools on PATH, so SVG fails with "An unknown error has
        # occurred" (shell exit 127 swallowed by Compressor.run's catch-all)
        curtail = prev.curtail.overrideAttrs (old: {
          preFixup = (old.preFixup or "") + ''
            makeWrapperArgs+=("--prefix" "PATH" ":" "${lib.makeBinPath [ prev.scour ]}")
          '';
        });

        # Upstream bug (DMS 1.5.3, still on master): the bar honours showOnLastDisplay
        # but SettingsData's bar-geometry helpers do not, so on a single display the
        # bar renders while the connected frame gets no bar edge and draws no background
        # Drop once fix https://github.com/AvengeMedia/DankMaterialShell/issues/2998
        # Must run in postFixup: the package copies QML straight from $src
        dms-shell = prev.dms-shell.overrideAttrs (old: {
          postFixup = (old.postFixup or "") + ''
            substituteInPlace $out/share/quickshell/dms/Common/SettingsData.qml \
              --replace-fail \
                'if (!prefs.includes("all") && !isScreenInPreferences(screen, prefs))' \
                'if (!prefs.includes("all") && !isScreenInPreferences(screen, prefs) && !(bc.showOnLastDisplay && Quickshell.screens.length === 1))'
          '';
        });
      })
    ];
  };

  programs = {
    dconf.enable = true;
    dsearch.enable = true;
    dms-shell = {
      enable = true;
      enableDynamicTheming = false;
      enableCalendarEvents = false;
      systemd.enable = true;
    };
    firejail = {
      enable = true;
      wrappedBinaries = {
        # Bypass Tailscale
        # https://github.com/tailscale/tailscale/issues/10396#issuecomment-3871203280
        vesktop = {
          executable = "${pkgs.vesktop}/bin/vesktop";
          extraArgs = [
            "--net=wlp2s0"
            "--noprofile"
          ];
        };
      };
    };
    gnome-disks.enable = true;
    kdeconnect.enable = true;
    nh = {
      enable = true;
      flake = "/home/lkz/Repositories/nixos-config";
    };
    niri.enable = true;
    nix-ld = {
      enable = true;
      # stdenv.cc.cc.lib + zlib: pip-installed torch/numpy wheels need a 64-bit
      # libstdc++.so.6 and libz.so.1. nvidia package: libcuda.so.1 for the cuda wheels.
      libraries = pkgs.steam-run.args.multiPkgs pkgs ++ [
        pkgs.stdenv.cc.cc.lib
        pkgs.zlib
        config.hardware.nvidia.package
      ];
    };
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
    };
  };

  security = {
    pam.services = {
      login.enableGnomeKeyring = true;
      # Unlock gnome keyring after greetd login https://github.com/NixOS/nixpkgs/pull/481342
      greetd.text = ''
        auth      substack      login
        account   include       login
        password  substack      login
        session   optional      ${pkgs.pam_fde_boot_pw}/lib/security/pam_fde_boot_pw.so inject_for=gkr
        session   include       login
      '';
    };
    polkit = {
      enable = true;
      enablePkexecWrapper = true;
    };
    rtkit.enable = true;
  };

  services = {
    automatic-timezoned.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    caddy = {
      enable = true;
      virtualHosts = {
        "pi.localhost".extraConfig = ''
          reverse_proxy http://localhost:30141
        '';
        "syncthing.localhost".extraConfig = ''
          reverse_proxy http://localhost:8384
        '';
        "wakapi.localhost".extraConfig = ''
          reverse_proxy http://localhost:3333
        '';
      };
    };
    displayManager = {
      autoLogin = {
        enable = true;
        user = "lkz";
      };
      defaultSession = "niri";
      dms-greeter = {
        enable = true;
        compositor.name = "niri";
        configHome = "/home/lkz";
      };
    };
    geoclue2.enable = true;
    gnome.gnome-keyring.enable = true;
    gvfs.enable = true;
    keybase.enable = true;
    kbfs.enable = true;
    languagetool = {
      enable = true;
      allowOrigin = "*";
    };
    ollama.enable = true;
    openssh = {
      enable = true;
      openFirewall = false;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        AllowUsers = [ "lkz" ];
      };
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    pulseaudio.enable = false;
    printing.enable = true;
    tailscale = {
      enable = true;
      openFirewall = true;
    };
    udev.packages = [ pkgs.libmtp.out ];
    udisks2.enable = true;
    upower.enable = true;
    wakapi = {
      enable = true;
      environmentFiles = [
        "/home/lkz/.wakapi.env"
      ];
      settings = {
        app.leaderboard_enabled = false;
        mail.enabled = false;
        server.port = 3333;
      };
    };
    xserver.videoDrivers = [
      "amdgpu"
      "nvidia"
    ];
  };

  system.stateVersion = "25.11";

  systemd.user = {
    # KBFS workaround https://github.com/NixOS/nixpkgs/issues/278277
    services.kbfs.serviceConfig.PrivateTmp = lib.mkForce false;
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
      packages = with pkgs; [
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
        claude-code
        cloudflared
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
        herdr
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
        moon
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
        (pi-coding-agent.overrideAttrs (
          finalAttrs: previousAttrs: {
            # Save npm extension in pi agent folder instead of global
            postFixup = ''
              wrapProgram $out/bin/pi \
                --set NPM_CONFIG_PREFIX "/home/lkz/.pi/agent/.npm/" \
            '';
          }
        ))
        pnpm
        (python3.withPackages (
          ps: with ps; [
            aiohttp-oauthlib
            ipykernel
            matplotlib
            notebook
            numpy
            pandas
          ]
        ))
        ripgrep
        rtk
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
        inputs.zen-browser.packages.${system}.default
        zoom-us
        zotero
      ];
    };
  };

  virtualisation = {
    docker.enable = true;
    waydroid = {
      enable = true;
      package = pkgs.waydroid-nftables;
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    config.common.default = [
      "gnome"
      "gtk"
    ];
  };
}
