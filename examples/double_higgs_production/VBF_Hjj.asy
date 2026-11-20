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

// panel (c): VBF -> H* -> HH
drawFermion(q1i -- pl_l_u);
drawFermion(pl_l_u -- q1f);
drawFermion(q2i -- pl_l_d);
drawFermion(pl_l_d -- q2f);

drawPhoton(pl -- pl_l_u);
drawPhoton(pl_l_d -- pl);

drawScalar(pl -- C, None);
drawScalar(C -- h1, None);
drawScalar(C -- h2, None);

dot(pl_l_u, linewidth(3));
dot(pl_l_d, linewidth(3));
dot(pl, linewidth(3));
dot(C, linewidth(3));

label("$q_1$", q1i, left);
label("$q'_1$", q1f, right);
label("$q_2$", q2i, left);
label("$q'_2$", q2f, right);
label("$H$", h1, right);
label("$H$", h2, right);

// mediator labels at line midpoints, offset clear of the wiggles
label("$V$", (pl + pl_l_u)/2 + (-0.38L, 0));
label("$V$", (pl + pl_l_d)/2 + (-0.38L, 0));
label("$H^*$", ((pl.x + C.x)/2, -0.18L));

// vertex labels near their dots, clear of the mediator labels
label("$\kappa_V$", (pl.x + 0.14L, pl.y + 0.15L));
label("$\kappa_\lambda$", (C.x - 0.14L, C.y + 0.15L));
