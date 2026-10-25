{ pkgs, ... }:
{
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
      # The DMS Lenovo battery plugin runs pkexec from a popout that closes (and
      # kills pkexec) when the polkit dialog takes focus, so skip the prompt for
      # exactly its two commands. polkit reports the resolved program, so pin it to
      # a bash in the (root-owned) store instead of a user-writable `sh`.
      extraConfig = ''
        polkit.addRule(function (action, subject) {
          if (
            action.id == "org.freedesktop.policykit.exec" &&
            subject.isInGroup("wheel") &&
            /^\/nix\/store\/[a-z0-9]{32}-bash-interactive-[^\/]+\/bin\/bash$/.test(
              action.lookup("program")
            ) &&
            /^\S+ -c echo [01] > \/sys\/bus\/platform\/devices\/VPC2004:00\/conservation_mode$/.test(
              action.lookup("command_line")
            )
          ) {
            return polkit.Result.YES;
          }
        });
      '';
    };
    rtkit.enable = true;
  };
}
