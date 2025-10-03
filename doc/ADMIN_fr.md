Les personnes souhaitant s'abonner à la liste peuvent le faire en envoyant un mail vide à `__LOCAL_PART__+subscribe@__DOMAIN_PART__`.

La liste peut être configurée via le panneau de configuration de l'app YunoHost. 

Cependant, tous les paramètres ne sont pas disponibles depuis cette interface. Il est possible de modifier la configuration dans `__INSTALL_DIR__/list` d'après la documentation disponible [ici](https://mlmmj.org/TUNABLES.html).

Il est également possible de gérer la liste depuis la ligne de commande de `mlmmj`, comme par exemple:

- **Lister les abonné·e·s**: `sudo -u __APP__ -- __INSTALL_DIR__/app/bin/mlmmj-list -L __INSTALL_DIR__/list`
- **Ajouter un abonnement**: `sudo -u __APP__ -- __INSTALL_DIR__/app/bin/mlmmj-sub -L __INSTALL_DIR__/list -a sasha@domain.tld`
- **Supprimer un abonnement**: `sudo -u __APP__ -- __INSTALL_DIR__/app/bin/mlmmj-unsub -L __INSTALL_DIR__/list -a sasha@domain.tld`

Plus d'informations sur ces commandes peuvent être obtenuers en ajoutant l'option `-h`.
