# Endless Runner 3D (Potion Run)
 
Un jeu de course infinie en 3D développé avec le moteur **Godot 4**. Le joueur doit courir automatiquement, esquiver des obstacles générés de manière procédurale et collecter des pièces pour battre son record.

---

## 🎮 Mécaniques de Jeu (MVP)

*   **Déplacement automatique** : Le personnage avance de manière continue sur l'axe Z.
*   **Accélération progressive** : La vitesse du jeu augmente au fil du temps pour élever le niveau de difficulté.
*   **Contrôles du joueur** : Déplacements latéraux fluides (axe X) et saut (axe Y) pour esquiver les dangers.
*   **Gestion des collisions** : Détection des impacts avec les obstacles entraînant un Game Over immédiat.
*   **Système de Score** : Calcul des points en temps réel basé sur la distance parcourue et les pièces collectées.
*   **Sauvegarde du High-score** : Persistance du meilleur score localement sur la machine (via `ConfigFile`).
*   **Flux de jeu** : Menu principal pour lancer la partie et écran de Game Over avec option de redémarrage instantané (*Restart*).

---

## 📁 Architecture du Projet

Le projet est structuré de façon modulaire afin de séparer proprement les scènes, les scripts et les ressources brutes :

```text
📁 res://
  📁 assets/                  # Fichiers sources et ressources brutes
    📁 3d_models/             # Modèles (Personnage, décors, obstacles)
    📁 textures/              # Textures et matériaux 3D
    📁 audio/                 # Musiques et effets sonores (SFX)
    📁 fonts/                 # Polices d'écriture pour l'UI
  📁 scenes/                  # Scènes Godot et scripts associés
    📁 core/                  # Scène Main, GameManager (Autoload)
    📁 player/                # Scène du joueur, logique et animations
    📁 level/                 # Générateur de niveau et tronçons de route
    📁 ui/                    # HUD, Menu Principal, Écran Game Over

```

---

## 🛠️ Configuration & Outils requis

* **Moteur** : Godot Engine 4.x (Stable)
* **Contrôles par défaut** :
* `Espace` / `Flèche Haut` : Sauter
* `Flèche Gauche` / `Q` : Aller à gauche
* `Flèche Droite` / `D` : Aller à droite



---

## 🚀 Installation pour le Développement

1. Clonez ce dépôt Git sur votre machine locale :

```bash
git clone https://github.com/TK-Porky/endless-runner-3d.git
````


2. Ouvrez **Godot Engine 4**.
3. Cliquez sur **Importer**, puis sélectionnez le fichier `project.godot` situé à la racine du dossier cloné.
4. Lancez le projet en appuyant sur `F5`.

---

## 👤 Développeur

* **Nom Professionnel** : TK-Porky
* **Rôle** : Concepteur & Développeur Lead
* **Dépôt Officiel** : [GitHub du Projet](https://github.com/TK-Porky/endless-runner-3d.git)

```
