# TP10 — Configuration automatique réseau, DNS multi-niveaux et mise en service

## Objectifs

À l’issue de ce TP, vous devez être capables de :

- comprendre comment une machine obtient automatiquement sa configuration (DHCP)
- identifier les paramètres nécessaires à une communication réseau
- configurer un serveur DHCP fonctionnel
- comprendre une résolution DNS simple et multi-niveaux
- analyser un dysfonctionnement réseau en manipulant des outils concrets

## Idée centrale

DHCP → IP → routage → DNS → service

Une erreur à une étape empêche l’accès final.

---

## Partie 0 — Mise en situation

```bash
docker compose down -v
docker compose up -d --build
```

Dans le conteneur client :

```bash
ip addr
ip route
ping 10.20.0.10
nslookup serveur1
curl http://serveur1:8000
```

### Travail demandé

Pour chaque commande :

- fonctionne / ne fonctionne pas
- ce que cela teste réellement

### Question

Quel type de problème semble empêcher le fonctionnement global ?

---

## Partie 1 — Diagnostic initial

### Travail demandé

Compléter :

Pour communiquer, une machine a besoin de :

- une adresse __________  
- une __________ par défaut  
- un serveur __________  

Lequel de ces éléments semble manquer ici ?

Quel mécanisme permet normalement d’obtenir ces informations automatiquement ?

---

## Partie 2 — Construction du DHCP

### Objectif

Configurer un serveur DHCP permettant au client d’être autonome.

### Étape 1 — Définir une plage IP

Réseau : 10.10.0.0/24

Travail demandé :  
Proposer une plage d’adresses valide (éviter réseau, broadcast, routeur)

---

### Étape 2 — Compléter la configuration DHCP

Dans dns1, fichier dnsmasq.conf :

```conf
dhcp-range=________________________
dhcp-option=3,____________________
dhcp-option=6,____________________
```

---

### Étape 3 — Tester

Dans le client :

```bash
dhclient eth0
```

Vérification :

```bash
ip addr
ip route
cat /etc/resolv.conf
```

### Travail demandé

Associer chaque information obtenue à la configuration DHCP correspondante.

---

## Partie 3 — Validation du système

```bash
docker compose restart client
dhclient eth0
ping serveur1
nslookup serveur1
curl http://serveur1:8000
```

### Travail demandé

Compléter :

ping serveur1 vérifie : ______________________  
nslookup serveur1 vérifie : __________________  
curl serveur1 vérifie : ______________________  

### Question

Pourquoi ces trois tests sont-ils complémentaires ?

---

## Partie 4 — DHCP en pratique

### Libération de l’adresse

```bash
dhclient -r eth0
ip addr
```

Travail demandé :  
Que devient l’adresse IP après cette commande ?

---

### Renouvellement

```bash
dhclient -v eth0
```

Travail demandé :  
Que montre l’option -v ?

---

### Observation réseau

Dans dns1 :

```bash
tcpdump -i eth0 -n port 67 or port 68
```

Relancer DHCP côté client.

Travail demandé :  
Associer les paquets observés aux actions du client.

### Question

Pourquoi le client utilise-t-il un broadcast au début ?

---

## Partie 5 — DNS multi-niveaux

### Situation

- dns1 ne connaît pas serveur1  
- dns2 connaît serveur1  

### Configuration

dns1 :

```conf
server=/serveur1/10.20.0.54
```

dns2 :

```conf
address=/serveur1/10.20.0.10
```

### Test

```bash
nslookup serveur1
```

### Travail demandé

Compléter :

1. Le client interroge : __________  
2. Ce serveur contacte : __________  
3. La réponse provient de : ________  

---

### Observation réseau

```bash
tcpdump -i eth0 port 53
```

Travail demandé :  
Quel serveur fournit réellement la réponse ?

---

## Partie 6 — Comportement dynamique DNS

Modifier dns2 pour changer l’IP retournée.

### Test

```bash
nslookup serveur1
curl serveur1
```

### Travail demandé

Pourquoi le résultat change-t-il sans modifier le client ?

---

## Partie 7 — Multi-DNS et fallback

Configurer DHCP pour fournir deux DNS.

### Test 1

```bash
docker compose stop dns1
nslookup serveur1
```

Travail demandé :  
Pourquoi la résolution fonctionne encore ?

---

### Test 2

```bash
nslookup serveur1
curl serveur1
```

Travail demandé :  
Quel serveur DNS est utilisé ? Pourquoi ?

---

## Partie 8 — Injection d’erreurs

### Cas 1 — mauvaise gateway

```bash
ping 10.20.0.10
```

Travail :  
Pourquoi cela ne fonctionne pas ?

---

### Cas 2 — mauvais DNS

```bash
ping IP
curl serveur1
```

Travail :  
Expliquer la différence de comportement.

---

### Cas 3 — plage DHCP incorrecte

```bash
dhclient eth0
ip addr
```

Travail :  
Pourquoi l’adresse est incorrecte ?

---

### Cas 4 — DNS partiellement fonctionnel

```bash
nslookup serveur1
curl serveur1
```

Travail :  
Identifier précisément le problème.

---

## Conclusion

Compléter :

DHCP permet de __________________________  
DNS permet de ___________________________  
HTTP permet de __________________________  

Une erreur dans DHCP peut entraîner :

_________________________________________
