module app;

import std.stdio;
import helix.mainloop;
import engine;
import allegro5.allegro;

void main()
{
	al_run_allegro(
	{
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

		mainloop.applyStyling("style");
		mainloop.addState("TitleState", new TitleState(mainloop));
		mainloop.addState("GameState", new GameState(mainloop));
		mainloop.switchState("TitleState");
		mainloop.run();
		return 0;
	});

}