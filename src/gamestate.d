module gamestate;

import engine;
import helix.mainloop;
import helix.widgets;
import helix.tilemap;
import helix.util.vec;
import helix.util.coordrange;
import helix.layout;
import helix.component;
import planetview;
import std.json;
import sim;
import cell;
import std.conv;
import std.format;
import std.array;
import std.algorithm;
import startSpecies;
import std.stdio; // TODO: debug only
import helix.signal;
import helix.timer;
import dialog;

class RadioGroup(T) {

	Model!T value;
	Component[T] buttons;

	void addButton(Component c, T _value) {
		buttons[_value] = c;
		c.onAction.add({
			value.set( _value);
			updateButtons();
		});
	}

	void updateButtons() {
		foreach(v, button; buttons) {
			button.selected = (v == value.get());	
		}
	}
}

class GameState : State {

	Sim sim;
	Component logElement;
	Component planetElement;
	TileMap planetMap;
	TileMap speciesMap;
	Cell currentCell;
	RadioGroup!ulong speciesGroup;
	PlanetView planetView;

	this(MainLoop window) {
		super(window);

		/* GAME SCREEN */
		buildDialog(window.resources.getJSON("game-layout"));

		planetMap.fromTiledJSON(window.resources.getJSON("planetscape")); 
		planetMap.tilelist.bmp = window.resources.getBitmap("biotope");

		speciesMap.fromTiledJSON(window.resources.getJSON("speciesmap"));
		speciesMap.tilelist.bmp = window.resources.getBitmap("species");

		auto planetViewParentElt = getElementById("div_planet_view");
		
		planetView = new PlanetView(window);
		planetView.planetMap = planetMap;
		planetView.speciesMap = speciesMap;
		planetView.selectedTile.onChange.add({
			currentCell = sim.grid.get(planetView.selectedTile.get());
		});
		planetViewParentElt.addChild(planetView);
	
		planetElement = getElementById("pre_planet_info");
		logElement = getElementById("pre_cell_info");
		
		auto btn1 = getElementById("btn_species_info");
		btn1.onAction.add({ 
			openDialog(window, START_SPECIES[speciesGroup.value.get()].backstory); 
		});

		auto btn2 = getElementById("btn_species_introduce");
		btn2.onAction.add({
			writefln("Introducing species %s at %s", speciesGroup.value.get(), planetView.selectedTile.get());
			
			if (currentCell) {
				ulong selectedSpecies = speciesGroup.value.get();
				currentCell.addSpecies(selectedSpecies, 10);
				
				// TODO...
				speciesGroup.buttons[selectedSpecies].disabled = true;
				
				// TODO
				addChild (new Timer(window, 400, {
					speciesGroup.buttons[selectedSpecies].disabled = false;
				}));
				// speciesElement.disableSpecies(selectedSpecies, sim.tick);

				// very crude hack. We should trigger on a particular tick instead
				// setTimeout(() => this.speciesElement.enableSpecies(selectedSpecies), 20000);
			}

			// sim.introduceSpecies(); //TODO
		});

		initSpeciesButtons();
		initSim(planetMap);
	}

	void initSpeciesButtons() {
		Component parentElt = getElementById("pnl_species_buttons");
		int xco = 0;
		int yco = 0;
		speciesGroup = new RadioGroup!ulong();
		
		foreach(i, sp; START_SPECIES) {
			Button btn = new Button(window);
			btn.layoutData = LayoutData(xco, yco, 0, 0, 36, 36, LayoutRule.BEGIN, LayoutRule.BEGIN);
			btn.icon = window.resources.getBitmap(sp.iconUrl);
			xco += 40;
			btn.setStyle(window.getStyle("button"));
			btn.setStyle(window.getStyle("button", "selected"), 1);
			btn.setStyle(window.getStyle("button", "disabled"), 2);
			parentElt.addChild(btn);
			speciesGroup.addButton(btn, i);
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

	
	override void update() {
		super.update();

		// in original game, delay was 500 msec
		static int tickDelay = 0;
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
		sim.checkAchievements(window);

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
				speciesMap.grid.set(pos + deltas[i], tileIdx);
			}
		}
	}

}
