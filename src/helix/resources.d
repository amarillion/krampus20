module helix.resources;

import allegro5.allegro_font;
import allegro5.allegro;
import std.path;

/*
struct ResourceHandle(T)
{
	string fname;
	Signal onReload;
	T resource;

	this(fname) {
		this.fname = fname;
	}

	T get()
	
	load(fname) {

	}

	reload(fname) {

	}
}

class ResourceMap(T) {

	ResourceHandle!T data;
	ref auto opIndex(string index)
	{

	}
}

class ResourceManager {
	ResourceMap!(ALLEGRO_FONT*) fonts;
	ResourceMap!(ALLEGRO_BITMAP*) bitmaps;

	void refreshAll();
}
*/

unittest {
	//TODO, make it like this: 
	/*
	resources.addSearchPath("./data");
	
	ALLEGRO_FONT *f1 = resources.fonts["Arial"].get(16);
	ALLEGRO_FONT *f2 = resources.fonts["builtin_font"].get();
	resources.fonts["Arial"].onReload.add(() => writeln("Font changed"));
	
	ALLEGRO_BITMAP *bitmap = resources.bitmaps["MyBitmap"].get();
	resources.bitmaps["MyBitmap"].onReload.add(() => writeln("Bitmap changed"));

	JSONNode n1 = resources.json["map1"].get();
	
	// transparently accesses the same file...
	Tilemap map = resources.tilemaps["map1"].get();
	
	resources.refreshAll();
	*/

}

class ResourceManager
{
	/**
		Remembers file locations.
		For each size requested, reloads font on demand.
	*/
	class FontLoader
	{
		private string filename;
		private ALLEGRO_FONT*[int] fonts;
		
		ALLEGRO_FONT *get(int size = 12)
		{
			if (!(size in fonts))
			{
				auto font = al_load_font(cast(const char*) (filename ~ '\0'), size, 0);
				assert (font != null);
				fonts[size] = font;
			}
			return fonts[size];
		}
		
		this(string fileVal)
		{
			filename = fileVal;
		}
	}
	
	private FontLoader[string] fonts;
	private ALLEGRO_BITMAP*[string] bitmaps;

	public void addFile(string filename)
	{
		string ext = extension(filename); // ext includes .
		string base = baseName(stripExtension(filename));
		
		// "data/DejaVuSans.ttf"
		if (ext == ".ttf")
		{
			fonts[base] = new FontLoader(filename);			
		}
		else if (ext == ".png")
		{
			bitmaps[base] = al_load_bitmap (cast(const char *)(filename ~ '\0'));
		}
	}
	
	public ALLEGRO_FONT *getFont(string name, int size = 12)
	{
		assert (name in fonts, "There is no font named [" ~ name ~ "]"); 
		return fonts[name].get(size);
	}

}