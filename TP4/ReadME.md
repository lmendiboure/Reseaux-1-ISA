
# TP4 — Automatiser la configuration réseau : DHCP
## Comprendre comment les machines obtiennent automatiquement une adresse IP

---

# Objectifs pédagogiques

À la fin de ce TP, vous devez être capables de :

- expliquer pourquoi DHCP existe
- décrire le fonctionnement du protocole DHCP (cycle DORA)
- comprendre pourquoi DHCP utilise des broadcasts
- configurer un serveur DHCP sur un routeur
- observer les échanges DHCP avec Wireshark
- analyser les informations distribuées aux clients

---

# Architecture utilisée

```
[ PC Client ]
     |
   Wi-Fi
     |
[ Raspberry Pi Routeur ]
     |
   Ethernet
     |
[ Raspberry Pi Serveur ]
```

Sous-réseaux :

- Wi-Fi : 192.168.10.0/24  
- LAN serveur : 192.168.42.0/24

Le routeur devient serveur DHCP.

---

# PARTIE 1 — Pourquoi DHCP existe-t-il ?

Jusqu’ici vous configuriez manuellement :

- adresse IP
- masque
- passerelle
- DNS

Exemple :

IP : 192.168.10.2  
Masque : 255.255.255.0  
Passerelle : 192.168.10.1

Maintenant, configurer deuxs machines avec :

192.168.10.10  
192.168.10.11  

Tester la communication avec ping.

Configurer ensuite volontairement deux machines avec la même adresse IP.

Questions :

1. Que se passe-t-il lorsque deux machines ont la même IP ?
2. Comment détecter ce problème ?
3. Est-il réaliste de configurer manuellement des centaines de machines ?

---

# PARTIE 2 — Principe du protocole DHCP

DHCP signifie Dynamic Host Configuration Protocol.

Il permet à un client d’obtenir automatiquement :

- adresse IP
- masque
- passerelle
- DNS
- durée du bail

Cycle DHCP :

Discover → le client cherche un serveur  
Offer → le serveur propose une adresse  
Request → le client demande cette adresse  
Ack → le serveur confirme

Schéma :

Client → DHCPDISCOVER (broadcast)  
Serveur → DHCPOFFER  
Client → DHCPREQUEST  
Serveur → DHCPACK

Question :

Pourquoi le premier message est-il envoyé en broadcast ?

---

# PARTIE 3 — Installer un serveur DHCP

Sur le routeur :

```console
sudo apt update  
sudo apt install dnsmasq
```

Configurer :

```console
sudo nano /etc/dnsmasq.conf
```

Ajouter :

```console
interface=wlan0  
dhcp-range=192.168.10.50,192.168.10.100,12h
```

Redémarrer :

```console
sudo systemctl restart dnsmasq
```

Vérifier :

```console
sudo systemctl status dnsmasq
```

---

# PARTIE 4 — Obtenir automatiquement une adresse IP

Sur le client :

supprimer la configuration IP manuelle

puis lancer :

```console
sudo dhclient
```

Observer :

ip addr  
ip route

Questions :

1. Quelle adresse IP a été attribuée ?
2. Quelle passerelle a été configurée ?
3. Est-ce cohérent avec la configuration DHCP ?

---

# PARTIE 5 — Observer DHCP avec Wireshark

Lancer une capture sur l’interface Wi‑Fi.

Puis renouveler l’adresse :

```console
sudo dhclient -r  
sudo dhclient
```

Identifier :

DHCP Discover  
DHCP Offer  
DHCP Request  
DHCP Ack

Compléter :

| Message | IP source | IP destination | Port source | Port destination |
|--------|-----------|---------------|-------------|-----------------|

Questions :

1. Pourquoi l’IP source est parfois 0.0.0.0 ?
2. Pourquoi la destination est 255.255.255.255 ?
3. Pourquoi DHCP utilise UDP ?

---

# PARTIE 6 — Informations distribuées par DHCP

DHCP peut fournir :

- adresse IP
- masque
- passerelle
- DNS
- durée du bail

Ajouter un DNS dans dnsmasq.conf :

```console
dhcp-option=6,8.8.8.8
```

Redémarrer dnsmasq.

Vérifier côté client :

```console
cat /etc/resolv.conf
```

Questions :

1. Le DNS a‑t‑il été configuré automatiquement ?
2. Quelle différence avec une configuration manuelle ?

---

# PARTIE 7 — Observer les baux DHCP

Sur le routeur :

```console
cat /var/lib/misc/dnsmasq.leases
```

Observer :

- adresse IP
- adresse MAC
- durée du bail

Questions :

1. Pourquoi le serveur garde‑t‑il cette liste ?
2. Que se passe‑t‑il lorsqu’un client se reconnecte ?

---

# BONUS

## Réservation DHCP

Associer une adresse MAC à une IP fixe :

```console
dhcp-host=AA:BB:CC:DD:EE:FF,192.168.10.20
```

## Observer le renouvellement de bail

sudo dhclient -v

## Simuler une panne DHCP

sudo systemctl stop dnsmasq  
sudo dhclient

---

# Conclusion

Votre architecture réseau possède maintenant :

- routage
- NAT
- redirection de ports
- configuration automatique des clients (DHCP)

Vous avez construit une infrastructure réseau similaire à celle d’un réseau domestique réel.
