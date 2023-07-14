[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-24ddc0f5d75046c5622901739e7c5dd533143b0c8e959d652212380cedb1ea36.svg)](https://classroom.github.com/a/QY_7UTQb)
[![Open in Visual Studio Code](https://classroom.github.com/assets/open-in-vscode-718a45dd9cf7e7f842a935f5ebbe5719a5e09af4491e668f4dbf3b35d5cca122.svg)](https://classroom.github.com/online_ide?assignment_repo_id=10968924&assignment_repo_type=AssignmentRepo)
# HEIGVD - Sécurité des Réseaux - 2023

# Laboratoire n°5 - VPN

Ce travail est à réaliser en équipes de deux personnes.
Choisissez une personne avec qui vous n'avez pas encore travaillé pour un labo du cours SRX.
C'est le **troisième travail noté** du cours SRX.

Répondez aux questions en modifiant directement votre clone du README.md.

Le rendu consiste simplement à compléter toutes les parties marquées avec la mention "LIVRABLE".
Le rendu doit se faire par un `git commit` sur la branche `main`.

## Table de matières

- [Introduction](#introduction)
  - [Échéance](#échéance)
  - [Évaluation](#évaluation)
  - [Introduction](#introduction)
  - [Configuration](#configuration)
  - [Test](#test)
- [OpenVPN](#openvpn)
  - [Mise en place du CA](#mise-en-place-du-ca)
  - [Réseau à réseau](#réseau-à-réseau)
  - [Remote à réseau](#remote-à-réseau)
  - [Desktop à réseau](#desktop-à-réseau)
- [WireGuard](#wireguard)
  - [Création des clés](#création-des-clés)
  - [Réseau à réseau](#réseau-à-réseau-1)
  - [Remote à réseau](#remote-à-réseau-1)
  - [Bonus - Desktop à réseau](#bonus--desktop-à-réseau)
- [IPSec](#ipsec)
  - [Mise en place du CA](#mise-en-place-du-ca-1)
  - [Réseau à réseau](#réseau-à-réseau-2)
  - [Remote à réseau](#remote-à-réseau-2)
- [Comparaison](#comparaison)
  - [Sécurité](#sécurité)
  - [Facilité d'utilisation](#facilité-dutilisation)
  - [Performances](#performance)
- [Points spécifiques](#points-spécifiques)
  - [OpenVPN](#openvpn-1)
  - [WireGuard](#wireguard-1)
  - [IPSec](#ipsec-1)

# Introduction

## Échéance

Ce travail devra être rendu au plus tard, **le 14 mai 2023 à 23h59.**

## Évaluation

Vous trouverez le nombre de points pour chaque question derrière le numéro de la question:

**Question 1 (2):**

Désigne la 1ère question, qui donne 2 points.
La note finale est calculée linéairement entre 1 et 6 sur le nombre de points totaux.
Les pénalités suivantes sont appliquées:

- 1/2 note pour chaque tranche de 24h de retard

À la fin du document, vous trouverez une liste de points supplémentaires qui se feront sur la base de votre
code rendu.

## Introduction

Ce labo va vous présenter trois types de VPNs: OpenVPN, WireGuard et IPSec.
On va voir au cours une partie de la configuration, pour le reste, vous devez faire
vos propres recherches sur internet.
La quatrième partie vous demande de faire une comparaison des différents VPNs vu dans ce labo.

Les trois VPNs vont être fait avec deux connexions différentes:

- une pour connecter deux réseaux distants
- une pour connecter un ordinateur pour faire partie du réseau `main`
  Pour OpenVPN, vous devez aussi connecter votre ordinateur hôte au réseau docker.

Il y a trois réseaux:

- 10.0.0.0/24 - fait office d'internet - toutes les adresses "publiques" seront dans cette plage.
  L'ordinateur distant a l'adresse publique 10.0.0.4
- 10.0.1.0/24 - le réseau `main` avec le serveur VPN, adresse publique de 10.0.0.2
- 10.0.2.0/24 - le réseau `far` qui sera à connecter au réseau `main`, adresse publique de 10.0.0.3

Pour les deux réseaux, on aura chaque fois trois machines:

- serveur: avec le host-IP = 2 et l'adresse publique correspondante
- client1: avec le host-IP = 10
- client2: avec le host-IP = 11
  Les deux serveurs vont faire un routing des paquets avec un simple NAT.
  Docker ajoute une adresse avec le host-IP de 1 qui est utilisée pour router le trafic vers l'internet.

Une fois la connexion VPN établie, vous devrez vous assurer que:

- toutes les machines connectées peuvent échanger des paquets entre eux
- tous les paquets entre les réseaux et l'ordinateur distant doivent passer par le VPN.
  Vous pouvez utiliser le script décrit dans [Test](#test) pour cela.

## Configuration

Vu que vous devez faire trois configurations qui se basent sur les mêmes images docker,
j'ai ajouté une configuration automatique.
Ceci vous permet de travailler sur les trois configurations, OpenVPN, WireGuard, et IPSec,
et de pouvoir aller de l'une à l'autre.

D'abord il y a le fichier [routing.sh](root/routing.sh) qui fait le routage pour les serveurs
et les clients.
Ce script est copié dans l'image docker et il est exécuté au démarrage.
Ainsi les clients vont envoyer tous leurs paquets vers le serveur et le serveur va faire du
NAT avant d'envoyer les paquets vers l'internet/intranet.
Ceci est nécessaire parce que par défaut docker ajoute une passerelle avec le host-id `1`,
et sans ce changement dans le routage, connecter les serveurs en VPN ne ferait rien pour
les clients.

Après il y a un répertoire pour chaque serveur et pour la machine distante qui se trouve dans les
répertoires suivants.
Chaque répertoire est monté en tant que `/root` dans la machine correspondante.

- [main](root/main) pour le serveur `MainS`
- [far](root/far) pour le serveur `FarS`
- [remote](root/remote) pour l'ordinateur `Remote`
  Le répertoire [host](root/host) sert à ajouter la configuration depuis votre machine hôte pour
  se connecter au VPN.

Ceci vous permet deux choses:

- éditer les fichiers dans ces répertoires directement sur votre machine hôte et les utiliser dans les machines docker
- lancer le `docker-compose` en indiquant quel fichier il faut exécuter après le démarrage:

```
RUN=openvpn.sh docker-compose up
```

Ceci va exécuter le fichier `openvpn.sh` sur les deux serveurs et la machine distante.
Tous les fichiers supplémentaires sont à mettre dans un sous-répertoire.

Ça sera à vous d'ajouter les fichiers nécessaires pour les autres VPNs.
Appelez-les `wireguard.sh` pour le wireguard, et `ipsec.sh` pour l'IPSec.

## Test

Une fois que vous avez terminé avec une implémentation de VPN, vous pouvez la tester avec
la commande suivante:

```
./test/runit.sh openvpn
```

Vous pouvez remplacer `openvpn` avec `wireguard` et `ipsec`.

Chaque fois que vous faites un `git push` sur github, il y a un `git workflow` qui vérifie si
les VPNs se font de façon juste.

# OpenVPN

[OpenVPN](https://openvpn.net/community-resources/how-to) est un VPN basé sur des connexions
SSL/TLS.
Il n'est pas compatible avec les autres VPNs comme WireGuard ou IPSec.
Des implémentations pour Linux, Windows, et Mac existent.
La configuration de base, et celle qu'on retient ici, est basé sur un système de certificats.
Le serveur et les clients se font mutuellement confiance si le certificat de la station distante
est signé par le certificat racine, vérifié avec la clé publique qui est disponible sur chaque machine.

---

**Question 1 (1): route par défaut**

Quelle est l'avantage d'utiliser le routage par défaut pour le OpenVPN?
A quoi est-ce qu'il faut faire attention si on utilise cette méthode sur un client?

---

**Réponse**

L'utilisation du routage par défaut dans OpenVPN permet de simplifier la configuration du client VPN, car il n'est pas nécessaire de spécifier manuellement toutes les routes réseau pour chaque serveur ou sous-réseau auquel le client doit se connecter. Cela permet également d'assurer une connectivité complète pour toutes les destinations réseau sans avoir à ajouter de routes supplémentaires.

Cependant, lors de l'utilisation du routage par défaut, il est important de prendre en compte les conséquences potentielles sur la sécurité et les performances du réseau. Si un client VPN est compromis, l'accès réseau complet peut être accordé à l'attaquant. De plus, le trafic réseau de l'ensemble du client VPN est acheminé via le serveur VPN, ce qui peut entraîner des problèmes de latence et de congestion du réseau.

---

## Mise en place du CA

---

**Question 2 (2) : Avantages du CA**

Décrivez deux avantages d'un système basé sur les Certificate Authority dans le cadre de
l'authentification des machines.

---

**Réponse**

- Investissement minimum de la part des utilisateurs. Une fois que l'autorité de certification est installée, les utilisateurs n'ont pas besoin de faire énormément de manipulations.
- Plus facile de déployer pour une grande infrastructure (meilleure scalabilité).

---

**Question 3 (2) : commandes utilisées**

Quelles commandes avez-vous utilisées pour mettre en place le CA et les clés des clients?
Décrivez les commandes et les arguments et à quoi ils servent.

---

**Réponse**

Sur le server MainS:
```bash
# EASY-RSA
make-cadir /root/openvpn/ca && cd /root/openvpn/ca # Création du dossier ca, ainsi que de l'arborescence  

export EASYRSA_BATCH=1  # Permet de faire la configuration en mode interactif
export EASYRSA_REQ_CN=main_server.local # Configure le Common Name du CA

./easyrsa init-pki  # Création de l'arborescence pour stocker les clés, certificats, etc... (Structure de la PKI)
./easyrsa build-ca nopass # Création du certificat CA et n'utilisant pas de mot de passe (nopass)
./easyrsa gen-dh # Génère les paramètres de DH

# Pour les commandes ci-dessous, le premier paramètre représente le nom du fichier (far.key/far.crt) et le second précise que l'on ne met pas de mot de passe (nopass)
./easyrsa build-server-full server nopass # Création la clé et certificat du serveur 
./easyrsa build-client-full far nopass # Création de la clé et certificat pour serveur far
./easyrsa build-client-full remote nopass # Création de la clé et certificat pour serveur remote
./easyrsa build-client-full host nopass # Création de la clé et certificat pour pc host

openvpn --genkey tls-auth ta.key # Génération de la clé pour le SSL
```

**Question bonus 4 (2) : création de clés sécurisée**

Quel est une erreur courante dans la création de ces clés comme décrite dans le HOWTO d'OpenVPN?
Comment est-ce qu'on peut éviter cette erreur?

---

**Réponse**

L'erreur courante est de générer toutes les clés sur le serveur, car cela implique d'ensuite pouvoir les transférer aux clients. Sauf qu'un transfert de clés demande d'avoir au préalable un canal qui est déjà sécurisé pour éviter d'avoir des clés qui sont transportées en clair via le réseau.
Si un canal déjà sécurisé existe, on connait des méthodes comme SCP ou SFTP pour du transport sécurisé. 

Si ce n'est pas le cas, ce que dit OpenVPN dans son HOWTO c'est qu'il est possible de mettre en place la PKI sans ce canal justement.
Pour le faire correctement, c'est au client de générer sa clé privée localement et ensuite de soumettre une Certificate Signing Request (CSR) au serveur signant les certificats pour avoir son certificat signé.

---

## Réseau à réseau

Pour commencer, vous allez connecter les réseaux `main` et `far`.
Utilisez seulement le fichier de configuration OpenVPN, sans ajouter des `ip route`
ou des règles `nftable`.
Chaque machine de chaque réseau doit être capable de contacter chaque autre machine de chaque
réseau avec un `ping`.

---

**Question 5 (2) : routage avec OpenVPN**

Décrivez les lignes de votre fichier de configuration qui font fonctionner le routage entre
les deux réseaux.
Pour chaque ligne, expliquez ce que cette ligne fait.

---

**Réponse**

Il faut faire une configuration en utilisant les CCD (Client-config-dir). 
On doit donc dans un premier temps ajouter les deux lignes suivantes dans la configuration du serveur (`server.conf`).

```bash
push "route 10.0.1.0 255.255.255.0" # Push une route sur les clients vers le réseau 10.0.1.0/24
push "route 10.0.2.0 255.255.255.0" # Push une route sur les clients vers le réseau 10.0.2.0/24
client-config-dir /root/openvpn/ccd # Défini le dossier pour les fichiers de CCD
route 10.0.2.0 255.255.255.0        # Ajoute une route à la configuration du serveur vers le réseau 10.0.2.0/24
```

Ensuite dans le dossier `ccd`, on met la configuration par rapport à ce client et son sous-réseau. 
Elle permet de faire le lien avec ce qui est dans la configuration du serveur.

```bash
iroute 10.0.2.0 255.255.255.0       # Routage de l'extérieur de FAR à l'intérieur du réseau FAR
```

---

## Remote à réseau

Maintenant, vous allez faire une connexion avec la station distante `Remote` et la machine `MainS`.
Vérifiez que la machine `Remote` peut atteindre toutes les machines dans les deux réseaux `main` et `far`.
Comme pour l'exercice précédent, n'utilisez pas des `ip route` supplémentaires ou des commandes `nftable`.

Une fois que tout est bien mise en place, faites de sorte que la configuration est chargée automatiquement
à travers des scripts `openvpn.sh` pour chaque hôte.
À la fin, la commande suivante doit retourner avec succès:

```bash
./test/runit.sh openvpn
```

## Desktop à réseau

Utiliser l'application [OpenVPN Connect Client](https://openvpn.net/vpn-client/) sur votre hôte pour vous
connecter au réseau docker.
Mettez la configuration nécessaire quelque part dans le répertoire `root/host`.
L'assistant va tester si cette configuration marche, en faisant un `ping` sur toutes les machines du réseau docker.

---

**Question 6 (1) : integration des clés dans le fichier de configuration**

Comment avez-vous fait pour faire un seul fichier de configuration pour OpenVPN?

---

**Réponse**

Il se trouve, qu'il est possible d'inclure directement la clé et les certificats dans la configuration du client. 
Le but consiste donc à utiliser les balises ci-dessous et de mettre le contenu des fichiers correspondant entre ces balises :

- `<ca></ca>` : Permet d'intégrer le contenu du fichier ca.crt.
- `<cert></cert>` : Permet d'intégrer le contenu du fichier host.cert
- `<key></key>` : Permet d'intégrer le contenu de host.key.
- `<tls-auth></tls-auth>` : Permet d'intégrer le contenu de ta.key

**NB :** Il faut aussi préciser la direction pour la clé utilisé pour le TLS. Il suffit de rajouter `key-direction 1`.

Ainsi, on se retrouve avec un seul fichier et les certificats et clés sont directement intégrés.

---

# WireGuard

Pour [WireGuard](https://www.wireguard.com/quickstart/) la partie `Desktop à réseau` est une partie
bonus qu'il ne faut pas faire absolument.
Vous allez configurer WireGuard avec des clés statiques, tout en décrivant comment éviter que les
clés privées se trouvent sur plus d'une seule machine.
Utilisez le port `51820` pour les connexions, car c'est celui qui est aussi ouvert avec le `docker-compose.yaml`.

## Création des clés

D'abord il faut commencer à créer des clés statiques pour les différentes machines.
Utilisez la commande `wg` pour ceci et stockez les clés quelque part dans les répertoires `root`,
pour que vous puissiez les retrouver facilement après.

---

**Question 7 (2) : Sécuriser la création des clés**

A quoi est-ce qu'il faut faire attention pendant la création des clés pour garantir une
sécurité maximale?
Un point est indiqué par la commande `wg` quand vous créez les clés privées.
L'autre point a déjà été discuté plusieurs fois au cours par rapport à la création et
la distribution des clés privées.

---

**Réponse:** Le seul message affiché à la création des clés privées, c'est la clé elle-même. Il se trouve que par défaut WG va juste afficher la clé dans la console, il faut alors faire une redirection vers le fichier que l'on souhaite.
Cependant, il faut faire extrêmement attention aux droits qu'ont ces fichiers lors de leur création, car ils sont sensibles et il ne faudrait pas qu'elles soient lisibles ou accessibles par d'autres utilisateurs ou processus sur le système.
Il faut aussi, comme pour OpenVPN, des canaux sécurisés pour l’échange des clés sinon un attaquant pourrait intervenir durant l'échange et pourrait par exemple récupérer la clé privée d'un client.

---

## Réseau à réseau

Comme pour l'OpenVPN, commencez par connecter les deux machines `MainS` et `FarS` ensemble.
Il n'est pas nécessaire de changer le script `routing.sh` ou d'ajouter d'autres règles au
pare-feu.
Vous pouvez faire toute la configuration avec les fichiers de configuration pour la commande
`wg-quick`.
Appelez les fichiers de configuration `wg0.conf`.
A la fin, assurez-vous que vous pouvez faire un `ping` entre toutes les machines du réseau `Main` et
le réseau `Far`.

---

**Question 8 (2) : sécurité du fichier `wg0.conf`**

Si vous créez votre fichier `wg0.conf` sur votre système hôte avec les permissions
normales, qu'est-ce qui va s'afficher au lancement de WireGuard?
Pourquoi c'est un problème?
Et avec quelle commande est-ce qu'on peut réparer ceci?

---

**Réponse** 

```
Warning: `/root/wireguard/conf/wg0.conf' is world accessible
```

C'est un problème étant donné que le fichier contient notamment une clé privée qui est une information qu'il faut absolument garder secrète.

On peut facilement corriger ce problème en utilisant la commande `chmod`. Ainsi les droits ne seront attribués qu'au propriétaire/utilisateur et non à tout le monde.

```bash
chmod 600 /root/wireguard/conf/wg0.conf
```

---

## Remote à réseau

Maintenant faites la configuration pour la machine `Remote`.
Il faut qu'elle puisse contacter toutes les autres machines des réseaux `Main` et `Far`.

---

**Question 9 (1): tableau de routage sur `MainS`**

Ajoutez ici une copie du tableau de routage de `MainS` une fois les connexions avec
`FarS` et `Remote` sont établies.

---

**Réponse**

Ci-dessous deux versions de la table de routage, une fois avec `route` et l'autre avec `ip route`.

```bash
root@MainServer:~# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         10.0.0.1        0.0.0.0         UG    0      0        0 eth0
10.0.0.0        0.0.0.0         255.255.255.0   U     0      0        0 eth0
10.0.1.0        0.0.0.0         255.255.255.0   U     0      0        0 eth1
10.0.2.0        0.0.0.0         255.255.255.0   U     0      0        0 wg0
172.16.0.2      0.0.0.0         255.255.255.255 UH    0      0        0 wg0
172.16.0.3      0.0.0.0         255.255.255.255 UH    0      0        0 wg0

root@MainServer:~# ip route show
default via 10.0.0.1 dev eth0
10.0.0.0/24 dev eth0 proto kernel scope link src 10.0.0.2
10.0.1.0/24 dev eth1 proto kernel scope link src 10.0.1.2
10.0.2.0/24 dev wg0 scope link
172.16.0.2 dev wg0 scope link
172.16.0.3 dev wg0 scope link
```

---

**Question 10 (3): passage des paquets**

Décrivez par quelles interfaces un paquet passe quand on fait un `ping 10.0.2.10` sur la machine `Remote`.
Pour chaque passage à une nouvelle interface, indiquez la machine, l'interface, et si le paquet va être
transféré d'une façon chiffrée ou pas.
Décrivez le chemin aller du `echo request` et le chemin retour du `echo reply`.

---

**Réponse**

```bash
echo request :
Remote(wg0)   -->   Remote(eth0)  : chifré (Passsage de wg0 chiffre)
Remote(eth0)  -->   MainS(eth0)   : chifré
MainS(eth0)   -->   FarS(eth0)    : chifré
FarS(eth0)    -->   FarS(wg0)     : chifré
FarS(wg0)     -->   FarS(eth1)    : déchiffré (Passsage de wg0 déchiffre)
FarS(eth1)    -->   FarC1(eth0)   : déchifré

echo reply:
FarC1(eth0) --> FarS(eth1) : chifré (Passsage de wg0 chiffre)
FarS(eth1) --> FarS(wg0) : chifré
FarS(wg0) --> FarS(eth0) : chifré
FarS(eth0) --> MainS(eth0) : déchiffré
MainS(eth0) --> Remote(eth0) : déchiffré
Remote(eth0) --> Remote(wg0) : déchiffré (Passsage de wg0 déchiffre)
```

---

Comme pour OpenVPN, assurez-vous que tout le démarrage de la configuration soit dans les scripts
`wireguard.sh` pour les différentes machines.
Quand tout est fait, la commande suivante doit retourner avec succès:

```bash
./test/runit.sh wireguard
```

## Bonus: Desktop à réseau

Je n'ai pas réussi à connecter le desktop hôte sur le réseau docker avec WireGuard.
Donc si vous réussissez à vous connecter avec [WireGuard Client](https://www.wireguard.com/install/)
depuis votre machine hôte à vos dockers et faire des pings sur les différents réseaux, c'est un bonus!
Mettez le fichier de configuration quelque part dans le répertoire `root/host`. 

# IPSec

Ici, vous allez utiliser l'implémentation de [StrongSwan](https://docs.strongswan.org/docs/5.9/config/quickstart.html)
pour mettre en place un VPN entre les différentes machines.
Comme OpenVPN, StrongSwan se base sur des certificats pour l'autorisation des connexions.
Par contre, il ne va pas utiliser le TLS pour la connexion, mais d'autres protocols.

Pour lancer StrongSwan, vous devez d'abord lancer le daemon `charon` avec la commande suivante:

```bash
/usr/lib/ipsec/charon &
```

Contrairement à OpenVPN et WireGuard, il est plus difficile de configurer StrongSwan avec un répertoire différent.
Il faut donc que votre script `ipsec.sh` copie les fichiers depuis le répertoire `/root` dans les endroits
appropriés.
Assurez-vous que seulement les fichiers nécessaires sont copiés!

## Mise en place du CA

Utilisez les commandes décrites dans la documentation de StrongSwan pour mettre en place une CA auto-signé.
Ceci veut dire que vous ne vous reposez pas sur une autorité reconnue mondialement, mais sur une clé
créée par vous-mêmes.
Comme ça vous devriez copier la partie publique de cette clé sur toutes les autres machines, afin que celles-ci
puissent vérifier que les certificats proposés sont valides.

Le certificat inclut aussi une description des machines.
Regardez quels sont les informations correctes à y mettre.
Vous pouvez bien sûr inventer une entreprise et un nom de domaine à votre idée.

Gardez les clés quelque part dans l'arborescence `root` de votre projet.
Assurez-vous que les clés sont seulement disponibles sur les machines qui en ont besoin. 

---

**Question 11 (2): commandes pour création de clés**

- 1 - Quelles sont les commandes que vous avez utilisées pour créer le CA et les clés pour les machines?
- 1 - Si vous avez écrit un script pour créer les clés, copiez-le dans votre répertoire et indiquez le chemin ici.

---

**Réponse**

1. Les commandes demandées (qui se trouvent dans le script de génération):
   ````bash
   #Note: Generate a priv key and issue a certificate for each gateway/host (mains/fars/remote)
   # Generate priv key for a host
   pki --gen --type ed25519 --outform pem > mainsKey.pem
   
   # Create the CA based on the mains priv key
   pki --self --ca --lifetime 3652 --in mainsKey.pem --dn "C=CH, O=heig, CN=heig Root CA" --outform pem > caCert.pem
   
   # Generate the CSR for a host	 
   pki --req --type priv --in mainsKey.pem --dn "C=CH, O=heig, CN=heig.mains" --outform pem > mainsReq.pem
   		  
   # Issue the CSR for a host
   pki --issue --cacert caCert.pem --cakey mainsKey.pem --type pkcs10 --in mainsReq.pem --serial 01 --lifetime 1826 --outform pem > mainsCert.pem
   ````
   
   
   
2. Le script de génération ce clés ce trouve à `root/main/startup/ipsec_keygen.sh`

**Question 12 (3) : création de clés hôtes sécurisée**

Dans la documentation de StrongSwan il y a une description pour éviter que la personne qui a créé le
CA de racine voie les clés privées des hôtes.
Supposant qu'il y a deux entités, le `CA holder` et le `host`, décrivez chronologiquement qui crée quelle
clé à quel moment, et quelles sont les fichiers échangés.
Laissez ces fichiers dans les sous-répertoires correspondants, même si vous en avez plus besoin.

---

**Réponse**

Les hôtes utilisent un CSR pour faire signer leur certificat à l’autorité de certification:

1. `host` créé sa clé privée
2. `host` créé le CSR (Certificate Signing Request) avec sa clé privée
3. `host` envoie le CSR à `CA holder`
4. `CA holder` issue le CSR avec le CA et sa clé privée
5. `CA holder` envoie le certificat signé à `host` 

Note : nous avons laissé les CSR dans /root/ipsec/pems de chaque machine (main, far et remote)

---

## Réseau à réseau

Maintenant, vous êtes prêt·e·s pour configurer StrongSwan pour connecter les réseaux `Main` et `Far`.
Faites attention, parce que StrongSwan va seulement créer la connexion une fois un paquet le requiert.
En mettant en place la connexion, `charon` va journaliser ses efforts dans le terminal.
Regardez bien ce journal si quelque chose ne marche pas.

Comme décrit dans l'introduction pour IPSec, il faut stocker les fichiers nécessaires dans le répertoire `root`, puis
les copier dans l'arborescence pour que StrongSwan puisse les trouver.

---

**Question 13 (2) : fichiers et leur utilité**

Pour les hôtes `MainS` et `FarS`, décrivez pour chaque fichier que vous copiez la destination et l'utilité de
ce fichier.

---

**Réponse**

Déjà nous avons fait un script pour copier tous les certificats générés dans la machine MainS. Il se trouve dans root/scripts/copyIpSec.sh:
```bash
# Copy the MainS pems to /root/main/ipsec/pems
cp ./root/main/mainsKey.pem ./root/main/mainsReq.pem ./root/main/mainsCert.pem ./root/main/caCert.pem ./root/main/ipsec/pems

# Copy the FarS pems to /root/far/ipsec/pems
cp ./root/main/farsKey.pem ./root/main/farsReq.pem ./root/main/farsCert.pem ./root/main/caCert.pem ./root/far/ipsec/pems

# Copy the Remote pems to /root/remote/ipsec/pems
cp ./root/main/remoteKey.pem ./root/main/remoteReq.pem ./root/main/remoteCert.pem ./root/main/caCert.pem ./root/remote/ipsec/pems

#Remove copied pems
rm -f ./root/main/*.pem
```

Ensuite, dans le script ipsec.sh présent sur chaque machine, nous copions tous les pems de la machine dans les répertoires appropriés:

MainS - Fichiers copiés  (depuis /root/ipsec/pems de MainS):

1. ipsec/pems/caCert.pem => /etc/swanctl/x509ca # CA
2. ipsec/pems/mainsKey.pem => /etc/swanctl/private # Clé privée de mains
3. ipsec/pems/mainsCert.pem => /etc/swanctl/x509 # Certificat de mains
4. ipsec/swanctl.conf => /etc/swanctl/conf.d # Fichier de configuration utilisé pour lancer le VPN



FarS - Fichiers copiés (depuis /root/ipsec/pems de FarS):

1. ipsec/pems/caCert.pem => /etc/swanctl/x509ca # CA
2. ipsec/pems/farsKey.pem => /etc/swanctl/private # Clé privée de fars
3. ipsec/pems/farsCert.pem => /etc/swanctl/x509 # Certificat de fars
4. ipsec/swanctl.conf => /etc/swanctl/conf.d # Fichier de configuration utilisé pour lancer le VPN



---

## Remote à Réseau

La prochaine étape est de connecter un seul hôte à `MainS`.
Ce hôte doit être capable de contacter autant le réseau `main` que le réseau `far`.
Bien sûr que ça requiert que l'IPSec entre `main` et `far` est actif.
Cherchez dans la documentation StrongSwan à quelle configuration ceci correspond et ajoutez-la à votre
configuration existante.

---

**Question 14 (1) : fichiers et leur utilité**

Comme pour l'exercice _Réseau à réseau_, les fichiers doivent être dans le répertoire `root`, mais
StrongSwan en a besoin dans d'autres répertoires.
Pour l'hôte `Remote`, décrivez pour chaque fichier que vous copiez la destination et l'utilité de
ce fichier.
Indiquez aussi quel(s) fichier(s) vous avez dû ajouter à `MainS`.

---

**Réponse**

Remote - Fichiers copiés (depuis /root/ipsec/pems de Remote):

1. ipsec/pems/caCert.pem => /etc/swanctl/x509ca # CA
2. ipsec/pems/remoteKey.pem => /etc/swanctl/private # Clé privée de remote
3. ipsec/pems/remoteCert.pem => /etc/swanctl/x509 # Certificat de remote
4. ipsec/swanctl.conf => /etc/swanctl/conf.d # Fichier de configuration utilisé pour lancer le VPN

Nous n'avons pas dû ajouter de fichier à MainS, simplement ajouté la configuration pour la connexion de Remote dans swanctl.conf de MainS.

**Configuration du fichier swanctl.conf de remote:**
Nous avons utilisé l'exemple [Roadwarrior Case with Virtual IP](https://docs.strongswan.org/docs/5.9/config/quickstart.html) en faisant bien attention de ne pas faire la même erreur que dans leur exemple, à savoir:

```
children {
        rw {
          local_ts  = 10.1.0.0/16 # This must be remote_ts not local_ts
        }
```

**Configuration de ipsec.sh et swanctl.conf de MainS**

Dans la configuration swanctl de MainS, nous avons ajouté la configuration du `rw` avec un pool de virtual ip (`10.4.0.0/16`). de plus, nous avons ajouté dans la configuration `net-net`, dans le local_ts le pool de VIPs. En plus de Cette configuration, nous avons du ajouter `strongswan --load-pools` dans le script ipsec.sh pour dire à charon de charger le pool de VIPs et les mettre à disposition des clients qui se connectent à la paserelle MainS.

---

# Comparaison

Maintenant, vous allez devoir comparer les différents protocols entre eux.
Pour chaque question, assurez-vous de bien donner des explications complètes,
sauf si la question vous demande de donner qu'une courte réponse.

## Sécurité

---

**Question 15 (2) : Sécurité de la communication**

Décrivez la sécurité maximale disponible pour chaque protocol une fois la connexion établie.
Pour chacune de votre configuration retenue dans ce labo, décrivez quels sont les algorithmes
utilisés pour sécuriser la connexion.

---

**Réponse:**

- OpenVPN :
  - Algorithme de chiffrement : AES-256.
  - Algorithme d'intégrité des données : HMAC-SHA256
  - Algorithme d'échange de clés : Diffie-Hellman avec une taille de clé de 4096 bits est recommandé pour l'échange de clés sécurisé.
  - Algorithme de signature : RSA avec SHA-256 (ou SHA-512 pour une sécurité maximale) peut être utilisé pour la vérification des certificats.
  - Protocole d'authentification : OpenVPN peut être configuré pour utiliser des certificats X.509 pour l'authentification des pairs.

- WireGuard :
  - Algorithme de chiffrement : ChaCha20 avec Poly1305 
  - Algorithme d'échange de clés : Elliptic Curve Diffie-Hellman (ECDH) avec une courbe elliptique de 25519 bits
  - Algorithme d'authentification : WireGuard utilise des clés pré-partagées (PSK) pour l'authentification, éliminant ainsi la nécessité d'algorithmes de signature.
- IPsec :
  - Protocole d'authentification : IKEv2 avec des méthodes d'authentification robustes, telles que les signatures RSA avec SHA-512, ou les signatures ECDSA avec des courbes elliptiques plus longues (par exemple, P-384 ou P-521).
  - Algorithme de chiffrement : AES-256
  - Algorithme d'intégrité des données : HMAC-SHA512 est utilisé pour assurer l'intégrité des données échangées.
  - Algorithme d'échange de clés : Diffie-Hellman avec des groupes de taille appropriée (par exemple, Group 19, 20 ou 21) est recommandé pour l'échange de clés.

---

**Question 16 (2) : Sécurité de l'authentification**

Décrivez la sécurité de l'authentification que nous avons choisi pour les différents
exercices.
Regardez aussi les certificats et l'algorithme de signature utilisé et commentez si c'est un algorithme
sécure ou pas.

---

**Réponse:**

- OpenVPN:

  Pour l'echange de clés, nous utilisons Diffie-Hellman, qui est sûr si pas de MITM. Easyrsa utilise RSA avec SHA-256 comme algorithme de signature par défaut pour les certificats x509v3.

- WireGuard:

  WG utilise le Noise protocol framework pour l'échange de clés et l'authentification. Il utilise Diffie-Hellman pour l'échange de clés avec Noise. Plus précisément, il utilise l'algorithme ECDH pour générer une clé secrète partagée entre les pairs. WireGuard n'utilise pas d'algorithmes de signature pour l'échange de clés ou l'authentification, mais s'appuie sur des PSK échangées entre les pairs lors de la configuration initiale. Ces PSK servent de secret partagé pour authentifier et sécuriser la communication.

- IPSec:
  Avec StongSwan nous utilisons [IKEv2](https://docs.strongswan.org/docs/5.9/howtos/ipsecProtocol.html#_internet_key_exchange_version_2_ikev2) qui responsable pour authentification mutuelle des endpoints IPSec et l'établissement automatisé des clés de session de chiffrement et d'intégrité des données. IKEv2 incorpore Diffie-Hellman.
  IKEv2 propose également différents algorithmes de signature pour l'authentification. Nous avons utilisé Ed25519, qui est le système de signature ECDSA utilisant SHA-512 et Curve25519. ECDSA est recommandé par le [NIST](https://csrc.nist.gov/news/2023/nist-releases-fips-186-5-and-sp-800-186), mais n'est pas résistant au post-quantum. Il s'agit d'un algorithme sécure, même si il est vulnérable à des "fault attacks" ([voir ce papier](https://cybermashup.files.wordpress.com/2017/10/practical-fault-attack-against-eddsa_fdtc-2017.pdf)), il ne s'agit pas d'une attaque cryptographique contre l'algorithme lui-même, mais contre le hardware qui l'utilise.
  
  [Sources](https://en.wikipedia.org/wiki/IPsec)
  
  Tous ces algorithmes sont considérés comme sûrs.

---

## Facilité d'utilisation

---

**Question 17 (1) : Facilité de la configuration serveur**

Quelle est la complexité de mettre en place un serveur pour les deux cas demandés
dans les exercices?
Trier votre réponse pour que la solution VPN la plus facile soit au début et que la difficulté augmente avec chaque
entrée.

---

**Réponse:**

- WireGuard: Nous avons trouvé que WG était le plus simple à mettre en place, car la génération de clé était native et la configuration vraiment minimaliste.
- OpenVPN: Ce VPN arrive en seconde position, car si on le compare à WG la seule partie qui est un peu plus complexe, c'est la génération des clés. Il faut passer par un logiciel tiers pour avoir nos pairs, sinon tout le reste est très simple.
- IPSec: C'est la configuration qui a pris le plus de temps et qui est aussi la plus complexe à réaliser. Elle demande plus de configuration de notre part et la syntaxe est aussi plus compliquée que les deux VPNs précédents.



---

**Question 18 (1) : Facilité de la configuration client desktop**

Quelle est la complexité de mettre en place un client desktop pour les deux cas demandés
dans les exercices?

---

**Réponse:**

- OpenVPN: Configuration super simple comme le serveur et minimale. Elle ne demande pas beaucoup de configuration de notre côté.
- WireGuard: Comparer à OpenVPN, il faut tout de même configurer les accès avec les IPs, etc... Cela la rend donc plus complexe que OpenVPN
- IPSec: Comme pour le serveur, cette configuration est la plus compliquée, car elle nous demande plus d'effort de configuration et la syntaxe est assez stricte.

---

## Performance

---

**Question 19 (2) : Plus vite au plus lent**

Trie les trois configurations que nous avons vues dans l'ordre décroissant
de leur vitesse mesuré avec `iperf`.
Pour chaque protocol, indique les trois vitesses suivantes:
- entre le `MainS` et le `FarS`
- entre `MainC1` et `FarC1` 
- entre `Remote` et `FarC2`
Si un des protocols est beaucoup plus rapide que les autres, décrivez pourquoi c'est le cas.

---

**Réponse:**

Alors déjà, nous avons écrit un magnifique script qui va faire ces tests pour nous. Il est disponible dans test/iperf.sh, et il va générer un rapport avec les résultats générés par iperf. voici ce que nous avons obtenur comme résultats:
```
*** Testing openvpn ***
MainS to FarS
[  1] local 172.16.0.1 port 50032 connected with 10.0.2.2 port 5001
[ ID] Interval       Transfer     Bandwidth
[  1] 0.0000-10.0125 sec  1.01 GBytes   871 Mbits/sec
MainC1 to FarC1
[  1] local 10.0.1.10 port 38350 connected with 10.0.2.10 port 5001
[ ID] Interval       Transfer     Bandwidth
[  1] 0.0000-10.0107 sec   729 MBytes   611 Mbits/sec
Remote to FarC2
[  1] local 172.16.0.10 port 45072 connected with 10.0.2.11 port 5001
[ ID] Interval       Transfer     Bandwidth
[  1] 0.0000-10.0096 sec   723 MBytes   606 Mbits/sec
=== End of openvpn report ===

*** Testing wireguard ***
MainS to FarS
[  1] local 172.16.0.1 port 49296 connected with 10.0.2.2 port 5001
[ ID] Interval       Transfer     Bandwidth
[  1] 0.0000-10.0368 sec  1.29 GBytes  1.10 Gbits/sec
MainC1 to FarC1
[  1] local 10.0.1.10 port 57258 connected with 10.0.2.10 port 5001
[ ID] Interval       Transfer     Bandwidth
[  1] 0.0000-10.0407 sec  1.25 GBytes  1.07 Gbits/sec
Remote to FarC2
[  1] local 172.16.0.3 port 53338 connected with 10.0.2.11 port 5001
[ ID] Interval       Transfer     Bandwidth
[  1] 0.0000-10.0378 sec  1.30 GBytes  1.12 Gbits/sec
=== End of wireguard report ===

*** Testing ipsec ***
MainS to FarS
[  1] local 10.0.1.2 port 46542 connected with 10.0.2.2 port 5001
[ ID] Interval       Transfer     Bandwidth
[  1] 0.0000-10.0230 sec  1.45 GBytes  1.24 Gbits/sec
MainC1 to FarC1
[  1] local 10.0.1.10 port 57370 connected with 10.0.2.10 port 5001
[ ID] Interval       Transfer     Bandwidth
[  1] 0.0000-10.0044 sec  2.04 GBytes  1.75 Gbits/sec
Remote to FarC2
[  1] local 10.4.0.1 port 57176 connected with 10.0.2.11 port 5001
[ ID] Interval       Transfer     Bandwidth
[  1] 0.0000-10.0035 sec   539 MBytes   452 Mbits/sec
=== End of ipsec report ===
```

Donc nous pouvons classer les vpn comme suit:

1. Wireguard avec les résultats suivants:

   | MainS - FarS   | MainC1 - FarC1 | Remote - FarC2 |
   | -------------- | -------------- | -------------- |
   | 1.10 Gbits/sec | 1.07 Gbits/sec | 1.12 Gbits/sec |

2. IPSec avec les résultats suivants:

   | MainS - FarS   | MainC1 - FarC1 | Remote - FarC2 |
   | -------------- | -------------- | -------------- |
   | 1.24 Gbits/sec | 1.75 Gbits/sec | 452 Mbits/sec  |

3. OpenVPN avec les résultats suivants:

   | MainS - FarS  | MainC1 - FarC1 | Remote - FarC2 |
   | ------------- | -------------- | -------------- |
   | 871 Mbits/sec | 611 Mbits/sec  | 606 Mbits/sec  |

Ce qui est très étrange c'est les résultats obtenus entre MainC1 et FarC1 en utilisant IPSec. Nous ne comprenons pas pourquoi deux clients dans des sous réseaux différents peuvent avoir un débit plus élevé que les deux passerelles.

---

# Points spécifiques

Voici quelques points supplémentaires qui seront évalués, avec leurs points:

- 20 (2) - organisation des fichiers dans le répertoire `root`
- 21 (3) - acceptation du labo par le script `test/runit.sh`
- 22 (2) - bonne utilisation des scripts

## OpenVPN

- 23 (2) - est-ce que la configuration dans `root/far/openvpn/client.ovpn` marche pour une connexion depuis l'ordinateur
  hôte et toutes les machines sont atteignables depuis l'hôte

## WireGuard

- 24 (3) bonus - connexion avec la configuration dans `root/far/wireguard/client.conf` depuis l'ordinateur
  hôte et toutes les machines sont atteignables depuis l'hôte

## IPSec

- 25 (1) - pas de clés supplémentaires pour le IPSec dans les autres machines
- 26 (1) - présence des fichiers utilisés pour la mise en place des clés pour IPSec

