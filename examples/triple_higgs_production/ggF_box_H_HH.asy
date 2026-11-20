import feynman;

currentpen = linewidth(0.75);
fmdefaults();

real L = 50;
real h = 0.8L;

pair G1 = (-2.2L, +h);
pair G2 = (-2.2L, -h);
pair TL = (-1.0L, +h);
pair BL = (-1.0L, -h);
pair Ha = (2.3L, 1.5L);
pair Hb = (2.7L, 0);
pair Hc = (2.3L, -1.5L);

// ---- panel 2: box loop, one direct H + H* -> HH at lambda_3 ----
pair TR = (+0.6L, +h);
pair BR = (+0.6L, -h);

drawFermion(TL -- TR);
drawFermion(TR -- BR);
drawFermion(BR -- BL);
drawFermion(BL -- TL);

drawGluon(G1 -- TL);
drawGluon(G2 -- BL);

drawScalar(TR -- Ha, None);      // direct Higgs

pair S = (+1.6L, 0);             // lambda_3 vertex
drawScalar(BR -- S, None);       // off-shell Higgs
drawScalar(S  -- Hb, None);
drawScalar(S  -- Hc, None);

dot(TL, linewidth(3));
dot(BL, linewidth(3));
dot(TR, linewidth(3));
dot(BR, linewidth(3));
dot(S,  linewidth(4));

label("$g$", G1, left);
label("$g$", G2, left);
label("$H$", Ha, right);
label("$H$", Hb, right);
label("$H$", Hc, right);
label("$H^*$", ((BR.x + S.x)/2, (BR.y + S.y)/2 - 0.20L));
label("$\lambda_3$", (S.x - 0.14L, S.y + 0.16L));

// top-quark loop labels: bottom/return segment is an anti-top
label("$t$", ((TL.x + TR.x)/2, TL.y + 0.20L));
label("$t$", (TR.x + 0.25L, (TR.y + BR.y)/2));
label("$\bar{t}$", ((BR.x + BL.x)/2, BL.y - 0.20L));
label("$t$", (BL.x - 0.25L, (BL.y + TL.y)/2));
