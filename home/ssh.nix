{ config, ... }:

# ssh client config, and the keys that follow this user to other machines.
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # A login as this user on another machine forwards the local gpg-agent
    # to the remote's agent socket, so a `git commit` there signs with the
    # key behind this machine's agent. The remote end needs sshd's
    # StreamLocalBindUnlink (nixos-core sets it) and the public key below.
    # %i is the local uid; both ends have the same one.
    settings."Match user ${config.home.username}".RemoteForward = {
      bind.address = "/run/user/%i/gnupg/S.gpg-agent";
      host.address = "/run/user/%i/gnupg/S.gpg-agent.extra";
    };
  };

  # The public half of the signing key, so gpg here can sign through a
  # forwarded agent.
  programs.gpg.publicKeys = [
    {
      source = ../keys/nullcopy.asc;
      trust = "ultimate";
    }
  ];

  # Keys allowed to log in as this user.
  home.file.".ssh/authorized_keys".text = ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINnyo4KOBG3TTGMz7L8jpd8fZbJNaN5XgbVVaMDUlQb0
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB66B70xeHQYxNZK3tgzhOscPWIksqO1FooTpWFjfcrt
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMOtbgZq3tOseRjRA+r27JVwvD1wtQvEfpnNzLrnfDtR
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIORZI+M1bi+tmdNb0mytP9Ng+ba6Wlk2PIhLalhUy/zR
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILvhIXIJwQWjbrgo0/qmHAB/hgueV/648P6nNv4naBl7
  '';
}
