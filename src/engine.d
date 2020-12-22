module engine;

import helix.color;
import helix.component;

import std.stdio;
import std.conv;
import std.math;

import allegro5.allegro;
import allegro5.allegro_primitives;

class Engine : Component
{
	override void draw(GraphicsContext gc) {
		al_clear_to_color(WHITE);
		al_draw_rectangle(50, 50, 100, 100, RED, 2.0);
	}

	override void update() {
	}

}