module helix.richtext;

import helix.component;
import helix.widgets;
import helix.layout;
import helix.util.vec;
import helix.mainloop;
import helix.style;
import helix.allegro.bitmap;

import allegro5.allegro;
import allegro5.allegro_font;

import std.exception;
import std.string;
import std.conv : to;
import std.regex;
import helix.util.math;

import helix.color; //TODO: debug
import std.stdio; //TODO: debug
import allegro5.allegro_primitives; // TODO: debug

enum defaultLineHeight = 16; // For lines with nothing in it. TODO: should depend on current font...

class Context {
	MainLoop window;
	Point cursor;
	int lineHeight;
	int maxWidth;

	//TODO: this can be re-used between layouts
	Style parentStyle;
	Style[string] styleMap;

	Style getStyle(string styleName) {
		if (!(styleName in styleMap)) {
			Style child = styleName == "default"
				? parentStyle
				: new Style (window.getStyle(styleName), parentStyle);
			styleMap[styleName] = child;
		}
		return styleMap[styleName];
	}

	this(MainLoop window, int maxWidth, Style parentStyle) {
		this.parentStyle = parentStyle;
		cursor = Point(0);
		this.window = window;
		this.maxWidth = maxWidth;
		this.lineHeight = defaultLineHeight;
	}

	void nextLine() {
		cursor = Point(0, cursor.y + lineHeight);
		lineHeight = defaultLineHeight;
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
	private Style parentStyle;

	this(string text, string styleName = "default") { this.text = text; this.styleName = styleName; }

	Component[] layout(Context context) {
		Label label = new Label(context.window);
		label.text = text;
		label.initialIndent = context.cursor.x;
		label.setStyle(context.getStyle(styleName));
		int totalHeight;
		int originalY = context.cursor.y;
		int lineHeight;
		label.calculateLayout(context.maxWidth, lineHeight, totalHeight, context.cursor);
		context.lineHeight = max(context.lineHeight, lineHeight);
		label.layoutData = LayoutData(0, originalY, 0, 0, 0, totalHeight, LayoutRule.STRETCH, LayoutRule.BEGIN);
		return [ label ];
	}
}

class InlineImage : Span {
	private Bitmap bitmap;
	
	this(Bitmap bitmap) {
		enforce(bitmap !is null);
		this.bitmap = bitmap;
	}

	Component[] layout(Context context) {
		ImageComponent img = new ImageComponent(context.window);
		img.img = bitmap;
		const w = bitmap.w;
		const h = bitmap.h;
		img.layoutData = LayoutData(context.cursor.x, context.cursor.y, 0, 0, w, h, LayoutRule.BEGIN, LayoutRule.BEGIN);
		
		//TODO: move to new line if there is no space left for image...
		context.cursor.x = context.cursor.x + w; //TODO add margin?
		context.lineHeight = max(context.lineHeight, h);
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
	* optionally breaks at / ignores hard line breaks ('\n')
	* TODO: handling of tabs...
	* will insert soft line breaks
	* first line may have hanging indent
*/
class Label : Component {

	this(MainLoop window) {
		super(window);
	}

	int initialIndent;
	bool ignoreHardBreaks = true;
	
	struct Line {
		int xofst;
		int w;
		immutable(char)* line;
	}
	Line[] lines;

	private static void softBreaks(ref Line[] lines, string line, ref int xofst, int maxWidth, ALLEGRO_FONT *font) {
		if (line.empty) return; // do not insert empty newLine in this case...
		
		string sep = "";
		Line prevLine = Line(xofst, 0, toStringz("")); // in case first word doesn't fit, we start with an empty line
		string currentString = "";
		
		// Merge whitespace, remove tabs
		foreach(word; line.splitter(regex(`\s+`))) {
			// line.splitter has an oddity that we rely on in this case
			// if there is leading whitespace, the first word is the empty string
			// this is useful, because we want a leading whitespace in the output as well.
			currentString ~= sep; 
			currentString ~= word;
			sep = " ";
			// There was a weird bug here - lz & currentString point to same memory even though toStringz should have made a copy...
			// we force duplication with .dup
			immutable(char)*lz = toStringz(currentString.dup); 
			int ww = al_get_text_width(font, lz);

			if (xofst + ww > maxWidth) {
				lines ~= prevLine;
				currentString = word;
				xofst = 0;
				lz = toStringz(currentString);
				ww = al_get_text_width(font, lz);
			}

			prevLine = Line(xofst, ww, lz);
		}

		lines ~= prevLine;
		xofst = prevLine.xofst + prevLine.w;

	}

	void calculateLayout(int maxWidth, out int lineHeight, out int totalHeight, ref Point cursor) {		
		assert(styles.length != 0, "must set style before calculateLayout()");
		assert(text != "", "must set text before calculateLayout()");
		Style style = styles[0];
		ALLEGRO_FONT *font = style.getFont();
		
		int w = al_get_text_width(font, toStringz(text));
		
		lines = [];
		int xofst = initialIndent;

		// newline characters as hard breaks
		if (ignoreHardBreaks) {
			softBreaks(lines, text, xofst, maxWidth, font);
		}
		else {
			foreach (l; text.split("\n")) {
				softBreaks(lines, l, xofst, maxWidth, font);
				xofst = 0;
			}
		}

		const lineNum = to!int(lines.length);
		lineHeight = al_get_font_line_height(font);
		totalHeight = lineNum * lineHeight;

		// update cursor
		cursor = Point(cursor.x + w, cursor.y + (lineNum - 1) * lineHeight);
	}

	override void draw(GraphicsContext gc) {
		// al_draw_rectangle(shape.x, shape.y, shape.x + shape.w, shape.y + shape.h, Color.RED, 1.0);

		Style style = styles[0];
		// TODO render multiple lines...
		if (text != "") {
			assert (!lines.empty, "Must invoke calculateLayout() before draw()");

			ALLEGRO_COLOR color = style.getColor("color");
			ALLEGRO_FONT *font = style.getFont();

			int yco = y;
			int xco = x;
			int lh = al_get_font_line_height(font);
			foreach(l; lines) {
				al_draw_text(font, color, xco + l.xofst, yco, ALLEGRO_ALIGN_LEFT, l.line);
				xco = x;
				yco += lh;
			}
			
			
		}
	}
}

class RichTextBuilder {

	private Span[] spans;
	
	Span[] build() { 
		return spans;
	}

	/** same as .text(), but treats newlines as hard line breaks */
	RichTextBuilder lines(string text) {
		foreach (l; text.split("\n")) {
			if (!l.empty) {
				spans ~= new TextSpan(l);
			}
			spans ~= new LineBreak();
		}
		return this;
	}
	
	/** ignores hard line breaks. If you need them, use .lines() instead */
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

	RichTextBuilder img(Bitmap bitmap) {
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

	RichTextBuilder i(string text) {
		spans ~= new TextSpan(text, "i");
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
		clearChildren();
		this.spans = spans;
		dirty = true;
	}

	int calculateHeight(int inputWidth) { return 0; /* TODO */ }

	override void draw(GraphicsContext gc) {
		if (dirty) {
			Context context = new Context(window, shape.w, styles[0]);
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