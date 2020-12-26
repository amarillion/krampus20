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
		mainloop.resources.addFile("data/style.json");
		mainloop.applyRootStyle("style");
		
		auto engine = new Engine(mainloop);
		mainloop.setRootComponent(engine);
		mainloop.run();
		return 0;
	});

}