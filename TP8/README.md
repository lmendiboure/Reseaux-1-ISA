# TP8 — Filtrage réseau et diagnostic avec Docker (iptables + conntrack)

## Objectifs pédagogiques

Dans ce TP, vous allez compléter le travail effectué précédemment en ajoutant une nouvelle dimension au réseau : le contrôle du trafic.

Jusqu’à présent :

- vous avez appris à acheminer les paquets (routage) ;
- vous avez appris à les transformer (NAT).

Dans ce TP, vous allez apprendre à :

- décider si un paquet a le droit de circuler ou non ;
- diagnostiquer un problème réseau.

À l’issue de cette séance, vous devrez être capables de :

- distinguer routage, NAT et filtrage ;
- comprendre le rôle de la chaîne `FORWARD` ;
- construire des règles de filtrage ;
- expliquer la différence entre firewall *stateless* et *stateful* ;
- comprendre le rôle de `conntrack` ;
- diagnostiquer une panne réseau de manière structurée ;
- utiliser `iptables`, `tcpdump` et `ip route` efficacement.

---

## Architecture

On reprend la même topologie que lors du TP précédent.

```text
Réseau A (LAN client)              Réseau B (LAN serveurs)

10.10.0.0/24                     10.20.0.0/24

client (10.10.0.10)
        |
        |
routeur (10.10.0.254 / 10.20.0.254)
        |
        |
-----------------------------
        |
serveur1 (10.20.0.10:8000)
serveur2 (10.20.0.20:9000)
```

---

## À comprendre avant de commencer

Avant de commencer les manipulations, prenez quelques minutes pour réfléchir aux questions suivantes. L’objectif n’est pas encore d’avoir une réponse parfaite, mais d’identifier ce que vous pensez comprendre du rôle du routeur, du NAT et du firewall.

- Un firewall modifie-t-il les paquets ou décide-t-il seulement de leur passage ?  
  → ____________________________________________________________

- Un paquet peut-il être correctement routé mais bloqué ?  
  → ____________________________________________________________

- Le NAT remplace-t-il un firewall ?  
  → ____________________________________________________________

- Le retour d’un flux TCP est-il automatique ?  
  → ____________________________________________________________

---

## Partie 0 — Mise en place

On commence par remettre l’environnement dans un état propre, puis on relance l’architecture complète.

### Étape 1 — Reset

```bash
docker compose down -v
```

### Étape 2 — Lancement (mode normal)

```bash
docker compose up -d --build
```

### Étape 3 — Vérification

```bash
docker ps
```

Questions :

- Les quatre conteneurs attendus sont-ils présents ?  
  → ____________________________________________________________

- Tous les conteneurs sont-ils bien démarrés ?  
  → ____________________________________________________________

---

## Partie 0 bis — Remise en place du routage

⚠️ Important : les routes du TP précédent ne sont plus présentes.  
Avant de parler de filtrage, il faut donc s’assurer que le routage de base est à nouveau opérationnel. Sans cela, vous ne pourriez pas distinguer un problème de route d’un problème de firewall.

### Dans `client`

```bash
docker compose exec client sh
ip route add 10.20.0.0/24 via 10.10.0.254
```

### Dans `serveur1`

```bash
docker compose exec serveur1 sh
ip route add 10.10.0.0/24 via 10.20.0.254
```

### Dans `serveur2`

```bash
docker compose exec serveur2 sh
ip route add 10.10.0.0/24 via 10.20.0.254
```

Questions :

- Pourquoi faut-il ajouter une route dans `client` ?  
  → ____________________________________________________________

- Pourquoi faut-il aussi ajouter une route dans les serveurs ?  
  → ____________________________________________________________

- Que se passerait-il si seule la route aller existait ?  
  → ____________________________________________________________

---

## Partie 1 — Vérification initiale

Avant d’introduire des règles de filtrage, on vérifie d’abord la situation de référence : le réseau fonctionne-t-il dans l’état actuel ?

### Dans le client

```bash
curl 10.20.0.10:8000
```

### Questions

- La communication fonctionne-t-elle ?  
  → ____________________________________________________________

- Quel chemin emprunte le paquet ?  
  → ____________________________________________________________

- Le routage suffit-il à lui seul à garantir la communication ?  
  → ____________________________________________________________

- À ce stade, voyez-vous déjà une intervention explicite du firewall ?  
  → ____________________________________________________________

---

## Partie 2 — Bloquer tout le trafic (version enrichie)

### Objectif

Dans cette partie, vous allez montrer qu’un firewall peut bloquer un paquet, même si le routage fonctionne parfaitement.  
Autrement dit : *un paquet peut savoir où aller, mais ne pas avoir le droit d’y aller*.

### Étape 1 — Vérification de référence

Avant toute modification, vérifier que la communication fonctionne.

Dans le client :

```bash
curl 10.20.0.10:8000
```

Questions :

- La communication fonctionne-t-elle ?  
  → ____________________________________________________________

- Le paquet traverse-t-il le routeur ?  
  → ____________________________________________________________

- Le firewall intervient-il déjà ?  
  → ____________________________________________________________

### Étape 2 — Réflexion

On veut maintenant empêcher toute communication entre les deux réseaux.

Quel type d’action faut-il appliquer ?

- [ ] `ACCEPT`
- [ ] `DROP`
- [ ] `MASQUERADE`

→ Réponse : _________________________________________________

Expliquez votre choix :

→ ____________________________________________________________

### Étape 3 — Choix de la chaîne

Le trafic traverse le routeur : il n’est ni destiné au routeur, ni émis par lui.  
Il faut donc identifier la chaîne correspondant à ce cas.

Sur quelle chaîne faut-il agir ?

- [ ] `INPUT`
- [ ] `OUTPUT`
- [ ] `FORWARD`

→ Réponse : _________________________________________________

Expliquez brièvement pourquoi les deux autres chaînes ne conviennent pas :

- `INPUT` : _________________________________________________
- `OUTPUT` : ________________________________________________

### Étape 4 — Construction de la commande

Éléments disponibles :

- `iptables`
- `-P`
- `FORWARD`
- `DROP`

Complétez :

```bash
iptables ___ ______ ______
```

Commande complète écrite par vos soins :

```bash
____________________________________________________________
```

### Étape 5 — Test

Dans le client :

```bash
curl 10.20.0.10:8000
```

Résultat observé :

→ ____________________________________________________________

### Étape 6 — Observation

Dans le routeur :

```bash
iptables -L -v
```

Questions :

- Voyez-vous la politique par défaut de la chaîne `FORWARD` ?  
  → ____________________________________________________________

- Les compteurs évoluent-ils ?  
  → ____________________________________________________________

### Étape 7 — Analyse avec `tcpdump`

Dans le routeur, observer les deux interfaces.

#### Interface côté client

```bash
tcpdump -i eth0
```

#### Interface côté serveur

```bash
tcpdump -i eth1
```

Relancer ensuite :

```bash
curl 10.20.0.10:8000
```

Questions :

- Le paquet arrive-t-il sur l’interface côté client ?  
  → ____________________________________________________________

- Le paquet sort-il vers le réseau serveur ?  
  → ____________________________________________________________

- Où le paquet est-il bloqué ?  
  → ____________________________________________________________

- Le routage fonctionne-t-il toujours ?  
  → ____________________________________________________________

- Le firewall modifie-t-il le paquet ou le bloque-t-il ?  
  → ____________________________________________________________

### Étape 8 — Vérifier le comportement du retour

Dans le serveur :

```bash
ping 10.10.0.10
```

Questions :

- Le serveur peut-il joindre le client ?  
  → ____________________________________________________________

- Le blocage est-il symétrique ?  
  → ____________________________________________________________

- Quelle règle ou politique est responsable de ce comportement ?  
  → ____________________________________________________________

### Étape 9 — Compréhension fine

Compléter :

Le paquet :

- arrive au routeur : ________________________________________
- est analysé par le firewall : _______________________________
- est transmis vers le serveur : ______________________________

### Étape 10 — Discussion

Répondez avec des phrases complètes.

- Quelle est la différence entre routage et filtrage ?  
  → ____________________________________________________________

- Pourquoi le paquet peut-il être correctement routé mais ne jamais atteindre le serveur ?  
  → ____________________________________________________________

- Que se passerait-il si la politique par défaut était `ACCEPT` ?  
  → ____________________________________________________________

---

## Partie 3 — Autoriser un seul sens (version enrichie)

### Objectif

On cherche maintenant à affiner le filtrage.  
Au lieu de tout bloquer, on veut autoriser uniquement le trafic du client vers les serveurs, **sans autoriser explicitement le retour**.

L’enjeu est de comprendre qu’une communication TCP n’est pas simplement un “aller”, mais un échange bidirectionnel.

### Étape 1 — Réflexion

Le trafic souhaité est :

`10.10.0.0/24 → 10.20.0.0/24`

Quels champs permettent d’identifier ce flux ?

- [ ] adresse IP source
- [ ] adresse IP destination
- [ ] port
- [ ] interface

Cochez les éléments pertinents puis justifiez :

→ ____________________________________________________________

### Étape 2 — Choix de la chaîne

Ce trafic traverse le routeur.

Sur quelle chaîne faut-il agir ?

- [ ] `INPUT`
- [ ] `OUTPUT`
- [ ] `FORWARD`

→ Réponse : _________________________________________________

### Étape 3 — Construction de la règle

Éléments disponibles :

- `iptables`
- `-A FORWARD`
- `-s`
- `-d`
- `-j ACCEPT`

Complétez :

```bash
iptables ___ ______ -s __________ -d __________ -j ________
```

Commande complète :

```bash
____________________________________________________________
```

### Étape 4 — Vérification

```bash
curl 10.20.0.10:8000
```

Résultat :

→ ____________________________________________________________

### Étape 5 — Observation avec `tcpdump`

Dans le routeur :

```bash
tcpdump -i eth0
```

Puis :

```bash
tcpdump -i eth1
```

Questions :

- Le paquet arrive-t-il au routeur ?  
  → ____________________________________________________________

- Le paquet sort-il du routeur ?  
  → ____________________________________________________________

- Le serveur reçoit-il quelque chose ?  
  → ____________________________________________________________

- La réponse revient-elle ?  
  → ____________________________________________________________

### À retenir

Autoriser un seul sens ne suffit pas pour une communication TCP.

Expliquez pourquoi :

→ ____________________________________________________________

---

## Partie 4 — Autoriser le retour (version enrichie)

### Objectif

Dans la partie précédente, vous avez autorisé le trafic du client vers le serveur, mais la communication reste incomplète si le retour n’est pas lui aussi autorisé.

Ici, on va donc permettre au serveur de répondre au client.

### Étape 1 — Réflexion

Un flux TCP fonctionne ainsi :

`client → serveur → client`

La réponse doit-elle être explicitement autorisée ?

- [ ] Oui
- [ ] Non

→ Réponse : _________________________________________________

Justification :

→ ____________________________________________________________

### Étape 2 — Construction

Le trafic retour est :

`10.20.0.0/24 → 10.10.0.0/24`

Complétez :

```bash
iptables ___ ______ -s __________ -d __________ -j ________
```

Commande complète :

```bash
____________________________________________________________
```

### Étape 3 — Test

```bash
curl 10.20.0.10:8000
```

Résultat observé :

→ ____________________________________________________________

### Étape 4 — Vérification des règles

```bash
iptables -L -v
```

Questions :

- Combien de règles sont nécessaires dans ce mode de fonctionnement ?  
  → ____________________________________________________________

- Pourquoi le firewall ne “devine”-t-il pas le retour ?  
  → ____________________________________________________________

- Quel est le problème si l’on a 100 flux différents ?  
  → ____________________________________________________________

### À retenir

Un firewall *stateless* nécessite une règle pour chaque sens.

Expliquez cela avec vos mots :

→ ____________________________________________________________

---

## Partie 5 — Firewall stateful (`conntrack` détaillé)

### Objectif

Jusqu’ici, vous avez dû écrire une règle pour l’aller et une autre pour le retour.  
Cette approche devient vite lourde. On va maintenant utiliser un mécanisme qui permet de **reconnaître les paquets appartenant à une connexion déjà ouverte**.

C’est le rôle de `conntrack`.

### Étape 1 — Reset

```bash
iptables -F
iptables -P FORWARD DROP
```

Pourquoi refaire un reset ici ?

→ ____________________________________________________________

### Étape 2 — Réflexion

On veut autoriser automatiquement les paquets appartenant à une connexion déjà ouverte.

Quels états semblent pertinents ?

- [ ] `NEW`
- [ ] `ESTABLISHED`
- [ ] `RELATED`

→ Réponse : _________________________________________________

### Étape 3 — Comprendre les états

Compléter :

- `NEW` : ____________________________________________________

- `ESTABLISHED` : ____________________________________________

- `RELATED` : ________________________________________________

### Étape 4 — Construction de la règle *stateful*

Complétez :

```bash
iptables ___ ______ -m _________ --ctstate _____________ -j ________
```

Commande complète :

```bash
____________________________________________________________
```

### Étape 5 — Autoriser l’initiation

Complétez :

```bash
iptables ___ ______ -s __________ -d __________ -j ________
```

Commande complète :

```bash
____________________________________________________________
```

### Étape 6 — Test

```bash
curl 10.20.0.10:8000
```

Résultat observé :

→ ____________________________________________________________

### Étape 7 — Observation

```bash
iptables -L -v
```

Questions :

- Quelle règle traite le retour ?  
  → ____________________________________________________________

- Pourquoi n’a-t-on plus besoin d’une règle inverse explicite ?  
  → ____________________________________________________________

- Quel mécanisme interne permet cela ?  
  → ____________________________________________________________

### À retenir

`conntrack` mémorise les connexions et simplifie le filtrage.

Expliquez précisément en quoi il simplifie la configuration :

→ ____________________________________________________________

---

## Partie 6 — Ordre des règles (version renforcée)

### Objectif

Même avec de bonnes règles, un firewall peut ne pas fonctionner comme prévu si l’ordre des règles est mauvais.

Dans cette partie, vous allez montrer que `iptables` applique les règles **dans l’ordre**, et que cet ordre change totalement le comportement du système.

### Étape 1 — Mise en place

```bash
iptables -F
iptables -P FORWARD ACCEPT
```

Puis :

```bash
iptables -A FORWARD -j DROP
iptables -A FORWARD -s 10.10.0.0/24 -d 10.20.0.0/24 -j ACCEPT
```

Avant de tester, faites une hypothèse :

- Que va-t-il se passer ?  
  → ____________________________________________________________

### Étape 2 — Test

```bash
curl 10.20.0.10:8000
```

Résultat observé :

→ ____________________________________________________________

### Étape 3 — Observation

```bash
iptables -L -v
```

Questions :

- Quelle règle est appliquée en premier ?  
  → ____________________________________________________________

- Les compteurs de quelle règle augmentent ?  
  → ____________________________________________________________

- Pourquoi la règle `ACCEPT` n’est-elle jamais atteinte ?  
  → ____________________________________________________________

### Étape 4 — Correction

Inversez l’ordre des règles.

Écrivez ici la séquence corrigée :

```bash
____________________________________________________________
____________________________________________________________
```

### À retenir

`iptables` applique les règles dans l’ordre.

Expliquez pourquoi cette propriété est critique en diagnostic :

→ ____________________________________________________________

---

## Partie 7 — Interaction avec NAT (version approfondie)

### Objectif

Jusqu’ici, vous avez étudié le filtrage comme s’il était isolé.  
En réalité, un paquet peut aussi subir des transformations NAT. Il faut donc comprendre **à quel moment** le filtrage intervient dans la chaîne de traitement.

### Étape 1 — Réflexion

Un paquet subit plusieurs étapes possibles :

- `DNAT`
- routage
- filtrage
- `SNAT`

Dans quel ordre s’enchaînent-elles ?

→ ____________________________________________________________

### Étape 2 — Compléter

```text
PREROUTING → __________ → __________ → POSTROUTING
```

### Étape 3 — Question

Le firewall voit-il :

- [ ] l’adresse originale
- [ ] l’adresse après DNAT
- [ ] l’adresse après SNAT

→ Réponse : _________________________________________________

Justification :

→ ____________________________________________________________

### Étape 4 — Expérience

Configurer un `DNAT` (si déjà vu) :

```bash
iptables -t nat -A PREROUTING -p tcp --dport 8080   -j DNAT --to-destination 10.20.0.10:8000
```

Puis :

```bash
curl 10.10.0.254:8080
```

### Étape 5 — Observation

```bash
tcpdump -i eth1
```

Questions :

- Quelle destination voit le serveur ?  
  → ____________________________________________________________

- Le firewall filtre-t-il avant ou après transformation ?  
  → ____________________________________________________________

- Pourquoi est-ce important pour écrire une règle correcte ?  
  → ____________________________________________________________

### À retenir

Le filtrage se fait après `DNAT` mais avant `SNAT`.

Expliquez cette phrase :

→ ____________________________________________________________

---

## Partie 8 — Conception complète d’un firewall (version avancée)

### Objectif

Vous allez maintenant mobiliser tout ce qui a été vu pour construire un firewall réaliste.

### Contraintes

On veut :

- autoriser HTTP vers `serveur1` ;
- bloquer `serveur2` ;
- autoriser `ping` ;
- bloquer tout le reste.

### Étape 1 — Analyse

Compléter :

#### Flux autorisés

- ____________________________________________________________
- ____________________________________________________________

#### Flux bloqués

- ____________________________________________________________
- ____________________________________________________________

### Étape 2 — Choix des critères

Sur quels éléments peut-on filtrer ?

- [ ] IP
- [ ] port
- [ ] protocole
- [ ] interface

Quels critères allez-vous utiliser ici, et pourquoi ?

→ ____________________________________________________________

### Étape 3 — Construction

Construire les règles nécessaires.

Écrivez vos règles ci-dessous :

```bash
____________________________________________________________
____________________________________________________________
____________________________________________________________
____________________________________________________________
____________________________________________________________
```

### Étape 4 — Vérification

```bash
curl 10.20.0.10:8000
curl 10.20.0.20:9000
ping 10.20.0.10
```

Résultats observés :

- `curl 10.20.0.10:8000` : ___________________________________
- `curl 10.20.0.20:9000` : ___________________________________
- `ping 10.20.0.10` : ________________________________________

### Étape 5 — Observation

```bash
iptables -L -v
```

Questions :

- Quelle règle autorise HTTP ?  
  → ____________________________________________________________

- Quelle règle bloque `serveur2` ?  
  → ____________________________________________________________

- Pourquoi le `ping` fonctionne-t-il ?  
  → ____________________________________________________________

- Que se passe-t-il si une règle est mal placée ?  
  → ____________________________________________________________

---

## Partie 9 — Diagnostic d’un environnement buggué

### Objectif

Jusqu’ici, vous avez construit et compris les règles progressivement.  
Dans cette dernière partie, vous changez de posture : vous n’êtes plus en train de configurer un réseau propre, mais de **diagnostiquer un environnement cassé**.

L’objectif est d’adopter une méthode rigoureuse :
- observer un symptôme ;
- formuler une hypothèse ;
- tester cette hypothèse avec les bons outils ;
- localiser précisément le problème.

### Lancement (mode bug)

Exemple :

```bash
docker compose down -v
docker compose -f docker-compose.yml -f docker-compose.bug-order.yml up -d --build
```

ou

```bash
docker compose -f docker-compose.yml -f docker-compose.bug-dnat.yml up -d --build
```

⚠️ **Règle importante : ne pas lire les fichiers au début.**  
Le but n’est pas de “trouver la réponse dans le compose”, mais de diagnostiquer comme on le ferait dans un vrai système.

### Étape 1 — Symptôme

Selon le mode :

```bash
curl 10.20.0.10:8000
```

ou

```bash
curl 10.10.0.254:8080
```

Décrivez précisément le symptôme observé :

→ ____________________________________________________________

### Étape 2 — Hypothèse

Le problème semble-t-il venir de :

- [ ] routage
- [ ] NAT
- [ ] firewall

→ Hypothèse initiale : _______________________________________

Justifiez votre hypothèse :

→ ____________________________________________________________

### Étape 3 — Méthode

Pour diagnostiquer proprement, il faut suivre le chemin du paquet dans l’ordre.

1. Le paquet part-il ?  
   → _________________________________________________

2. Arrive-t-il au routeur ?  
   → _________________________________________________

3. Sort-il du routeur ?  
   → _________________________________________________

4. Arrive-t-il au serveur ?  
   → _________________________________________________

5. Le retour fonctionne-t-il ?  
   → _________________________________________________

### Étape 4 — Outils

Utiliser selon les besoins :

```bash
ip route get ...
tcpdump -i eth0
tcpdump -i eth1
iptables -L -v
iptables -t nat -L -v
```

Pour chaque outil utilisé, notez ce qu’il vous a appris :

- `ip route get` : ___________________________________________
- `tcpdump -i eth0` : ________________________________________
- `tcpdump -i eth1` : ________________________________________
- `iptables -L -v` : _________________________________________
- `iptables -t nat -L -v` : __________________________________

### Étape 5 — Diagnostic

Le paquet est bloqué :

- [ ] avant le routeur
- [ ] dans le firewall
- [ ] dans le NAT
- [ ] ailleurs

→ Conclusion : _______________________________________________

Expliquez précisément comment vous avez localisé le problème :

→ ____________________________________________________________

### Étape 6 — Validation

Seulement maintenant :

```bash
docker compose exec routeur sh
```

Vous pouvez alors inspecter la configuration réelle et vérifier si votre diagnostic était correct.

- Votre hypothèse initiale était-elle juste ?  
  → ____________________________________________________________

- Si non, quelle erreur de raisonnement aviez-vous faite ?  
  → ____________________________________________________________

---

## Bilan de fin de TP

Rédigez quelques phrases de synthèse.

- Quelle différence faites-vous désormais entre routage, NAT et filtrage ?  
  → ____________________________________________________________

- Qu’apporte un firewall *stateful* par rapport à un firewall *stateless* ?  
  → ____________________________________________________________

- Quel outil vous a semblé le plus utile pour diagnostiquer un problème, et pourquoi ?  
  → ____________________________________________________________

- Quelle erreur vous paraît la plus facile à commettre dans ce type d’architecture ?  
  → ____________________________________________________________
