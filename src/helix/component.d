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
import helix.allegro.bitmap;
import helix.allegro.font;

import std.string;
import std.algorithm;
import std.range;
import std.json;

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
	string type;
	string id;
	private Rectangle _shape;
	Bitmap icon;
	string text = null;

	//TODO: put collection of styles together more sensibly...
	protected Style[4] styleCache = [null, null, null, null]; // 0: normal, 1: selected, 2: disabled, 3: hover...
	StyleData localStyle;
	StyleData ancestorStyle;

	LayoutData layoutData;

	protected MainLoop window = null;
	
	// FLAGS:
	bool selected = false; // indicates toggled, checked, pressed or selected state 
	bool hover = false; // indicates mouse is hovering over element - hover state.
	bool hidden = false;
	bool focused = false; // used for keyboard focus. Display with outline.
	bool disabled = false;
	bool invalid = false; // used for input validation
	bool readonly = false; // used for edit controls
	bool canFocus = false;
	bool killed = false;

	this(MainLoop window, string type) {
		this.window = window;
		this.type = type;
	}

	Style getStyle(int mode = 0) {	
		if (styleCache[mode] is null) {
			Style result;
			switch (mode) {
				case 0: result = window.styles.getStyle(type, "", ancestorStyle, localStyle); break;
				case 1: result = window.styles.getStyle(type, "selected", ancestorStyle, localStyle); break;
				case 2: result = window.styles.getStyle(type, "disabled", ancestorStyle, localStyle); break;
				case 3: result = window.styles.getStyle(type, "hover", ancestorStyle, localStyle); break;
				default: assert(0);
			}
			styleCache[mode] = result;
		}
		return styleCache[mode];
	}

	/** 
		style override for this particular element,
		most specific, overrides all others
	 */
	void setLocalStyle(JSONValue value) {
		localStyle = StyleData.fromJSON("local", value);
		styleCache = [null, null, null, null]; // clear cache
	}

	/**
		style from one of the ancestors of this node.
		should be behind local style and type-specific styles
		(TODO: currently only applied to RichTextComponent)
	*/
	void setAncestorStyle(StyleData value) {
		ancestorStyle = value;
		styleCache = [null, null, null, null]; // clear cache
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

	@property Rectangle shape() {
		return this._shape;
	}

	/** calculate shape for this component. Non-recursive. */
	void applyLayout(Rectangle parentRect) {
		_shape = layoutData.calculate(parentRect);
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
		
		const state = disabled ? 2 : (selected ? 1 : (hover ? 3 : 0));
		Style style = getStyle(state);
		
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
			al_draw_line(x, y, x + w, y, style.getColor("border-top"), borderWidth);
			al_draw_line(x + w, y, x + w, y + h, style.getColor("border-right"), borderWidth);
			al_draw_line(x + w, y + h, x, y + h, style.getColor("border-bottom"), borderWidth);
			al_draw_line(x, y + h, x, y, style.getColor("border-left"), borderWidth);
		}

		// render icon
		if (icon !is null) {
			int iw = icon.w;
			int ih = icon.h;
			al_draw_bitmap (icon.ptr, x + (w - iw) / 2, y + (h - ih) / 2, 0);
		}

		// render TextSpan
		if (text != "") {
			//TODO: use stringz...
			ALLEGRO_COLOR color = style.getColor("color");
			Font font = style.getFont();
			int th = font.lineHeight;
			al_draw_text(font.ptr, color, x + w / 2, y + (h - th) / 2, ALLEGRO_ALIGN_CENTER, toStringz(text));
		}

		// render focus outline...
		// TODO

		// and draw children.
		// TODO - should this be done by MainLoop/Window?
		foreach (child; children) {
			child.draw(gc);
		}
	}
	
	public void setRelative(int x1, int y1, int x2, int y2, int _w, int _h, LayoutRule horizontalRule, LayoutRule verticalRule) {
		layoutData = LayoutData(x1, y1, x2, y2, _w, _h, horizontalRule, verticalRule);
	}

	/** 
		set both position and size together 
		@deprecated use layoutData instead.
	*/
	public void setShape (int _x, int _y, int _w, int _h)
	{
		setRelative(_x, _y, 0, 0, _w, _h, LayoutRule.BEGIN, LayoutRule.BEGIN);
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

	public void onMouseEnter() {
		this.hover = true;
	}

	public void onMouseLeave() {
		this.hover = false;
		this.selected = false;
	}
	
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
	
	public bool contains(Point p)
	{
		return shape.contains(p);
	}
	
	@property int x() { return shape.x; }
	@property int y() { return shape.y; }
	@property int w() { return shape.w; }
	@property int h() { return shape.h; }

	@property void x(int val) { shape.x = val; }
	@property void y(int val) { shape.y = val; }
	@property void w(int val) { shape.w = val; }
	@property void h(int val) { shape.h = val; }
}
