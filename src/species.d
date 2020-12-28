module species;

/*
long globalSpeciesCounter = 0;

struct Species {

	long id;
	string dna;
	double biomass;
	
	this() {
		id = globalSpeciesCounter++;
		dna = ""; // TODO random data
		calculateProperties();
	}

	void calculateProperties() {

	}
}
*/


struct SimpleSpecies {
	long speciesId;
	double biomass;
}