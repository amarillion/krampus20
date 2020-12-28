module sim;

import helix.util.grid;
import planet;
import species;
import cell;
import helix.util.vec;
import helix.dialog;

struct Trigger {
	string id;
	bool delegate(Sim) condition;
	string delegate(Sim) toMessage;
}

const TRIGGERS = [
	Trigger(
		"start",
		(sim) => sim.tickCounter > 0,
		(sim) => `<h1>Welcome to Exo Keeper</h1>
		<p>After a voyage of hundreds of lightyears, you have now arrived. Before you lies the barren surface of Kepler-7311b
		Your goal is to make the surface suitable for human inhabitation. 
		But the planet is far too cold. At a breezy ${sim.planet.temperature.toFixed(0)} K (Or ${(sim.planet.temperature - 273).toFixed(0)} C) it's impossible to 
		step outside without a jacket. Plus, there is no oxygen atmosphere.
		<p>
		To terraform the planet, we must introduce some microbe species to the surface.
		<p>
		Study and choose one of the 12 species below. Click on any location in the map, pick a species, and click 'Introduce species'.
		Note that after introducing a species, it takes 20 seconds of game-time before another new batch of that species is ready again.
		<p>
		To look around the planet surface, use the arrow keys and Q/E to zoom in/out`,
	),
	Trigger(
		"dead_biomass_increased",
		(sim) => sim.planet.deadBiomass > 1.2e5,
		(sim) => `<h1>Dead biomass build-up</h1>
		<p>Life on the surface is harsh, and microbes are dying, leaving their dead bodies behind.
		They won't decompose, unless you introduce the microbes that do so. Make sure you introduce some decomposers!`
	),
	Trigger(
		"albedo_lowered",
		(sim) => (sim.tickCounter > 10 && sim.planet.albedo < 0.65),
		(sim) => `<h1>Albedo is lowering</h1>
		<p>Great job! The albedo of the planet is currently ${sim.planet.albedo.toFixed(2)} and lowering.
		With a lower albedo, more of the energy from the star Kepler-7311 is being absorbed, warming the surface.
		By introducing more species, you can decrease the albedo of the planet even further`
	),
	Trigger(
		"first_ice_melting",
		(sim) => sim.planet.maxTemperature > 273,
		(sim) => `<h1>First ice is melting</h1>
		<p>At the warm equator, the temperature has reached ${sim.planet.maxTemperature.toFixed(0)} K (Or ${(sim.planet.maxTemperature - 273).toFixed(0)} C)
		This means that ice starts melting and the planet is getting even more suitable for life.
		Can you reach an average temperature of 298 K?`
	),
	Trigger(
		"room_temperature_reached",
		(sim) => sim.planet.temperature > 298,
		(sim) => `<h1>Temperate climate</h1>
		<p>The average temperature of your planet now stands at ${sim.planet.temperature.toFixed(0)} K (Or ${(sim.planet.temperature - 273).toFixed(0)} C)
		The ice has melted, there is oxygen in the atmosphere, the surface is teeming with life.
		Well done, you have taken this game as far as it goes!
		<p>
		Thank you for playing.
		Did you like it? Let us know at @Gekaremi, @Donall or @mpvaniersel on twitter!`
	)
];

class Sim {

	/** grid for cellular automata */
	Grid!(2, Cell) grid;

	SimpleSpecies[long] species; // map of species by id.

	Planet planet;
	long tickCounter = 0;
	bool[string] achievements;

	this(int w, int h) {
		// TODO: return to larger grid
		grid = new Grid!(2, Cell)(w, h);
		planet = new Planet(); // planetary properties
		init();
	}

	void init() {
		// introduce the first species with random DNA
		// NB: the first 12 species will be hardcoded
		foreach (i; 0..4) {
			// this.createSpecies();
		
			// randomly drop some species in a few spots.
			// for (let j = 0; j < 5; ++j) {
			// 	const randomCell = this.grid.randomCell();
			// 	randomCell.addSpecies(lca.id, 100);
			// }
		}
	}

/*
	void createSpecies() {
		//TODO - I don't think this was used at all?
		const s = new Species();
		species[s.id] = s;
		return s;
	}
*/
	void tick() {
		updatePhysicalProperties();
		// phase I
		growAndDie();
		// phase II
		interact();
		// phase III
		evolve();
		// phase IV
		migrate();
		// phase V
		updatePlanet();

		tickCounter += 1;
	}

	void updatePhysicalProperties() {
		foreach (ref c; grid.eachNode()) {
			c.updatePhysicalProperties();
		}

		// for each pair of cells, do diffusion
		foreach (ref c; grid.eachNodeCheckered()) {
			foreach (other; grid.getAdjacent(Point(c.x, c.y))) {
				c.diffusionTo(grid.get(other));
			}
		}
	}

	void growAndDie() {
		foreach (c; grid.eachNode()) {
			c.growAndDie();
		}
	}

	void interact() {

	}

	void evolve() {

	}

	void migrate() {
		// for each pair of cells, do migration
		foreach (cell; grid.eachNodeCheckered()) {
			foreach (other; grid.getAdjacent(Point(cell.x, cell.y))) {
				cell.migrateTo(grid.get(other));
			}
		}

	}

	void updatePlanet() {
		this.planet.reset();
		foreach (c; grid.eachNode()) {
			c.updateStats(this.planet);
		}
		const n = grid.width * grid.height;
		planet.temperature = planet.temperatureSum / n;
		planet.albedo = planet.albedoSum / n;

		checkAchievements();
	}

	void checkAchievements() {
		foreach (v; TRIGGERS) {
			// don't trigger twice...
			if (v.id in this.achievements) continue;

			if (v.condition(this)) {
				achievements[v.id] = true;
				openDialog(v.toMessage(this));
			}
		}
	}

}