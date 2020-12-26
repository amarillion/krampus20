module helix.rect;

import helix.util;
import helix.vec;

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

	bool contains(Point p) {
		return (p.x >= x && p.x < x + w && p.y >= y && p.y < y + h);
	}
}
