module helix.widgets;

import helix.component;
import helix.mainloop;
import helix.util.vec;

import allegro5.allegro;
import allegro5.allegro_font;
import std.array;
import std.string : toStringz;

import helix.allegro.bitmap;

class ImageComponent : Component {

	Bitmap img = null;

	this(MainLoop window) {
		super(window);
	}

	override void draw(GraphicsContext gc) {
		assert(img);
		
		// stretch mode...
		// TODO: allow ohter drawing modes...
		int iw = img.w;
		int ih = img.h;
		al_draw_scaled_bitmap(img.ptr, 0, 0, iw, ih, x, y, w, h, 0);
	}
}

class Button : Component {

	this(MainLoop window) {
		super(window);
	}

	override void onMouseDown(Point p) {
		if (!disabled) {
			onAction.dispatch();
		}
	}
}

class PreformattedText : Component {
	
	this(MainLoop window) {
		super(window);
	}

	override void draw(GraphicsContext gc) {
		// given component width...
		ALLEGRO_FONT *font = styles[0].getFont();
		ALLEGRO_COLOR color = styles[0].getColor("color");
			
		// split text by newlines...
		int y = this.shape.y;
		const th = al_get_font_line_height(font);
		
		foreach(line; text.split("\n")) {
			al_draw_text(font, color, this.shape.x, y,  ALLEGRO_ALIGN_LEFT, toStringz(line));
			y += th;
		}
	}
}