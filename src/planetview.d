module planetview;

import helix.component;
import helix.util.grid;
import helix.tilemap;
import helix.util.coordrange;
import helix.util.vec;
import helix.mainloop;
import helix.signal;
import helix.color;

import allegro5.allegro;
import allegro5.allegro_primitives;

class PlanetView : Component {

	this(MainLoop window) {
		super(window);
	}

	TileMap planetMap;
	TileMap speciesMap;
	Model!Point selectedTile;

	override void update() {}

	override void draw(GraphicsContext gc) {
		draw_tilemap(planetMap, shape);
		draw_tilemap(speciesMap, shape);
		
		Point p = selectedTile.get();
		Point p1 = p * 64;
		Point p2 = p1 + 64;
		al_draw_rectangle(p1.x, p1.y, p2.x, p2.y, Color.WHITE, 1.0);
	}

	override void onMouseDown(Point p) {
		Point mp = p / 64;
		if (planetMap.grid.inRange(vec3i(mp.x, mp.y, 0))) {
			selectedTile.set(mp);
		}
	}

}