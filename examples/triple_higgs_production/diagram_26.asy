import feynman;

currentpen = linewidth(0.75);
fmdefaults();

real L = 50;
real h = 0.8L;

// incoming gluons + middle H: horizontal, parallel, equal length
pair G1 = (-2.0L, +h);
pair G2 = (-2.0L, -h);
pair Hmid_in = (-2.0L, 0);

// ---- IDENTICAL to ggF_triangle on the loop + outgoing side ----
pair TL = (-0.8L, +h);
pair BL = (-0.8L, -h);
pair ML = (-0.8L, 0);         // middle point of the left edge (incoming H)
pair A  = (+0.4L, 0);         // kappa_t vertex (ttH)
pair S  = (+1.2L, 0);         // lambda_3 vertex (HHH)
pair H1 = (+2.0L, +h);
pair H2 = (+2.0L, -h);

drawFermion(BL -- ML);
drawFermion(ML -- TL);
drawFermion(TL -- A);
drawFermion(A  -- BL);

drawGluon(G1 -- TL);
drawGluon(G2 -- BL);
drawScalar(ML -- Hmid_in, None);

drawScalar(A -- S, None);
drawScalar(S -- H1, None);
drawScalar(S -- H2, None);

dot(TL, linewidth(3));
dot(BL, linewidth(3));
dot(ML, linewidth(3));
dot(A, linewidth(3));
dot(S, linewidth(3));

label("$g$", G1, left);
label("$g$", G2, left);
label("$H$", Hmid_in, left);
label("$H$", H1, right);
label("$H$", H2, right);

// mediator label BELOW the off-shell Higgs line
label("$H^*$", ((A.x + S.x)/2, -0.18L));

// loop labels exactly as ggF_triangle
label("$t$", (ML.x - 0.25L, (ML.y + TL.y)/2));
label("$t$", (ML.x - 0.25L, (BL.y + ML.y)/2));
label("$t$", ((TL.x + A.x)/2 + 0.05L, (TL.y + A.y)/2 + 0.30L));
label("$\bar{t}$", ((A.x + BL.x)/2 + 0.05L, (A.y + BL.y)/2 - 0.30L));

// vertex labels exactly as ggF_triangle (kappa_t / lambda_3 convention)
label("$\kappa_t$", (A.x + 0.14L, A.y + 0.15L));
label("$\lambda_3$", (S.x - 0.14L, S.y + 0.15L));
