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

class ImageComponent : StyledComponent {

	ALLEGRO_BITMAP *img = null;

	override void draw(GraphicsContext gc) {
		assert(img);
		// stretch mode...
		al_draw_scaled_bitmap(img, 0, 0, img.al_get_bitmap_width, img.al_get_bitmap_height, x, y, w, h, 0);
	}

	override void update() {}
}

class Engine : Component
{
	void buildDialog(JSONValue data) {
		
		auto styleData = `{ "background": "#888888", "border": "#444444", "border-left": "#BBBBBB", "border-top": "#BBBBBB", "border-width": 2.0, "color": "#FFFFFF" }`;
		Style style = window.createStyle(styleData);

		assert(data.type == JSONType.ARRAY);

		// ## TODO: crashes here...???
		foreach (eltData; data.array) {
			// create child components
		
			StyledComponent div = null;
			string type = eltData["type"].str;
			switch(type) {
				case "image": {
					ImageComponent img = new ImageComponent();
					img.img = window.resources.getBitmap(eltData["src"].str);
					div = img;
					break;
				}
				default: div = new StyledComponent(); break;
			}

			JSONValue layout = eltData["layout"].object;
			const top = layout["top"].integer;
			const left = layout["left"].integer;
			const width = layout["w"].integer;
			const height = layout["h"].integer;
			div.setShape(top, left, width, height);
			if ("text" in eltData) {
				div.text = eltData["text"].str;
			}
			div.style = style;
			if ("id" in eltData) {
				div.id = eltData["id"].text;
			}
			addChild(div);
		}
		

	}

	this(MainLoop window) {
		this.window = window;
		buildDialog(window.resources.getJSON("layout"));
		// getElementById("btn_start_game").onClick({ writeln("Hello World"); });
	}

	void addChild(Component c) {
		children ~= c;
	}

	override void draw(GraphicsContext gc) {
		foreach (child; children) {
			child.draw(gc);
		}
	}

	override void update() {
	}

}