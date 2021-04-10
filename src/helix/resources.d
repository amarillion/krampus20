module helix.resources;

import allegro5.allegro_font;
import allegro5.allegro;
import allegro5.allegro_acodec;
import allegro5.allegro_audio;
import std.path;
import std.json;
import std.stdio;
import std.format : format;
import std.string : toStringz;
import helix.allegro.bitmap : Bitmap;

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

*/

/**
ResourceMap is a wrapper for resource handles.
It has ownership of the given resources, and ensures they are destroyed in time.

This is a struct instead of a class so that it is destroyed at the same time as ResourceManager.

Note that it's important that resource managers explicitly invoke destructors of handled objects. If we rely on GC, 
they may not be destroyed before uninstall_system is called, and then the system crashes.
*/
struct ResourceMap(T) {
	private T[string] data;

	void put(string key, T value) {
		data[key] = value;
	}

	auto opIndex(string key) {
		assert (key in data, format("There is no resource named [%s]", key));
		return data[key];
	}

	~this() {
		foreach (f; data) {
			destroy(f);
		}
		data = null;
	}
}

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
	this() {
		fonts.put("builtin_font", new BuiltinFont());
	}

	interface FontWrapper {
		ALLEGRO_FONT *get(int size = 12);
	}

	/**
		Remembers file locations.
		For each size requested, reloads font on demand.
	*/
	class FontLoader : FontWrapper {
		private string filename;
		private ALLEGRO_FONT*[int] fonts;
		
		ALLEGRO_FONT *get(int size = 12)
		{
			if (!(size in fonts))
			{
				auto font = al_load_font(toStringz(filename), size, 0);
				assert (font != null);
				fonts[size] = font;
			}
			return fonts[size];
		}
		
		this(string fileVal)
		{
			filename = fileVal;
		}

		~this() {
			foreach (font; fonts) {
				al_destroy_font(font);
			}
			fonts = null;
		}
	}
	
	class BuiltinFont : FontWrapper {
		private ALLEGRO_FONT *cache = null;
		ALLEGRO_FONT *get(int size = 0 /* size param is ignored */) {
			if (!cache) {
				cache = al_create_builtin_font();
			}
			return cache;
		}

		~this() {
			if (cache) {
				al_destroy_font(cache);
				cache = null;
			}
		}
	}

	public ResourceMap!FontWrapper fonts;
	public ResourceMap!Bitmap bitmaps;
	private JSONValue[string] jsons;
	private ALLEGRO_AUDIO_STREAM*[string] musics;
	private ALLEGRO_SAMPLE*[string] samples;

	private JSONValue loadJson(string filename) {
		File file = File(filename, "rt");
		char[] buffer;
		while (!file.eof()) {
			buffer ~= file.readln();
		}
		// TODO: find streaming parser to support large files
		JSONValue result = parseJSON(buffer);
		return result;
	}

	public void addFile(string filename)
	{
		string ext = extension(filename); // ext includes '.'
		string base = baseName(stripExtension(filename));
		
		if (ext == ".ttf") {
			fonts.put(base, new FontLoader(filename));
		}
		else if (ext == ".png") {
			Bitmap bmp = Bitmap.load(filename);
			bitmaps.put(base, bmp);
		}
		else if (ext == ".json") {
			jsons[base] = loadJson(filename);
		}
		else if (ext == ".ogg") {
			ALLEGRO_SAMPLE *sample_data = al_load_sample(toStringz(filename));
			assert (sample_data, format ("error loading OGG %s", filename));
			//TODO: write to log but don't quit. Sound is not essential.
			samples[base] = sample_data;
		}
	}
	
	public void addMusicFile(string filename) {
		// string ext = extension(filename); // ext includes '.'
		string base = baseName(stripExtension(filename));

		auto temp = al_load_audio_stream (toStringz(filename), 4, 2048); //TODO: correct values for al_load_audio_stream
		assert (temp, format ("error loading Music %s", filename));
		al_set_audio_stream_playmode(temp, ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_LOOP);
		musics[base] = temp;
	}

	public JSONValue getJSON(string name) {
		assert (name in jsons, format("There is no JSON named [%s]", name)); 
		return jsons[name];
	}

	public ALLEGRO_SAMPLE *getSample (string name) {
		assert (name in samples, format("There is no sample named [%s]", name)); 
		return samples[name];
	}
	
	public ALLEGRO_AUDIO_STREAM *getMusic (string name) {
		assert (name in musics, format("There is no music named [%s]", name)); 
		return musics[name];
	}

	~this() {
		foreach (v; musics) {
			al_destroy_audio_stream(v);
		}
		musics = null;

		foreach (v; samples) {
			al_destroy_sample(v);
		}
		samples = null;
	}
}