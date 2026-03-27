# TP6 — Réseaux virtualisés avec Docker : IP, DNS, NAT et observation

---

## Objectifs pédagogiques

Pour plus de simplicité on bascule maintenant sur un environnement dockerisé. À l’issue de ce TP, vous devrez être capables dans ce nouvel environnement de :

- Identifier et interpréter les interfaces réseau, adresses IP et routes
- Comprendre la communication dans un réseau local (LAN) Docker
- Expliquer le rôle du DNS et sa mise en oeuvre dans ce contexte
- Comprendre le principe de NAT (traduction d’adresse et redirection de ports) lorsqu'il est appliqué à des réseaux Docker
- Observer et analyser du trafic réseau et comprendre que des choses très similaires à ce que l'on a pu observer avant se passent ici
- Faire des liens explicites avec les TP1–TP5

---

## Positionnement

> Docker est utilisé comme support expérimental afin d'accélérer la mise en oeuvre de systèmes/architectures. Tout ce qu'il y à en comprendre ici ? Cela permet de mettre en place des conteneurs ("alternative légère aux machines virtuelles") qui possèdent des interfaces réseau, des capacités de communication, etc.
> Les concepts réseau étudiés sont identiques à ceux vus précédemment ils sont simplement mis en oeuvre différemment.

Quelques commandes docker qui pourront être utiles pendant cette séance et celles à venir:
```console
docker ps
docker ps -a
docker rm
docker stop
docker exec -it NAME-CONTAINER /bin/bash
docker rm $(docker ps -a -q)
docker compose up -d
docker compose down
docker network ls
```

---

## Architecture du TP (à comprendre avant toute manipulation)

```
Machine étudiante (Mac) ou un Rasp si vous préférez

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

Créer le fichier `docker-compose.yml` suivant qui va nous permettre de lancer les conteneurs de notre réseau :

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

Ceci va nous permettre de créer automatiquement les machines qui nous intéressent...

---

# Partie 1 — Accès au service

Accéder via navigateur à l'adresse suivante :

http://localhost:8080

---

## Questions

Nous y reviendrons plus tard avec une vrai analyse mais réfléchissez déjà aux questions suivantes : 

1. Qui répond à cette requête HTTP ?
2. Le serveur écoute-t-il directement sur votre machine ? 

---

# Partie 2 — Exploration réseau du client

Entrer dans le conteneur client :

```bash
docker exec -it <client> bash
```

Pour trouver son nom ? Vous pouvez utiliser le docker compose ou les commandes Docker disponibles au début de ce sujet.

---

## Interfaces réseau

Tout comme pour les Raspberry, on va aussi pouvoir affichier les informations réseau de notre conteneur docker :

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

Là aussi des communications sont nécessaires : 

```bash
ip route
```

### Questions

1. Quelle est la passerelle par défaut ?
2. Que signifie la route par défaut ?
3. Faire le lien avec TP3 (rôle du routeur)

---

# Partie 3 — Communication interne

On va maintenant valider le fonctionnement des communications entre les conteneurs ?

Pour cela sur le conteneur client, lancez

```bash
ping <serveur>
curl serveur:8000
```

---

## Questions

1. Pourquoi le nom `<serveur>` fonctionne-t-il sans configuration ?
2. Qui fournit cette résolution ?
3. Est-ce un DNS Internet ?

---

## À retenir

> Docker fournit un DNS interne au réseau

---

# Partie 4 — Identifier l’IP du serveur

Sur votre Mac ou votre Rasp, on va maintenant faire quelques tests pour comprendre ce qui se passe :

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <serveur>
```

---

## Tests

Une nouvelle fois depuis le conteneur client, lancez les commandes suivantes : 

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

Accéder à nouveau à :

http://localhost:8080

---

## Questions fondamentales

Nous allons maintenant chercher à comprendre ce qui se passe

1. Pourquoi `localhost:8000` ne fonctionne pas ? 
2. Que pouvez vous observer dans le fichier Docker Compose ?
3. Qui reçoit la requête sur 8080 ?
4. Où est redirigé le trafic ?
5. Faire le lien avec NAT (TP3)

---

## À retenir

> Le port mapping Docker = NAT simplifié

---

# Partie 6 — Isolation réseau

On va maintenant créer un réseau Docker :

```bash
docker network create reseau2
```

Créer un conteneur isolé à l'intérieur de ce réseau :

```bash
docker run -dit --name iso --network reseau2 python:3.9-slim bash
```

---

## Test

Essayez maintenant depuis le client ou le serveur

```bash
ping iso
```

---

## Questions

1. Pourquoi la communication échoue-t-elle ?
2. Que représente un réseau Docker ?
3. Est il donc possible d'avoir plusieurs sous réseaux dans un environnement Docker ?

---

# Partie 7 — Ports ouverts

Sur le serveur exécutez la commande suivante : 

```bash
netstat -tuln
```

---

## Questions

1. Quels ports sont ouverts ?
2. Sur quelles interfaces ?
3. Le serveur écoute-t-il sur toutes les interfaces ?

---

# Et pour continuer

---

## IP dynamique

On va observer une autre caractéristique de Docker ici : 

Exécutez la commande s

```bash
docker compose down && docker compose up -d
```

Questions :
- L’IP change-t-elle ?
- Pourquoi cela ne pose pas problème ?

---

## Inspection réseau

On va finir par chercher à observer les réseaux docker.

Pour ce faire, vous pouvez utiliser les commandes suivantes :

```bash
docker network ls
docker network inspect <nom_du_dossier>
docker network inspect <reseau2>
```

Questions :
- Est ce le même subnet ?
- La même gateway ?
- Est ce de l'IPv4 ou v6 ?

---

# Et enfin — Ajouter un second serveur

## Étapes

Dans le docker compose, ajouter :

```yaml
  serveur2:
    image: python:3.9-slim
    command: bash -c "apt update && apt install -y iproute2 iputils-ping net-tools curl && python3 -m http.server 9000"
```

Testez depuis le client :

```bash
curl serveur2:9000
```

---

## Questions

- Est ce qu'on est toujours sur le même réseau ?
- Est ce qu'un acccès externe est possible ? (ie depuis votre Mac) Si non que faudrait il changer pour le permettre ?
- Et si on voulait permettre une communication entre deux sous réseaux docker, que faudrait il ajouter ? 

# Bonus, l'alternative à Wireshark — Analyse du trafic avec tcpdump (sniffer réseau)

---

## Étape 1 — Ajouter un conteneur sniffer

Modifier le `docker-compose.yml` :

```yaml
sniffer:
  image: nicolaka/netshoot
  command: sleep infinity
  cap_add:
    - NET_ADMIN
    - NET_RAW
```

Relancer :

```bash
docker compose up -d
```

---

## Étape 2 — Accéder au sniffer

```bash
docker exec -it <sniffer> bash
```

---

## Étape 3 — Observer les interfaces

```bash
ip addr
```

---

## Questions

1. Quelle est l’adresse IP du sniffer ?
2. Est-elle dans le même réseau que le client et le serveur ?
3. Que représente ce conteneur dans le réseau ?

---

## Étape 4 — Capturer le trafic

Lancer une capture :

```bash
tcpdump -i eth0
```

Laisser tourner cette commande.

---

## Étape 5 — Générer du trafic interne

Dans le conteneur client :

```bash
curl serveur:8000
```

---

## Questions

1. Voyez-vous passer des paquets dans tcpdump ?
2. Quelle est l’IP source ?
3. Quelle est l’IP destination ?
4. Le trafic reste-t-il dans le réseau Docker ?

---

## Étape 6 — Capturer le trafic NAT (accès externe)

Depuis votre machine :

```bash
curl localhost:8080
```

---

## Questions

1. Voyez-vous passer du trafic dans tcpdump ?
2. Les IP sont-elles identiques au cas précédent ?
3. Le chemin du trafic est-il le même ?
4. Où intervient la redirection de port ?

---

## Étape 7 — Filtrer le trafic

Dans le sniffer :

```bash
tcpdump -i eth0 port 8000
```

---

## Questions

1. Pourquoi utiliser un filtre ?
2. Quels paquets sont visibles maintenant ?
3. Peut-on distinguer client et serveur ?


---

# Conclusion

- Un conteneur est une machine réseau
- Docker crée un LAN virtuel
- DNS interne remplace l’usage des IP
- Le port mapping correspond à du NAT
- Les concepts réseau restent identiques

