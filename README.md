[English translation](https://github.com/PhilippeLeroux/plescripts/wiki/english)

### Objectifs :
Simuler une infrastructure de VMs pour créer des serveurs de base de données
dans les conditions proches de ce que l'on peut trouver en entreprise.

Le serveur central se nomme K2 et a en charge :
- la gestion du DNS via bind.
- la gestion du SAN via target (qui est présent sur les distributions de type Redhat),
les disques sont exportés sur le réseau via le protocole iSCSI.
- la GATEWAY qui centralise l'accès à internet des serveurs, par défaut aucun
serveur de base de données ne peut accéder à internet. Le firewall et SELinux sont
activés sur ce serveur.
- la gestion du dépôt rpm : synchronisation des dépôts Oracle sur ce serveur.
- de synchroniser l'horloge des serveurs de base de données.

Type de serveurs de base de données pouvant être créé :
- Base de données sur un serveur standalone.
- Base de données en RAC (pas de RAC étendue, uniquement MAA)
- Mise en dataguard de 2 serveurs standalone.

Versions logiciels :
- Oracle Linux 7 est utilisé pour les serveurs base de données et le serveur d'infrastructure.
- Oracle 12cR1 base SINGLE et RAC.
- Oracle 12cR2 base SINGLE EE et RAC SE2.

La création des serveurs de base de données est 100% automatisée, il n'y a pas
besoins de connaissances particulières sur la gestion d'un DNS ou d'un SAN.

La version 12cR1 d'oracle est particulièrement consommatrice en ressources mémoire
et CPU, un certain nombre de hacks sont mis en œuvre pour pouvoir installer
une base en SINGLE ou RAC sur un PC possédant au moins 8 Gb de RAM et un processeur
équivalent à un i5 4ème génération.

Si vous avez une configuration inférieure n'y pensez même pas.

--------------------------------------------------------------------------------

### Télécharger les logiciels suivants :

* VirtualBox : `zypper install [...]` ou `yum install [...]` ou `apt-get install [...]` en fonction de la distribution.

* Oracle Linux 7.2 : uniquement la première image ISO [V100082-01.iso](https://edelivery.oracle.com/osdc/faces/SearchSoftware) est nécessaire.

  Rechercher Oracle Linux 7.2, puis décocher les autres ISO.

  L'image de l'ISO Oracle Linux 7.3 ne fonctionne pas (V834394-01.iso), java plante lors de l'installation. En partant d'une 7.2
  je mets à jour sur une 7.3 mais en conservant le noyau linux 3.8.

* Oracle database & Grid Infrastructure : [12cR1](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/database12c-linux-download-2240591.html)
ou [12cR2](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/oracle12c-linux-12201-3608234.html)

* Cloner le dépôt `plescripts` dans le répertoire $HOME (instructions fournies plus loin).

--------------------------------------------------------------------------------

### Configuration du poste exécutant VirtualBox

Avant de créer les VMs il est nécessaire de configurer le poste exécutant VirualBox.

Suivre les [instructions ici](https://github.com/PhilippeLeroux/plescripts/wiki/Configuration-du-virtual-host)

--------------------------------------------------------------------------------

### Création des VMs `orclmaster` et `K2`.
2 VMs sont nécessaires pour commencer : [instructions](https://github.com/PhilippeLeroux/plescripts/wiki/Création-des-VMs-orclmaster-et-K2)
 - `orclmaster` qui est la VM clonée dès que l'on a besoin d'un nouveau serveur Oracle, pas besoins de réinstaller OL7.
 - `K2` qui est le serveur d'infrastructure (DNS, SAN, Gateway, NTP server, ...)

--------------------------------------------------------------------------------

### Création des serveurs de base de données Oracle.

* Création serveurs : [instructions](https://github.com/PhilippeLeroux/plescripts/wiki/Create-servers)

* Installation du Grid Infra & d'Oracle : [instructions](https://github.com/PhilippeLeroux/plescripts/wiki/Installation-:-Grid-infra-&-Oracle)

* Création d'une base : [instructions](https://github.com/PhilippeLeroux/plescripts/wiki/Cr%C3%A9ation-d'une-base-de-donn%C3%A9e)

* Mise en dataguard de 2 serveurs standalones : [instructions](https://github.com/PhilippeLeroux/plescripts/wiki/Create-dataguard)

--------------------------------------------------------------------------------

### Gestion du tnsnames.ora sur le virtual-host et adresse de scan

Comment utiliser l'adresse de scan et gestion du tnsnames.ora décrit [ici](https://github.com/PhilippeLeroux/plescripts/wiki/Gestion-du-tnsname.ora-depuis-le-virtual-host)

--------------------------------------------------------------------------------

##	Temps de références
### Création d'un dataguard (Base single)

script				|	id					|	temps
--------------------|:---------------------:|-------------:
clone_master.sh		|	venus				|	   3mn17s
install_grid.sh		|	venus				|	   7mn10s
install_oracle.sh	|	venus				|	   3mn46s
create_db.sh		|	venus				|	 19mn58s
clone_master.sh		|	saturne				|	   3mn40s
install_grid.sh		|	saturne				|	   7mn34s
install_oracle.sh	|	saturne				|	   4mn14s
create_dataguard.sh	|	VENUS with SATURNE	|	  11mn12s

###	Création d'un RAC

script				|	id					|	temps
--------------------|:---------------------:|-------------:
clone_master.sh		|	daisy				|	4mn15s
clone_master.sh		|	daisy				|	3mn37s
install_grid.sh		|	daisy				|	31mn46s
install_oracle.sh	|	daisy				|	13mn13s
create_db.sh		|	daisy				|	42mn29s

--------------------------------------------------------------------------------

![Screenshot](https://github.com/PhilippeLeroux/plescripts/wiki/virtualbox_manager.png)

--------------------------------------------------------------------------------

### LICENCE

Copyright © 2016,2017 Philippe Leroux <philippe.lrx@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
