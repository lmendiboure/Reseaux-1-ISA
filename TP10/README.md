# TP FINAL — Conception et déploiement d’un réseau complet

## Objectif général

Vous devez concevoir et déployer un réseau complet permettant à plusieurs clients d’accéder à un service HTTP via un nom de domaine.

L’objectif n’est pas seulement de faire fonctionner le réseau, mais aussi de justifier vos choix et de diagnostiquer les erreurs possibles.

---

## Contraintes générales

Vous ne disposez d’aucune configuration fournie.

Vous devez produire vous-mêmes :

- un fichier `docker-compose.yml` ;
- une architecture réseau cohérente ;
- un plan d’adressage ;
- la configuration des services ;
- les routes nécessaires ;
- les règles NAT nécessaires ;
- la configuration DNS ;
- une justification de vos choix.

---

## Technologies attendues

Vous devez réutiliser les notions vues dans les TP précédents :

- réseaux Docker ;
- adressage IP et subnetting ;
- routage ;
- NAT ;
- DNS avec `dnsmasq` ;
- diagnostic réseau avec :
  - `ip`
  - `ping`
  - `curl`
  - `nslookup`
  - éventuellement `tcpdump`

---

# Étape 1 — Dimensionnement du réseau

## Contrainte

Votre réseau doit supporter au minimum :

- 3 clients ;
- 1 routeur ;
- 2 serveurs HTTP ;
- 1 serveur DNS.

Vous devez prévoir une architecture avec au moins deux réseaux distincts :

- un réseau côté clients ;
- un réseau côté serveurs.

Le routeur doit relier ces deux réseaux.

---

## Travail demandé

### Question 1

Quel masque choisissez-vous pour le réseau client ?

- `/30`
- `/29`
- `/28`
- `/24`

Justifiez votre choix.

### Question 2

Combien d’adresses utilisables ce masque fournit-il ?

### Question 3

Proposez un plan d’adressage complet incluant :

- les clients ;
- le routeur côté clients ;
- le routeur côté serveurs ;
- les serveurs HTTP ;
- le serveur DNS.

Vous pouvez présenter votre réponse sous forme de tableau.

| Machine | Réseau | Adresse IP | Rôle |
|---|---|---|---|
| client1 | réseau clients | ... | client |
| routeur | réseau clients | ... | passerelle |
| routeur | réseau serveurs | ... | passerelle |
| serveur1 | réseau serveurs | ... | HTTP |
| dns | réseau serveurs | ... | DNS |

---

## Validation

Avant de continuer, votre plan doit être cohérent.

Vérifiez notamment :

- qu’aucune adresse IP n’est dupliquée ;
- que l’adresse réseau n’est pas utilisée comme adresse machine ;
- que l’adresse de broadcast n’est pas utilisée comme adresse machine ;
- que chaque machine est dans le bon réseau ;
- que le masque choisi permet bien d’accueillir toutes les machines nécessaires.

---

# Étape 2 — Mise en place de l’architecture

## Travail demandé

Créer une architecture Docker contenant au minimum :

- `client1`
- `client2`
- `client3`
- `routeur`
- `serveur1`
- `serveur2`
- `dns`

---

## Contraintes

- Les clients et les serveurs doivent être dans des réseaux différents.
- Le routeur doit avoir deux interfaces réseau.
- Les serveurs HTTP doivent écouter sur des ports connus.
- Le serveur DNS doit être accessible depuis les clients, directement ou via le routeur.
- Les conteneurs doivent être démarrables avec Docker Compose.

---

## Vérification

Sur la machine hôte :

```bash
docker ps
```

Travail demandé :

- vérifier que tous les conteneurs sont actifs ;
- identifier les noms des conteneurs ;
- vérifier à quels réseaux ils sont connectés.

---

# Étape 3 — Connectivité réseau en IP

## Objectif

Permettre aux clients d’atteindre les serveurs en utilisant directement leurs adresses IP.

---

## Travail demandé

Configurer :

- la route par défaut côté client ;
- le routage côté routeur ;
- les routes nécessaires côté serveurs, si besoin.

---

## Tests

Depuis chaque client :

```bash
ping <IP_du_serveur1>
ping <IP_du_serveur2>
```

---

## Questions

1. Pourquoi la communication ne fonctionnait-elle pas forcément au départ ?
2. Quel est le rôle de la passerelle par défaut ?
3. Pourquoi le routeur doit-il avoir deux interfaces ?
4. Quelle commande permet de vérifier la table de routage d’un conteneur ?

---

# Étape 4 — Mise en place du NAT

## Objectif

Permettre aux serveurs de répondre aux clients sans nécessairement connaître directement le réseau client.

---

## Travail demandé

Configurer une règle NAT sur le routeur.

Vous devez être capables d’expliquer :

- sur quelle interface s’applique la règle ;
- dans quel sens circule le trafic ;
- pourquoi la règle est nécessaire ;
- quelle adresse source est vue par le serveur.

---

## Test

Depuis un client :

```bash
curl http://<IP_du_serveur1>:8000
```

---

## Questions

1. Quelle adresse IP le serveur voit-il comme source ?
2. Pourquoi la réponse peut-elle revenir au client ?
3. Que se passerait-il si la règle NAT était supprimée ?
4. Quelle différence faites-vous entre routage et NAT ?

---

# Étape 5 — Mise en place du DNS

## Objectif

Permettre l’accès au service HTTP par nom de domaine :

```bash
curl http://serveur1:8000
```

---

## Travail demandé

Configurer un serveur DNS avec `dnsmasq`.

Le DNS doit permettre au minimum de résoudre :

- `serveur1`
- `serveur2`

---

## Tests

Depuis un client :

```bash
nslookup serveur1
nslookup serveur2
curl http://serveur1:8000
curl http://serveur2:9000
```

---

## Questions

1. Que teste `nslookup` ?
2. Que teste `curl` en plus de la résolution DNS ?
3. Que se passe-t-il si le serveur DNS retourne une mauvaise adresse IP ?
4. Que se passe-t-il si le serveur DNS est inaccessible ?

---

# Étape 6 — Passage à plusieurs clients

## Objectif

Vérifier que l’architecture fonctionne pour plusieurs clients.

---

## Travail demandé

Ajouter ou activer :

- `client2`
- `client3`

Chaque client doit pouvoir accéder aux deux serveurs.

---

## Tests

Depuis chaque client :

```bash
ping serveur1
curl http://serveur1:8000
nslookup serveur1
```

Puis :

```bash
ping serveur2
curl http://serveur2:9000
nslookup serveur2
```

---

## Questions

1. Les clients peuvent-ils communiquer entre eux ?
2. Sont-ils dans le même réseau ?
3. Cette communication est-elle nécessaire pour accéder aux serveurs ?
4. Que faudrait-il modifier pour isoler complètement les clients les uns des autres ?

---

# Étape 7 — Injection d’erreurs

Vous devez maintenant casser volontairement votre propre réseau, puis diagnostiquer les problèmes observés.

Pour chaque erreur, vous devez fournir :

- la modification effectuée ;
- le symptôme observé ;
- la commande utilisée pour diagnostiquer ;
- la cause identifiée ;
- la correction proposée.

---

## Erreur 1 — Mauvais subnet

Modifier l’adresse IP d’un client pour qu’il ne soit plus dans le bon réseau.

### Questions

1. Pourquoi la communication échoue-t-elle ?
2. Le client peut-il encore joindre sa passerelle ?
3. Quelle commande permet de voir l’erreur ?

---

## Erreur 2 — Mauvaise gateway

Modifier la passerelle d’un client.

### Questions

1. Quel type de communication est impacté ?
2. Le client peut-il encore communiquer avec une machine du même réseau ?
3. Le client peut-il joindre une machine d’un autre réseau ?
4. Quelle commande permet de vérifier la passerelle utilisée ?

---

## Erreur 3 — DNS incorrect

Configurer un serveur DNS erroné ou inaccessible.

### Tests

```bash
ping <IP_du_serveur>
curl http://serveur1:8000
nslookup serveur1
```

### Questions

1. Pourquoi le ping par IP peut-il fonctionner alors que le curl par nom échoue ?
2. Quelle couche est en défaut ?
3. Quelle commande permet de confirmer le problème ?

---

## Erreur 4 — NAT supprimé

Supprimer la règle NAT sur le routeur.

### Questions

1. Pourquoi la requête peut-elle partir du client ?
2. Pourquoi la réponse ne revient-elle pas correctement ?
3. Quelle adresse source le serveur voit-il ?
4. Quelle règle permet de corriger le problème ?

---

## Erreur 5 — Mauvais dimensionnement réseau

Utiliser un masque trop petit pour le nombre de machines nécessaires.

### Questions

1. Pourquoi certaines machines ne peuvent-elles pas fonctionner correctement ?
2. Quelle est la différence entre une adresse réseau, une adresse utilisable et une adresse de broadcast ?
3. Comment choisir un masque adapté ?

---

# Étape 8 — Analyse finale

Répondez aux questions suivantes de manière argumentée.

---

## Question 1

Quel est le rôle exact du routeur dans votre architecture ?

---

## Question 2

Quelle est la différence entre les commandes suivantes ?

- `ping`
- `nslookup`
- `curl`

Pour chacune, préciser ce qui est testé et ce qui n’est pas testé.

---

## Question 3

Pourquoi le NAT est-il nécessaire dans votre architecture ?

---

## Question 4

Quel est l’impact d’un mauvais dimensionnement réseau ?

---

## Question 5

Décrire le chemin complet d’une requête HTTP depuis le client jusqu’au serveur.

Votre réponse doit inclure :

- la résolution DNS ;
- le choix de la route ;
- le passage par le routeur ;
- l’éventuelle traduction NAT ;
- l’arrivée au serveur HTTP ;
- le retour de la réponse.

---

# Extensions pour les groupes rapides

Ces extensions sont optionnelles. Elles doivent être réalisées uniquement lorsque l’architecture principale fonctionne correctement.

---

## Extension 1 — DNAT

Permettre l’accès suivant :

```bash
curl http://<IP_du_routeur>:8080
```

La requête doit être redirigée vers un serveur HTTP interne.

### Travail demandé

- configurer une règle DNAT ;
- tester l’accès ;
- expliquer la différence entre SNAT/MASQUERADE et DNAT.

---

## Extension 2 — Deux serveurs HTTP

Ajouter un second serveur HTTP avec un nom différent.

Exemple :

- `serveur1`
- `serveur2`

### Travail demandé

- configurer le DNS ;
- vérifier l’accès aux deux serveurs ;
- expliquer comment le client choisit le bon serveur.

---

## Extension 3 — DNS multi-niveaux

Mettre en place une résolution DNS en chaîne :

client → DNS1 → DNS2

### Travail demandé

- configurer deux serveurs DNS ;
- faire en sorte que DNS1 transmette certaines requêtes à DNS2 ;
- observer le trafic DNS avec `tcpdump`.

---

# Conclusion

Ce TP final doit vous permettre de relier toutes les notions vues précédemment :

DHCP / configuration IP → routage → NAT → DNS → HTTP → diagnostic

L’objectif principal est de savoir localiser une panne dans une chaîne de communication complète, et non seulement de faire fonctionner une commande isolée.
