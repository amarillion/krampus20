module cell;

import constants;
import startSpecies;
import planet;
import std.math;
import std.algorithm;
import std.range;
import species;
import std.format;

struct Cell {

	int x, y;

	// the following are all in Mol
	
	/** dead organic material, represented by formula ch2o */
	double deadBiomass = 0; 
	double co2 = START_CO2;
	double o2 = 0;
	double h2o = START_H2O;
	
	/** latitude in degrees, from -90 (north pole) to 90 (south pole) */
	int latitude;

	double heat = START_HEAT;
	double stellarEnergy;

	int biotope = 0;
	double temperature;
	double albedo;
	double heatLoss;
	string albedoDebugStr;

	/** 
	pairs of { speciesId, biomass }
	keep this list sorted, most prevalent species first
	*/
	SimpleSpecies[] _species;

	/** constructor */
	this(int x, int y) {
		this.x = x;
		this.y = y;

		// the following are all in Mol
		deadBiomass = 0; // dead organic material, represented by formula ch2o
		co2 = START_CO2;
		o2 = 0;
		h2o = START_H2O;
		latitude = ((y * 160 / (MAP_HEIGHT - 1)) - 80);
		heat = START_HEAT;
		
		// constant amount of stellar energy per tick
		stellarEnergy = cos(this.latitude / 180 * 3.141) * MAX_STELLAR_HEAT_IN;
		assert (this.stellarEnergy >= 0);

		_species = [];
	}

	double sumLivingBiomass() {
		return reduce!((acc, cur) => acc + cur.biomass)(0.0, _species);
	}

	SimpleSpecies[] species() {
		return _species;
	}

	// introduce a given amount of species to this cell
	void addSpecies(long speciesId, double biomass) {
		auto existing = _species.find!(i => i.speciesId == speciesId);
		if (!existing.empty) {
			existing[0].biomass += biomass;
			sortSpecies();
		}
		else {
			_species ~= SimpleSpecies(speciesId, biomass);
			maxSpeciesCheck();
		}
	}

	// if there are more than a given number of species in this cell, the last one is automatically removed
	void maxSpeciesCheck() {
		sortSpecies();
		if (_species.length > MAX_SPECIES_PER_CELL) {
			removeLowestSpecies();
		}
	}

	void removeLowestSpecies() {
		deadBiomass += _species[$-1].biomass; // biomass converted from dead species
		_species = _species[0..$-1]; // pop last one
	}

	// clean up pink elephants (as in: there are not 0.0001 pink elephants in this room)
	// if the amount of species drops below 1.0 mol, then the remainder dies and is cleaned up completely.
	void pinkElephantCheck() {
		sortSpecies();

		if (_species.empty) return;

		auto last = _species[$-1];
		if (last.biomass < 1.0) {
			removeLowestSpecies();
		}
	}

	void sortSpecies() {
		sort!"b.biomass < a.biomass"(_species); // TODO: check sort order...
	}

	string speciesToString() {
		return _species.map!(i => `${i.speciesId}: ${i.biomass.toFixed(1)}`).join("\n  ");
	}

	// string representation of cell...
	string toString() {
		return `[${this.x}, ${this.y}] Biotope: ${this.biotope}` ~
		`
Heat: ${this.heat.toExponential(2)} GJ/km^2
Temperature: ${this.temperature.toFixed(0)} K
Heat gain from sun: ${this.stellarEnergy.toExponential(2)} GJ/km^2/tick
Heat loss to space: ${this.heatLoss.toExponential(2)} GJ/km^2/tick
Albedo: ${this.albedo.toFixed(2)}
${this.albedoDebugStr}
Latitude: ${this.latitude.toFixed(0)} deg

CO2: ${this.co2.toFixed(1)}
H2O: ${this.h2o.toFixed(1)}
O2: ${this.o2.toFixed(1)}
Organic: ${this.deadBiomass.toFixed(1)}

Species: ${this.speciesToString()}`;
	}

	/** part of Phase I */
	void growAndDie() {
		// each species should grow and die based on local fitness.

		foreach (sp; _species) {
			const info = getStartSpecies()[sp.speciesId]; // TODO: caching

			double fitness = 1.0;
			assert (this.biotope in info.biotopeTolerances);
			fitness *= info.biotopeTolerances[this.biotope];
			
			// no chance of survival outside preferred temperature range
			if (temperature < info.temperatureRange[0] ||
				temperature > info.temperatureRange[1]) {
				fitness *= 0.1;
			}

			//TODO: fitness is affected by presence of symbionts
	
			// fitness must always be a value between 0.0 and 1.0
			assert(fitness >= 0.0 && fitness <= 1.0);

			// each species has 3 possible roles:
			// consumer, producer, reducer	
			if (info.role == ROLE.PRODUCER) {
				// lowest substrate determines growth rate.
				const minS = min(this.co2, this.h2o);
				const rate = fitness * this.temperature * this.stellarEnergy * PHOTOSYNTHESIS_BASE_RATE * minS; // growth per tick
				
				const amount = min(sp.biomass * rate, this.co2, this.h2o);
				assert (amount >= 0);

				co2 -= amount;
				h2o -= amount;

				o2 += amount;
				sp.biomass += amount;
				assert (sp.biomass >= 0);
			}
			else if (info.role == ROLE.CONSUMER) {
				// for each other species
				foreach (other; _species) {
					if (other.speciesId == sp.speciesId) continue; // don't interact with self

					const interaction = info.interactionMap[other.speciesId];
					if (interaction == INTERACTION.EAT) {
						// sp(ecies) eats other (species)
						// take some of the biomass from other, and adopt it as own biomass
						const rate = fitness * CONVERSION_BASE_RATE * other.biomass;
						const amount = min(sp.biomass * rate, other.biomass);

						assert (amount >= 0);
						other.biomass -= amount;
						sp.biomass += amount;

						assert(sp.biomass >= 0);
						assert(other.biomass >= 0);
					}
				}
			}
			else if  (info.role == ROLE.REDUCER) {
				// reducers take some of the dead biomass, and adopt it as their own biomass
				const rate = fitness * CONVERSION_BASE_RATE * this.deadBiomass;
				const amount = min(sp.biomass * rate, this.deadBiomass);

				assert (amount >= 0);
				deadBiomass -= amount;
				sp.biomass += amount;

				assert (this.deadBiomass >= 0);
				assert (sp.biomass >= 0);
			}

			if (info.role != ROLE.PRODUCER) {
				// simulate respiration for consumers and reducers.
				// lowest substrate determines growth rate.
				const minS = min(sp.biomass, this.o2);
				// not affected by fitness - all species consume oxygen at a given rate
				const rate = RESPIRATION_BASE_RATE * minS;
				const amount = min(sp.biomass, sp.biomass * rate, this.o2);

				assert (amount >= 0);
				this.o2 -= amount;
				sp.biomass -= amount;
				this.h2o += amount;
				this.co2 += amount;

				assert (this.deadBiomass >= 0);
				assert (sp.biomass >= 0);
			}

			// all species die at a given rate...
			{
				assert(sp.biomass >= 0, `Wrong value ${sp.biomass} ${sp.speciesId}`);

				// the lower the fitness, the higher the death rate
				// divisor has a minimum just above 0, to avoid division by 0
				// death rate has a maximum of 1.0 (instant death)
				const rate = min(1.0, DEATH_RATE / max(fitness, 0.0001));
				const amount = min(sp.biomass * rate, sp.biomass);

				assert (amount >= 0);
				this.deadBiomass += amount;
				sp.biomass -= amount;

				assert(sp.biomass >= 0);
			}

			assert(sp.biomass >= 0);
		}

		assert (this.o2 >= 0);
		assert (this.co2 >= 0);
		assert (this.h2o >= 0);
		assert (this.deadBiomass >= 0);

		pinkElephantCheck();
	}

	void migrateTo(Cell other) {
		if (this._species.length == 0) return;

		foreach (sp; _species) {
			const amount = sp.biomass * 0.02;
			
			// do not migrate less than one unit - otherwise it will die immediately and will be a huge drain on early growth
			if (amount < 1.0) {
				continue;
			}

			other.addSpecies(sp.speciesId, amount);
			sp.biomass -= amount;
		}
	}

	void diffuseProperty(string prop)(ref Cell other, double pct_exchange) {
		mixin ("const netAmount = (this."  ~ prop ~ " * pct_exchange) - (other." ~ prop ~ " * pct_exchange);");
		mixin("this." ~ prop ~ " -= netAmount;");
		mixin("other." ~ prop ~ " += netAmount;");
		mixin("assert(this." ~ prop ~  " >= 0);");
		mixin("assert(other." ~ prop ~ " >= 0);");
	}

	void diffusionTo(Cell other) {

		// diffusion of CO2
		{
			// if CO2 is solid, a smaller percentage will diffuse
			const pct_exchange = this.temperature < CO2_BOILING_POINT ? 0.001 : 0.1;
			this.diffuseProperty!"co2"(other, pct_exchange);
		}

		// diffusion of H2O
		{
			// if H2O is solid, a smaller percentage will diffuse
			const pct_exchange = this.temperature < H2O_MELTING_POINT ? 0.001 : 0.1;
			this.diffuseProperty!"h2o"(other, pct_exchange);
		}

		// diffusion of o2
		{
			const pct_exchange = 0.1;
			this.diffuseProperty!"o2"(other, pct_exchange);
		}

		// heat diffusion.
		// a percentage of heat always diffuses...
		// TODO to be realistic, we should also make this dependent on weather
		{
			const pct_exchange = 0.1;
			this.diffuseProperty!"heat"(other, pct_exchange);
		}
	}

	/** calculate heat, albedo, greenhouse effect */
	void updatePhysicalProperties() {
		this.temperature = this.heat / SURFACE_HEAT_CAPACITY; // In Kelvin
		
		// intersects y-axis at 1.0, reaches lim in infinity.
		double mapAlbedoReduction (double lim, double x) {
			return lim + ((1-lim)/(x+1));
		}

		// intersects y-axis at base, reaches 1.0 in infinity
		double mapAlbedoRise (double base, double x) {
			return 1 - ((1-base)/(x+1));
		}

		// start albedo
		// albedo decreased by absence of dry ice or ice
		// (this will increase albedo at the poles for a long time)
		const dryIceEffect = this.temperature < CO2_BOILING_POINT ? mapAlbedoRise(0.9, this.co2 / 1000) : 0.9;
		const iceEffect = this.temperature < H2O_MELTING_POINT ? mapAlbedoRise(0.9, this.h2o / 1000) : 0.9;
		
		const ALBEDO_BASE = 0.75;
		this.albedo = ALBEDO_BASE * iceEffect * dryIceEffect;

		albedoDebugStr = format(`%g * %g [ice] * %g [dryIce]`, ALBEDO_BASE, iceEffect, dryIceEffect);

		foreach (sp; _species) {
			const info = getStartSpecies()[sp.speciesId]; // TODO: better caching
			const speciesEffect = mapAlbedoReduction(info.albedo, sp.biomass / 500);
			this.albedo *= speciesEffect;
			albedoDebugStr ~= format(` * %g [%s] `, speciesEffect, sp.speciesId);
		}

		albedoDebugStr = albedoDebugStr;

		assert(this.albedo >= 0.0 && this.albedo <= 1.0);

		// receive fixed amount of energy from the sun, but part radiates back into space by albedo effect
		this.heat += (1.0 - this.albedo) * this.stellarEnergy;

		// percentage of heat radiates out to space
		const heatLossPct = 0.01; // TODO: influenced by greenhouse effect and albedo
		this.heatLoss = this.heat * heatLossPct;
		this.heat -= (this.heatLoss);
	}

	void updateStats(Planet planet) {
		planet.co2 += this.co2;
		planet.o2 += this.o2;
		planet.h2o += this.h2o;
		planet.deadBiomass += this.deadBiomass;

		planet.albedoSum += this.albedo;
		planet.temperatureSum += this.temperature;

		if (this.temperature > planet.maxTemperature) { planet.maxTemperature = this.temperature; }
		if (this.temperature < planet.minTemperature) { planet.minTemperature = this.temperature; }
		
		foreach (sp; _species) {
			if (!(sp.speciesId in planet.species)) {
				planet.species[sp.speciesId] = 0;
			}
			planet.species[sp.speciesId] += sp.biomass;
		}

	}

}