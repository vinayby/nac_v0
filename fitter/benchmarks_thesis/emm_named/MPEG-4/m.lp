\ Model lpplace
\ LP format - for model browsing. Use MPS format to capture full model detail.
Minimize
  3 dx_[a,b] + dx_[b,d] + 0.1 dx_[a,c] + 0.5 dx_[c,d] + 2 dx_[a,d]
   + 4 dx_[p,a] + 0.4 dx_[p,b] + 3 dy_[a,b] + dy_[b,d] + 0.1 dy_[a,c]
   + 0.5 dy_[c,d] + 2 dy_[a,d] + 4 dy_[p,a] + 0.4 dy_[p,b]
Subject To
 R0: x_[a] <= 2
 R1: x_[c] <= 2
 R2: x_[b] <= 2
 R3: x_[d] <= 2
 R4: x_[p] <= 2
 R5: y_[a] <= 2
 R6: y_[c] <= 2
 R7: y_[b] <= 2
 R8: y_[d] <= 2
 R9: y_[p] <= 2
 R10: x_[a] - x_[b] - dx_[a,b] <= 0
 R11: x_[b] - x_[d] - dx_[b,d] <= 0
 R12: x_[a] - x_[c] - dx_[a,c] <= 0
 R13: x_[c] - x_[d] - dx_[c,d] <= 0
 R14: x_[a] - x_[d] - dx_[a,d] <= 0
 R15: - x_[a] + x_[p] - dx_[p,a] <= 0
 R16: - x_[b] + x_[p] - dx_[p,b] <= 0
 R17: - x_[a] + x_[b] - dx_[a,b] <= 0
 R18: - x_[b] + x_[d] - dx_[b,d] <= 0
 R19: - x_[a] + x_[c] - dx_[a,c] <= 0
 R20: - x_[c] + x_[d] - dx_[c,d] <= 0
 R21: - x_[a] + x_[d] - dx_[a,d] <= 0
 R22: x_[a] - x_[p] - dx_[p,a] <= 0
 R23: x_[b] - x_[p] - dx_[p,b] <= 0
 R24: y_[a] - y_[b] - dy_[a,b] <= 0
 R25: y_[b] - y_[d] - dy_[b,d] <= 0
 R26: y_[a] - y_[c] - dy_[a,c] <= 0
 R27: y_[c] - y_[d] - dy_[c,d] <= 0
 R28: y_[a] - y_[d] - dy_[a,d] <= 0
 R29: - y_[a] + y_[p] - dy_[p,a] <= 0
 R30: - y_[b] + y_[p] - dy_[p,b] <= 0
 R31: - y_[a] + y_[b] - dy_[a,b] <= 0
 R32: - y_[b] + y_[d] - dy_[b,d] <= 0
 R33: - y_[a] + y_[c] - dy_[a,c] <= 0
 R34: - y_[c] + y_[d] - dy_[c,d] <= 0
 R35: - y_[a] + y_[d] - dy_[a,d] <= 0
 R36: y_[a] - y_[p] - dy_[p,a] <= 0
 R37: y_[b] - y_[p] - dy_[p,b] <= 0
 R38: dx_[a,b] >= 1.5
 R39: dx_[b,d] >= 1.5
 R40: dx_[a,c] >= 1.5
 R41: dx_[c,d] >= 1.5
 R42: dx_[a,d] >= 1.5
 R43: dx_[p,a] >= 1.5
 R44: dx_[p,b] >= 1.5
 R45: dy_[a,b] >= 1.5
 R46: dy_[b,d] >= 1.5
 R47: dy_[a,c] >= 1.5
 R48: dy_[c,d] >= 1.5
 R49: dy_[a,d] >= 1.5
 R50: dy_[p,a] >= 1.5
 R51: dy_[p,b] >= 1.5
 R52: x_[a] = 0
 R53: y_[a] = 0
 R54: x_[p] = 2
 R55: y_[p] = 2
Bounds
End
