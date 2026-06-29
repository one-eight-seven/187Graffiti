# [187] Graffiti

> Contrôle de territoire par le graffiti. Les joueurs taguent 20 murs répartis dans Los Santos pour revendiquer du territoire au nom de leur gang. Les gangs rivaux peuvent effacer les tags en sprayant suffisamment de fois. Les blips de la minimap se mettent à jour en temps réel — aucun combat requis, juste de la présence stratégique.

## Aperçu
<!-- Screenshot ou GIF ici -->

## Dépendances
| Ressource | Lien |
|-----------|------|
| ox_lib | https://github.com/overextended/ox_lib |
| oxmysql | https://github.com/overextended/oxmysql |

## Installation
1. Placer `187Graffiti` dans `resources/[187]/`
2. Ajouter `ensure 187Graffiti` dans `server.cfg`
3. Importer `database.sql` dans votre base de données
4. Définir `Config.Framework` sur `'esx'`, `'qbcore'` ou `'standalone'` dans `config.lua`
5. Si besoin, modifier `framework/esx.lua` ou `framework/qbcore.lua` pour correspondre à votre version du framework

## Fonctionnalités
- [x] 20 murs de graffiti répartis dans Los Santos
- [x] 8 styles de tag (Ghost, Flame, Crown, Skull, Diamond, Star, Thunder, All-Seeing)
- [x] Mécanique de spray : N sprays consécutifs du même gang pour revendiquer ou écraser un mur
- [x] Suivi de contestation : affiche quel gang conteste et combien de sprays il a effectués
- [x] Mécanique de défense : sprayer son propre mur réinitialise une contestation active
- [x] Blips minimap en temps réel — couleur mise à jour à chaque changement de propriétaire
- [x] Tableau de classement des gangs par territoire
- [x] Récompense en argent lors d'une prise ou défense de mur
- [x] Animation de spray + particule (brume de peinture) + retour sonore
- [x] Barre de progression annulable pour chaque spray
- [x] Effet d'éclair lors d'une revendication réussie
- [x] Cooldown par joueur entre les tentatives de spray
- [x] Notification au gang adverse quand leur mur est pris
- [x] Statistiques par joueur (sprays, murs revendiqués, murs perdus)
- [x] Commande admin `/greset [id]` — réinitialiser un mur
- [x] Commande admin `/gresetall` — réinitialiser tous les murs
- [x] Commande standalone `/setgang [nom]` — rejoindre un gang sans framework
- [x] Intégration optionnelle avec 187Banking (auto-détectée)
- [x] Exports pour les autres scripts

## Fonctionnement

### Flux de spray
1. Le joueur s'approche à moins de `Config.SprayDistance` mètres d'un mur → indication ox_lib apparaît
2. Appui sur **E** → le panneau s'ouvre avec les infos du mur, le sélecteur de style et le classement
3. Le joueur choisit un style et clique sur le bouton d'action
4. Une barre de progression de 4 secondes se lance avec l'animation de spray et la particule de peinture
5. À la fin, l'événement de spray est envoyé côté serveur

### Logique de propriété (côté serveur)
- **Mur non revendiqué** : un gang le spraye. Après `Config.SprayCount` sprays du même gang → le mur est revendiqué.
- **Propre mur** : sprayer réinitialise la contestation active. Le gang reçoit `Config.RewardOnDefend`.
- **Mur ennemi** : un gang rival commence à contester. Après `Config.SprayCount` sprays consécutifs → la propriété change. Le gang reçoit `Config.RewardOnClaim`. Les membres du gang précédent sont notifiés.
- Si un autre gang s'intercale en cours de contestation, le compteur repart à 1 pour le nouveau gang.

### Détection de gang ESX
Le bridge ESX lit le champ métadonnée `gang` du joueur (défini par des plugins comme `esx_gang`). Si votre serveur utilise les noms de jobs comme identifiants de gang, remplacez le corps de `Framework.getGang` dans `framework/esx.lua` par `return xPlayer.job.name`.

## Configuration
| Paramètre | Défaut | Description |
|-----------|--------|-------------|
| `Config.Framework` | `'esx'` | Framework : `'esx'`, `'qbcore'`, `'standalone'` |
| `Config.SprayDistance` | `2.5` | Mètres pour interagir avec un mur |
| `Config.SprayCooldown` | `120` | Secondes entre deux sprays par joueur |
| `Config.SprayCount` | `5` | Sprays consécutifs pour revendiquer/écraser |
| `Config.SprayDuration` | `4000` | Durée de la barre de progression en ms |
| `Config.RewardOnClaim` | `250` | Récompense $ lors d'un changement de propriétaire |
| `Config.RewardOnDefend` | `50` | Récompense $ pour la défense de territoire |
| `Config.RequireItem` | `false` | Exiger l'objet `spray_can` pour sprayer |
| `Config.Walls` | 20 entrées | Emplacements des murs — ajouter ou supprimer selon vos besoins |
| `Config.TagStyles` | 8 styles | Designs de tag disponibles |
| `Config.GangColors` | table | IDs de couleur de blip par nom de gang |

## Commandes & Keybinds
| Commande | Permission | Description |
|----------|-----------|-------------|
| `/greset [id]` | ace `command.greset` | Réinitialiser un mur par son ID |
| `/gresetall` | ace `command.gresetall` | Réinitialiser tous les murs |
| `/setgang [nom]` | tous | Standalone uniquement : rejoindre un gang |

Ajouter dans `server.cfg` pour les admins :
```
add_ace group.admin command.greset allow
add_ace group.admin command.gresetall allow
```

## Exports
| Export | Côté | Description |
|--------|------|-------------|
| `getGangWallCount(gang)` | Serveur | Nombre de murs appartenant à un gang |
| `getWallsState()` | Serveur | Table complète de l'état des murs |
| `resetWall(wallId)` | Serveur | Réinitialise un mur par programmation |

## Compatibilité framework
Fonctionne avec **ESX**, **QBCore** et **Standalone**. Définir `Config.Framework` dans `config.lua`.
Chaque framework a son propre fichier bridge dans `framework/` — modifier celui qui correspond à votre setup si votre version utilise des noms de fonctions différents.

---
**187Scripts** — Scripts FiveM de qualité
