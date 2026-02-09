# TP 1 — Du réseau contraint au réseau maîtrisé  
## Proxy HTTP, LAN minimal et service SSH

---

## Objectifs généraux du TP

Ce TP a pour objectif de vous faire comprendre comment une machine communique réellement sur un réseau, en distinguant clairement :

- ce qui relève de la configuration IP (interfaces, adresses, routes),
- ce qui relève des applications (navigateurs, clients HTTP, outils réseau),
- ce qui relève des services réseau (processus écoutant sur des ports).

On se concentre donc une nouvelle fois sur la compréhension (indirecte) du modèle OSI mais via une vraie mise en application.

Vous travaillerez successivement sur :

1. un **réseau institutionnel/universitaire contraint**, que vous ne maîtrisez pas (proxy),
2. un **réseau local minimal**, que vous maîtrisez entièrement,
3. un **service réseau réel**, observé à bas niveau (SSH) et mis en oeuvre sur votre réseau local à base de Raspberry Pi.

---

## Outils utilisés

On va lister ici certains outils dont il peut être utile de se soutenir et qui seront réutilisés/dont la liste sera mise à jour dans les prochaines séainces:

- `ip`, `ping`, `arp`, `ip neigh`, `ss`
- `curl`, `wget`, `nc`, `ssh`
- Wireshark

---

# TEMPS 1 — Réseau de l’école et proxy HTTP  
*(Comprendre un réseau que l’on ne maîtrise pas)*

---

## 1.1 — Observer la configuration réseau locale

On va ici chercher à identifier comment la machine est configurée au niveau IP, indépendamment de toute application ou d’Internet. 

Pour ce faire, on va connecter le Raspberry Pi au réseau Ethernet de l'Université (en lieu et place des ordinateurs de la salle) et observer ce qui se passe.

En théorie, étant actuellement connectés au réseau VLAN étudiant de l'université, nous ne devrions pas être en mesure d'accéder à internet mais... Vérifions le ! 

### Commandes

Une fois connectés, commençons par tester quelques commandes pour voir ce qu'il se passe.

```bash
ip addr
```

`ip addr` affiche :

- les interfaces réseau de la machine,
- les adresses IP associées,
- les masques réseau,
- l’état des interfaces (UP / DOWN).

Cette commande permet de répondre à la question fondamentale :  “Quelle est l’identité réseau de ma machine ?”

```bash
ip route
```

`ip route` affiche la table de routage (couche 3 donc !), c’est-à-dire :

- comment la machine décide où envoyer les paquets IP,
- quelle est la passerelle par défaut,
- quels réseaux sont atteignables directement.

### Questions

- La machine a-t-elle une IP valide ?
- Est-elle dans un réseau privé ou public ?
- Quelle est la passerelle par défaut ?
- Peut-on déduire l’accès à Internet uniquement avec `ip route` ?

---

## 1.2 — Tester la connectivité IP et applicative

```bash
ping 8.8.8.8
```

`ping` utilise ICMP, un protocole de diagnostic. Pour rappel, il permet de vérifier :

- que la machine peut envoyer des paquets IP,
- que le routage IP fonctionne,
- qu’un hôte distant est joignable.

MAIS..... Un ping réussi ne garantit PAS l’accès Internet applicatif.

```bash
ping google.com
```

Cette commande ajoute une étape préalable que nous avons également vue en cours (le passage NOM - IP) :

1. résolution DNS,
2. puis échange ICMP.

Si cela échoue alors que `ping 8.8.8.8` fonctionne, le problème n’est pas IP, mais DNS (on a donc changé de niveau...).

Une dernière commande à tester ? Ou, alternativement essayez simplement d'accéder à une page internet en ouvrant votre navigateur.

```bash
curl -X POST https://httpbin.org/post \
     -H "Content-Type: application/json" \
     -d '{"name":"alice","role":"test"}'
```

`curl` est un client HTTP :

- il teste un service applicatif réel,
- il dépend des politiques réseau (proxy, filtrage).

httpbin.org est couramment utilisé pour des tests car il est fait pour ça. Le serveur renvoie ce qu’il a reçu, si on a une réponse c'est donc que cela fonctionne !

### Questions

Est ce que des commandes ont fonctionné ici ? Si oui, lesquelles ? 

---

## 1.3 — Comprendre et configurer le proxy

On va maintenant chercher à comprendre que le proxy agit au niveau applicatif, et pas au niveau IP.

### Configuration du proxy

Tout d'abord, vérifions que pour l'instant aucun proxy n'a été configuré sur cette machine :  
```bash
env | grep -i proxy
```

Dans le fichier `~/.bashrc` on va ajouter les commandes suivantes qui permettront de dire à la machine "utilise ce proxy pour les communications HTTP comme pour celles HTTPS" :

```bash
export http_proxy="http://cache.univ-pau.fr:3128"
export https_proxy="http://cache.univ-pau.fr:3128"
```

Pourquoi dans `.bashrc` ?

- ce fichier est lu à chaque ouverture de shell,
- il définit des variables d’environnement,
- ces variables sont héritées par les programmes lancés depuis ce shell.

Lorsque vous avez besoin d'alias ou autres, n'hésitez pas non plus à utiliser ce fichier...

On va ensuite le recharger sans avoir à démarrer le terminal :

```bash
source ~/.bashrc
```
Puis vérifions si cela a été bien pris en compte : 

```bash
env | grep -i proxy
```


---

## 1.4 — Observer l’impact réel du proxy

Retentons la commande curl de toute à l'heure, fonctionne-t-elle à présent ?

Ce qu'il faut comprendre ici ? Le proxy **ne modifie pas le chemin IP, il modifie **le comportement des applications.

---

## 1.5 — Observation avec Wireshark

Pour finir on va chercher à observer la différence entre le chemin logique et le chemin IP réel.

Pour ce faire:

- Configurer le navigateur (firefox ou autre) pour qu'il aille par défaut utiliser le proxy
- Lancer une capture Wireshark
- Connectez vous à n'importe quel site depuis le navigateur

Ce que vous devriez observer en théorie ?
- la destination IP est celle du proxy,
- le serveur final n’est jamais contacté directement,
- le trafic HTTP est encapsulé dans un échange proxy.

Il y a donc une différence entre ce que l’application croit faire et ce que le réseau fait réellement.

---

# TEMPS 2 — Réseau local minimal (LAN autonome)  

À partir de maintenant, le proxy n’intervient plus du tout. On va simplement chercher à connecter entre eux deux Raspberry Pi via un lien Ethernet : Rasp 1 --- Rasp 2.


## 2.1 — Configuration IP manuelle

Ici nous allons créer un réseau simple : sans DHCP, sans routeur, sans infrastructure. Ceds différents éléments seront introduits petit à petit dans les prochaines séances...

Sur Rasp 1, lancez les commandes suivantes ; 

```bash
ip addr add 192.168.42.1/24 dev eth0
ip link set eth0 up
```

Faites de même sur Rasp 2 :
```bash
ip addr add 192.168.42.2/24 dev eth0
ip link set eth0 up
```

Ce que ça va nous permettre de faire ?

- `ip addr add` : assigne une IP à une interface,
- `ip link set up` : active l’interface.

---

## 2.2 — Tester et observer ARP

Sur Rasp 1, après avoir lancé une capture dans wireshark :
```bash
ping 192.168.42.2
```
On devrait donc observer :
1. résolution ARP,
2. puis échange ICMP.

Une autre façon de l'observer : 
```bash
ip neigh
```

Elle affiche la table ARP dont  nous avons déjà discuté à plusieurs reprises :

- correspondance IP ↔ MAC,
- uniquement pour les hôtes du LAN.

Sans ARP, aucune communication IP locale n’est possible.

---

## 2.3 — Sous-réseaux différents : comprendre l’échec

On va à présent modifier une IP pour sortir du sous-réseau.

Si l'on se focalise sur Rasp 2, quelle adresse IP peut on lui mettre pour être sûr qu'il n'appartienne plus au même sous réseau ?

**Note :** Pour pouvoir observer les modifications, il va falloir que l'on supprime côté Rasp 1 ce que l'on avait enregistré jusqu'ici, on peut le faire avec la commande : `sudo ip neigh flush all`

En lançant un enregistrement Wireshark, est ce que l'on observe toujours des messages ARP lors d'un ping de Rasp 1 vers Rasp 2 après cette modification ? Pourquoi ?

Pour rappel : 
- la machine décide localement si la destination est locale ou distante,
- si elle est distante, elle cherche un routeur,
- ici, aucun routeur n’existe ! La communication inter-réseaux n'est donc pas possible.

---

# TEMPS 3 — SSH : observer un service réseau réel

On va à présent chercher à mettre en oeuvre et observer un service réseau réel. Nous allons plus particulièrement nous concentrer sur ssh que vous avez normalement observé dans d'autres cours : une méthode permettant d'envoyer, de manière sécurisée, des commandes à un ordinateur sur un réseau non sécurisé. SSH utilise la cryptographie pour authentifier et chiffrer les connexions entre les appareils. SSH permet également la tunnellisation, ou la redirection de ports, permettant aux paquets de traverser des réseaux qu'ils ne pourraient pas traverser autrement. SSH est souvent utilisé pour contrôler des serveurs à distance, pour la gestion de l'infrastructure et les transferts de fichiers.

---

## 3.1 — Vérifier un service qui écoute

Comme on l'a indiqué en cours, un service réseau correspond à un processus et un port auquel celui-ci est rattaché. 

`ssh` est généralement lancé sur le port 22. Qu'en est il actuellement sur Rasp 2 ? Est ce que le service ssh est bien lancé ?

```bash
ss -tlnp | grep :22
```

Pour rappel, `ss` permet de
- afficher les sockets réseau,
- voir quels ports sont ouverts,
- identifier les processus associés.

En utilisant "grep :22" on dit : "sors nous uniquement les lignes contenant cela".

---

Ayant constaté que le service n'était pour l'heure pas lancé, on va pouvoir le rendre opérationnel avec la commande suivante : 

```bash
sudo systemctl start ssh
```

## 3.2 — Connexion SSH et observation avec Wireshark

De retour sur le rasp 1, après avoir une nouvelle fois nettoyé la table ARP (`sudo ip neigh flush all`), et réouvert Wireshark, nous allons nous connecter en ssh sur l'utilisateur qui y existe :  

```bash
ssh utilisateur@192.168.42.2
```

Faisons attention à utiliser le bon user...

Ce que ssh implique normalement ? Beaucoup de processus... 

- TCP
- port 22
- authentification
- chiffrement

On est donc censés pouvoir observer beaucoup de choses : 

- ARP,
- handshake TCP,
- flux chiffré (contenu illisible).

Le réseau est donc là pour le transport mais n'a pas du tout la main sur le contenu géré lui au niveau de l'application.

---

## 3.4 — Comparaison avec netcat

Si à présent on lance les commandes suivantes (bien sûr en faisant attention de lancer un client d'un côté et le serveur de l'autre !).

```bash
nc -l 2222
nc 192.168.42.2 2222
```

Si on essaye d'observer les paquets, quelles différences avec ce qui existait en ssh ? On est ici sur une communication TCP directe.

---

# Synthèse finale attendue

Vous devez être capables d’expliquer :

- pourquoi le proxy ne modifie pas `ip route`,
- pourquoi ARP est indispensable dans un LAN,
- pourquoi deux sous-réseaux ne communiquent pas sans routeur,
- ce que SSH ajoute au-dessus de TCP,
- la différence entre connectivité IP et service applicatif.

---

## Bonus (pour les plus rapides)

On peut pour aller plus loin essayer de réaliser diverses modifications intéressantes à observer.

Tout d'abord, nous pouvons **changer le port ssh** : 

Sur le Rasp 2 dans le fichier `/etc/ssh/sshd_config`, modifiez Port `2222` puis relancez le service : `sudo systemctl restart ssh`.

Depuis le Rasp 1, testez une connexion avec la commande suivante (en faisant toujours attention à l'utilisateur) : `ssh -p 2222 utilisateur@192.168.42.2` 

Est-ce que l'on observe ou non des différences avec le premier cas dans wireshark ?

L'idée est principalement de comprendre que bien que ssh ait un port par défaut, on peut aussi imaginer le faire fonctionner sur un autre port de la machine sans que cela ne pose de problème.

On peut aussi introduire une première idée de **filtrage** et **bloquer temporairement SSH (port 22)** avec `iptables`.

En d'autres termes on va chercher à montrer qu’un service réseau peut être rendu indisponible sans changer l’IP, ni le routage, juste via une règle de filtrage.

Pour ce faire on va commencer par remettre les choses en l'état initial en remettant ssh sur son port standard (et en vérifiant avec la commande ss que c'est bien le cas).

Sur Rasp 2, on ajoute maintenant une règle qui drop les connexions TCP entrantes vers le port 22 :

```bash
sudo iptables -I INPUT -p tcp --dport 22 -j DROP
```

On va derrière afficher les règles pour vérifier que c'est bien le cas :

```bash
sudo iptables -L INPUT -n -v --line-numbers
```

Retendez depuis Rasp 1 une connexion ssh. Qu'observez vous dans Wireshark ? Qu'est ce qui est différent ? Quelle interprétation ?

On va à présent remplacer DROP par REJECT pour voir une autre signature réseau.

Sur Rasp 2, on supprime donc la règle DROP (en théorie en première position) :

```bash
sudo iptables -D INPUT 1
```

On ajoute à la place une règle REJECT :

```bash
sudo iptables -I INPUT -p tcp --dport 22 -j REJECT --reject-with tcp-reset
```

Testez à nouveau depuis Rasp 1. Est-ce que ce que l'on observe est le même comportement ? Si non, quelle différence ?

**Avant de partir, pensez à remettre les choses en l'état pour éviter de rencontrer des problèmes lors de la prochaine séance...**
