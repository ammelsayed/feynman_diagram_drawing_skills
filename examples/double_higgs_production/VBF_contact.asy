import feynman;

currentpen = linewidth(0.75);
fmdefaults();

real L = 50;

// FIXED EXTERNAL GEOMETRY — shared by all three VBF diagrams
pair pl = (-0.5*L, 0);
pair pl_l_u = pl + L*dir(+120);
pair pl_l_d = pl + L*dir(-120);
pair q1i = pl_l_u + 1.5*L*dir(+170);
pair q1f = pl_l_u + 2.1*L*dir(+10);
pair q2i = pl_l_d + 1.5*L*dir(-170);
pair q2f = pl_l_d + 2.1*L*dir(-10);
pair C  = pl + 0.9*L;
pair h1 = C + 1.15*L*dir(+30);
pair h2 = C + 1.15*L*dir(-30);

// panel (e): TRUE 4-point VVHH contact — 2 V in, 2 H out, one vertex
drawFermion(q1i -- pl_l_u);
drawFermion(pl_l_u -- q1f);
drawFermion(q2i -- pl_l_d);
drawFermion(pl_l_d -- q2f);

drawPhoton(pl_l_u -- C);
drawPhoton(pl_l_d -- C);

drawScalar(C -- h1, None);
drawScalar(C -- h2, None);

dot(pl_l_u, linewidth(3));
dot(pl_l_d, linewidth(3));
dot(C, linewidth(4));

// incoming/outgoing labels at line endpoints
label("$q_1$", q1i, left);
label("$q'_1$", q1f, right);
label("$q_2$", q2i, left);
label("$q'_2$", q2f, right);
label("$H$", h1, right);
label("$H$", h2, right);

// mediator V labels at the middle of each vector-boson line, offset clear of the wiggles
label("$V$", (pl_l_u + C)/2 + (-0.30L, -0.12L));
label("$V$", (pl_l_d + C)/2 + (-0.30L, 0.12L));

// vertex label near the contact point, above it and clear of both Higgs lines
label("$\kappa_{2V}$", (C.x, C.y + 0.28L));
