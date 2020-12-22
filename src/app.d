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
		auto engine = new Engine();
		mainloop.setEngineComponent(engine);
		mainloop.run();
		return 0;
	});

}