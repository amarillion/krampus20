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
		auto mainloop = new MainLoop("krampus20");
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

		mainloop.resources.addFile("data/species_cover_art/angry_intro1.png");
		mainloop.resources.addFile("data/species_cover_art/catcrobe_intro1.png");
		mainloop.resources.addFile("data/species_cover_art/catcrobe_intro2.png");
		mainloop.resources.addFile("data/species_cover_art/donut_intro1.png");
		mainloop.resources.addFile("data/species_cover_art/fungi_intro0.png");
		mainloop.resources.addFile("data/species_cover_art/herbivore_intro0.png");
		mainloop.resources.addFile("data/species_cover_art/microb_intro1.png");
		mainloop.resources.addFile("data/species_cover_art/microb_intro2.png");
		mainloop.resources.addFile("data/species_cover_art/microb_intro4.png");
		mainloop.resources.addFile("data/species_cover_art/microb_intro5.png");
		mainloop.resources.addFile("data/species_cover_art/microb_intro7.png");
		mainloop.resources.addFile("data/species_cover_art/platn_intro1.png");
		mainloop.resources.addFile("data/species_cover_art/platn_intro2.png");

		mainloop.resources.addFile("data/images/biotope/canyon1.png");
		mainloop.resources.addFile("data/images/biotope/mountain3.png");
		mainloop.resources.addFile("data/images/biotope/sorry_sulfuric2.png");
		mainloop.resources.addFile("data/images/biotope/sorry_salt0.png");
		mainloop.resources.addFile("data/images/biotope/lava1.png");
		mainloop.resources.addFile("data/images/biotope/salt4.png");
		mainloop.resources.addFile("data/images/biotope/lowland0.png");
		mainloop.resources.addFile("data/images/biotope/sulfur4.png");
		mainloop.resources.addFile("data/images/biotope/canyon2.png");
		mainloop.resources.addFile("data/images/biotope/sorry_sulfuric1.png");

		mainloop.resources.addMusicFile("data/music/ExoMusicIntro.ogg");
		mainloop.resources.addMusicFile("data/music/ExoMusicLoop.ogg");

		mainloop.applyStyling("style");
		mainloop.addState("TitleState", new TitleState(mainloop));
		mainloop.addState("GameState", new GameState(mainloop));
		mainloop.switchState("TitleState");

		mainloop.audio.playMusic(mainloop.resources.getMusic("ExoMusicLoop"), 1.0);
		mainloop.run();

		return 0;
	});

}