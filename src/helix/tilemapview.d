module helix.tilemapview;

import helix.component;
import helix.util.grid;
import helix.tilemap;
import helix.util.coordrange;
import helix.util.vec;

import allegro5.allegro;

class TileMapView : Component {

	TileMap tilemap;

	override void update() {}

	override void draw(GraphicsContext gc) {

		assert(tilemap.grid);
		assert(tilemap.tilelist.bmp);

		void teg_drawtile (const ref TileList tiles, int index, int x, int y)
		{
			assert (index >= 0);
			assert (index < tiles.tilenum);
			assert (tilemap.tilelist.bmp !is null);
			const tiles_per_row = tilemap.tilelist.bmp.al_get_bitmap_width / tiles.tilew;
			al_draw_bitmap_region (tilemap.tilelist.bmp,
				(index % tiles_per_row) * tiles.tilew,
				(index / tiles_per_row) * tiles.tileh,
				tiles.tilew, tiles.tileh,
				x, y,
				0);
		}

		int x, y;
	
		// idem as teg_draw, but only a part of the target bitmap will be drawn.
		// x, y, w and h are relative to the target bitmap coordinates
		// xview and yview are relative to the target bitmap (0,0), not to (x,y)
		// void teg_partdraw (const TEG_MAP* map, int layer, int cx, int cy, int cw, int ch, int xview, int yview)

		int ox, oy, ow, oh;
		int cx = shape.x;
		int cy = shape.y;
		int cw = shape.w;
		int ch = shape.h;


		// TODO: setting clipping should maybe be built into the Component system...
		al_get_clipping_rectangle(&ox, &oy, &ow, &oh);

		al_set_clipping_rectangle(cx, cy, cw, ch);
		
		const tileSize = Point(tilemap.tilelist.tilew, tilemap.tilelist.tileh);
		const viewPos = Point(0); // TODO Point(xview, yview);
		int layer = 0; //TODO
		foreach (tilePos; CoordRange!Point(Point(tilemap.grid.width, tilemap.grid.height))) {
			Point pixelPos = tilePos * tileSize - viewPos;

			int i = tilemap.grid.get(vec3i(tilePos.x, tilePos.y, layer));
			if (i >= 0 && i < tilemap.tilelist.tilenum) {
				teg_drawtile(tilemap.tilelist, i, pixelPos.x, pixelPos.y);
			}
		}

		al_set_clipping_rectangle(ox, oy, ow, oh);
	}

}