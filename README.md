# Carnet de Fête

Site partagé pour une fête, avec quatre onglets :

- **Carte** : une carte interactive (plan, satellite ou OpenStreetMap) pour ajouter et organiser les étapes, avec le temps de marche entre elles.
- **Jauge** : le compteur de boissons.
- **Comptes** : le partage des dépenses, façon Tricount.
- **Photos** : la galerie des souvenirs.

Tout le monde utilise le même lien, sans créer de compte. Les ajouts apparaissent en direct chez les autres.

Le site repose sur trois éléments :

| Élément | Rôle | Coût |
|---|---|---|
| `index.html` | le site lui-même | — |
| GitHub Pages | héberge le site et donne le lien à partager | gratuit |
| Supabase | garde les données partagées et les photos | gratuit (offre Free) |

Comptez environ 30 minutes la première fois. Les noms des boutons dans Supabase et GitHub peuvent changer un peu d'une version à l'autre.

---

## Étape 1 — Créer la base de données (Supabase)

1. Allez sur **supabase.com** et cliquez sur **Start your project**. Le plus simple est de vous connecter avec votre compte GitHub (*Continue with GitHub*).
2. Cliquez sur **New project** et remplissez :
   - **Name** : `carnet-de-fete`
   - **Database Password** : cliquez sur *Generate a password* et notez-le quelque part. Il ne servira pas pour le site, mais ne le mettez jamais dans `index.html`.
   - **Region** : *West EU (Paris)*
   - Plan : **Free**

   Cliquez sur **Create new project**, puis attendez environ 2 minutes.
3. Dans le menu de gauche, ouvrez **SQL Editor** puis **New query**.
4. Ouvrez le fichier `supabase.sql`, copiez **tout** son contenu, collez-le dans l'éditeur et cliquez sur **Run**. Le message attendu est *Success. No rows returned*.
5. Récupérez les deux valeurs à coller dans le site :
   - **Project URL** : elle est affichée sur la page d'accueil du projet ou dans *Project Settings → Data API*. Elle ressemble à `https://abcdefgh.supabase.co`.
   - **La clé publique** : dans *Project Settings → API Keys*, copiez la **Publishable key** (`sb_publishable_…`). Si vous ne la voyez pas, prenez la clé **anon public** dans l'onglet *Legacy API keys*.
   - ⚠️ Ne prenez **jamais** la clé *secret* ni la clé *service_role*.

## Étape 2 — Mettre le site en ligne (GitHub Pages)

1. Créez un compte sur **github.com** si ce n'est pas déjà fait.
2. Cliquez sur **+** en haut à droite, puis sur **New repository**, et remplissez :
   - **Repository name** : par exemple `fete-max`. Ce nom apparaîtra dans le lien.
   - Cochez **Public**, car GitHub Pages est gratuit pour les dépôts publics.
   - Cliquez sur **Create repository**.
3. Sur la page du dépôt vide, cliquez sur le lien **uploading an existing file**. Glissez-y `index.html`, `supabase.sql` et `README.md`, puis cliquez sur **Commit changes**.
4. Collez vos clés dans le site :
   - cliquez sur `index.html`, puis sur l'icône **crayon** (*Edit this file*) ;
   - dans le bloc **RÉGLAGES** en haut, remplacez `COLLER_ICI_PROJECT_URL` par la Project URL et `COLLER_ICI_CLE_PUBLIQUE` par la clé publique, en gardant les guillemets ;
   - si la fête n'a pas lieu à Paris, changez `CENTRE_CARTE` (coordonnées de la ville) ;
   - cliquez sur **Commit changes…**, puis encore sur **Commit changes**.
5. Activez la publication :
   - ouvrez l'onglet **Settings** du dépôt, puis **Pages** dans le menu de gauche ;
   - dans **Source**, choisissez *Deploy from a branch* ;
   - dans **Branch**, choisissez `main` et `/ (root)`, puis cliquez sur **Save**.
6. Attendez 1 à 2 minutes, puis rechargez la page. Le lien s'affiche en haut : `https://VOTRE-PSEUDO.github.io/fete-max/`

## Étape 3 — Tester puis partager

1. Ouvrez le lien. Si le bandeau jaune « pas encore relié à Supabase » s'affiche, les valeurs de l'étape 2.4 sont mal collées.
2. Faites un test complet : ajoutez une étape en touchant la carte, un verre, un participant et une photo.
3. Ouvrez le lien sur un deuxième téléphone : vos ajouts doivent y apparaître.
4. Envoyez le lien à vos amis.

Pour modifier le site plus tard, éditez `index.html` sur GitHub. Le site se met à jour en 1 à 2 minutes et les données ne sont pas touchées.

---

## Bon à savoir

- **Qui peut modifier ?** Toute personne qui a le lien. Ne le publiez pas sur les réseaux sociaux. La clé publique visible dans `index.html` est faite pour être visible : c'est normal.
- **Mise en veille :** un projet Supabase gratuit se met en pause après environ une semaine sans visite. Ouvrez le site la veille de la fête. S'il est en pause, cliquez sur *Restore project* dans Supabase.
- **Carte :**
  - les fonds de carte viennent de CARTO, OpenStreetMap et Esri (satellite) ;
  - la recherche d'adresse utilise OpenStreetMap ;
  - les temps de marche sont calculés sur les rues par le service piéton d'OpenStreetMap. S'il ne répond pas, le site affiche une estimation.
- **Photos :** elles sont réduites à environ 1800 px avant l'envoi. L'offre gratuite de Supabase laisse largement la place pour plusieurs centaines de photos.
- **Après la fête :** pour tout effacer, supprimez le projet dans Supabase (*Project Settings → General → Delete project*) et le dépôt dans GitHub (*Settings → Delete this repository*).
