import feynman;

currentpen = linewidth(0.75);
fmdefaults();

real L = 50;
real h = 0.8L;                 // half-height of the SQUARE top loop

// ---- fixed external geometry (shared with ggF_triangle) ----
pair G1 = (-2.0L, +h);
pair G2 = (-2.0L, -h);
pair H1 = (+2.0L, +h);
pair H2 = (+2.0L, -h);

// ---- square loop: width = height = 1.6L ----
pair TL = (-0.8L, +h);
pair TR = (+0.8L, +h);
pair BL = (-0.8L, -h);
pair BR = (+0.8L, -h);

// fermion flow: BL -> TL -> TR -> BR -> BL
drawFermion(TL -- TR);
drawFermion(TR -- BR);
drawFermion(BR -- BL);
drawFermion(BL -- TL);

drawGluon(G1 -- TL);
drawGluon(G2 -- BL);

drawScalar(TR -- H1, None);
drawScalar(BR -- H2, None);

dot(TL, linewidth(3));
dot(TR, linewidth(3));
dot(BL, linewidth(3));
dot(BR, linewidth(3));

// incoming g: label at line start; outgoing H: label at line end
label("$g$", G1, left);
label("$g$", G2, left);
label("$H$", H1, right);
label("$H$", H2, right);

// closed fermion loop: one directed top-quark flow -> every segment is a t
label("$t$", ((TL.x + TR.x)/2, TR.y + 0.25L));
label("$t$", (TR.x + 0.25L, (TR.y + BR.y)/2));
label("$\bar{t}$", ((BR.x + BL.x)/2, BR.y - 0.25L));
label("$t$", (BL.x - 0.25L, (BL.y + TL.y)/2));

// vertex labels: kappa_t at the two Htt vertices
label("$\kappa_t$", (TR.x, TR.y + 0.14L));
label("$\kappa_t$", (BR.x, BR.y - 0.14L));
