module gamestate;

import engine;
import helix.mainloop;
import helix.widgets;
import helix.tilemapview;
import helix.tilemap;
import helix.util.vec;
import helix.util.coordrange;
import helix.layout;
import helix.component;
import std.json;
import sim;
import cell;
import std.conv;
import std.format;
import std.array;
import std.algorithm;
import startSpecies;
import std.stdio; // TODO: debug only

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
		
		initSpeciesButtons();
		initSim(planetMap);
	}

	void initSpeciesButtons() {
		Component parentElt = getElementById("pnl_species_buttons");
		int xco = 0;
		int yco = 0;
		foreach(sp; START_SPECIES) {
			Button btn = new Button(window);
			btn.layoutData = LayoutData(xco, yco, 0, 0, 36, 36, LayoutRule.BEGIN, LayoutRule.BEGIN);
			btn.icon = window.resources.getBitmap(sp.iconUrl);
			xco += 40;
			btn.style = window.getStyle("button");
			parentElt.addChild(btn);
		}
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
		updateSpeciesMap();
	}

	void updateSpeciesMap() {
		
		foreach (cell; sim.grid.eachNode()) {

			vec3i pos = vec3i(cell.x, cell.y, 0) * 2;
			vec3i[] deltas = CoordRange!vec3i(vec3i(2, 2, 1)).array;
			foreach (delta; deltas) {
				speciesMap.grid.set(pos + delta, -1);
			}

			// get top 4 species from cell...
			foreach (i; 0 .. min(cell.species.length, 4)) {
				auto sp = cell.species[i];
				if (sp.biomass < 5.0) continue;
				const tileIdx = START_SPECIES[sp.speciesId].tileIdx;
				speciesMap.grid.set(pos + deltas[i], tileIdx + 1);
			}
		}
	}

}
