# TP6 — Réseaux virtualisés avec Docker : IP, DNS, NAT et observation

---

## Objectifs pédagogiques

Pour plus de simplicité on bascule maintenant sur un environnement dockerisé. À l’issue de ce TP, vous devez être capables de :

- Identifier et interpréter les interfaces réseau, adresses IP et routes
- Comprendre la communication dans un réseau local (LAN)
- Expliquer le rôle du DNS
- Comprendre le principe de NAT (traduction d’adresse et redirection de ports)
- Observer et analyser du trafic réseau
- Faire des liens explicites avec les TP1–TP5

---

## Positionnement

> Docker est utilisé comme support expérimental.  
> Les concepts réseau étudiés sont identiques à ceux vus précédemment.

---

## Architecture du TP (à comprendre avant toute manipulation)

```
Machine étudiante (Mac)

localhost:8080
      │
      ▼
[ NAT Docker / Port Mapping ]
      │
      ▼
Réseau Docker (LAN virtuel)
172.x.x.x

[ client ]  --->  [ serveur HTTP :8000 ]
```

---

## Questions préliminaires (à faire avant de commencer)

1. Où se trouve le serveur HTTP ?
2. Le client et le serveur sont-ils sur la même machine physique ?
3. Y a-t-il un câble réseau entre eux ?
4. Comment expliquer qu’ils puissent communiquer ?

---

# Partie 0 — Mise en place

Créer le fichier `docker-compose.yml` :

```yaml
services:
  serveur:
    image: python:3.9-slim
    command: bash -c "apt update && apt install -y iproute2 iputils-ping net-tools curl && python3 -m http.server 8000"
    ports:
      - "8080:8000"

  client:
    image: python:3.9-slim
    stdin_open: true
    tty: true
    command: bash -c "apt update && apt install -y iproute2 iputils-ping net-tools curl && bash"
```

Lancer :

```bash
docker compose up -d
```

---

# Partie 1 — Accès au service

Accéder via navigateur :

http://localhost:8080

---

## Questions

1. Qui répond à cette requête HTTP ?
2. Le serveur écoute-t-il directement sur votre machine ?
3. Faire un parallèle avec TP3 (serveur derrière un routeur/NAT)

---

# Partie 2 — Exploration réseau du client

Entrer dans le conteneur :

```bash
docker exec -it <client> bash
```

---

## Interfaces réseau

```bash
ip addr
```

### Questions

1. Combien d’interfaces réseau observez-vous ?
2. Quelle est l’adresse IP ?
3. Est-elle privée ou publique ?
4. À quel réseau appartient-elle ?

---

## Routage

```bash
ip route
```

### Questions

1. Quelle est la passerelle par défaut ?
2. Que signifie la route par défaut ?
3. Faire le lien avec TP3 (rôle du routeur)

---

# Partie 3 — Communication interne

```bash
ping serveur
curl serveur:8000
```

---

## Questions

1. Pourquoi le nom `serveur` fonctionne-t-il sans configuration ?
2. Qui fournit cette résolution ?
3. Est-ce un DNS Internet ?

---

## À retenir

> Docker fournit un DNS interne au réseau

---

# Partie 4 — Identifier l’IP du serveur

Sur la machine :

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <serveur>
```

---

## Tests

```bash
ping <IP_serveur>
curl <IP_serveur>:8000
```

---

## Questions

1. Quelle est l’IP du serveur ?
2. Quelle méthode est préférable : IP ou nom ?
3. Pourquoi ?

---

# Partie 5 — NAT et redirection de port

Accéder à :

http://localhost:8080

---

## Questions fondamentales

1. Pourquoi `localhost:8000` ne fonctionne pas ?
2. Que signifie `8080:8000` ?
3. Qui reçoit la requête sur 8080 ?
4. Où est redirigé le trafic ?
5. Faire le lien avec NAT (TP3)

---

## À retenir

> Le port mapping Docker = NAT simplifié

---

# Partie 6 — Isolation réseau

Créer un réseau :

```bash
docker network create reseau2
```

Créer un conteneur isolé :

```bash
docker run -dit --name iso --network reseau2 python:3.9-slim bash
```

---

## Test

```bash
ping iso
```

---

## Questions

1. Pourquoi la communication échoue-t-elle ?
2. Que représente un réseau Docker ?
3. Faire le lien avec VLAN / segmentation réseau

---

# Partie 7 — Ports ouverts

```bash
netstat -tuln
```

---

## Questions

1. Quels ports sont ouverts ?
2. Sur quelles interfaces ?
3. Le serveur écoute-t-il sur toutes les interfaces ?

---

# BONUS — Wireshark

---

## Étapes

1. Lancer Wireshark
2. Capturer sur interface "any"
3. Générer trafic :

```bash
curl serveur:8000
```

---

## Filtres

```
http
```

ou

```
ip.addr == <IP_serveur>
```

---

## Questions

1. Quelle est l’IP source ?
2. Quelle est l’IP destination ?
3. Le trafic sort-il de la machine ?

---

## Test NAT

```bash
curl localhost:8080
```

---

## Analyse

Comparer :
- trafic interne Docker
- trafic via NAT

---

# BONUS POUR LES PLUS RAPIDES

---

## IP dynamique

```bash
docker compose down && docker compose up -d
```

Questions :
- L’IP change-t-elle ?
- Pourquoi cela ne pose pas problème ?

---

## Sans DNS

```bash
curl <IP_serveur>:8000
```

---

## 🔹 Inspection réseau

```bash
docker network inspect bridge
```

Questions :
- Subnet ?
- Gateway ?

---

# 🧠 Synthèse (obligatoire)

| Réseau réel | Docker |
|------------|--------|
| Machine    |        |
| Câble      |        |
| Switch     |        |
| DNS        |        |
| NAT        |        |

---

# 🎯 Conclusion

- Un conteneur est une machine réseau
- Docker crée un LAN virtuel
- DNS interne remplace l’usage des IP
- Le port mapping correspond à du NAT
- Les concepts réseau restent identiques

---

## 📌 Message clé

> Ce TP ne vous apprend pas Docker.  
> Il vous permet de comprendre le réseau autrement.
