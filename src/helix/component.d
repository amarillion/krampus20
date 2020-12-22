module helix.component;

import std.stdio;

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import helix.util;

class GraphicsContext
{
	Rectangle area;
}

struct Rectangle
{
	double x;
	double y;
	double w;
	double h;
	
	//TODO: choose returning or inplace replacement for intersection and merge.
	void merge (double _x, double _y, double _w, double _h)
	{
		double x1 = min (_x, x);
		double y1 = min (_y, y);
		double x2 = max (_x + _w, x + w);
		double y2 = max (_y + _h, y + h);
		x = x1;
		y = y1;
		w = x2 - x1;
		h = y2 - y1;
	}
	
	//TODO: choose doubles or Rectangles as parameter for overlaps and Intersection
	
	bool overlaps (double _x, double _y, double _w, double _h)
	{
		bool xoverlap = (_x < x + w) && (_x + _w > _x);
		bool yoverlap = (_y < y + h) && (_y + _h > _y);  
		return xoverlap && yoverlap;
	}
	
	Rectangle intersection(Rectangle other)
	{
		double x1 = max (x, other.x);
		double y1 = max (y, other.y);
		double x2 = min (x + w, other.x + other.w);
		double y2 = min (y + h, other.y + other.h); 
		return Rectangle(x1, y1, x2 - x1, y2 - y1);
	}
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
	
	private double cx = 0, cy = 0, cw = 8, ch = 8;
			
	/** set both position and size together */
	public void setShape (double _x, double _y, double _w, double _h)
	{
		cx = _x;
		cy = _y;
		cw = _w;
		ch = _h;
	}

	/** set both x and y together */
	public void setPosition (double _x, double _y)
	{
		cx = _x;
		cy = _y;
	}

	/** return the font. If the font is not set expressly for this
		component, the parent font is returned, or null
		if there is no parent. */
	@property public ALLEGRO_FONT *font()
	{
		if (cfont !is null) return cfont;
		// if (cparent is null) return getDefaultFont();
		return cparent.font;
	}
	
	private static ALLEGRO_FONT *defaultFont;
	
	/**
		Override the font for this component
	  */
	@property void font(ALLEGRO_FONT *value)
	{
		cfont = value;
	}
	
	
	/** should return true if keyboard event is handled, false otherwise */
	public bool onKey(int code, int c, int mod) { return false; }
	
	public void onMouseEnter() { }

	public void onMouseLeave() { }
	
	public void onMouseMove(int x, int y) { }

	public void onMouseDown(int x, int y) { }

	public void onMouseUp(int x, int y) { }

	public void gainFocus() { }
	
	// public bool hasFocus() 
	// { 
	// 	if (!cparent) return false;
	// 	return cparent.focus == this;
	// }
	
	public void loseFocus() { }
	
	//TODO: add to Rectangle	
	public bool contains(int xx, int yy)
	{
		return ((xx >= cx) && (xx < (cx + cw)) && (yy >= cy) && (yy < (cy + ch)));
	}
	
	@property double x() { return cx; }
	@property double y() { return cy; }
	@property double w() { return cw; }
	@property double h() { return ch; }

	//TODO: store in rectangle struct
	@property void x(double val) { cx = val; }
	@property void y(double val) { cy = val; }
	@property void w(double val) { cw = val; }
	@property void h(double val) { ch = val; }
}
