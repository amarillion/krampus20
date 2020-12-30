module helix.richtext;

import helix.component;
import helix.widgets;
import helix.layout;
import helix.util.vec;
import helix.mainloop;
import helix.style;

import allegro5.allegro;
import allegro5.allegro_font;

import std.exception;
import std.string;

void multilineTextLayout(string text, ALLEGRO_FONT *font, int max_width, int openingIndent,
	void delegate(string line, int x, int y) cb) {

}

class Context {
	MainLoop window;
	Point cursor;
	int lineHeight;
	int maxWidth;

	this(MainLoop window, int maxWidth) {
		cursor = Point(0);
		this.window = window;
		this.maxWidth = maxWidth;
		this.lineHeight = 20; //TODO: lineHeight should be determined by spans...
	}

	void nextLine() {
		cursor = Point(0, cursor.y + lineHeight);
	}

	int remain() {
		return maxWidth - cursor.x;
	}
}

interface Span {
	Component[] layout(Context context);
}

class TextSpan : Span {

	private string text;
	private string styleName;

	this(string text, string styleName = "default") { this.text = text; this.styleName = styleName; }

	Component[] layout(Context context) {
		Label label = new Label(context.window);
		label.text = text;
		label.initialIndent = context.cursor.x;
		label.setStyle(context.window.getStyle(styleName));
		int height;
		label.calculateLayout(context.maxWidth, height, context.cursor);
		label.layoutData = LayoutData(0, context.cursor.y, 0, 0, 0, height, LayoutRule.STRETCH, LayoutRule.BEGIN);
		return [ label ];
	}
}

class InlineImage : Span {
	private ALLEGRO_BITMAP *bitmap;
	
	this(ALLEGRO_BITMAP *bitmap) {
		enforce(bitmap != null);
		this.bitmap = bitmap;
	}

	Component[] layout(Context context) {
		ImageComponent img = new ImageComponent(context.window);
		img.img = bitmap;
		const w = al_get_bitmap_width(bitmap);
		const h = al_get_bitmap_height(bitmap);
		img.layoutData = LayoutData(context.cursor.x, context.cursor.y, 0, 0, w, h, LayoutRule.BEGIN, LayoutRule.BEGIN);
		//TODO: move to new line if there is no space left for image...
		context.cursor.x = context.cursor.x + w; //TODO add margin?
		return [ img ];
	}
}

class LineBreak : Span {
	Component[] layout(Context context) {
		context.nextLine();
		return [];
	}	
}

class ParagraphBreak : Span {

	Component[] layout(Context context) {
		context.nextLine();
		context.nextLine();
		return [];
	}
}

class Indent : Span {

	Component[] layout(Context context) {
		context.cursor.x = context.cursor.x + 32; //TODO customizable...
		return [];
	}

}

/** 
	a section of text with a uniform style
	at a specific position, rendered and clickable (for links...)
	
	* all with a single style
	* may span multiple lines
	* may include hard line breaks ('\n')
	* will insert soft line breaks
	* first line may have hanging indent
*/
class Label : Component {

	this(MainLoop window) {
		super(window);
	}

	int initialIndent;

	void calculateLayout(int maxWidth, out int height, ref Point cursor) {		
		assert(!styles.empty);
		Style style = styles[0];
		ALLEGRO_FONT *font = style.getFont();
		
		int w = al_get_text_width(font, toStringz(text));
		
		//TODO - calculate multiline...
		const lineNum = 1;
		const lineHeight = al_get_font_line_height(font);
		height = lineNum * lineHeight;
		cursor = Point(cursor.x + w, cursor.y);
	}

	override void draw(GraphicsContext gc) {
		Style style = styles[0];
		
		// TODO render multiple lines...
		if (text != "") {
			//TODO: use stringz...
			ALLEGRO_COLOR color = style.getColor("color");
			ALLEGRO_FONT *font = style.getFont();
			// int th = al_get_font_line_height(font);
			al_draw_text(font, color, x + initialIndent, y, ALLEGRO_ALIGN_LEFT, toStringz(text));
		}
	}
}

class RichTextBuilder {

	private Span[] spans;
	
	Span[] build() { 
		return spans;
	}

	RichTextBuilder text(string text) {
		spans ~= new TextSpan(text);
		return this;
	}

	RichTextBuilder br() {
		spans ~= new LineBreak();
		return this;
	}

	RichTextBuilder p() {
		spans ~= new ParagraphBreak();
		return this;
	}

	RichTextBuilder indent() {
		spans ~= new Indent();
		return this;
	}

	RichTextBuilder img(ALLEGRO_BITMAP *bitmap) {
		spans ~= new InlineImage(bitmap);
		return this;
	}

	RichTextBuilder h1(string text) {
		spans ~= new TextSpan(text, "h1");
		spans ~= new ParagraphBreak();
		return this;
	}

	RichTextBuilder b(string text) {
		spans ~= new TextSpan(text, "b");
		return this;
	}

	RichTextBuilder link(string text, string url) {
		spans ~= new TextSpan(text, "a");
		return this;
	}
}

class RichText : Component {

	this(MainLoop window) {
		super(window);
	}

	private Span[] spans;
	bool dirty = true;

	void setSpans(Span[] spans) {
		this.spans = spans;
		dirty = true;
	}

	int calculateHeight(int inputWidth) { return 0; /* TODO */ }

	override void draw(GraphicsContext gc) {
		if (dirty) {
			Context context = new Context(window, shape.w);
			foreach (span; spans) {
				Component[] clist = span.layout(context);
				foreach(c; clist) {
					addChild(c);
				}
			}
			dirty = false;
			window.calculateLayout(this);
		}
		super.draw(gc);
	}

}