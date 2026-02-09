# TP 2 — Routage IP et NAT  
## Faire transiter un service à travers un routeur

---

## Objectifs généraux du TP

Ce TP vise à comprendre comment un paquet IP traverse un équipement intermédiaire et à distinguer clairement :

- le routage IP (décision de transfert),
- le NAT (modification volontaire des adresses),
- le rôle d’un routeur par rapport à une machine finale.

À l’issue du TP, vous devrez être capables d’expliquer :

- pourquoi deux sous-réseaux IP distincts ne communiquent pas spontanément,
- comment transformer un Raspberry Pi en routeur IP,
- ce que change (et ne change pas) l’activation du NAT,
- ce que voit réellement un serveur distant.

---

## Outils utilisés

Quelques-uns de supplémentaires ici par rapport à la dernière séance...

- `ip`, `ip route`, `ip neigh`
- `ping`, `ssh`, `ss`
- `sysctl`, `iptables`
- Wireshark
- `hostapd`

---

## Architecture du TP

Là aussi on va avoir des modifications à observer. On quitte notre simple réseau LAN à deux machines vers un réseau dans lequel plus de machines pourront intervenir : 

```
[ PC client ]
   IP statique
   Wi-Fi
      |
[ Raspberry Pi #2 ]
   Point d’accès Wi-Fi
   Routeur IP
   NAT optionnel
      |
   Ethernet
      |
[ Raspberry Pi #1 ]
   Serveur SSH
```

Le Wi-Fi est utilisé comme LAN local.  

---

## Plan d’adressage imposé

Celui-ci va devoir être mis en oeuvre pour que le fonctionnement du système de bout en bout puisse être garanti :

| Équipement | Interface | Adresse IP |
|----------|-----------|------------|
| PC client | Wi-Fi | 192.168.10.2/24 |
| RPi #2 (routeur) | wlan0 | 192.168.10.1/24 |
| RPi #2 (routeur) | eth0 | 192.168.42.1/24 |
| RPi #1 (serveur) | eth0 | 192.168.42.2/24 |

---

# TEMPS 1 — Mise en place du point d’accès Wi-Fi  

---

## 1.1 — Principe à comprendre

Contrairement à Ethernet, une interface Wi-Fi possède un rôle qui peut varier en fonction des situations :

- client (généralement le cas sur nos machines),
- point d’accès (auquel nous nous connectons).

Ce rôle est géré par des démons système, pas par la commande `ip`.

Pour maîtriser le réseau, nous allons ici faire en sorte de forcer explicitement le rôle point d’accès pour le Rasp 2 dans notre architecture.

---

## 1.2 — Désactiver la gestion automatique du Wi-Fi

Si on veut pouvoir agir "manuellement/en ligne de commande sur le WiFi" on va devoir réduire le périmètre d'action de **NetworkManager**. Pour en savoir plus sur ce service mis en oeuvre sur quasi tous les systèmes Linux ? https://networkmanager.dev/ 

Vérifier que NetworkManager est actif :

```bash
systemctl status NetworkManager
```

Si c'est bien le cas, créez le fichier suivant :

```bash
sudo nano /etc/NetworkManager/conf.d/unmanaged-wlan.conf
```

Avec le contenu suivant (**où INT doit être remplacé par le nom de l'interface WiFi sur le Raspberry**) :

```ini
[keyfile]
unmanaged-devices=interface-name:INT
```

Vous allez ensuite pouvoir redémarrer NetworkManager :

```bash
sudo systemctl restart NetworkManager
```

À partir de maintenant, le système ne gère plus wlan0 automatiquement, il vaudra mieux ne plus avoir besoin d'un accès internet ou alors être connecté en Ethernet (ce qui sera peut-être nécessaire dans 2 étapes...).

---

## 1.3 — Configuration IP manuelle de l’interface Wi-Fi

On va maintenant définir comme suit les informations de l'interface Wi-Fi :
```bash
sudo ip addr flush dev wlan0 # on supprime les adresses qui pouvaient être attachés à cette interface
sudo ip addr add 192.168.10.1/24 dev wlan0 # on définit l'adresse
sudo ip link set wlan0 up # on lance l'interface
```
Pourquoi à votre avis utilise-t-on une adresse en **.1** ?

Vous pouvez vérifier que la commande que vous venez d'appliquer a bien fonctionné :

```bash
ip addr show wlan0
```

---

## 1.4 — Installation et configuration de `hostapd`

Si on veut pouvoir lancer un point d'accès WiFi sur notre interface, on va pour cela avoir besoin d'un outil particulier : `hostapd` (plus d'infos : https://doc.ubuntu-fr.org/hostapd).

Pour cela, commençons par l'installation :

```bash
sudo apt update
sudo apt install hostapd
```

On va ensuite créer le fichier de configuration :

```bash
sudo nano /etc/hostapd/hostapd.conf
```

Avec le contenu minimal suivant qui contient des informations sur la norme WiFi que l'on souhaite utiliser, les canaux que l'on souhaite utiliser, etc. **Faites attention à utiliser un ID unique pour votre groupe afin d'éviter les conflits !**

```ini
interface=wlan0
driver=nl80211
ssid=TP-Reseau-ID
hw_mode=g
channel=6
auth_algs=1
wmm_enabled=0
```

on va également avoir besoin de déclarer le fichier de configuration pour que le service sache où aller le chercher :

```bash
sudo nano /etc/default/hostapd
```

Dans lequel on ajoute le chemin vers le fichier que l'on vient de créer (**n'oubliez pas de compléter !**) :

```bash
DAEMON_CONF="............/hostapd.conf"
```

En toute logique on peut à présent lancer le point d’accès :

```bash
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl start hostapd
```

Et vérifier qu'il est bien opérationnel:

```bash
systemctl status hostapd
```

Le réseau **TP-Reseau-ID** doit être à présent visible sur les postes clients.

---

# TEMPS 2 — Configuration manuelle du client Wi-Fi

Sur le PC client (Linux ou macOS) on va avoir besoin manuellement d'aller indiquer les éléments suivants dans la "connexion WiFi" :

- Adresse IP : `192.168.10.2`
- Masque : `255.255.255.0`
- Passerelle : `192.168.10.1`
- DNS : inutile pour ce TP

On devrait ensuite pouvoir tester le fonctionnement :

```bash
ping 192.168.10.1
```

Le PC communique donc en toute logique avec le routeur, mais pas encore avec le serveur.

---

# TEMPS 3 — Mise en place du LAN serveur

---

## 3.1 — Configuration du serveur SSH (RPi #1)

On va maintenant s'occuper de la partie filaire. Pour cela tout comme durant la dernière séance  on va réaliser les opérations suivantes : 1à définir l'adresse à 192.168.42.2/24 et lancer l'interface.

```bash
sudo ip addr add 192.168.42.2/24 dev eth0
sudo ip link set eth0 up
```

On peut vérifier que c'est bien effectif avec la ommande suivante :

```bash
ip addr
ip route
```

On peut également vérifier le service ssh et le relancer au besoin : 

```bash
ss -tlnp | grep :22
```

---

## 3.2 — Configuration Ethernet du routeur (RPi #2)

De la même manière on peut configurer côté Rasp 1 avec : 192.168.42.1/24

Et tester que cela fonctionne bien :

```bash
ping 192.168.42.2
```

En théorie, chaque lien individuel doit donc bien être opérationnel !

---

# TEMPS 4 — Constater l’échec sans routage

Depuis le PC client on va essayer de vior ce qui se passe :

```bash
ping 192.168.42.2
ssh utilisateur@192.168.42.2
```

Pour ce faire, lancez Wireshark sur le routeur, qu'observez vous ? Qu'est ce que le routeur fait des paquets ? Les reçoit il bien ?

---

# TEMPS 5 — Activer le routage IP

---

On va à présent essayer de corriger ce problème !

## 5.1 — Vérifier l’état du routage

Pour ce faire, on va vérifier l'état du routage côté Rasp routeur :

```bash
sysctl net.ipv4.ip_forward
```

Quelle valeur observe-t-on ? Si c'est un 0 ça signifie que le routage n'est pas activité, si c'est un 1 à contrario il l'est bien.

---

## 5.2 — Activer le routage

On va maintenant activer le routage pour résoudre ce problème :

```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

Le Raspberry devient doncc de ce fait un **routeur IP**.

Si on reteste maintenant les choses avec une tentative côté PC utilisateur, arrive-t-on à pinger le serveur ssh ? Est ce que toute la chaine est opérationnelle ? On va avoir besoin d'un wireshark sur deux interfaces en même temps ! (WiFi et Ethernet)

---

## 5.3 — Ajouter la route de retour côté serveur

Sur le serveur pour pallier au nouveau problème rencontré on va ajouter des indications :

```bash
sudo ip route add 192.168.10.0/24 via 192.168.42.1
```

A quoi est ce que cela correspond ? Pourquoi est ce nécessaire ?

---

## 5.4 — Tester le routage

Depuis le PC on va à présent voir si on s'en est sorti :

```bash
ping 192.168.42.2
ssh utilisateur@192.168.42.2
```

La communication fonctionne donc sans NAT.

---

# TEMPS 6 — Observation du routage

Sur le routeur on va à nouveau essayer d'observer la chaine de bout en  bout :

- capture Wireshark sur `wlan0`
- capture Wireshark sur `eth0`

Qu'est ce que l'on est censés observer ici ?

- mêmes adresses IP source/destination,
- pas de modification des paquets,
- ARP distinct de chaque côté.

Le routage ne modifie pas les paquets IP.

---

# TEMPS 7 — Introduction du NAT

---

Notre système est opérationnel parce que nous avons indiqué côté routeur SSH comment retransférer le traffic reçu depuis une autre IP, ce qui est peu réaliste dans la pratique...

Nous allons donc chercher à aller au-delà de ce problème en activant le NAT ! 

Vous rappelez vous bien de quoi il s'agit ?

## 7.1 — Activer le NAT

Sur le routeur pour l'activer on va utiliser la commande suivante :

```bash
sudo iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -o eth0 -j MASQUERADE
```

Qu'est ce qu'elle veut dire concrètement ? "Quand des paquets sortent du réseau local 192.168.10.0/24 vers l’extérieur par l’interface eth0, réécris leur adresse IP source avec l’adresse IP de eth0."

---

## 7.2 — Tester avec NAT actif

Testons à nouveau côté PC client le fonctionnement de bout en bout, est ce qu'avec le NAT le système est toujours opérationnel ? Quel est à votre avis la différence qui existe dans Wireshark côté serveur ?

---

## 7.3 — Observer côté serveur

Sur le serveur on va donc vouloir observer le changement, pour ce faire, on peut utiliser la commande suivante :

```bash
ss -tn
```

A quoi correspond à présent l'adresse source ? Est-ce qu'il y a des changements dans notre système ?

---

# Synthèse finale attendue

Vous devez être capables d’expliquer :

- le rôle de `ip_forward`,
- pourquoi une route de retour est nécessaire sans NAT,
- ce que le NAT modifie réellement,
- pourquoi le NAT est omniprésent sur Internet,
- pourquoi le NAT n’est pas un mécanisme de sécurité.

---

## Bonus (pour les plus rapides)

Vous pouvez essayer de faire les actions suivantes et d'observer leur impact

- Désactiver le NAT à chaud et observer l’impact,
- Supprimer la route de retour et diagnostiquer l’échec,
- Comparer `ping` et `ssh` à travers le routeur.

---

