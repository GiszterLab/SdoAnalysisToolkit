** SDO Matrix Null Hypotheses ** 

These are the H1-H7 null hypotheses used for testing the efficacy of the spike-triggered SDO to serve as a predictor relative to other models. Each function generates a (N_STATES x N_STATES) matrix which can then be used to predict dpx for generating predictions of subsequent state: px1 = px0+dpx; 

Matrices are returned either as SDOs dp(x1|x0) or as Markov Operators p(x1|x0) (i.e., conditional rather than covariance-normalized)

Matrices: 
- H1 | No-Change Matrix; px1 = px0
- H2 | Gaussian Diffusion; px1 = G*px0;
- H3 | "Spike Triggered Average"; px1 = average px1;
- H4 | Background Dynamics; px1 = L_{bck}*px0 + px0;
- H5 | 1st-Order Markov;   px1 = M^{dt}*px0;
- H6 | "Background + Spike Offset";
- H7 | Spike-triggered SDO
