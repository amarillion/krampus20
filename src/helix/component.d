module helix.component;

import std.stdio;

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import helix.util;
import helix.mainloop;
import helix.style;
import helix.signal;
import helix.rect;
import helix.vec;

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
	/* may be null */
	private Component cparent = null;
	
	//TODO: encapsulate
	Component[] children;
	MainLoop window = null;
	string id;

	protected Style style = null;
	protected string text = null;

	void setStyle(Style value) {
		style = value;
	}

	void setText(string value) {
		text = value;
	}

	/** 
		may only be called by container.add()
		may only be called once: it's not allowed to reassign to a different parent.
	*/
	private void _setParent (Component value)
	{
		assert (cparent is null); // may not reassign parent.
		cparent = value;
	}	
	
	/** returns the parent component, 
		or null if this component hasn't be added to anything yet. */	
	@property public Component parent() { return cparent; }
		
	/* local font. May be null, in which case the parent font is used */
	private ALLEGRO_FONT *cfont;
	
	abstract void update();
	abstract void draw(GraphicsContext gc);
	
	private Rectangle rect;
	
	/** set both position and size together */
	public void setShape (double _x, double _y, double _w, double _h)
	{
		rect.x = _x;
		rect.y = _y;
		rect.w = _w;
		rect.h = _h;
	}

	/** set both x and y together */
	public void setPosition (double _x, double _y)
	{
		rect.x = _x;
		rect.y = _y;
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
		return rect.contains(p);
	}
	
	@property double x() { return rect.x; }
	@property double y() { return rect.y; }
	@property double w() { return rect.w; }
	@property double h() { return rect.h; }

	//TODO: store in rectangle struct
	@property void x(double val) { rect.x = val; }
	@property void y(double val) { rect.y = val; }
	@property void w(double val) { rect.w = val; }
	@property void h(double val) { rect.h = val; }
}
