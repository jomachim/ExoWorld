package sample;

import dn.Delayer;

import Vector;

class FogOfWar {
  // Grille de tuiles qui représente l'état du brouillard de guerre
  private var tiles:Vector<Vector<Bool>>;

  // Couche de brouillard de guerre qui affiche l'état du brouillard de guerre
  private var fogLayer:Tilemap;

  // Constructeur qui initialise la grille de tuiles et la couche de brouillard de guerre
  public function new(width:Int, height:Int, tileSize:Int, tileset:Tileset) {
    // Initialise la grille de tuiles avec des tuiles cachées
    tiles = new Vector();
    for (y in 0...height) {
      tiles.push(new Vector());
      for (x in 0...width) {
        tiles[y].push(false);
      }
    }

    // Initialise la couche de brouillard de guerre
    fogLayer = new Tilemap(tileset, width, height, tileSize, tileSize);
    for (y in 0...height) {
      for (x in 0...width) {
        fogLayer.setTile(x, y, 1); // met toutes les tuiles en état caché
      }
    }
  }

  // Méthode qui révèle les tuiles autour d'un point donné
  public function reveal(x:Int, y:Int, radius:Int):Void {
    for (dy in -radius...radius) {
      for (dx in -radius...radius) {
        // Vérifie si la tuile est dans les limites de la carte
        if (x + dx >= 0 && x + dx < tiles[0].length && y + dy >= 0 && y + dy < tiles.length) {
          // Révèle la tuile
          tiles[y + dy][x + dx] = true;
          fogLayer.setTile(x + dx, y + dy, 0); // met la tuile en état visible
        }
      }
    }
  }

  // Méthode qui met à jour l'état du brouillard de guerre en fonction de l'état de chaque tuile
  public function update():Void {
    for (y in 0...tiles.length) {
      for (x in 0...tiles[y].length) {
        fogLayer.setVisible(x, y, !tiles[y][x]); // cache la tuile si elle est cachée, sinon la montre
      }
    }
  }
}
