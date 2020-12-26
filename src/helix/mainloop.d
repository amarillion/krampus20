module helix.mainloop;

//NOTE: these pragma's work when the source of modtwist is included.
//will it also work when twist is a compiled library?
pragma(lib, "dallegro5");
pragma(lib, "allegro");
pragma(lib, "allegro_primitives");
pragma(lib, "allegro_image");
pragma(lib, "allegro_font");
pragma(lib, "allegro_ttf");
pragma(lib, "allegro_color");

import std.stdio;
import std.string;

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import helix.component;
import helix.resources;
import helix.style;

/**
	MainLoop is responsible for:

	* Initialising allegro
	* Running the main event loop
	* passing mouse & keyboard events, managing focus
	* keeping a map of components by id
	* Hooking up elements to style and resources
	* Doing layout

	TODO:
	'MainLoop' could be renamed to 'Window'.
*/

class MainLoop
{
	private Component engine;
	ResourceManager resources;
	private Style rootStyle;

	void setRootComponent(Component value)
	{
		assert(display, "Programming error: display must be initialized before calling setRootComponent()");
		this.engine = value;
		engine.w = al_get_display_width(display);
		engine.h = al_get_display_height(display);
		engine.x = 0;
		engine.y = 0;
		engine.window = this;
		// engine.applyLayoutRule(); //TODO
	}
	
	ALLEGRO_EVENT_QUEUE* queue;
	ALLEGRO_DISPLAY* display;
	ALLEGRO_TIMER *timer;
	
	void init()
	{
		ALLEGRO_CONFIG* cfg = al_load_config_file("turnover.ini");
		
		//TODO: make configurable
		al_set_new_display_flags(ALLEGRO_WINDOWED | ALLEGRO_RESIZABLE);
		
		display = al_create_display(800, 480);
				
		queue = al_create_event_queue();

		al_install_keyboard();
		al_install_mouse();
		al_init_image_addon();
		al_init_font_addon();
		al_init_ttf_addon();
		al_init_primitives_addon();

		al_register_event_source(queue, al_get_display_event_source(display));
		al_register_event_source(queue, al_get_keyboard_event_source());
		al_register_event_source(queue, al_get_mouse_event_source());
		
		al_show_mouse_cursor(display);
		
  		timer = al_create_timer(0.02);
		al_register_event_source(queue, al_get_timer_event_source(timer));
		al_start_timer(timer);

		resources = new ResourceManager();
		rootStyle = new Style(resources); //TODO
	}

	void run()
	{
		assert (engine !is null, "Must call setRootComponent() before run()");
		
		bool exit = false;
		bool need_redraw = true;
		
		while(!exit)
		{
			ALLEGRO_EVENT event;
			while(!exit)
			{
				if (need_redraw && al_is_event_queue_empty(queue))
				{
					GraphicsContext gc = new GraphicsContext();
					engine.draw(gc);

					al_flip_display();
					need_redraw = false;
				}

				al_wait_for_event(queue, &event);
				switch(event.type)
				{
					case ALLEGRO_EVENT_DISPLAY_RESIZE:
					{
						writeln ("Window resize");
						engine.setShape(0, 0, al_get_display_width(display), al_get_display_height(display));
						// engine.applyLayoutRule(); //TODO
						break;
					}
					case ALLEGRO_EVENT_DISPLAY_CLOSE:
					{
						writeln ("Display close");
						exit = true;
						break;
					}
					case ALLEGRO_EVENT_KEY_CHAR:
					{
						engine.onKey(event.keyboard.keycode, event.keyboard.unichar, event.keyboard.modifiers);
						switch(event.keyboard.keycode)
						{
							case ALLEGRO_KEY_ESCAPE:
							{
								writeln ("Escape pressed");
								exit = true;
								break;
							}
							default:
						}
						break;
					}
					case ALLEGRO_EVENT_MOUSE_BUTTON_DOWN:
					{
						engine.onMouseDown(event.mouse.x, event.mouse.y);
						break;
					}
					case ALLEGRO_EVENT_MOUSE_BUTTON_UP:
					{
						engine.onMouseUp(event.mouse.x, event.mouse.y);
						break;
					}
					case ALLEGRO_EVENT_MOUSE_AXES:
					{
						engine.onMouseMove(event.mouse.x, event.mouse.y);
						break;
					}
					case ALLEGRO_EVENT_TIMER: 
					{
						engine.update();
						need_redraw = true;
						break;
					}
					default:
				}
			}
		
		}
		
		done();
	}
	
	private void done()
	{
		 al_destroy_timer(timer);
		 al_destroy_display(display);
		 al_destroy_event_queue(queue);
	}
	
}
