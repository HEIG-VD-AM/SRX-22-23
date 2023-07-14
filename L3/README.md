[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-8d59dc4de5201274e310e4c54b9627a8934c3b88527886e3b421487c677d23eb.svg)](https://classroom.github.com/a/27yZ_HEr)
[![Open in Visual Studio Code](https://classroom.github.com/assets/open-in-vscode-c66648af7eb3fe8bc4f294546bfd86ef473780cde1dea487d3c4ff354943c9ae.svg)](https://classroom.github.com/online_ide?assignment_repo_id=10557585&assignment_repo_type=AssignmentRepo)
# HEIGVD - Sécurité des Réseaux - 2023
# Laboratoire n°3 - IDS

Ce travail est à réaliser en équipes de deux personnes.
C'est le **deuxième travail noté** du cours SRX.

Vous pouvez répondre aux questions en modifiant directement votre clone du README.md ou avec un fichier pdf que vous pourrez uploader sur votre fork.

Le rendu consiste simplement à compléter toutes les parties marquées avec la mention "LIVRABLE". Le rendu doit se faire par un `git commit` sur la branche `main`.

## Table de matières

[Introduction](#introduction)

[Echéance](#echéance)

[Démarrage de l'environnement virtuel](#démarrage-de-lenvironnement-virtuel)

[Communication avec les conteneurs](#communication-avec-les-conteneurs)

[Configuration de la machine IDS et installation de Snort](#configuration-de-la-machine-ids-et-installation-de-snort)

[Essayer Snort](#essayer-snort)

[Utilisation comme IDS](#utilisation-comme-un-ids)

[Ecriture de règles](#ecriture-de-règles)

[Travail à effectuer](#exercises)

[Cleanup](#cleanup)

# Introduction

## Echéance

Ce travail devra être rendu au plus tard, **le 2 avril 2023 à 23h59.**


## Introduction

Dans ce travail de laboratoire, vous allez explorer un système de détection contre les intrusions (IDS) dont l'utilisation es très répandue grâce au fait qu'il est très performant tout en étant gratuit et open source. Il s'appelle [Snort](https://www.snort.org). Il existe des versions de Snort pour Linux et pour Windows.

### Les systèmes de détection d'intrusion

Un IDS peut "écouter" tout le traffic de la partie du réseau où il est installé. Sur la base d'une liste de règles, il déclenche des actions sur des paquets qui correspondent à la description de la règle.

Un exemple de règle pourrait être, en langage commun : "donner une alerte pour tous les paquets envoyés par le port http à un serveur web dans le réseau, qui contiennent le string 'cmd.exe'". En on peut trouver des règles très similaires dans les règles par défaut de Snort. Elles permettent de détecter, par exemple, si un attaquant essaie d'éxecuter un shell de commandes sur un serveur Web tournant sur Windows. On verra plus tard à quoi ressemblent ces règles.

Snort est un IDS très puissant. Il est gratuit pour l'utilisation personnelle et en entreprise, où il est très utilisé aussi pour la simple raison qu'il est l'un des systèmes IDS des plus efficaces.

Snort peut être exécuté comme un logiciel indépendant sur une machine ou comme un service qui tourne après chaque démarrage. Si vous voulez qu'il protège votre réseau, fonctionnant comme un IPS, il faudra l'installer "in-line" avec votre connexion Internet.

Par exemple, pour une petite entreprise avec un accès Internet avec un modem simple et un switch interconnectant une dizaine d'ordinateurs de bureau, il faudra utiliser une nouvelle machine éxecutant Snort et la placer entre le modem et le switch.


## Matériel

Vous avez besoin de votre ordinateur avec Docker et docker-compose. Vous trouverez tous les fichiers nécessaires pour générer l'environnement pour virtualiser ce labo dans le projet que vous avez cloné.
Vu qu'il faudra aussi faire un nat, sous Windows vous avez besoin de configurer votre docker pour
utiliser "Hyper-V" au lieu de "WSL2". Il faut désactiver la configuration [Use the WSL2 based engine](https://docs.docker.com/desktop/settings/windows/).


## Démarrage de l'environnement virtuel

Ce laboratoire utilise docker-compose, un outil pour la gestion d'applications utilisant multiples conteneurs. Il va se charger de créer un réseaux virtuel `snortlan`, la machine IDS, un client avec un navigateur Firefox, une machine "Client" et un conteneur Wireshark directement connecté à la même interface réseau que la machine IDS. Le réseau LAN interconnecte les autres 3 machines (voir schéma ci-dessous).

![Plan d'adressage](images/docker-snort.png)

Nous allons commencer par lancer docker-compose. Il suffit de taper la commande suivante dans le répertoire racine du labo, celui qui contient le fichier [docker-compose.yml](docker-compose.yml). Optionnelement vous pouvez lancer le script [up.sh](scripts/up.sh) qui se trouve dans le répertoire [scripts](scripts), ainsi que d'autres scripts utiles pour vous :

```bash
docker-compose up --detach
```

Le téléchargement et génération des images prend peu de temps.

Les images utilisées pour les conteneurs client et la machine IDS sont basées sur l'image officielle Kali. Le fichier [Dockerfile](Dockerfile) que vous avez téléchargé contient les informations nécessaires pour la génération de l'image de base. [docker-compose.yml](docker-compose.yml) l'utilise comme un modèle pour générer ces conteneurs. Les autres deux conteneurs utilisent des images du groupe LinuxServer.io. Vous pouvez vérifier que les quatre conteneurs sont crées et qu'ils fonctionnent à l'aide de la commande suivante.

```bash
docker ps
```

## Communication avec les conteneurs

Afin de simplifier vos manipulations, les conteneurs ont été configurées avec les noms suivants :

- IDS
- Client
- wireshark
- firefox

Pour accéder au terminal de l’une des machines, il suffit de taper :

```bash
docker exec -it <nom_de_la_machine> /bin/bash
```

Par exemple, pour ouvrir un terminal sur votre IDS :

```bash
docker exec -it IDS /bin/bash
```

Vous pouvez bien évidemment lancer des terminaux communiquant avec toutes les machines en même temps ou même lancer plusieurs terminaux sur la même machine. ***Il est en fait conseillé pour ce laboratoire de garder au moins deux terminaux ouverts sur la machine IDS en tout moment***.


### Configuration de la machine Client et de firefox

Dans un terminal de votre machine Client et de la machine firefox, taper les commandes suivantes :

```bash
ip route del default
ip route add default via 192.168.220.2
```

Ceci configure la machine IDS comme la passerelle par défaut pour les deux autres machines.


## Configuration de la machine IDS et installation de Snort

Pour permettre à votre machine Client de contacter l'Internet à travers la machine IDS, il faut juste une petite règle NAT par intermédiaire de nftables sur la machine IDS.
Si votre machine hôte est un Windows, il ne faut pas oublier de changer la configuration docker pour utiliser hyper-v.

```bash
nft add table nat
nft 'add chain nat postrouting { type nat hook postrouting priority 100 ; }'
```

Cette commande `iptables` définit une règle dans le tableau NAT qui permet la redirection de ports et donc, l'accès à l'Internet pour la machine Client.

On va maintenant installer Snort sur le conteneur IDS.

La manière la plus simple c'est d'installer Snort en ligne de commandes. Il suffit d'utiliser la commande suivante :

```
apt update && apt install -y snort
```

Ceci télécharge et installe la version la plus récente de Snort.

Il est possible que vers la fin de l'installation, on vous demande de fournir deux informations :

- Le nom de l'interface sur laquelle snort doit surveiller - il faudra répondre ```eth0```
- L'adresse de votre réseau HOME. Il s'agit du réseau que vous voulez protéger. Cela sert à configurer certaines variables pour Snort. Vous pouvez répondre ```192.168.220.0/24```.


## Essayer Snort

Une fois installé, vous pouvez lancer Snort comme un simple "sniffer". Pourtant, ceci capture tous les paquets, ce qui peut produire des fichiers de capture énormes si vous demandez de les journaliser. Il est beaucoup plus efficace d'utiliser des règles pour définir quel type de trafic est intéressant et laisser Snort ignorer le reste.

Snort se comporte de différentes manières en fonction des options que vous passez en ligne de commande au démarrage. Vous pouvez voir la grande liste d'options avec la commande suivante :

```
snort --help
```

On va commencer par observer tout simplement les entêtes des paquets IP utilisant la commande :

```
snort -v -i eth0
```

**ATTENTION : le choix de l'interface devient important si vous avez une machine avec plusieurs interfaces réseau. Dans notre cas, vous pouvez ignorer entièrement l'option ```-i eth0``` et cela devrait quand-même fonctionner correctement.**

Snort s'éxecute donc et montre sur l'écran tous les entêtes des paquets IP qui traversent l'interface eth0. Cette interface reçoit tout le trafic en provenance de la machine "Client" puisque nous avons configuré le IDS comme la passerelle par défaut.

Pour arrêter Snort, il suffit d'utiliser `CTRL-C`.

**attention** : généralement, ceci fonctionne si vous patientez un moment... Snort est occupé en train de gérer le contenu du tampon de communication et cela qui peut durer quelques secondes. Cependant, il peut arriver de temps à autres que Snort ne réponde plus correctement au signal d'arrêt. Dans ce cas-là on peut utliliser `CTRL-Z`, puis lancer la commande `pkill -f -9 snort`.


## Utilisation comme un IDS

Pour enregistrer seulement les alertes et pas tout le trafic, on execute Snort en mode IDS. Il faudra donc spécifier un fichier contenant des règles.

Il faut noter que `/etc/snort/snort.config` contient déjà des références aux fichiers de règles disponibles avec l'installation par défaut. Si on veut tester Snort avec des règles simples, on peut créer un fichier de config personnalisé (par exemple `mysnort.conf`) et importer un seul fichier de règles utilisant la directive "include".

Les fichiers de règles sont normalement stockés dans le répertoire `/etc/snort/rules/`, mais en fait un fichier de config et les fichiers de règles peuvent se trouver dans n'importe quel répertoire de la machine.

Par exemple, créez un fichier de config `mysnort.conf` dans le repertoire `/etc/snort` avec le contenu suivant :

```
include /etc/snort/rules/icmp2.rules
```

Ensuite, créez le fichier de règles `icmp2.rules` dans le repertoire `/etc/snort/rules/` et rajoutez dans ce fichier le contenu suivant :

```
alert icmp any any -> any any (msg:"ICMP Packet"; sid:4000001; rev:3;)
```

On peut maintenant éxecuter la commande :

```
snort -c /etc/snort/mysnort.conf
```

Vous pouvez maintenant faire quelques pings depuis votre "Client" et regarder les résultas dans le fichier d'alertes contenu dans le repertoire `/var/log/snort/`.

## Enlever les avertissements

Si on applique la règle en haut et qu'on fait un ping depuis une des machines `firefox` ou `Client`, snort
affiche l'avertissement suivant:

```
WARNING: No preprocessors configured for policy 0.
```

Ceci veut dire que snort a détécté une ou plusieurs règles qui ne sont pas précédées par un préprocesseur.
Pour ajouter un préprocesseur, vous pouvez ajouter la ligne suivante au début de votre fichier de configuration:

```
preprocessor frag3_global: max_frags 65536
```

## Ecriture de règles

Snort permet l'écriture de règles qui décrivent des tentatives de exploitation de vulnérabilités bien connues. Les règles Snort prennent en charge à la fois, l'analyse de protocoles et la recherche et identification de contenu.

Il y a deux principes de base à respecter :

* Une règle doit être entièrement contenue dans une seule ligne
* Les règles sont divisées en deux sections logiques : (1) l'entête et (2) les options.

L'entête de la règle contient l'action de la règle, le protocole, les adresses source et destination, et les ports source et destination.

L'option contient des messages d'alerte et de l'information concernant les parties du paquet dont le contenu doit être analysé. Par exemple:

```
alert tcp any any -> 192.168.220.0/24 111 (content:"|00 01 86 a5|"; msg: "mountd access";)
```

Cette règle décrit une alerte générée quand Snort trouve un paquet avec tous les attributs suivants :

* C'est un paquet TCP
* Emis depuis n'importe quelle adresse et depuis n'importe quel port
* A destination du réseau identifié par l'adresse 192.168.220.0/24 sur le port 111

Le text jusqu'au premier parenthèse est l'entête de la règle.

```
alert tcp any any -> 192.168.220.0/24 111
```

Les parties entre parenthèses sont les options de la règle:

```
(content:"|00 01 86 a5|"; msg: "mountd access";)
```

Les options peuvent apparaître une ou plusieurs fois. Par exemple :

```
alert tcp any any -> any 21 (content:"site exec"; content:"%"; msg:"site
exec buffer overflow attempt";)
```

La clé "content" apparait deux fois parce que les deux strings qui doivent être détectés n'apparaissent pas concaténés dans le paquet mais a des endroits différents. Pour que la règle soit déclenchée, il faut que le paquet contienne **les deux strings** "site exec" et "%".

Les éléments dans les options d'une règle sont traités comme un AND logique. La liste complète de règles sont traitées comme une succession de OR.

## Informations de base pour le règles

### Actions :

```
alert tcp any any -> any any (msg:"My Name!"; content:"Skon"; sid:1000001; rev:1;)
```

L'entête contient l'information qui décrit le "qui", le "où" et le "quoi" du paquet. Ça décrit aussi ce qui doit arriver quand un paquet correspond à tous les contenus dans la règle.

Le premier champ dans le règle c'est l'action. L'action dit à Snort ce qui doit être fait quand il trouve un paquet qui correspond à la règle. Il y a six actions :

* alert - générer une alerte et écrire le paquet dans le journal
* log - écrire le paquet dans le journal
* pass - ignorer le paquet
* drop - bloquer le paquet et l'ajouter au journal
* reject - bloquer le paquet, l'ajouter au journal et envoyer un `TCP reset` si le protocole est TCP ou un `ICMP port unreachable` si le protocole est UDP
* sdrop - bloquer le paquet sans écriture dans le journal

### Protocoles :

Le champ suivant c'est le protocole. Il y a trois protocoles IP qui peuvent être analysés par Snort : TCP, UDP et ICMP.


### Adresses IP :

La section suivante traite les adresses IP et les numéros de port. Le mot `any` peut être utilisé pour définir "n'import quelle adresse". On peut utiliser l'adresse d'une seule machine ou un block avec la notation CIDR.

Un opérateur de négation peut être appliqué aux adresses IP. Cet opérateur indique à Snort d'identifier toutes les adresses IP sauf celle indiquée. L'opérateur de négation est le `!`.

Par exemple, la règle du premier exemple peut être modifiée pour alerter pour le trafic dont l'origine est à l'extérieur du réseau :

```
alert tcp !192.168.220.0/24 any -> 192.168.220.0/24 111
(content: "|00 01 86 a5|"; msg: "external mountd access";)
```

### Numéros de Port :

Les ports peuvent être spécifiés de différentes manières, y-compris `any`, une définition numérique unique, une plage de ports ou une négation.

Les plages de ports utilisent l'opérateur `:`, qui peut être utilisé de différentes manières aussi :

```
log udp any any -> 192.168.220.0/24 1:1024
```

Journaliser le traffic UDP venant d'un port compris entre 1 et 1024.


```
log tcp any any -> 192.168.220.0/24 :6000
```

Journaliser le traffic TCP venant d'un port plus bas ou égal à 6000.

```
log tcp any :1024 -> 192.168.220.0/24 500:
```

Journaliser le traffic TCP venant d'un port privilégié (bien connu) plus grand ou égal à 500 mais jusqu'au port 1024.


### Opérateur de direction

L'opérateur de direction `->`indique l'orientation ou la "direction" du trafique.

Il y a aussi un opérateur bidirectionnel, indiqué avec le symbole `<>`, utile pour analyser les deux côtés de la conversation. Par exemple un échange telnet :

```
log 192.168.220.0/24 any <> 192.168.220.0/24 23
```

## Alertes et logs Snort

Si Snort détecte un paquet qui correspond à une règle, il envoie un message d'alerte ou il journalise le message. Les alertes peuvent être envoyées au syslog, journalisées dans un fichier text d'alertes ou affichées directement à l'écran.

Le système envoie **les alertes vers le syslog** et il peut en option envoyer **les paquets "offensifs" vers une structure de repertoires**.

Les alertes sont journalisées via syslog dans le fichier `/var/log/snort/alerts`. Toute alerte se trouvant dans ce fichier aura son paquet correspondant dans le même repertoire, mais sous le fichier `snort.log.xxxxxxxxxx` où `xxxxxxxxxx` est l'heure Unix du commencement du journal.

Avec la règle suivante :

```
alert tcp any any -> 192.168.220.0/24 111
(content:"|00 01 86 a5|"; msg: "mountd access";)
```

un message d'alerte est envoyé à syslog avec l'information "mountd access". Ce message est enregistré dans `/var/log/snort/alerts` et le vrai paquet responsable de l'alerte se trouvera dans un fichier dont le nom sera `/var/log/snort/snort.log.xxxxxxxxxx`.

Les fichiers log sont des fichiers binaires enregistrés en format pcap. Vous pouvez les ouvrir avec Wireshark ou les diriger directement sur la console avec la commande suivante :

```
tcpdump -r /var/log/snort/snort.log.xxxxxxxxxx
```

Vous pouvez aussi utiliser des captures Wireshark ou des fichiers snort.log.xxxxxxxxx comme source d'analyse por Snort.

## Exercises

**Réaliser des captures d'écran des exercices suivants et les ajouter à vos réponses.**

### Essayer de répondre à ces questions en quelques mots, en réalisant des recherches sur Internet quand nécessaire :

**Question 1: Qu'est ce que signifie les "preprocesseurs" dans le contexte de Snort ?**

---

**Réponse :**  Permet d'étendre les fonctionnalités de Snort avant que celui-ci applique les règles de détection. On peut en particulier faire des analyses et des modifications supplémentaires sur le paquet déjà décodé. Ils agissent comme des plugs-in.

---

**Question 2: Pourquoi êtes vous confronté au WARNING suivant `"No preprocessors configured for policy 0"` lorsque vous exécutez la commande `snort` avec un fichier de règles ou de configuration "fait-maison" ?**

---

**Réponse :** Ce message apparaît car aucun pré-processeur n'a été configuré dans le fichier de configuration.

---

### Trouver du contenu :

Considérer la règle simple suivante:

alert tcp any any -> any any (msg:"Mon nom!"; content:"Rubinstein"; sid:4000015; rev:1;)

**Question 3: Qu'est-ce qu'elle fait la règle et comment ça fonctionne ?**

---

**Réponse :**  Alerte tout paquet TCP (quel que soit le port et quel que soit l'ip dans toutes les directions) contenant la chaîne de caractère"Rubinstein", le message de l'alerte sera "Mon nom!". Le sid précise la signature unique de l'alerte et rev donne la version de la règle.

---

Utiliser nano ou vim pour créer un fichier `myrules.rules` sur votre répertoire home (`/root`). Rajouter une règle comme celle montrée avant mais avec votre text, phrase ou mot clé que vous aimeriez détecter. Lancer Snort avec la commande suivante :

```
snort -c myrules.rules -i eth0
```

**Question 4: Que voyez-vous quand le logiciel est lancé ? Qu'est-ce que tous ces messages affichés veulent dire ?**

---

**Réponse :**  Cela nous permet de voir toutes les règles que Snort utilise, ainsi que l'endroit où sont stockées les rules, le fichier de logs, etc...


```
        --== Initializing Snort ==--
Initializing Output Plugins!
Initializing Preprocessors!
Initializing Plug-ins!
Parsing Rules file "root/myrules.rules"
Tagged Packet Limit: 256
Log directory = /var/log/snort

+++++++++++++++++++++++++++++++++++++++++++++++++++
Initializing rule chains...
1 Snort rules read
    1 detection rules
    0 decoder rules
    0 preprocessor rules
1 Option Chains linked into 1 Chain Headers
+++++++++++++++++++++++++++++++++++++++++++++++++++

+-------------------[Rule Port Counts]---------------------------------------
|             tcp     udp    icmp      ip
|     src       0       0       0       0
|     dst       0       0       0       0
|     any       1       0       0       0
|      nc       0       0       0       0
|     s+d       0       0       0       0
+----------------------------------------------------------------------------

+-----------------------[detection-filter-config]------------------------------
| memory-cap : 1048576 bytes
+-----------------------[detection-filter-rules]-------------------------------
| none
-------------------------------------------------------------------------------

+-----------------------[rate-filter-config]-----------------------------------
| memory-cap : 1048576 bytes
+-----------------------[rate-filter-rules]------------------------------------
| none
-------------------------------------------------------------------------------

+-----------------------[event-filter-config]----------------------------------
| memory-cap : 1048576 bytes
+-----------------------[event-filter-global]----------------------------------
+-----------------------[event-filter-local]-----------------------------------
| none
+-----------------------[suppression]------------------------------------------
| none
-------------------------------------------------------------------------------
Rule application order: pass->drop->sdrop->reject->alert->log
Verifying Preprocessor Configurations!

[ Port Based Pattern Matching Memory ]
+-[AC-BNFA Search Info Summary]------------------------------
| Instances        : 1
| Patterns         : 1
| Pattern Chars    : 9
| Num States       : 9
| Num Match States : 1
| Memory           :   1.64Kbytes
|   Patterns       :   0.05K
|   Match Lists    :   0.10K
|   Transitions    :   1.10K
+-------------------------------------------------
pcap DAQ configured to passive.
Acquiring network traffic from "eth0".
Reload thread starting...
Reload thread started, thread 0xffff9e9c2080 (36)
Decoding Ethernet

        --== Initialization Complete ==--

``` 

---

Aller sur un site web contenant dans son texte la phrase ou le mot clé que vous avez choisi (il faudra chercher un peu pour trouver un site en http... Si vous n'y arrivez pas, vous pouvez utiliser [http://neverssl.com](http://neverssl.com) et modifier votre  règle pour détecter un morceau de texte contenu dans le site).

Pour accéder à Firefox dans son conteneur, ouvrez votre navigateur web sur votre machine hôte et dirigez-le vers [http://localhost:4000](http://localhost:4000). Optionnellement, vous pouvez utiliser wget sur la machine client pour lancer la requête http ou le navigateur Web lynx - il suffit de taper `lynx neverssl.com`. Le navigateur lynx est un navigateur basé sur texte, sans interface graphique.
Chez moi, Linus, je n'arrive pas à entrer du texte si j'utilise le lien sous Firefox. Mais sous Safari et Chrome ça marche.

**Question 5: Que voyez-vous sur votre terminal quand vous chargez le site depuis Firefox ou la machine Client ?**

---

**Réponse :** On voit afficher dans le terminal : `WARNING: No preprocessors configured for policy 0.`

---

Arrêter Snort avec `CTRL-C`.

**Question 6: Que voyez-vous quand vous arrêtez snort ? Décrivez en détail toutes les informations qu'il vous fournit.**

---

**Réponse :**  

- Les statistiques sur le nombre de paquets reçus selon les protocoles
- Les paquets avec des mauvais checksum par exemple
- Le nombre d'actions effectuées comme les paquets acceptés, alertés, etc...
- Usage mémoire 
- I/O des paquets : nombre de paquets reçus / envoyés

---


Aller au répertoire /var/log/snort. Ouvrir le fichier `alert`. Vérifier qu'il y ait des alertes pour votre texte choisi.

**Question 7: A quoi ressemble l'alerte ? Qu'est-ce que chaque élément de l'alerte veut dire ? Décrivez-la en détail !**

---

**Réponse :**  

```
[**] [1:4000015:1] NeverSSL [**]
[Priority: 0] 
03/27-14:11:43.319320 34.223.124.45:80 -> 192.168.220.2:46918
TCP TTL:213 TOS:0x0 ID:48394 IpLen:20 DgmLen:1424 DF
***AP*** Seq: 0x2DF117F8  Ack: 0x7F904F0D  Win: 0xD2  TcpLen: 32
TCP Options (3) => NOP NOP TS: 1498928 2291762859 

[**] [1:4000015:1] NeverSSL [**]
[Priority: 0] 
03/27-14:11:43.319324 34.223.124.45:80 -> 192.168.220.4:46918
TCP TTL:212 TOS:0x0 ID:48394 IpLen:20 DgmLen:1424 DF
***AP*** Seq: 0x2DF117F8  Ack: 0x7F904F0D  Win: 0xD2  TcpLen: 32
TCP Options (3) => NOP NOP TS: 1498928 2291762859 
```

On voit la le SID de l'alerte, la priorité assignée à l'alerte, la date et l'heure, les adresses source/destination et le port, ainsi que des informations sur le paquet TCP.

---

### Detecter une visite à Wikipedia

Ecrire deux règles qui journalisent (sans alerter) chacune un message à chaque fois que Wikipedia est visité **SPECIFIQUEMENT DEPUIS VOTRE MACHINE CLIENT OU DEPUIS FIREFOX**. Chaque règle doit identifier quelle machine à réalisé la visite. Ne pas utiliser une règle qui détecte un string ou du contenu. Il faudra se baser sur d'autres paramètres.

**Question 8: Quelle est votre règle ? Où le message a-t'il été journalisé ? Qu'est-ce qui a été journalisé ?**

---

**Réponse :** 

```
log tcp 192.168.220.3 any <> 185.15.58.226  80 (sid:4000001; rev:1)
log tcp 192.168.220.4 any <> 185.15.58.226  80 (sid:4000002; rev:1)
log tcp 192.168.220.3 any <> 185.15.58.226  443 (sid:4000003; rev:1)
log tcp 192.168.220.4 any <> 185.15.58.226  443 (sid:4000004; rev:1)
```

C'est une règle qui détecte toute la communication entre les machines cliente (1ère IP) et Firefox (2nd IP) et l'adresse IP de `wikipedia.com` que nous avons trouvée en faisant un ping sur le nom de domaine.

La connexion ma générée un log (`/var/log/snort/snort.log.1679928796`). On y retrouve toutes les informations sur l'échanges entre la machine cliente et le serveur de Wikipedia.

---

### Détecter un ping d'un autre système

Ecrire une règle qui alerte à chaque fois que votre machine IDS **reçoit** un ping depuis une autre machine (n'import laquelle des autres machines de votre réseau). Assurez-vous que **ça n'alerte pas** quand c'est vous qui **envoyez** le ping depuis l'IDS vers un autre système !

**Question 9: Quelle est votre règle ?**

---

**Réponse :**   

```
alert icmp [192.168.220.0/24,![192.168.220.2]] any -> 192.168.220.2 any (msg:"Ping IDS";sid:4000005; rev:1;)
```

---


**Question 10: Comment avez-vous fait pour que ça identifie seulement les pings entrants ?**

---

**Réponse :** On doit spécifier que l'on détecte tous les pings venant de notre réseau (`192.168.220.0/24`) et ayant comme destination l'IDS (`192.168.220.2`). Sauf qu'il faut faire une exception sur les IPs sources sur l'adresse de l'IDS pour que tous ses pings ne soient pas pris en compte. 

---


**Question 11: Où le message a-t-il été journalisé ?**

---

**Réponse :** Il est journalisé dans le fichier `/var/log/snort/alert` comme vu précédemment :

```
[**] [1:4000005:1] Ping IDS [**]
[Priority: 0] 
03/27-15:10:27.557322 192.168.220.4 -> 192.168.220.2
ICMP TTL:64 TOS:0x0 ID:35477 IpLen:20 DgmLen:84
Type:0  Code:0  ID:12  Seq:2  ECHO REPLY
```

---

Les journaux sont générés en format pcap. Vous pouvez donc les lire avec Wireshark. Vous pouvez utiliser le conteneur wireshark en dirigeant le navigateur Web de votre hôte sur vers [http://localhost:3000](http://localhost:3000). Optionnellement, vous pouvez lire les fichiers log utilisant la commande `tshark -r nom_fichier_log` depuis votre IDS.

**Question 12: Qu'est-ce qui a été journalisé ?**

---

**Réponse :**  

On remarque que l'on voit bien les quelques pings que nous avons réalisés sur l'IDS. A savoir que nous avons aussi essayé de ping les clients depuis l'IDS et que ceux-ci n'apparaissent pas.

```
root@IDS:/# tshark -r /var/log/snort/snort.log.1679929782 
Running as user "root" and group "root". This could be dangerous.
    1   0.000000 192.168.220.4 ? 192.168.220.2 ICMP 98 Echo (ping) request  id=0x014c, seq=0/0, ttl=64
    2   1.000275 192.168.220.4 ? 192.168.220.2 ICMP 98 Echo (ping) request  id=0x014c, seq=1/256, ttl=64
    3   2.000438 192.168.220.4 ? 192.168.220.2 ICMP 98 Echo (ping) request  id=0x014c, seq=2/512, ttl=64
    4   3.000716 192.168.220.4 ? 192.168.220.2 ICMP 98 Echo (ping) request  id=0x014c, seq=3/768, ttl=64
    5   4.000895 192.168.220.4 ? 192.168.220.2 ICMP 98 Echo (ping) request  id=0x014c, seq=4/1024, ttl=64
    6  22.619829 192.168.220.3 ? 192.168.220.2 ICMP 98 Echo (ping) reply    id=0x000b, seq=1/256, ttl=64
    7  23.631345 192.168.220.3 ? 192.168.220.2 ICMP 98 Echo (ping) reply    id=0x000b, seq=2/512, ttl=64
    8  25.246950 192.168.220.4 ? 192.168.220.2 ICMP 98 Echo (ping) reply    id=0x000c, seq=1/256, ttl=64
    9  26.255309 192.168.220.4 ? 192.168.220.2 ICMP 98 Echo (ping) reply    id=0x000c, seq=2/512, ttl=64

```

---

### Detecter les ping dans les deux sens

Faites le nécessaire pour que les pings soient détectés dans les deux sens.

**Question 13: Qu'est-ce que vous avez fait pour détecter maintenant le trafic dans les deux sens ?**

---

**Réponse :** 

```
alert icmp [192.168.220.0/24] any <> 192.168.220.2 any (msg:"Ping IDS";sid:4000005; rev:1;)
```

```
[**] [1:4000005:1] Ping IDS  [**]
[Priority: 0] 
03/27-15:34:33.093256 192.168.220.3 -> 192.168.220.2
ICMP TTL:64 TOS:0x0 ID:15878 IpLen:20 DgmLen:84
Type:0  Code:0  ID:14  Seq:2  ECHO REPLY

[**] [1:4000005:1] Ping IDS  [**]
[Priority: 0] 
03/27-15:34:34.117204 192.168.220.2 -> 192.168.220.3
ICMP TTL:64 TOS:0x0 ID:50120 IpLen:20 DgmLen:84 DF
Type:8  Code:0  ID:14   Seq:3  ECHO
```

---


### Detecter une tentative de login SSH

Essayer d'écrire une règle qui Alerte qu'une tentative de session SSH a été faite depuis la machine Client sur l'IDS.

**Question 14: Quelle est votre règle ? Montrer la règle et expliquer en détail comment elle fonctionne.**

---

**Réponse :**  

```
alert tcp 192.168.220.3 any -> 192.168.220.2 22 (msg:"Connexion SSH depuis le client"; sid:4000008;rev:1;)
```

---


**Question 15: Montrer le message enregistré dans le fichier d'alertes.**

---

**Réponse :**  

```
[**] [1:4000008:1] Connexion SSH depuis le client [**]
[Priority: 0] 
03/27-16:26:41.969836 192.168.220.3:41896 -> 192.168.220.2:22
TCP TTL:64 TOS:0x10 ID:0 IpLen:20 DgmLen:52 DF
***A**** Seq: 0xBA4E88A3  Ack: 0x3BF42740  Win: 0x1F5  TcpLen: 32
TCP Options (3) => NOP NOP TS: 2355993391 2002753334 
```

---


### Analyse de logs

Depuis l'IDS, servez-vous de l'outil ```tshark```pour capturer du trafic dans un fichier. ```tshark``` est une version en ligne de commandes de ```Wireshark```, sans interface graphique.

Pour lancer une capture dans un fichier, utiliser la commande suivante :

```
tshark -w nom_fichier.pcap
```

Générez du trafic depuis le deuxième terminal qui corresponde à l'une des règles que vous avez ajoutées à votre fichier de configuration personnel. Arrêtez la capture avec ```Ctrl-C```.

**Question 16: Quelle est l'option de Snort qui permet d'analyser un fichier pcap ou un fichier log ?**

---

**Réponse :**  

```
snort –r <fichier.pcap>
```

---

Utiliser l'option correcte de Snort pour analyser le fichier de capture Wireshark que vous venez de générer.

**Question 17: Quelle est le comportement de Snort avec un fichier de capture ? Y-a-t'il une différence par rapport à l'analyse en temps réel ?**

---

**Réponse :**  On remarque que ça correspond au rapport de fin d'analyse qui nous est généré quand on stop Snort.

---

**Question 18: Est-ce que des alertes sont aussi enregistrées dans le fichier d'alertes?**

---

**Réponse :** Non aucune alerte ne peut être générée, car Snort n'était pas lancé. Et il n'enregistre pas les alertes basées sur des .pcap qu'on lui donne ça ne ferait pas beaucoup de sens.

---


### Contournement de la détection

Faire des recherches à propos des outils `fragroute` et `fragrouter`.

**Question 19: A quoi servent ces deux outils ?**

---

**Réponse :**  Les outils `fragroute` et `fragrouter` sont des utilitaires réseau qui permettent la fragmentation et la réassemblage de paquets IP. Ils sont souvent utilisés pour fragmenter les paquets dans le cadre d'intrusions afin d'éviter la détection par des IDS/IPS.

---


**Question 20: Quel est le principe de fonctionnement ?**

---

**Réponse :**  

Lorsqu'un paquet est envoyé sur un réseau, il est souvent divisé en plusieurs fragments pour faciliter son transport à travers les différents noeuds du réseau. Les outils fragroute et fragrouter interviennent à ce niveau pour modifier les fragments, les supprimer ou les ajouter, ou encore pour réassembler les fragments dans un ordre différent de celui d'origine.

Ces outils peuvent être utilisés pour réaliser des attaques de type "man-in-the-middle", en interceptant les paquets et en modifiant leur contenu avant de les transmettre à leur destination. Ils peuvent également être utilisés pour contourner les mécanismes de sécurité des réseaux, en fragmentant les paquets de manière à éviter leur détection par les pare-feux et les IDS (systèmes de détection d'intrusion).

---


**Question 21: Qu'est-ce que le `Frag3 Preprocessor` ? A quoi ça sert et comment ça fonctionne ?**

---

**Réponse :**  

C'est un module pour Snort. Il est conçu pour détecter et prévenir les attaques basées sur la fragmentation de paquets IP, notamment celles réalisées avec les outils `fragroute` et `fragrouter`.

Son fonctionnement repose sur la réassemblage des fragments de paquets IP. Contrairement à ces outils de fragmentation, il réassemble les fragments de manière à détecter les paquets malveillants qui ont été modifiés ou manipulés par les attaquants.

---


L'utilisation des outils ```Fragroute``` et ```Fragrouter``` nécessite une infrastructure un peu plus complexe. On va donc utiliser autre chose pour essayer de contourner la détection.

L'outil nmap propose une option qui fragmente les messages afin d'essayer de contourner la détection des IDS. Générez une règle qui détecte un SYN scan sur le port 22 de votre IDS.


**Question 22: A quoi ressemble la règle que vous avez configurée ?**

---

**Réponse :**  

```
alert tcp any any -> 192.168.220.2 22 (msg:"SYN SCAN"; flags:S; sid:4000030; rev:1;)
```

---

Pour cet exercice, vous devez d'abord désactiver le préprocesseur `frag3_global`, avant de le réactiver plus tard.
Le plus simple est d'ajouter un `#` au début de la ligne, ainsi elle est ignorée par snort.

Ensuite, servez-vous du logiciel nmap pour lancer un SYN scan sur le port 22 depuis la machine Client :

```
nmap -sS -p 22 192.168.220.2
```
Vérifiez que votre règle fonctionne correctement pour détecter cette tentative.

Ensuite, modifiez votre commande nmap pour fragmenter l'attaque :

```
nmap -sS -f -p 22 --send-eth 192.168.220.2
```

**Question 23: Quel est le résultat de votre tentative ?**

---

**Réponse :** La sortie dans les alertes de Snort pour la première commande est bien composée de la détection du `SYN SCAN` grâce à la règle mise en place. Et comme attendu, la second règle passe et ne se fait pas détectée.

---


Modifier le fichier `myrules.rules` pour que Snort utiliser le `Frag3 Preprocessor` et refaire la tentative.


**Question 24: Quel est le résultat ?**

---

**Réponse :** En ajoutant au fichier des règles `preprocessor frag3_global` et `preprocessor frag3_engine`. On remarque que maintenant le second scan est lui aussi détectée par Snort.  

---


**Question 25: A quoi sert le `SSL/TLS Preprocessor` ?**

---

**Réponse :**  

Il permet d'inspecter le trafic SSL/TLS chiffré pour détecter les tentatives d'exploitation ou d'attaques par injection de code malveillant à travers des connexions chiffrées.

Il utilise une approche de type "man-in-the-middle" pour intercepter et inspecter le trafic SSL/TLS. Il utilise une technique pour déchiffrer le trafic SSL/TLS en utilisant la clé privée du serveur (fournie par l'administrateur système) pour déchiffrer le trafic sans interrompre la communication.

---


**Question 26: A quoi sert le `Sensitive Data Preprocessor` ?**

---

**Réponse :**  

Il permet de rechercher des informations sensibles dans le trafic réseau, telles que des numéros de cartes de crédit, des numéros de sécurité sociale, des adresses e-mail ou des mots de passe en clair.

Il peut être configuré pour détecter ces informations sensibles en utilisant des RegEx. Elles sont utilisées pour rechercher des modèles de données sensibles dans les paquets réseau. Lorsqu'une correspondance est trouvée, une alerte est déclenchée pour signaler que des données sensibles ont été détectées.

---

### Conclusions


**Question 27: Donnez-nous vos conclusions et votre opinion à propos de snort**

---

**Réponse :**  

C'était de la découverte qui a bien permis de mettre en pratique la théorie vue en classe. Bien configuré avec les bonnes règles, les bonnes configurations c'est sûrement un outil très puissant. Après, on a cru comprendre que ce n'était pas forcément l'outil le plus utilisé sur le marché et on pense que ça serait sympa de pouvoir faire un comparatif.

---

<sub>This guide draws heavily on http://cs.mvnu.edu/twiki/bin/view/Main/CisLab82014</sub>
