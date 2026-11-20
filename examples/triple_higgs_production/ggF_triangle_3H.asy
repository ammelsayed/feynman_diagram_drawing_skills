import feynman;

currentpen = linewidth(0.75);
fmdefaults();

real L = 50;
real h = 0.8L;

// incoming gluons: horizontal, parallel
pair G1 = (-2.2L, +h);
pair G2 = (-2.2L, -h);

// SQUARE loop
pair TL = (-0.8L, +h);
pair TR = (+0.8L, +h);
pair BR = (+0.8L, -h);
pair BL = (-0.8L, -h);
// middle point of the right edge where the middle Higgs is emitted
pair MR = (+0.8L, 0);

// outgoing Higgs endpoints: equal-length horizontal stubs
pair H1 = (+2.0L, +h);
pair H2 = (+2.0L, 0);
pair H3 = (+2.0L, -h);

drawFermion(TL -- TR);
drawFermion(TR -- MR);
drawFermion(MR -- BR);
drawFermion(BR -- BL);
drawFermion(BL -- TL);

drawGluon(G1 -- TL);
drawGluon(G2 -- BL);

drawScalar(TR -- H1, None);
drawScalar(MR -- H2, None);
drawScalar(BR -- H3, None);

dot(TL, linewidth(3));
dot(TR, linewidth(3));
dot(MR, linewidth(3));
dot(BR, linewidth(3));
dot(BL, linewidth(3));

label("$g$", G1, left);
label("$g$", G2, left);
label("$H$", H1, right);
label("$H$", H2, right);
label("$H$", H3, right);

// top-quark loop labels: bottom/return edge is an anti-top
label("$t$", ((TL.x + TR.x)/2, TL.y + 0.20L));
label("$t$", (TR.x + 0.25L, (TR.y + MR.y)/2));
label("$t$", (MR.x + 0.25L, (MR.y + BR.y)/2));
label("$\bar{t}$", ((BR.x + BL.x)/2, BL.y - 0.20L));
label("$t$", (BL.x - 0.25L, (BL.y + TL.y)/2));
