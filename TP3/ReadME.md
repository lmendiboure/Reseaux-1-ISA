# TP 3 --- Exposer un service derrière un routeur

## Comprendre NAT sortant, DNAT et architecture réseau

# Objectifs généraux du TP

À l'issue de ce TP, vous devez être capables de :

-   Expliquer clairement la différence entre :
    -   NAT sortant (SNAT / MASQUERADE)
    -   NAT entrant (DNAT), quelque chose de très important lorsque vous utilisez le proxy de l'université
-   Comprendre à quel moment un paquet est modifié dans le routeur.
-   Expliquer pourquoi un service derrière un routeur n'est pas
    accessible par défaut.
-   Mettre en place une redirection de port de manière raisonnée.
-   Analyser les implications architecturales et de sécurité.

------------------------------------------------------------------------

# Architecture de travail

On va commencer par mettre en place la même architecture que la dernière fois : 

\[ PC Client \] → Wi-Fi → \[ RPi #2 Routeur \] → Ethernet → \[ RPi #1
Serveur \]

Sous-réseaux :

-   192.168.10.0/24 (Wi-Fi)
-   192.168.42.0/24 (LAN serveur)

Le routeur est une frontière logique entre : le réseau client et le réseau serveur

------------------------------------------------------------------------

# PARTIE 1 --- Rappel : NAT sortant (SNAT)

Vous avez déjà utilisé :

`iptables -t nat -A POSTROUTING -j MASQUERADE`

Cette commande signifie :

-   Les paquets quittant le réseau interne voient leur adresse source modifiée.
-   Le routeur remplace l'IP interne par la sienne (POSTROUTING).
-   Une table interne conserve les correspondances.

Le NAT sortant permet à plusieurs machines internes de partager une seule adresse visible.

**Q.** :\
Le NAT sortant empêche-t-il réellement les attaques ?\
Ou masque-t-il simplement l'origine ?

------------------------------------------------------------------------

# PARTIE 2 --- Pourquoi un service n'est PAS exposé par défaut ?

Le serveur SSH écoute sur 192.168.42.2:22.

Si vous tapez :

```console
ssh 192.168.10.1
```

Le paquet arrive sur le routeur avec destination = 192.168.10.1.

Le routeur : 1. regarde l'adresse destination, 2. constate qu'elle lui
appartient, 3. ne la modifie pas, 4. ne la transmet pas.

Sans règle explicite, un routeur ne redirige rien.

**Q.** Réfléchissez :\
Un routeur devrait-il rediriger automatiquement tout trafic entrant ?
Pourquoi ?

------------------------------------------------------------------------

# PARTIE 3 --- DNAT : principe général

DNAT = Destination NAT.

Cela consiste à modifier la destination d'un paquet entrant.

Exemple conceptuel :

Client → 192.168.10.1:2222\
Routeur transforme en → 192.168.42.2:22

Cela se produit en PREROUTING, avant la décision de routage (à l'inverse du SNAT donc !).

**Q.** Pourquoi est ce que cette opération contrainrement à l'autre ne peut pas se réaliser en pré-routage ?

------------------------------------------------------------------------

# PARTIE 4 --- Mise en place raisonnée d'une redirection SSH

## 4.1 Ce que nous allons faire

Nous allons dire au routeur :

"Si quelqu'un arrive sur moi (192.168.10.1) au port 2222,\
envoie ce trafic vers le serveur réel (192.168.42.2) au port 22."

Nous créons donc volontairement une porte d'entrée.

**Q.** Quel peut être à votre avis l'intérêt d'une telle mise en place ? Quels peuvent être les risques ? https://irp.nain-t.net/doku.php/130netfilter:610-netfilter-plus

------------------------------------------------------------------------

## 4.2 Ajout de la règle DNAT

```console
sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 2222 -j DNAT --to-destination 192.168.42.2:22
```

**Q.** Expliquez précisément :

-   Quelle information est modifiée ?
-   À quel moment ?
-   Qui verra cette modification ?

------------------------------------------------------------------------

## 4.3 Autorisation du forwarding

```console
sudo iptables -A FORWARD -p tcp -d 192.168.42.2 --dport 22 -j ACCEPT
```

**Q.** Pourquoi le routeur doit-il explicitement autoriser le passage ?

**Q.** Réfléchissez au rôle de la chaîne FORWARD. Un site éventuel pour en parler : https://www.digitalocean.com/community/tutorials/how-to-forward-ports-through-a-linux-gateway-with-iptables 

------------------------------------------------------------------------

## 4.4 Test

```console
ssh -p 2222 192.168.10.1
```

**Q.** Expliquez :

-   Le client pense parler à qui ?
-   Le serveur reçoit une connexion venant de qui ?

------------------------------------------------------------------------

# PARTIE 5 --- Observation détaillée avec Wireshark

Capturez sur :

-   wlan0 (côté client)
-   eth0 (côté serveur)

Complétez :

  Interface   IP source   IP destination
  ----------- ----------- ----------------

**Q.** Analysez :

-   Pourquoi la destination change-t-elle entre les deux interfaces ?
-   Pourquoi la source peut-elle rester identique ?
-   Que se passerait-il si l'on combinait DNAT et SNAT ?

------------------------------------------------------------------------

# PARTIE 6 --- Exposer un serveur HTTP : pourquoi ?

## 6.1 Pourquoi exposer un serveur HTTP ?

HTTP est un protocole simple, observable, non chiffré (dans ce cas).

En exposant un serveur HTTP :

-   Vous simulez un site web accessible depuis l'extérieur.
-   Vous reproduisez le fonctionnement d'un hébergement derrière une box
    Internet.
-   Vous rendez visible concrètement l'effet de DNAT.

Ce n'est pas seulement un exercice technique :\
c'est la reproduction d'un scénario réel.

------------------------------------------------------------------------

## 6.2 Mise en place

Sur le serveur :

```console
python3 -m http.server 8000
```

Sur le routeur :

```console
sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 8080 -j DNAT --to-destination 192.168.42.2:8000
```

Tester :

```console
curl http://192.168.10.1:8080
```

------------------------------------------------------------------------

## 6.3 Compréhension architecturale

**Q.** Répondez :

1.  En quoi votre routeur joue-t-il le rôle d'une box domestique ?
2.  Si le serveur HTTP contient une faille, que permet cette redirection
    ?
3.  Pourquoi est-il dangereux d'exposer tous les ports ?

------------------------------------------------------------------------

# PARTIE 7 --- DMZ minimale

Une DMZ est une zone exposée mais isolée du réseau interne.

Cherchez à comprendre à quoi sert une DMZ : https://www.fortinet.com/fr/resources/cyberglossary/what-is-dmz puis répondez aux questions suivantes.

**Q.** Dans votre architecture :

-   Le serveur est-il isolé du reste du réseau ?
-   Peut-il initier des connexions vers le réseau client ?
-   Quelles règles supplémentaires faudrait-il pour créer une vraie DMZ
    ?


------------------------------------------------------------------------

# Et pour aller plus loin

## Double exposition contrôlée

Exposez simultanément :

-   SSH sur 2222
-   HTTP sur 8080

Puis :

-   testez les deux services
-   observez les compteurs iptables
-   vérifiez les flux Wireshark

**Q.** Expliquez comment le routeur distingue les flux.

------------------------------------------------------------------------

## Limiter l'exposition

Modifiez la règle DNAT pour qu'elle n'accepte que les connexions venant d'une IP spécifique (vous devez donc trouver comment modifier cette règle).

Testez le comportement.

**Q.** Expliquez en quoi cela améliore la sécurité.

------------------------------------------------------------------------

# Synthèse finale attendue

Vous devez être capables d'expliquer clairement :

-   La différence entre SNAT et DNAT.
-   Le rôle de PREROUTING.
-   Pourquoi exposer un service est un choix architectural.
-   Ce que vous venez réellement de construire.

------------------------------------------------------------------------

# Conclusion

Vous avez transformé un simple routeur en :

-   traducteur d'adresses,
-   point d'entrée contrôlé,
-   frontière entre deux réseaux.

Vous venez de reproduire le mécanisme fondamental de publication d'un
service sur Internet.
