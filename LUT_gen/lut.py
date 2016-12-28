import numpy as np
import coe_gen

MIN = -8
MAX = 8 

x = np.linspace(MIN, MAX, 1024)
y = np.round(1 / (1 + np.e ** (-x)) * 255).astype(int)

coe_gen.generate_coe("activations.coe", y)
