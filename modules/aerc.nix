# aerc (https://aerc-mail.org), a terminal mail client. Accounts are a
# per-machine choice, made outside this repo: aerc's first run offers a
# wizard that writes ~/.config/aerc/accounts.conf, which holds
# credentials and must stay 0600, so home-manager does not generate it
# and nothing from it lands in the store.
{
  programs.aerc.enable = true;
}
