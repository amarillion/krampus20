module engine;

import helix.color;
import helix.component;
import helix.style;
import helix.resources;
import helix.mainloop;

import std.stdio;
import std.conv;
import std.math;

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_font;
import allegro5.allegro_ttf;

import std.json;

class StyledComponent : Component {

	Style style = null;
	string text = null;

	void setStyle(Style value) {
		style = value;
	}

	void setText(string value) {
		text = value;
	}

	override void draw(GraphicsContext gc) {
		assert(style);
		
		// render shadow
		// TODO

		// render background
		al_draw_filled_rectangle(x, y, x + w, y + h, style.getColor("background"));
		
		// render border
		const borderWidth = style.getNumber("border-width");
		ALLEGRO_COLOR borderColor = style.getColor("border");
		al_draw_line(x, y, x + w, y, style.getColor("border-top", borderColor), borderWidth);
		al_draw_line(x + w, y, x + w, y + h, style.getColor("border-right", borderColor), borderWidth);
		al_draw_line(x + w, y + h, x, y + h, style.getColor("border-bottom", borderColor), borderWidth);
		al_draw_line(x, y + h, x, y, style.getColor("border-left", borderColor), borderWidth);
		
		// render label
		//TODO: use stringz...
		ALLEGRO_COLOR color = style.getColor("color");
		ALLEGRO_FONT *font = style.getFont();
		int th = al_get_font_line_height(font);
		int tdes = al_get_font_descent(font);
		al_draw_text(font, color, x + w / 2, y + (h - th) / 2 - tdes, ALLEGRO_ALIGN_CENTER, cast(const char*) (text ~ '\0'));

		// render icon
		// TODO

		// render outline...
		// TODO
	}

	override void update() {}
}

class Engine : Component
{
	this(MainLoop window) {
		
		auto styleData = `{ "background": "#888888", "border": "#444444", "border-left": "#BBBBBB", "border-top": "#BBBBBB", "border-width": 2.0, "color": "#008000" }`;
		Style style = window.createStyle(styleData);

		// create child components
		auto button = new StyledComponent();
		button.setStyle(style);
		button.setShape(50, 50, 120, 40);
		button.text = "Hello World!";
		addChild(button);
	}

	void addChild(Component c) {
		children ~= c;
	}

	override void draw(GraphicsContext gc) {
		al_clear_to_color(Color.WHITE);
		foreach (child; children) {
			child.draw(gc);
		}
	}

	override void update() {
	}

}