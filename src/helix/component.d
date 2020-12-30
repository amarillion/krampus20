module helix.component;

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import helix.util.math;
import helix.mainloop;
import helix.style;
import helix.signal;
import helix.util.rect;
import helix.util.vec;
import helix.layout;
import helix.color;

import std.string;
import std.algorithm;
import std.range;

class GraphicsContext
{
	Rectangle area;
}

/**
A component occupies an area (x,y,w,h) and 
knows how to draw itself. 

It does not need to opaquely fill the area,
i.e. it can be transparent or non-rectangular.

A component may receive mouse events or keyboard events
from its parent.
*/
class Component
{		
	//TODO: encapsulate
	Component[] children;
	string id;
	Rectangle shape;
	ALLEGRO_BITMAP *icon;
	string text = null;

	//TODO: put collection of styles together more sensibly...
	protected Style[] styles = []; // 0: normal, 1: selected, 2: disabled...

	LayoutData layoutData;

	protected MainLoop window = null;
	
	// FLAGS:
	bool selected = false; // indicates toggled, checked, pressed or selected state 
	bool hidden = false;
	bool focused = false; // used for keyboard focus. Display with outline.
	bool disabled = false;
	bool invalid = false; // used for input validation
	bool readonly = false; // used for edit controls
	bool canFocus = false;
	bool killed = false;

	this(MainLoop window) {
		this.window = window;
		styles.length = 3; //TODO: currently can only store 3 styles...
	}

	void setStyle(Style value, int mode = 0) {
		styles[mode] = value;
	}

	void setText(string value) {
		text = value;
	}

	void addChild(Component c) {
		children ~= c;
	}

	void clearChildren() {
		children = [];
	}

	void update() {
		if (killed) return;
		foreach(child; children) {
			child.update();
		}
		children = children.filter!(c => !c.killed).array;
	}

	void kill() {
		killed = true;
	}

	void draw(GraphicsContext gc) {
		if (killed || hidden) return;
		
		Style style = disabled ? styles[2] : (selected ? styles[1] : styles[0]);
		assert(style, "You must set a style for the current state");
		
		// render shadow
		// TODO

		// render background
		ALLEGRO_COLOR background = style.getColor("background");
		if (!background.isTransparent()) {
			al_draw_filled_rectangle(x, y, x + w, y + h, background);
		}
		
		// render border
		const borderWidth = style.getNumber("border-width");
		if (borderWidth > 0) {
			al_draw_line(x, y, x + w, y, style.getColor("border-top", "border"), borderWidth);
			al_draw_line(x + w, y, x + w, y + h, style.getColor("border-right", "border"), borderWidth);
			al_draw_line(x + w, y + h, x, y + h, style.getColor("border-bottom", "border"), borderWidth);
			al_draw_line(x, y + h, x, y, style.getColor("border-left", "border"), borderWidth);
		}

		// render icon
		if (icon != null) {
			int iw = al_get_bitmap_width(icon);
			int ih = al_get_bitmap_height(icon);
			al_draw_bitmap (icon, x + (w - iw) / 2, y + (h - ih) / 2, 0);
		}

		// render label
		if (text != "") {
			//TODO: use stringz...
			ALLEGRO_COLOR color = style.getColor("color");
			ALLEGRO_FONT *font = style.getFont();
			int th = al_get_font_line_height(font);
			al_draw_text(font, color, x + w / 2, y + (h - th) / 2, ALLEGRO_ALIGN_CENTER, toStringz(text));
		}

		// render focus outline...
		// TODO

		// and draw children.
		// TODO - should this be done by MainLoop/Window?
		foreach (child; children) {
			child.draw(gc);
		}

	}
	
	
	/** set both position and size together */
	public void setShape (int _x, int _y, int _w, int _h)
	{
		shape.x = _x;
		shape.y = _y;
		shape.w = _w;
		shape.h = _h;
	}

	/** set both x and y together */
	public void setPosition (int _x, int _y)
	{
		shape.x = _x;
		shape.y = _y;
	}	
	
	/** should return true if keyboard event is handled, false otherwise */
	public bool onKey(int code, int c, int mod) { return false; }
	
	Signal onAction;

	public void onMouseEnter() { }

	public void onMouseLeave() { }
	
	public void onMouseMove(Point p) { }

	public void onMouseDown(Point p) { }

	public void onMouseUp(Point p) { }

	public void gainFocus() { }
	
	// public bool hasFocus() 
	// { 
	// 	if (!cparent) return false;
	// 	return cparent.focus == this;
	// }
	
	public void loseFocus() { }
	
	//TODO: add to Rectangle	
	public bool contains(Point p)
	{
		return shape.contains(p);
	}
	
	@property int x() { return shape.x; }
	@property int y() { return shape.y; }
	@property int w() { return shape.w; }
	@property int h() { return shape.h; }

	//TODO: store in rectangle struct
	@property void x(int val) { shape.x = val; }
	@property void y(int val) { shape.y = val; }
	@property void w(int val) { shape.w = val; }
	@property void h(int val) { shape.h = val; }
}
