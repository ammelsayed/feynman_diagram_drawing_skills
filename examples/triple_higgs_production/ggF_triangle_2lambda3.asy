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

// ---- panel 3: triangle loop, cascade H* -> H H* -> H H ----
pair A = (+0.8L, 0);

drawFermion(BL -- TL);
drawFermion(TL -- A);
drawFermion(A  -- BL);

drawGluon(G1 -- TL);
drawGluon(G2 -- BL);

pair S1 = (+1.5L, +0.30L);
pair S2 = (+2.2L, -0.50L);
drawScalar(A  -- S1, None);      // H*
drawScalar(S1 -- Ha, None);      // H
drawScalar(S1 -- S2, None);      // H*
drawScalar(S2 -- Hb, None);      // H
drawScalar(S2 -- Hc, None);      // H

dot(TL, linewidth(3));
dot(BL, linewidth(3));
dot(A,  linewidth(3));
dot(S1, linewidth(4));
dot(S2, linewidth(4));

label("$g$", G1, left);
label("$g$", G2, left);
label("$H$", Ha, right);
label("$H$", Hb, right);
label("$H$", Hc, right);
label("$H^*$", (A.x + 0.30L, A.y + 0.20L));
label("$H^*$", ((S1.x + S2.x)/2 + 0.12L, (S1.y + S2.y)/2 + 0.22L));
label("$\lambda_3$", (S1.x + 0.04L, S1.y + 0.20L));
label("$\lambda_3$", (S2.x - 0.18L, S2.y - 0.22L));

// top-quark loop labels: bottom/return segment is an anti-top
label("$t$", (BL.x - 0.25L, (BL.y + TL.y)/2));
label("$t$", ((TL.x + A.x)/2 + 0.05L, (TL.y + A.y)/2 + 0.16L));
label("$\bar{t}$", ((A.x + BL.x)/2 + 0.05L, (A.y + BL.y)/2 - 0.16L));
