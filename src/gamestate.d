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
import helix.richtext;
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

RichTextBuilder biotope(RichTextBuilder b, MainLoop window, int biotope) {
	const biotopes = [
		0: "sorry_sulfuric2",
		1: "mountain3",
		2: "sulfur4",
		3: "lava1",
		4: "canyon1",
		5: "lowland0",
		6: "salt4",
		7: "canyon2",
	];
	return b.img(window.resources.getBitmap(biotopes[biotope]));
}

RichTextBuilder species(RichTextBuilder b, MainLoop window, int sp) {
	return b.img(window.resources.getBitmap(START_SPECIES[sp].iconUrl));
}

	RichTextBuilder cellInfo(RichTextBuilder b, MainLoop window, Cell c) {
		b
		.h1("Selected area")
		.biotope(window, c.biotope)
		.text(format!`[%d, %d]`(c.x, c.y))
		.br()
		.text(format!
`Heat: %.2e GJ/km²
Temperature: %.0f °K
Heat gain from sun: %.2e GJ/km²/tick
Heat loss to space: %.2e GJ/km²/tick
Albedo: %.2f
%s
Latitude: %d deg

CO₂: %.1f
H₂O: %.1f
O₂: %.1f
Organic: %.1f`(
	c.heat, c.temperature, c.stellarEnergy, c.heatLoss, c.albedo, c.albedoDebugStr, 
	c.latitude, c.co2, c.h2o, c.o2, c.deadBiomass)).p();
		foreach(ref sp; c._species) { b
			.species(window, to!int(sp.speciesId))
			.text(format!": %.1f "(sp.biomass.get()));
			if (sp.status != "") { b.b(sp.status); }
			b.br();
		}
		return b;
	}


class GameState : State {

	Sim sim;
	RichText logElement;
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
		logElement = cast(RichText)getElementById("rt_cell_info");
		assert(logElement);

		auto btn1 = getElementById("btn_species_info");
		btn1.onAction.add({ 
			Component slotted = new Component(window);
			slotted.setStyle(window.getStyle("default")); //TODO: should not have to do this every time...

			auto info = START_SPECIES[speciesGroup.value.get()];
			ImageComponent img = new ImageComponent(window);
			img.layoutData = LayoutData(0, 0, 0, 0, 512, 384, LayoutRule.BEGIN, LayoutRule.CENTER);
			img.img = window.resources.getBitmap(info.coverArt);

			RichText rt1 = new RichText(window);
			rt1.setStyle(window.getStyle("default"));
			rt1.layoutData = LayoutData(528, 0, 0, 0, 0, 0, LayoutRule.STRETCH, LayoutRule.STRETCH);
			
			auto rtb = new RichTextBuilder().h1("Species info")
				.text(info.backstory)
				.p()
				.text(format("Albedo: %.2f", info.albedo)).br()
				.text("Likes:").br();

			foreach (k, v; info.biotopeTolerances) {
				if (v > 0.5) {
					rtb.biotope(window, k);
				}
			}
			rtb.p().text("Dislikes:").br();
			foreach (k, v; info.biotopeTolerances) {
				if (v < 0.5) {
					rtb.biotope(window, k);
				}
			}

				// TODO: likes and dislikes
			rt1.setSpans(rtb.build());
			
			slotted.addChild(img);
			slotted.addChild(rt1);
			Dialog dlg = new Dialog(window, slotted);
			window.pushScene(dlg);
		});

		auto btn2 = getElementById("btn_species_introduce");
		btn2.onAction.add({
			if (currentCell) {
				ulong selectedSpecies = speciesGroup.value.get();
				currentCell.addSpecies(selectedSpecies, 10);
				
				speciesGroup.buttons[selectedSpecies].disabled = true;
				addChild (new Timer(window, 400, {
					speciesGroup.buttons[selectedSpecies].disabled = false;
				}));
			}
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
		sim = new Sim(map.width, map.height);
		currentCell = sim.grid.get(Point(0));
		this.initBiotopes(map);
	}

	void initBiotopes(TileMap map) {
		// copy biotopes from layer to cells
		foreach(pos; PointRange(map.layer[0].size)) {
			int biotope = map.layer[0].get(pos);
			sim.grid.get(pos).biotope = biotope;
		}
	}

	
	override void update() {
		super.update();

		// in original game, delay was 500 msec
		static int tickDelay = 0;
		if (tickDelay++ == 25) {
			tickAndLog();
			tickDelay = 0;
		}
	}

	void tickAndLog() {
		sim.tick();
		// gridView.update(); // TODO
		logElement.setSpans (new RichTextBuilder().cellInfo(window, currentCell).build());
		planetElement.text = format("Tick: %s\n%s", sim.tickCounter, sim.planet);
		updateSpeciesMap();
		sim.checkAchievements(window);

	}

	void updateSpeciesMap() {
		
		foreach (cell; sim.grid.eachNode()) {

			Point pos = Point(cell.x, cell.y) * 2;
			Point[] deltas = PointRange(Point(2)).array;
			foreach (delta; deltas) {
				speciesMap.layer[0].set(pos + delta, -1);
				speciesMap.layer[1].set(pos + delta, -1);
			}

			// get top 4 species from cell...
			foreach (i; 0 .. min(cell.species.length, 4)) {
				auto sp = cell.species[i];
				if (sp.biomass.get() < 5.0) continue;
				const tileIdx = START_SPECIES[sp.speciesId].tileIdx;
				speciesMap.layer[0].set(pos + deltas[i], tileIdx);
				
				double change = sp.biomass.changeRatio();
				int tile2 = -1;
				if (change < 0.95) {
					tile2 = change < 0.9 ? 19: 18;
				}
				else if (change > 1.05) {
					tile2 = change > 1.10 ? 17: 16;
				}
				speciesMap.layer[1].set(pos + deltas[i], tile2);
			}


			// save each value to calculate ratio next round
			foreach (ref sp; cell.species) {
				sp.biomass.tick();
			}
		}
	}

}
