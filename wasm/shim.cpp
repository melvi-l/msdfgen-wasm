#include <cstddef>
#include "msdfgen.h"
using namespace msdfgen;

extern "C" {

Shape* msdf_shape_new() { return new Shape(); }
void   msdf_shape_free(Shape* s) { delete s; }
Contour* msdf_shape_add_contour(Shape* s) { s->contours.emplace_back(); return &s->contours.back(); }
void msdf_contour_add_line(Contour* c, double x0, double y0, double x1, double y1) {
    c->edges.emplace_back(Point2(x0, y0), Point2(x1, y1));
}

void msdf_contour_add_quadratic(Contour* c, double x0, double y0, double cx, double cy, double x1, double y1) {
    c->edges.emplace_back(Point2(x0, y0), Point2(x1, y1), Point2(cx, cy)); 
}

void msdf_contour_add_cubic(Contour* c, double x0, double y0, double c1x, double c1y, double c2x, double c2y, double x1, double y1) {     
    c->edges.emplace_back(Point2(x0, y0), Point2(x1, y1), Point2(c1x, c1y), Point2(c2x, c2y)); 
}

void msdf_edge_color(Shape* s, double angleThreshold) {
    edgeColoringSimple(*s, angleThreshold);
    s->normalize();
}

void msdf_generate_msdf(const Shape* s, float* out, int w, int h, double range, double sx, double sy, double tx, double ty) {
    Bitmap<float, 3> bmp(w, h);
    Projection proj(Vector2(sx, sy), Vector2(tx, ty));
    MSDFGeneratorConfig cfg; // défauts OK
    generateMSDF(bmp, *s, proj, Range(range), cfg);

    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            const float* px = bmp(x, y);
            const size_t i = 3u * (static_cast<size_t>(y) * static_cast<size_t>(w) + static_cast<size_t>(x));
            out[i+0] = px[0]; out[i+1] = px[1]; out[i+2] = px[2];
        }
    }
}

} 

