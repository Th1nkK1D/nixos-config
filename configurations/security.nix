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
    };
    rtkit.enable = true;
  };
}
