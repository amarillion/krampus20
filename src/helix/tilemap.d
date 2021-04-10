module helix.tilemap;

import std.json;
import std.format;
import helix.util.grid;
import helix.util.vec;
import helix.util.rect;
import helix.util.coordrange;
import helix.allegro.bitmap;

import allegro5.allegro;
import std.conv;

struct TileList {
	int tilew;
	int tileh;
	int tilenum;
	Bitmap bmp = null;

	void fromTiledJSON(JSONValue node) {
		tilew = to!int(node["tilewidth"].integer);
		tileh = to!int(node["tileheight"].integer);
		tilenum = to!int(node["tilecount"].integer);
		// TODO: also link up bitmap...
	}
}

alias TileGrid = Grid!(2, int);

class TileMap {

	TileGrid[] layers;
	TileList tilelist;

	private int _width, _height;
	@property int width() { return _width; }
	@property int height() { return _height; }
	
	this(int width, int height, int numLayers) {
		this._width = width;
		this._height = height;
		foreach (l; 0..numLayers) {
			layers ~= new Grid!(2, int)(width, height);
		}
	}
	
	static TileMap fromTiledJSON(JSONValue node) {

		int width = cast(int)node["width"].integer;
		int height = cast(int)node["height"].integer;

		TileMap result = new TileMap(width, height, 0);

		int dl = 0;
		foreach (l; node["layers"].array) {
			if (l["type"].str == "tilelayer") { dl++; }
		}
		assert(dl > 0);
		
		result.tilelist.fromTiledJSON(node["tilesets"].array[0]);

		foreach (l; node["layers"].array) {
			if (l["type"].str != "tilelayer") { continue; }
			auto grid = new Grid!(2, int)(width, height);
			result.layers ~= grid;

			auto data = l["data"].array;
			foreach (p; PointRange(grid.size)) {
				const val = to!int(data[grid.toIndex(p)].integer - 1);
				grid.set(p, val);
			}
		}

		return result;
	}

	override string toString() {
		return format("TileMap(%s, tiles: %s)", layers[0].size, tilelist.tilenum);
	}
}

void draw_tilemap(TileMap tilemap, Rectangle shape, Point viewPos = Point(0), int layer = 0) {

	assert(tilemap.layers[layer]);
	assert(tilemap.tilelist.bmp);

	void teg_drawtile (const ref TileList tiles, int index, int x, int y)
	{
		assert (index >= 0);
		assert (index < tiles.tilenum);
		assert (tilemap.tilelist.bmp !is null);
		const tiles_per_row = tilemap.tilelist.bmp.w / tiles.tilew;
		al_draw_bitmap_region (tilemap.tilelist.bmp.ptr,
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
	foreach (tilePos; PointRange(tilemap.layers[layer].size)) {
		Point pixelPos = tilePos * tileSize - viewPos;

		int i = tilemap.layers[layer].get(tilePos);
		if (i >= 0 && i < tilemap.tilelist.tilenum) {
			teg_drawtile(tilemap.tilelist, i, pixelPos.x, pixelPos.y);
		}
	}

	al_set_clipping_rectangle(ox, oy, ow, oh);
}
