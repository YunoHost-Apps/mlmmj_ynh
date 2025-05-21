People that want to subscribe to the list can do so by sending an empty email to `__LOCAL_PART__+subscribe@__DOMAIN_PART__`.

This list can be configured via the YunoHost configuration panel.

However, not all settings are available in this interface. It is possible to tweak configurations in `__INSTALL_DIR__/list` and according to the documentation available [here](https://mlmmj.org/TUNABLES.html)

You can also run the various `mlmmj` commands from the CLI, such as

- **List subscribers**: `sudo -u __APP__ -- __INSTALL_DIR__/app/bin/mlmmj-list -L __INSTALL_DIR__/list`
- **Add a subscriber**: `sudo -u __APP__ -- __INSTALL_DIR__/app/bin/mlmmj-sub -L __INSTALL_DIR__/list -a sasha@domain.tld`
- **Remove a subscriber**: `sudo -u __APP__ -- __INSTALL_DIR__/app/bin/mlmmj-unsub -L __INSTALL_DIR__/list -a sasha@domain.tld`

More info about those commands can be obtained by adding the `-h` flag.
