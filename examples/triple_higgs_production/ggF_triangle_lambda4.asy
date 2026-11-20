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

// ---- panel 4: triangle loop, quartic lambda_4 vertex ----
pair A = (+0.8L, 0);

drawFermion(BL -- TL);
drawFermion(TL -- A);
drawFermion(A  -- BL);

drawGluon(G1 -- TL);
drawGluon(G2 -- BL);

pair Q = (+1.7L, 0);
drawScalar(A -- Q, None);        // H*
drawScalar(Q -- Ha, None);
drawScalar(Q -- Hb, None);
drawScalar(Q -- Hc, None);

dot(TL, linewidth(3));
dot(BL, linewidth(3));
dot(A,  linewidth(3));
dot(Q,  linewidth(4));

label("$g$", G1, left);
label("$g$", G2, left);
label("$H$", Ha, right);
label("$H$", Hb, right);
label("$H$", Hc, right);
label("$H^*$", ((A.x + Q.x)/2, 0.22L));
label("$\lambda_4$", (Q.x + 0.02L, Q.y + 0.22L));

// top-quark loop labels: bottom/return segment is an anti-top
label("$t$", (BL.x - 0.25L, (BL.y + TL.y)/2));
label("$t$", ((TL.x + A.x)/2 + 0.05L, (TL.y + A.y)/2 + 0.16L));
label("$\bar{t}$", ((A.x + BL.x)/2 + 0.05L, (A.y + BL.y)/2 - 0.16L));
