module helix.tilemap;

import std.json;
import std.format;
import helix.util.grid;
import helix.util.vec;
import helix.util.coordrange;
import allegro5.allegro;
import std.conv;

struct TileList {
	int tilew;
	int tileh;
	int tilenum;
	ALLEGRO_BITMAP *bmp = null;

	void fromTiledJSON(JSONValue node) {
		tilew = to!int(node["tilewidth"].integer);
		tileh = to!int(node["tileheight"].integer);
		tilenum = to!int(node["tilecount"].integer);
		// TODO: also link up bitmap...
	}
}

alias TileGrid = Grid!(3, int);

struct TileMap {

	TileGrid grid;
	TileList tilelist;

	void fromTiledJSON(JSONValue node) {

		int w = cast(int)node["width"].integer;
		int h = cast(int)node["height"].integer;

		int dl = 0;
		foreach (l; node["layers"].array) {
			if (l["type"].str == "tilelayer") { dl++; }
		}
		assert(dl > 0);
		grid = new Grid!(3, int)(w, h, dl);

		tilelist.fromTiledJSON(node["tilesets"].array[0]);

		vec3i ll = vec3i(0);
		foreach (l; node["layers"].array) {
			if (l["type"].str != "tilelayer") { continue; }

			auto data = l["data"].array;
			foreach (p; CoordRange!vec3i(vec3i(w, h, 1))) {
				int val = to!int(data[p.x + (p.y * w)].integer - 1);
				grid.set(ll + p, val);
			}
			ll.z = ll.z + 1;
		}
	}

	string toString() {
		return format("TileMap(%s, tiles: %s)", grid.size, tilelist.tilenum);
	}
}