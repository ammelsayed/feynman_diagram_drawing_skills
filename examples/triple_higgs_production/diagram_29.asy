import feynman;

currentpen = linewidth(0.75);
fmdefaults();

real L = 50;
real h = 0.8L;

// incoming gluons: horizontal and parallel
pair G1 = (-2.2L, +h);
pair G2 = (-2.2L, -h);

// SQUARE loop with a midpoint on the left edge (for the middle Higgs)
pair TL = (-0.8L, +h);
pair ML = (-0.8L, 0);
pair BL = (-0.8L, -h);
pair TR = (+0.8L, +h);
pair BR = (+0.8L, -h);

// Higgs endpoints: middle one horizontal to the left; outgoing pair horizontal, equal length
pair Hleft = (-2.0L, 0);
pair Hup = (+2.0L, +h);
pair Hdn = (+2.0L, -h);

drawFermion(BL -- ML);
drawFermion(ML -- TL);
drawFermion(TL -- TR);
drawFermion(TR -- BR);
drawFermion(BR -- BL);

drawGluon(TL -- G1);
drawGluon(BL -- G2);

drawScalar(ML -- Hleft, None);
drawScalar(TR -- Hup, None);
drawScalar(BR -- Hdn, None);

dot(TL, linewidth(3));
dot(ML, linewidth(3));
dot(BL, linewidth(3));
dot(TR, linewidth(3));
dot(BR, linewidth(3));

label("$g$", G1, left);
label("$g$", G2, left);
label("$H$", Hleft, left);
label("$H$", Hup, right);
label("$H$", Hdn, right);

// top-quark loop labels: bottom/return edge is an anti-top
label("$t$", (ML.x - 0.25L, (ML.y + TL.y)/2));
label("$t$", (ML.x - 0.25L, (BL.y + ML.y)/2));
label("$t$", ((TL.x + TR.x)/2, TL.y + 0.20L));
label("$t$", (TR.x + 0.25L, (TR.y + BR.y)/2));
label("$\bar{t}$", ((BR.x + BL.x)/2, BL.y - 0.20L));
