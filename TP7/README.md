# TP7 — Routage et NAT avec Docker (SNAT + DNAT)

---

## Objectifs pédagogiques

Dans ce TP, vous allez construire progressivement un réseau réaliste composé de deux sous-réseaux interconnectés par un routeur. L’objectif n’est pas seulement de faire fonctionner le réseau, mais de comprendre pourquoi chaque étape est nécessaire et à quel moment les paquets sont transformés.

À l’issue de cette séance, vous devrez être capables de :

- expliquer pourquoi deux machines situées dans des réseaux différents ne peuvent pas communiquer directement ;
- identifier le rôle précis d’un routeur ;
- configurer une route par défaut sur une machine ;
- activer le routage IP sur un routeur ;
- construire une règle de SNAT en comprenant où et pourquoi elle s’applique ;
- construire une règle de DNAT en comprenant à quel moment la destination doit être modifiée ;
- décrire le chemin complet d’un paquet à l’aller et au retour ;
- comprendre comment plusieurs services peuvent être exposés derrière un même routeur.
---

## Architecture

Vous allez manipuler deux réseaux distincts.

```text
Réseau A (LAN client)              Réseau B (LAN serveurs)

172.18.0.0/16                     172.19.0.0/16

client (172.18.0.10)
        |
        |
routeur (172.18.0.1 / 172.19.0.1)
        |
        |
-----------------------------
        |
serveur1 (172.19.0.10:8000)
```
- le client appartient au réseau A ;
- le serveur appartient au réseau B ;
- le routeur possède une interface dans chaque réseau ;
- toute communication entre le client et les serveurs doit passer par le routeur.

---

## À comprendre avant de commencer

Avant toute manipulation, prenez quelques minutes pour répondre mentalement aux questions suivantes :

1. Le client et les serveurs sont-ils dans le même réseau ?
2. Si un paquet doit quitter le réseau `172.18.0.0/16`, qui décide où il va ?
3. Que se passe-t-il si aucune route n’est définie ?
4. Si un serveur reçoit un paquet, comment sait-il à qui répondre ?
5. Si l’on veut accéder à plusieurs serveurs derrière un même routeur, comment peut-on les distinguer ?

Ce TP repose sur une idée centrale :

> Un paquet ne se déplace jamais “tout seul”. Il est toujours guidé par une configuration réseau.
---

## Partie 0 — Mise en place

Créer le fichier docker-compose.yml :

```yaml
version: "3"

services:
  client:
    image: nicolaka/netshoot
    command: sleep infinity
    networks:
      netA:
        ipv4_address: 172.18.0.10

  serveur:
    image: python:3.9-slim
    command: python3 -m http.server 8000
    networks:
      netB:
        ipv4_address: 172.19.0.10

  routeur:
    image: nicolaka/netshoot
    command: sleep infinity
    cap_add:
      - NET_ADMIN
    networks:
      netA:
        ipv4_address: 172.18.0.1
      netB:
        ipv4_address: 172.19.0.1

networks:
  netA:
    ipam:
      config:
        - subnet: 172.18.0.0/16
  netB:
    ipam:
      config:
        - subnet: 172.19.0.0/16
```

Lancez ensuite l’environnement :

```bash
docker compose up -d
```

Vérifiez que les conteneurs existent :

```bash
docker ps
```
---

## Partie 1 — Observation initiale

### Étape 1 — Se placer dans le client

```bash
docker exec <completer> bash
```

### Étape 2 — Tester la connectivité

```bash
ping 172.18.0.1
ping 172.19.0.10
```

### Questions

1. Pourquoi le routeur est-il joignable ?
2. Pourquoi le serveur ne l’est-il pas ?
3. Le paquet part-il déjà vers le routeur, ou est-il bloqué avant ?

### À retenir

À ce stade, le client sait joindre une machine présente dans son propre réseau local, mais il ne sait pas comment atteindre un réseau différent.

---

## Partie 2 — Mise en place de la passerelle par défaut

Le client ne parvient pas à joindre le serveur situé dans un autre réseau.

### Étape 1 — Observer la configuration actuelle

Toujours dans le conteneur `client`, afficher les routes :

```bash
ip route
```

### Question

Que constatez-vous ?

- [ ] Le réseau `172.19.0.0/16` est connu
- [ ] Le client ne connaît que son réseau local
- [ ] Une route par défaut existe déjà

### Étape 2 — Réflexion

Si le client ne connaît pas le réseau distant, à qui doit-il envoyer les paquets destinés à ce réseau ?

### Étape 3 — Construire et appliquer la commande

On souhaite pour gérer cela ajouter une route par défaut.

Éléments disponibles :

- `ip route`
- `add`
- `default`
- `via <IP>`

Complétez et exécutez dans le client :

```bash
ip route ______ ______ via __________
```

### Étape 5 — Tester

```bash
ping 172.19.0.10
```

### Questions

1. Que signifie le mot `default` dans cette commande ?
2. Quel est le rôle de `172.18.0.1` ?
3. Pourquoi cela ne fonctionne-t-il toujours pas ?
4. Le paquet part-il maintenant vers le routeur ?

### À retenir

Le client sait désormais où envoyer les paquets destinés aux réseaux inconnus. Cela ne signifie pas encore que le routeur saura les retransmettre.

---

## Partie 3 — Transformer la machine en routeur

Le paquet arrive donc normalement au routeur, mais celui-ci ne le transmet pas vers le réseau B.

### Étape 1 — Identifier la bonne machine

Question :

Sur quelle machine faut-il intervenir ?

- [ ] client
- [ ] serveur
- [ ] routeur

### Étape 2 — Se placer dans le routeur

Dans un nouveau terminal connectez vous au rour

### Étape 3 — Comprendre le problème

Par défaut, une machine classique :

- reçoit des paquets pour elle-même ;
- mais ne retransmet pas les paquets vers d’autres réseaux.

Pour qu’elle joue le rôle d’un routeur, il faut activer le routage IP. Cela est vrai aujourd'hui et cela sera vraiment sur toute machine sur laquelle vous travaillerez. On l'avait d'ailleurs déjà constaté sur les Raspberry.

### Étape 4 — Construire la commande

Notre objectif est que la machine sache que le forwarding IP doit être à "True" et donc à 1.

Pour cela écritez simplement 1 dans le fichier ci-dessous.

```text
/proc/sys/net/ipv4/ip_forward
```

### Étape 6 — Tester

Revenir dans le client et lancez à nouveau le ping.

### Questions

1. Qu’est-ce qui a changé dans le comportement du routeur ?
2. Une machine classique et un routeur ont-ils le même rôle ?
3. Pourquoi le paquet peut-il maintenant sortir du réseau A ?

### À retenir

Activer `ip_forward` transforme la machine en équipement capable de transférer les paquets entre ses interfaces.

---

## Partie 4 — Mettre en place la route retour

Le serveur peut recevoir les paquets du client, mais il doit aussi savoir comment répondre.

### Étape 1 — Se placer dans le serveur

### Étape 2 — Observer les routes

```bash
ip route
```

### Question

Le serveur connaît-il le réseau `172.18.0.0/16` ?

Si le serveur ne connaît pas le réseau du client, à qui doit-il envoyer les réponses ?

### Étape 3 — Construire et appliquer la commande

On va faire exactement comme côté client et ajouter une route par défaut ici

### Étape 4 — Tester

Depuis le serveur :

```bash
ping 172.18.0.10
```

Puis, depuis le client :

```bash
curl 172.19.0.10:8000
```

### Questions

1. Pourquoi cette route retour est-elle nécessaire ?
2. Le routage doit-il être pensé dans un seul sens ou dans les deux ?
3. Que se passerait-il si le serveur recevait les paquets mais ne connaissait pas le chemin de retour ?

### À retenir

Une communication IP complète nécessite un aller **et** un retour. Le routeur ne suffit pas si les machines finales ne savent pas répondre.

---

## Partie 5 — Comprendre le chemin d’un paquet dans le routeur

Avant de construire des règles NAT, il faut comprendre le chemin logique d’un paquet à l’intérieur du routeur.

### Compléter

1. Le paquet ______ dans le routeur.
2. Le routeur décide de ______.
3. Le paquet ______ du routeur.

### Question

À quel moment la décision de routage est-elle prise ?

- [ ] Avant l’entrée
- [ ] Entre l’entrée et la sortie
- [ ] Après la sortie

### À retenir

Cette étape est essentielle. Pour savoir où appliquer une transformation, il faut savoir quand le routeur décide de sa sortie.

---

## Partie 6 — Construire une règle de SNAT

Jusqu’ici, le serveur a besoin d’une route retour pour répondre au client.

Nous allons maintenant chercher à éviter cette contrainte.

### Problème posé

Le serveur ne sait pas forcément joindre directement le client. On veut que le routeur se présente comme interlocuteur visible.

### Étape 1 — Identifier le problème

Quel champ pose problème ?

- [ ] IP source
- [ ] IP destination
- [ ] Port destination

### Étape 2 — Réfléchir au moment d’application

La décision de routage est-elle déjà prise au moment où l’on veut masquer l’adresse source ?

- [ ] Oui
- [ ] Non

Il faut donc agir :

- [ ] avant le routage
- [ ] après le routage

### Étape 3 — Choisir la chaîne

- [ ] PREROUTING
- [ ] POSTROUTING

### Étape 4 — Identifier l’interface concernée

Dans le routeur, afficher les interfaces :

```bash
ip addr
```

Question : par quelle interface le paquet sort-il vers les serveurs ?

### Étape 5 — Construire et appliqer la commande

Éléments disponibles :

- `iptables`
- `-t nat`
- `-A POSTROUTING`
- `-o <interface>`
- `-j MASQUERADE`

Complétez :

```bash
iptables -t ______ -A __________ -o ______ -j __________
```

### Étape 6 — Vérifier l’intérêt du SNAT

Dans le conteneur `serveur`, supprimez la route retour :

```bash
ip route del default
```

Puis, depuis le client :

```bash
curl 172.19.0.10:8000
```

### Questions

1. Pourquoi cela fonctionne-t-il encore ?
2. Quelle adresse IP voit maintenant le serveur ?
3. Quel est le rôle exact du routeur dans ce cas ?
4. Pourquoi cette technique évite-t-elle d’avoir à configurer la route retour sur le serveur ?

### À retenir

Le SNAT modifie l’adresse source après la décision de routage. Le serveur répond alors au routeur, et non directement au client.

---

## Partie 7 — Observer le SNAT

### Étape 1 — Se placer dans le serveur

Dans le conteneur `serveur` :

```bash
tcpdump -i eth0
```

### Étape 2 — Générer du trafic

Depuis le client, dans un autre terminal :

```bash
curl 172.19.0.10:8000
```

### Questions

1. Quelle IP source apparaît dans la capture ?
2. Est-ce l’adresse réelle du client ?
3. Pourquoi le serveur voit-il cette adresse et pas celle du client ?
4. Le routeur est-il désormais un simple relai ou un intermédiaire actif ?

### À retenir

Le NAT transforme réellement le paquet. Le routeur n’est plus seulement un équipement qui transmet : il modifie aussi les informations réseau.

---

## Partie 8 — Construire une règle de DNAT

### Situation

Le client va maintenant envoyer une requête vers le routeur, mais on veut que cette requête atteigne en réalité `serveur1`.

Exemple :

```bash
curl 172.18.0.1:8080
```

On souhaite en réalité atteindre :

```text
172.19.0.10:8000
```

### Étape 1 — Identifier le problème

Quelle information est incorrecte pour atteindre le bon service ?

- [ ] IP source
- [ ] IP destination
- [ ] Port source
- [ ] Port destination

### Étape 2 — Réfléchir au moment d’application

Si la destination est incorrecte, le routeur peut-il prendre une bonne décision de routage ?

- [ ] Oui
- [ ] Non

Il faut donc modifier la destination :

- [ ] avant le routage
- [ ] après le routage

### Étape 3 — Choisir la chaîne

- [ ] PREROUTING
- [ ] POSTROUTING

### Étape 4 — Construire et exécuter la commande

Éléments disponibles :

- `iptables`
- `-t nat`
- `-A PREROUTING`
- `-p tcp`
- `--dport 8080`
- `-j DNAT`
- `--to-destination IP:PORT`

Complétez :

```bash
iptables -t ______ -A __________ -p ___ --dport ____ \
  -j ______ --to-destination __________
```

### Étape 5 — Tester

Depuis le client :

```bash
curl 172.18.0.1:8080
```

### Questions

1. Quelle est la destination initiale du paquet ?
2. Quelle est la destination réelle après transformation ?
3. Pourquoi cette transformation doit-elle être appliquée avant la décision de routage ?
4. Que se passerait-il si on essayait de faire le DNAT après le routage ?

### À retenir

Le DNAT modifie la destination avant le routage, sinon le routeur prendrait sa décision à partir d’une mauvaise destination.

---

## Partie 9 — Ajouter un deuxième serveur

### Situation

Vous disposez maintenant de deux serveurs derrière le même routeur :

- `serveur1` sur `172.19.0.10:8000`
- `serveur2` sur `172.19.0.20:9000`

### Question

Peut-on accéder aux deux serveurs via une seule et même règle DNAT ?

- [ ] Oui
- [ ] Non

### Réflexion

Pour distinguer plusieurs services derrière un même point d’entrée, on peut s’appuyer sur :

- [ ] l’adresse IP du routeur ;
- [ ] le port d’entrée ;
- [ ] le nom du conteneur client.


---

## Partie 10 — Construire la règle DNAT vers serveur2

### Situation

On veut que :

```bash
curl 172.18.0.1:9090
```

atteigne en réalité :

```text
172.19.0.20:9000
```

### Étape 1 — Reprendre le raisonnement

1. Quelle information doit être modifiée ?
2. Cette modification doit-elle être faite avant ou après le routage ?
3. Quelle chaîne faut-il utiliser ?

### Étape 2 — Construire et appliquer la commande

Complétez :

```bash
iptables -t ______ -A __________ -p ___ --dport ____ \
  -j ______ --to-destination __________
```

### Étape 3 — Tester

Depuis le client :

```bash
curl 172.18.0.1:9090
```

### Questions

1. Pourquoi utilise-t-on le port `9090` ici ?
2. Que se passerait-il si l’on réutilisait `8080` ?
3. Le routeur devient-il un point d’accès unique vers plusieurs services ?
4. Combien de services différents peut-on, en théorie, exposer derrière un même routeur ?

### À retenir

Les ports d’entrée permettent de distinguer plusieurs services hébergés derrière un même routeur. Le routeur joue alors un rôle central d’aiguillage.

---

## Partie 11 — Observer la chaîne complète avec serveur2

### Étape 1 — Se placer dans serveur2

Dans un nouveau terminal :

```bash
docker exec -it serveur2 bash
```

Lancer une capture :

```bash
tcpdump -i eth0
```

### Étape 2 — Générer du trafic

Depuis le client :

```bash
curl 172.18.0.1:9090
```

### Questions

1. Quelle est la destination réelle de la requête ?
2. Quelle IP source est visible du point de vue de `serveur2` ?
3. Est-ce l’adresse réelle du client ?
4. Pourquoi la réponse revient-elle correctement au client ?
5. Le client sait-il directement qu’il parle à `serveur2`, ou a-t-il seulement l’impression de parler au routeur ?

### Compléter le schéma

```text
client → routeur → ______ → serveur2
serveur2 → routeur → ______ → client
```

### Question de synthèse

Pourquoi le DNAT seul ne suffit-il pas pour garantir un retour correct dans ce scénario ?

### À retenir

Dans cette chaîne complète :

- le DNAT modifie la destination à l’aller ;
- le SNAT modifie la source pour le retour ;
- le routeur devient un intermédiaire actif dans les deux sens.

---

## Partie 12 — Vérification conceptuelle finale

Complétez les phrases suivantes :

- DNAT agit ______ le routage car ________________________________________
- SNAT agit ______ le routage car ________________________________________

Répondez également :

1. Quelle différence fondamentale existe entre routage simple et NAT ?
2. Dans quel cas a-t-on encore besoin d’une route retour ?
3. Quel est l’intérêt d’utiliser un routeur comme point d’entrée unique ?

---

## Partie 13 — Synthèse

Compléter le tableau suivant :

| Mode     | Route retour nécessaire | IP vue par le serveur | Rôle principal |
|----------|-------------------------|-----------------------|----------------|
| Routage  |                         |                       |                |
| SNAT     |                         |                       |                |
| DNAT     |                         |                       |                |

---

## Conclusion

Dans ce TP, vous avez mis en place :

- un routeur entre deux réseaux ;
- une passerelle par défaut sur le client ;
- une route retour côté serveur ;
- un routage IP réel ;
- une règle de SNAT construite par raisonnement ;
- deux règles de DNAT permettant d’exposer plusieurs services derrière un même routeur.

Vous devez maintenant être capables d’expliquer, sans réciter une commande par cœur :

- où un paquet entre ;
- quand la décision de routage est prise ;
- pourquoi certaines transformations doivent être faites avant le routage ;
- pourquoi d’autres sont faites après ;
- comment plusieurs services peuvent être publiés derrière un même point d’accès.

---
