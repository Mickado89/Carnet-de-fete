# Carnet de Fête

Site partagé pour une soirée entre amis. Il s'installe comme une appli sur le téléphone et fonctionne même avec un mauvais réseau.

| Onglet | Ce qu'on y fait |
|---|---|
| **Carte** | Carte OpenStreetMap en direct (plus plan clair et satellite) : bars, restos, toilettes, distributeurs, taxis… affichables et ajoutables en un geste, temps de marche, votes, photos sur chaque épingle, « Retour maison » |
| **Jauge** | Compteur de verres du groupe, objectif avec animation « 5 étoiles » |
| **Retour** | « Je suis bien rentré·e » et capitaine de soirée (optionnel) |
| **Comptes** | Roulette russe (tirage au sort partagé de qui paye la tournée) et partage des dépenses, façon Tricount : qui doit quoi, message de remboursement à copier, bouton « Marquer remboursé » |
| **Photos** | Galerie rangée par étape |
| **Récap** | Le résumé du lendemain (chiffres, palmarès, photos, remboursements restants), prêt à partager · les **soirées passées** · le bouton admin **Nouvelle soirée** |

En plus, sur toutes les pages :

- **Fil d'activité** : une notification quand quelqu'un ajoute une étape, une photo, une dépense ou rentre chez lui.
- **Hors ligne** : sans réseau, les ajouts sont gardés sur le téléphone et envoyés automatiquement au retour de la connexion.
- **Code de soirée** (optionnel) : sans le code, on peut regarder le site mais pas le modifier.

## Les fichiers du dépôt

| Fichier | Rôle | À modifier ? |
|---|---|---|
| `index.html` | le site | non, il se remplace en entier à chaque mise à jour |
| `config.js` | **vos réglages** (adresse Supabase, clé, centre de la carte) | une seule fois |
| `sw.js`, `manifest.webmanifest` | le fonctionnement comme une appli et le hors-ligne | non |
| `icon-192.png`, `icon-512.png`, `icon-maskable-512.png`, `apple-touch-icon.png` | les icônes de l'appli | non |
| `supabase.sql` | le script de la base de données | non, il se colle dans Supabase |
| `README.md` | ce guide | non |

---

## Installation complète (première fois)

### 1. La base de données (Supabase)

1. Créez un compte sur **supabase.com**, le plus simple étant *Continue with GitHub*. Créez ensuite un **New project** :
   - **Region** : *West EU (Paris)* ;
   - **Plan** : *Free* ;
   - notez le mot de passe de la base, mais ne le mettez **jamais** dans les fichiers du site.
2. Ouvrez **SQL Editor**, puis **New query**. Collez **tout** `supabase.sql` et cliquez sur **Run**. Le message attendu est *Success*.
3. Notez deux valeurs :
   - la **Project URL** (`https://abcdefgh.supabase.co`, rien après `.co`) ;
   - la **Publishable key**, dans *Project Settings → API Keys*. À défaut, prenez la clé *anon public* dans l'onglet *Legacy API keys*. Ne prenez jamais la clé *secret* ni *service_role*.

### 2. Le site (GitHub Pages)

1. Sur **github.com**, créez un **New repository** **public**.
2. Cliquez sur **uploading an existing file**, glissez **tous les fichiers** puis cliquez sur **Commit changes**.
3. Ouvrez `config.js`, cliquez sur le crayon et collez vos deux valeurs entre les guillemets. Si la fête n'est pas à Paris, changez aussi `CENTRE_CARTE`. Terminez par **Commit changes**.
4. Allez dans **Settings → Pages → Deploy from a branch**, choisissez `main` et `/ (root)`, puis cliquez sur **Save**.
5. Après 1 à 2 minutes, le lien `https://VOTRE-PSEUDO.github.io/NOM-DU-DEPOT/` apparaît en haut de la page.

### 3. Choisir un code de soirée (optionnel)

1. Dans Supabase, ouvrez **SQL Editor**, puis **New query**.
2. Collez la ligne suivante en remplaçant `MonCode` par votre code, puis cliquez sur **Run** :
   ```sql
   update public.fete_secret set code = 'MonCode' where id = 1;
   ```
3. Donnez le code à vos amis : ils le tapent une seule fois par téléphone. Les majuscules et les espaces ne comptent pas.
4. Pour retirer le code, relancez la même ligne avec `''` (deux apostrophes) à la place de `'MonCode'`.

### 4. Installer l'appli sur le téléphone

Ouvrez le lien sur le téléphone, puis touchez **Installer l'appli** en haut de la page.

- **iPhone** : dans Safari, touchez *Partager*, puis *Sur l'écran d'accueil*.
- **Android** : dans Chrome, Android propose l'installation directement.

### 5. Définir le code admin (pour « Nouvelle soirée »)

Dans Supabase, ouvrez **SQL Editor**, puis **New query**. Lancez la ligne suivante en remplaçant `MonCodeAdmin` par votre code, et gardez-le pour vous :
```sql
update public.fete_secret set admin_code = 'MonCodeAdmin' where id = 1;
```

---

## Passer à une nouvelle soirée

1. Dans l'onglet **Récap**, tout en bas, ouvrez **Nouvelle soirée** (marqué *Admin*).
2. Remplissez les champs :
   - donnez un nom à la nouvelle soirée (optionnel) ;
   - choisissez de garder ou non la liste des participants aux comptes ;
   - tapez le code admin.
3. Touchez **Archiver et commencer une nouvelle soirée**, puis **Oui**.

Ce que fait ce bouton :

- **L'archivage** : toute la soirée est rangée dans **Soirées passées**, dans l'onglet Récap. Chaque soirée y garde son récap, ses photos et les remboursements restant à faire.
- **La remise à zéro, pour tout le monde** : étapes, verres, retours, capitaine, dépenses, roulette et photos repartent de zéro.
- **Sur chaque téléphone** : le carnet se nettoie tout seul, que le téléphone soit ouvert à ce moment ou plus tard. Les prénoms et les adresses « Retour maison » sont conservés.
- **Les retardataires** : une modification faite pendant l'ancienne soirée par un téléphone resté hors ligne est ignorée, pour qu'elle ne pollue pas la nouvelle.

---

## Mettre à jour le site

1. **Les fichiers** : sur la page du dépôt GitHub, cliquez sur **Add file → Upload files**. Glissez les fichiers reçus, sauf `config.js` qui garde vos clés, puis cliquez sur **Commit changes**. Les fichiers déposés remplacent les anciens.
2. **La base** : si la mise à jour le demande, recollez `supabase.sql` dans *SQL Editor* et cliquez sur *Run*. Le script ne supprime aucune donnée, et vous pouvez le relancer sans risque.
3. **La publication** : comptez 1 à 2 minutes, que vous pouvez suivre dans l'onglet **Actions**. Rechargez ensuite le site. Sur un téléphone où l'appli est installée, fermez-la complètement puis rouvrez-la. Si l'ancienne version reste affichée, rouvrez-la une deuxième fois : la première ouverture télécharge la nouvelle version.
4. **En cas de problème** : le bouton **History** sur chaque fichier GitHub permet de revenir à une version précédente.

---

## Bon à savoir

- **Sécurité** :
  - la clé publique dans `config.js` est faite pour être visible ;
  - toutes les modifications passent par une fonction de la base, qui vérifie le code de soirée s'il y en a un ;
  - sans code, toute personne qui a le lien peut modifier : ne le publiez pas sur les réseaux sociaux.
- **Hors ligne** :
  - le badge jaune « Hors ligne · 3 en attente » indique les ajouts gardés sur le téléphone ;
  - ne videz pas les données du navigateur tant que le badge est affiché ;
  - les photos, elles, ont besoin du réseau pour être envoyées.
- **Photos** : « Retirer » masque la photo pour tout le monde, mais le fichier reste dans Supabase (*Storage → photos*). Pour le supprimer définitivement, passez par Supabase.
- **Mise en veille** : un projet Supabase gratuit se met en pause après environ une semaine sans visite. Ouvrez le site la veille de la fête. S'il est en pause, cliquez sur *Restore project* dans Supabase.
- **Services utilisés pour la carte** :
  - fonds de carte : OpenStreetMap (par défaut et en version « plan clair » adoucie), satellite Esri en option ;
  - lieux affichés (bars, restos, toilettes…) : OpenStreetMap en direct via l'API Overpass ;
  - adresses et itinéraires à pied : OpenStreetMap ;
  - trajets en transports, voiture ou vélo : liens vers Google Maps.
- **Après la fête** : supprimez le projet Supabase et le dépôt GitHub pour tout effacer.
