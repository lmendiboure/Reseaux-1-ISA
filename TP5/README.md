# TP5 — Firewall et analyse réseau avec Wireshark
## Comprendre le réseau du système jusqu’au paquet

---

# Objectifs pédagogiques

À la fin de ce TP, vous devez être capables de :

- Comprendre le rôle d’un firewall  
- Distinguer les chaînes `INPUT` / `OUTPUT`  
- Comprendre le rôle des ports et des protocoles  
- Prédire l’effet d’une règle `iptables`  
- Analyser un problème réseau avec Wireshark  
- Relier :
  - commandes système  
  - comportement réseau  
  - paquets observés  

---

# Architecture

Aujourdh'ui, on simplifie ! Ca va nous permettre d'arriver plus rapidement à quelque chose de fonctionnel.

On a nos deux rasp connectés directement l'un à l'autre en ethernet et c'est tout.

```
RPi1 → 192.168.42.1 (firewall)
RPi2 → 192.168.42.2 (client + serveur)
```
---

# Ressources (qui pourraient être utiles pour répondre à quelques questions ci-dessous)

- https://man7.org/linux/man-pages/man8/iptables.8.html  
- https://wiki.wireshark.org/TCP  
- https://en.wikipedia.org/wiki/Three-way_handshake  

---

# PARTIE 0 — Mise en place

Configurer les adresses IP sur les deux machines.

Tester :

```bash
ping 192.168.42.1
```

---

## Questions

1. Pourquoi n’y a-t-il pas besoin de passerelle ?  
2. Quel protocole est utilisé avant ICMP ?  

---

# PARTIE 1 — Observer AVANT de filtrer

On retourne sur quelques bases juste pour bien vérifierqu'on se souvient de l'utilisation des outils et de la signification des concepts...t

## Lancer Wireshark

- Interface : `eth0`  
- Filtre conseillé :

```
tcp or icmp
```

---

## Test 1 — Ping

Depuis RPi2 :

```bash
ping 192.168.42.1
```

---

## Questions

1. Identifier :
   - requête ICMP  
   - réponse ICMP  
2. Y a-t-il une notion de connexion ?  
3. Quels champs permettent d’identifier ICMP ?  

---

## Test 2 — SSH

```bash
ssh 192.168.42.1
```

---

## Questions

1. Repérer :
   - SYN  
   - SYN-ACK  
   - ACK  
2. Qu’est-ce que le *3-way handshake* ?  (source potentielle : https://www.coursera.org/fr-FR/articles/three-way-handshake)
3. Pourquoi est-il nécessaire ?  

---

# PARTIE 2 — Introduction à iptables

Sur RPi1 entrez la commande suivante :

```bash
iptables -L -v
```

---

## Travail

1. Après avoir expliqué à quoi sert un firewall et iptables, identifier :
   - chaîne `INPUT`  
   - chaîne `OUTPUT`  
2. Que signifie `policy ACCEPT` ?  
3. Y a-t-il déjà du filtrage actif ?  

---

# PARTIE 3 — Blocage total (INPUT)

On va maintenant bloquer les paquets entrants

```bash
iptables -P INPUT DROP
```

---

## Observer Wireshark


1. Voyez-vous le paquet ICMP partir ?  
2. Voyez-vous une réponse ?  
3. Voyez-vous le SYN TCP ?  
4. Y a-t-il un SYN-ACK ?  


---

# PARTIE 4 — Réautoriser ICMP

En remplissant correctement la ligne ci-dessous ne permettez QUE les paquets icmp.

```bash
iptables -A INPUT -p packet-name -j ACCEPT
```

---

## Tests

- `ping`  
- `ssh`  

---

## Wireshark

Comparer avant / après.

---

## Questions

1. Pourquoi ICMP fonctionne ?  
2. Pourquoi SSH ne fonctionne pas ?  
3. Différence ICMP vs TCP ?  

---

# PARTIE 5 — Autoriser SSH 

Trouver :

- protocole  
- port  

Indice :

```bash
ss -tlnp
```

---

Ajouter la règle correcte.

---

## Wireshark

Observer :

- handshake TCP  
- trafic chiffré  

---

## Questions

1. Pourquoi SSH fonctionne maintenant ?  
2. Que transporte TCP ici ?  
3. Peut-on lire les données ?  

---

# PARTIE 6 — Notion d’état

Ajouter :

```bash
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
```

---

## Observation Wireshark

1. Identifier les flux aller / retour  
2. Comprendre le rôle de la réponse  

---

## Questions

1. Pourquoi une connexion est-elle bidirectionnelle ?  
2. Que se passe-t-il sans cette règle ?  

---

# PARTIE 7 — Filtrage OUTPUT

Après avoir filtré l'entrée on va maintenant filtrer la sortie !

```bash
iptables -P OUTPUT DROP
```

---

## Test

```bash
ping 192.168.42.2
```

---

## Wireshark

1. Le paquet part-il ?  
2. Pourquoi n’y a-t-il pas de réponse ?  

---

## Questions

1. Une machine peut-elle fonctionner sans OUTPUT ?  
2. Pourquoi ?  

---

# PARTIE 8 — Service netcat (analyse complète)

Sur RPi2 :

```bash
nc -l 5000
```

Sur RPi1 :

```bash
nc 192.168.42.2 5000
```

---

## Wireshark

1. Identifier TCP  
2. Observer le flux  

---

## Questions

1. Ce service est-il sécurisé ?  
2. Que transporte le flux ?  

---

## Blocage

Écrire vous-même la règle pour bloquer ce service.

---

## Wireshark

Comparer :

- avant blocage  
- après blocage  

---

## Analyse

1. Le SYN est-il envoyé ?  
2. Y a-t-il une réponse ?  
3. Où se situe le blocage ?  

---

# PARTIE 9 — Lecture avancée des règles

```bash
iptables -L -v
```

---

## Travail

1. Associer chaque test à une règle  
2. Interpréter les compteurs  
3. Identifier les règles actives  

---

# Analyse avancée

Répondez aux question suivantes.

## 1 — Bloquer SSH uniquement  

Comment faire ? Comment s'assurer que cela fonctionne ?

---

## 2 — Autoriser uniquement une IP  

Comment faire ? Comment s'assurer que cela fonctionne ?


---

## 3 — Observer un paquet bloqué  

Que se passe-t-il dans Wireshark ?

---

## 4 — Politique stricte  

Autoriser uniquement :

- ICMP  
- SSH  

Bloquer tout le reste  

---
