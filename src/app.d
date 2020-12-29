module app;

import std.stdio;
import helix.mainloop;
import engine;
import gamestate;
import allegro5.allegro;
import startSpecies;

void main()
{
	al_run_allegro(
	{
		// non-allegro setup
		initStartSpecies();

		al_init();
		auto mainloop = new MainLoop();
		mainloop.init();
		
		mainloop.resources.addFile("data/DejaVuSans.ttf");
		mainloop.resources.addFile("data/images/start3.png");
		mainloop.resources.addFile("data/images/biotope.png");
		mainloop.resources.addFile("data/images/species.png");
		mainloop.resources.addFile("data/style.json");
		mainloop.resources.addFile("data/title-layout.json");
		mainloop.resources.addFile("data/game-layout.json");
		mainloop.resources.addFile("data/dialog-layout.json");
		mainloop.resources.addFile("data/planetscape.json");
		mainloop.resources.addFile("data/speciesmap.json");

		mainloop.resources.addFile("data/images/species/angry1.png");
		mainloop.resources.addFile("data/images/species/catcrobe1.png");
		mainloop.resources.addFile("data/images/species/catcrobe2.png");
		mainloop.resources.addFile("data/images/species/donut1.png");
		mainloop.resources.addFile("data/images/species/fungi0.png");
		mainloop.resources.addFile("data/images/species/fungi1.png");
		mainloop.resources.addFile("data/images/species/herbivore0.png");
		mainloop.resources.addFile("data/images/species/microb1.png");
		mainloop.resources.addFile("data/images/species/microb2.png");
		mainloop.resources.addFile("data/images/species/microb3.png");
		mainloop.resources.addFile("data/images/species/microb4.png");
		mainloop.resources.addFile("data/images/species/microb5.png");
		mainloop.resources.addFile("data/images/species/plant0.png");
		mainloop.resources.addFile("data/images/species/plant1.png");

		mainloop.applyStyling("style");
		mainloop.addState("TitleState", new TitleState(mainloop));
		mainloop.addState("GameState", new GameState(mainloop));
		mainloop.switchState("TitleState");
		mainloop.run();
		return 0;
	});

}