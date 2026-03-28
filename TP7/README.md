# TP7 — Routage et NAT avec Docker (SNAT + DNAT) — Version enrichie complète

---

## Objectifs pédagogiques

Ce TP vise à comprendre en profondeur le fonctionnement d’un réseau réel, en particulier :

- le routage entre deux réseaux
- la transformation des paquets (NAT)
- le rôle central du routeur
- la gestion de plusieurs services derrière un même point d’entrée

---

## Architecture

```
Réseau A (LAN client)              Réseau B (LAN serveur)

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
serveur2 (172.19.0.20:9000)
```

---

## Partie 0 — Mise en place

(docker-compose identique)

---

## Partie 1 — Observation initiale

Tests :

```bash
ping 172.18.0.1
ping 172.19.0.10
```

Questions :

- Pourquoi le serveur n’est pas joignable ?
- Le client connaît-il le réseau distant ?

---

## Partie 2 — Routage

Ajouter :

```bash
ip route add default via 172.18.0.1
```

Puis activer le routage sur le routeur.

---

## Partie 3 — Comprendre le chemin du paquet

Compléter :

1. Le paquet ______ dans le routeur  
2. Le routeur décide de ______  
3. Le paquet ______ du routeur  

---

## Partie 4 — DNAT (construction)

Objectif : accéder à serveur1 via le routeur

Guidage identique (PREROUTING)

---

## Partie 5 — SNAT (construction)

Objectif : assurer le retour

Guidage identique (POSTROUTING)

---

# Partie 6 — Ajouter un second serveur (dimension clé)

---

## Situation

Vous disposez maintenant de deux serveurs :

- serveur1 → port 8000  
- serveur2 → port 9000  

---

## Question

Peut-on accéder aux deux serveurs via le routeur avec la même règle DNAT ?

- [ ] Oui  
- [ ] Non  

---

## Raisonnement

Chaque service doit être distingué par :

- [ ] l’adresse IP  
- [ ] le port  

---

## Conclusion attendue

On doit utiliser **des ports différents côté routeur**

---

# 🔧 Partie 7 — Construire DNAT pour serveur2

---

## Situation

On veut :

```bash
curl 172.18.0.1:9090
```

→ accéder à :

```
172.19.0.20:9000
```

---

## À compléter

```bash
iptables -t ______ -A __________ -p ___ --dport ____   -j ______ --to-destination __________
```

---

## Test

```bash
curl 172.18.0.1:9090
```

---

## Questions

- Pourquoi le port 9090 ?
- Que se passerait-il si on utilisait 8080 ?

---

# Partie 8 — Comprendre la mutualisation

---

## Question

Combien de serveurs peut-on exposer derrière un seul routeur ?

- [ ] 1  
- [ ] 2  
- [ ] plusieurs  

---

## Question

Quelle est la limite ?

---

## Attendu

- dépend du nombre de ports disponibles
- le routeur joue un rôle de point d’accès unique

---

# Partie 9 — Observation comparative

---

Dans serveur1 et serveur2 :

```bash
tcpdump -i eth0
```

---

## Tests

```bash
curl 172.18.0.1:8080
curl 172.18.0.1:9090
```

---

## Questions

1. Les deux serveurs voient-ils le même client ?
2. Quelle IP apparaît ?
3. Pourquoi ?

---

# Partie 10 — Analyse complète

Compléter :

```
client → routeur → DNAT → serveurX
serveurX → routeur → SNAT → client
```

---

## Question

Le client sait-il qu’il parle à deux serveurs différents ?

- [ ] Oui  
- [ ] Non  

---

# Partie 11 — Synthèse avancée

| Élément | Rôle |
|--------|------|
| Routeur | |
| SNAT | |
| DNAT | |
| Ports | |

---

# Conclusion

Vous avez construit un système permettant :

- d’interconnecter des réseaux
- d’exposer plusieurs services derrière un seul point d’entrée
- de contrôler précisément le chemin des paquets

Ce fonctionnement est identique à celui utilisé dans les réseaux réels.
