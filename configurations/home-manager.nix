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
  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    users.lkz = {
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
          # Helium ships no Widevine CDM and its bundle dir is read-only, so DRM
          # sites (Netflix) fail. Its component updater reads this hint file to
          # locate a sideloaded CDM.
          # https://github.com/imputnet/helium/issues/116
          ".config/net.imput.helium/WidevineCdm/latest-component-updated-widevine-cdm".text =
            builtins.toJSON {
              Path = "${pkgs.widevine-cdm}/share/google/chrome/WidevineCdm";
            };
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
      programs = {
        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
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
}
