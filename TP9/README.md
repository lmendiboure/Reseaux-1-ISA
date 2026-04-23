# TP9 — DNS, HTTP et diagnostic multi-couches

## Objectifs pédagogiques

Dans ce TP, vous allez comprendre comment une application trouve la machine avec laquelle elle doit communiquer.

À l’issue de la séance, vous devrez être capables de :

- expliquer comment un nom est transformé en adresse IP ;
- comprendre le rôle de /etc/hosts et /etc/resolv.conf ;
- comprendre le fonctionnement d’un serveur DNS ;
- diagnostiquer une panne en distinguant :
  - DNS
  - réseau
  - service

## Idée centrale

Une requête applicative suit la chaîne suivante :

nom → résolution → IP → réseau → service

Un problème peut apparaître à n’importe quelle étape.

## Architecture

```text
client (10.10.0.10)  
        |  
routeur (10.10.0.254 / 10.20.0.254)  
        |  
-----------------------------  
        |  
serveur1 (10.20.0.10:8000)  
serveur2 (10.20.0.20:9000)  
dns      (10.20.0.53)  
```

---

## Partie 0 — Mise en place

Sur la machine hôte :

```bash
docker compose down -v
docker compose up -d --build
```

### Configuration réseau

Dans le conteneur client :

```bash
docker compose exec client sh
ip route add 10.20.0.0/24 via 10.10.0.254
```

Dans les conteneurs serveur1, serveur2 et dns :

```bash
ip route add 10.10.0.0/24 via 10.20.0.254
```

---

## Partie 1 — Identifier le problème

Toutes les commandes suivantes sont à exécuter dans le conteneur client :

```bash
curl 10.20.0.10:8000
curl http://serveur1:8000
```

### Travail demandé

Expliquez précisément pourquoi la première commande fonctionne alors que la seconde échoue.

---

## Partie 2 — Résolution locale

Dans le conteneur client :

```bash
cat /etc/hosts
```

### Travail demandé

- Décrire la structure du fichier  
- Expliquer le rôle d’une ligne comme :  
  `127.0.0.1 localhost`

### Ajout d’une entrée

```bash
echo "10.20.0.10 serveur1" >> /etc/hosts
```

### Vérification

```bash
curl http://serveur1:8000
```

### Travail demandé

Qu'est ce que le système a fait pour résoudre le nom "serveur1". Pourquoi cette méthode n’est-elle pas adaptée à un système réel de grande taille ?

---

## Partie 3 — Comprendre la configuration DNS

Dans le conteneur client :

```bash
cat /etc/resolv.conf
```

### Travail demandé

Expliquer le rôle de ce fichier.

### Test

```bash
nslookup serveur1
```

### Travail demandé

Expliquez à quoi sert la commande `nslookup` ? Expliquer précisément pourquoi cette commande échoue dans le cas présent.

---

## Partie 4 — Utiliser un serveur DNS

Dans le conteneur client :

Commencez par nettoyer le fichiers hosts:
```bash
printf "127.0.0.1 localhost\n" > /etc/hosts
```

Puis mettez à jour le fichier resolv:

```bash
echo "nameserver 10.20.0.53" > /etc/resolv.conf
```

### Vérification

```bash
cat /etc/resolv.conf
```

### Tests

```bash
nslookup serveur1
curl http://serveur1:8000
```

### Travail demandé

Décomposer l’exécution de :

```bash
curl http://serveur1:8000
```

en étapes successives.

---

## Partie 5 — Observer et comprendre le DNS

### Observation réseau

Dans le conteneur routeur :

```bash
tcpdump -i eth1 port 53
```

Dans le conteneur client :

```bash
nslookup serveur1
```

### Travail demandé

Décrire le trafic observé et expliquer son rôle dans la communication.

---

## Partie 6 — Comprendre le serveur DNS (dnsmasq)

Accéder au conteneur DNS :

```bash
docker compose exec dns sh
```

### Observation

```bash
cat /etc/dnsmasq.conf
```

### Travail demandé

- Décrire la structure du fichier

### Analyse d’une ligne

```bash
address=/serveur1/10.20.0.10
```

### Questions

- Que signifie cette ligne ?
- Quel est son rôle dans la résolution DNS ?

### Lien avec le comportement

Expliquer pourquoi la commande suivante retourne cette IP :

```bash
nslookup serveur1
```

### Test croisé

Dans le client :

```bash
nslookup serveur2
```

Relier le résultat à la configuration DNS.

---

## Partie 7 — Effet du cache DNS et cohérence

### Objectif

Comprendre pourquoi une modification DNS n’est pas immédiatement visible.

### Étape 1

```bash
nslookup serveur1
```

Noter l’IP.

### Étape 2

Modifier :

```
address=/serveur1/10.20.0.10
```

en :

```
address=/serveur1/10.20.0.20
```

### Étape 3

```bash
docker compose restart dns
```

### Étape 4

```bash
nslookup serveur1
```

Observer.

### Étape 5

```bash
curl http://serveur1:8000
```

Identifier le serveur réellement contacté.

### Étape 6

Expliquer le rôle du cache DNS.

### Étape 7

```bash
docker compose restart client
nslookup serveur1
```

Comparer.

### Étape 8

Réflexion sur avantages / limites du cache DNS.

---

## Partie 8 — Priorité de résolution

Dans le conteneur client :

Créer un conflit :

```bash
echo "1.1.1.1 serveur1" >> /etc/hosts
```

### Tests

```bash
ping serveur1
nslookup serveur1
```

### Travail demandé

Comparer les résultats et expliquer pourquoi ils diffèrent.

### Réflexion

Quel mécanisme du système explique cette priorité ?

---

## Partie 9 — Diagnostic d’un problème

Sur la machine hôte :

```bash
docker compose down -v
docker compose -f docker-compose.yml -f docker-compose.bug-dns.yml up -d --build
```

Dans le conteneur client :

```bash
curl http://serveur1:8000
curl 10.20.0.10:8000
```

### Travail demandé

Que pouvez-vous conclure immédiatement ?

### Vérification

```bash
nslookup serveur1
```

### Diagnostic

Identifier précisément le problème.

### Validation

```bash
docker compose exec dns sh
```

### Correction

Proposer une correction.

---

## Partie 10 — Diagnostic multi-cas

Analyser les situations suivantes :

### Cas A

- nslookup serveur1 → échec  
- curl serveur1 → échec  

### Cas B

- nslookup serveur1 → fonctionne  
- ping IP → échec  

### Cas C

- nslookup serveur1 → fonctionne  
- ping IP → fonctionne  
- curl serveur1 → échec  

### Travail demandé

Associer chaque cas à une cause et justifier votre réponse.

# POur aller plus loin — DNS multi-niveaux (résolution en chaîne)

## Objectif

Dans cet exercice, vous allez découvrir qu’un serveur DNS ne répond pas nécessairement toujours directement à une requête. Il peut aussi transmettre la demande à un autre serveur DNS, qui dispose de l’information recherchée.

L’objectif est de comprendre qu’une résolution DNS peut s’effectuer en plusieurs étapes, et qu’il peut exister une forme de hiérarchie ou de chaînage entre serveurs.

---

## Principe

On met en place le chemin suivant :

client → DNS1 → DNS2 → IP

Dans ce scénario :

- le client interroge DNS1 ;
- DNS1 ne possède pas directement la réponse ;
- DNS1 transmet la requête à DNS2 ;
- DNS2 fournit l’adresse IP ;
- la réponse revient ensuite jusqu’au client.

---

## Étape 1 — Ajouter un second serveur DNS

Dans le fichier `docker-compose.yml`, ajouter le service suivant :

```yaml
  dns2:
    build:
      context: ./dns2
    command: ["dnsmasq", "-k"]
    networks:
      netB:
        ipv4_address: 10.20.0.54
```

---

## Étape 2 — Configurer DNS2

Créer ou modifier le fichier `dns2/dnsmasq.conf` avec le contenu suivant :

```conf
no-daemon
log-queries
log-facility=-
address=/serveur1/10.20.0.10
```

---

## Étape 3 — Modifier DNS1 pour qu’il relaie la requête

Dans le fichier `dns/dnsmasq.conf`, remplacer :

```conf
address=/serveur1/10.20.0.10
```

par :

```conf
server=/serveur1/10.20.0.54
```

### Travail demandé

Expliquer la différence entre les deux écritures suivantes :

```conf
address=/serveur1/10.20.0.10
```

et

```conf
server=/serveur1/10.20.0.54
```

---

## Étape 4 — Redémarrer l’architecture

Sur la machine hôte :

```bash
docker compose up -d --build
```

---

## Étape 5 — Tester la résolution

Dans le conteneur client :

```bash
nslookup serveur1
```

### Travail demandé

**Q1 — Observation**  
Le nom `serveur1` est-il toujours résolu ?

→ ____________________________________________________________

**Q2 — Compréhension**  
Quel serveur fournit réellement la réponse finale ? Quel chemin suit une requête DNS ?

→ ____________________________________________________________

---

## Étape 6 — Vérifier avec tcpdump

Dans le conteneur DNS1 :

```bash
tcpdump -i eth0 port 53
```

Dans le conteneur DNS2 :

```bash
tcpdump -i eth0 port 53
```

Puis, dans le conteneur client :

```bash
nslookup serveur1
```

### Travail demandé

Décrire ce que vous observez dans chaque conteneur.

---

## Conclusion

À la fin de ce TP, vous devez être capables de raisonner ainsi :

nom → résolution → IP → réseau → service

et d’identifier rapidement où se situe un problème.
