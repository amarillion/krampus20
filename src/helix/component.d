module helix.component;

import std.stdio;

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
	
	protected Style style = null;
	protected string text = null;
	LayoutData layoutData;

	protected MainLoop window = null;
	
	this(MainLoop window) {
		this.window = window;
	}

	void setStyle(Style value) {
		style = value;
	}

	void setText(string value) {
		text = value;
	}

	void addChild(Component c) {
		children ~= c;
	}
		
	abstract void update();
	
	void draw(GraphicsContext gc) {
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
