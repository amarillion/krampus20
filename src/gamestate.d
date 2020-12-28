module gamestate;

import engine;
import helix.mainloop;
import helix.widgets;
import helix.tilemapview;
import helix.tilemap;
import helix.util.vec;
import helix.util.coordrange;
import helix.component;
import std.json;
import sim;
import cell;
import std.conv;
import std.format;

class GameState : State {

	Sim sim;
	Component logElement;
	Component planetElement;
	TileMap planetMap;
	TileMap speciesMap;
	Cell currentCell;

	this(MainLoop window) {
		super(window);

		/* GAME SCREEN */
		buildDialog(window.resources.getJSON("game-layout"));

		planetMap.fromTiledJSON(window.resources.getJSON("planetscape")); 
		planetMap.tilelist.bmp = window.resources.getBitmap("biotope");

		speciesMap.fromTiledJSON(window.resources.getJSON("speciesmap"));
		speciesMap.tilelist.bmp = window.resources.getBitmap("species");

		{
			auto tilemapElt = cast(TileMapView)getElementById("tmap_planet_layer");
			tilemapElt.tilemap = planetMap;
		}
		{
			auto tilemapElt = cast(TileMapView)getElementById("tmap_organism_layer");
			tilemapElt.tilemap = speciesMap;
		}

		planetElement = getElementById("pre_planet_info");
		logElement = getElementById("pre_cell_info");

		initSim(planetMap);
	}

	void initSim(TileMap map) {
		sim = new Sim(map.grid.width, map.grid.height);
		currentCell = sim.grid.get(Point(0));
		this.initBiotopes(map);
	}

	void initBiotopes(TileMap map) {
		// copy biotopes from layer to cells
		foreach(pos; CoordRange!vec3i(map.grid.size)) {
			int biotope = map.grid.get(pos);
			sim.grid.get(Point(pos.x, pos.y)).biotope = biotope;
		}
	}

	int tickDelay = 0;
	override void update() {
		// in original game, delay was 500 msec
		if (tickDelay++ == 30) {
			tickAndLog();
			tickDelay = 0;
		}
	}

	void tickAndLog() {
		sim.tick();
		// gridView.update(); // TODO
		logElement.text = to!string(currentCell);
		planetElement.text = format("Tick: %s\n%s", sim.tickCounter, sim.planet);
		// updateSpeciesMap(); //TODO
	}

/*
	void updateSpeciesMap() {
		
		foreach (cell; sim.grid.eachNode()) {
			const mx = (cell.x * 2) + 0.5;
			const my = (cell.y * 2) + 0.5;
			
			let dx = 0.5;
			let dy = 0.5;

			for (let i = 0; i < 4; ++i) {
				this.speciesMap.removeTileAt(mx + dx, my + dy);
				[dx, dy] = [-dy, dx]; // rotate 90 degrees
			}

			// get top 4 species from cell...
			for (const { speciesId, biomass } of cell.species.slice(0, 4)) {
				if (biomass < 5.0) continue;
				const tileIdx = START_SPECIES[speciesId].tileIdx;
				this.speciesMap.putTileAt(tileIdx + 1, mx + dx, my + dy);
				[dx, dy] = [-dy, dx]; // rotate 90 degrees
			}
		}
	}
*/
}
