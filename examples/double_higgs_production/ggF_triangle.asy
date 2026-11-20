import feynman;

currentpen = linewidth(0.75);
fmdefaults();

real L = 50;
real h = 0.8L;

// ---- identical external endpoints to ggF_box ----
pair G1 = (-2.0L, +h);
pair G2 = (-2.0L, -h);
pair H1 = (+2.0L, +h);
pair H2 = (+2.0L, -h);

// ---- top triangle; fermion flow BL -> TL -> A -> BL ----
pair TL = (-0.8L, +h);
pair BL = (-0.8L, -h);
pair A  = (+0.4L, 0);         // kappa_t vertex (ttH)
pair S  = (+1.2L, 0);         // kappa_lambda vertex (HHH)

drawFermion(BL -- TL);
drawFermion(TL -- A);
drawFermion(A  -- BL);

drawGluon(G1 -- TL);
drawGluon(G2 -- BL);

drawScalar(A -- S, None);
drawScalar(S -- H1, None);
drawScalar(S -- H2, None);

dot(TL, linewidth(3));
dot(BL, linewidth(3));
dot(A, linewidth(3));
dot(S, linewidth(3));

// incoming/outgoing labels at endpoints
label("$g$", G1, left);
label("$g$", G2, left);
label("$H$", H1, right);
label("$H$", H2, right);

// mediator label BELOW the off-shell Higgs line (upper strip is crowded by the kappa labels)
label("$H^*$", ((A.x + S.x)/2, -0.18L));

// closed top-quark loop: consistent arrow flow -> every segment is a t
label("$t$", ((BL.x + TL.x)/2 - 0.2L, (BL.y + TL.y)/2));
label("$t$", ((TL.x + A.x)/2 + 0.05L, (TL.y + A.y)/2 + 0.30L));
label("$\bar{t}$", ((A.x + BL.x)/2 + 0.05L, (A.y + BL.y)/2 - 0.30L));

// vertex labels: above the dots, nudged toward the lower-density side
// kappa_t: upper-left is crowded by the top-quark diagonal -> nudge slightly RIGHT
label("$\kappa_t$", (A.x + 0.14L, A.y + 0.15L));
// kappa_lambda: upper-right is crowded by the outgoing H line -> nudge slightly LEFT
label("$\kappa_\lambda$", (S.x - 0.14L, S.y + 0.15L));
