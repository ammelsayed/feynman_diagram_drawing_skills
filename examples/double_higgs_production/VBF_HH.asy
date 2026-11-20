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

// panel (d): two VVH vertices, each radiating one Higgs
pair V1 = C + 0.3L*dir(+90);
pair V2 = C + 0.3L*dir(-90);

drawFermion(q1i -- pl_l_u);
drawFermion(pl_l_u -- q1f);
drawFermion(q2i -- pl_l_d);
drawFermion(pl_l_d -- q2f);

drawPhoton(pl_l_u -- V1);
drawPhoton(pl_l_d -- V2);
drawPhoton(V1 -- V2);

drawScalar(V1 -- h1, None);
drawScalar(V2 -- h2, None);

dot(pl_l_u, linewidth(3));
dot(pl_l_d, linewidth(3));
dot(V1, linewidth(3));
dot(V2, linewidth(3));

label("$q_1$", q1i, left);
label("$q'_1$", q1f, right);
label("$q_2$", q2i, left);
label("$q'_2$", q2f, right);
label("$H$", h1, right);
label("$H$", h2, right);

// mediator labels at the middle of each incoming V line
label("$V$", (pl_l_u + V1)/2 + (0, -0.22L));
label("$V$", (pl_l_d + V2)/2 + (0, 0.22L));

// vertex labels near their V dots, clear of lines and labels
label("$\kappa_V$", (V1.x, V1.y + 0.20L));
label("$\kappa_V$", (V2.x, V2.y - 0.20L));
