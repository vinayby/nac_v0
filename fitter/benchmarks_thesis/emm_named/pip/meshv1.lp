\ Model meshILPv1
\ LP format - for model browsing. Use MPS format to capture full model detail.
Minimize
  64 dx_[jug2,mem] + 64 dx_[jug1,mem] + 64 dx_[inmem2,jug2] + 64 dx_[HS,VS]
   + 64 dx_[inmem1,inmem2] + 128 dx_[inmem1,HS] + 64 dx_[mem,odisp]
   + 64 dx_[VS,jug1] + 64 dy_[jug2,mem] + 64 dy_[jug1,mem]
   + 64 dy_[inmem2,jug2] + 64 dy_[HS,VS] + 64 dy_[inmem1,inmem2]
   + 128 dy_[inmem1,HS] + 64 dy_[mem,odisp] + 64 dy_[VS,jug1]
Subject To
 R0: x_[jug2] <= 2
 R1: x_[jug1] <= 2
 R2: x_[inmem2] <= 2
 R3: x_[HS] <= 2
 R4: x_[inmem1] <= 2
 R5: x_[mem] <= 2
 R6: x_[VS] <= 2
 R7: x_[odisp] <= 2
 R8: y_[jug2] <= 2
 R9: y_[jug1] <= 2
 R10: y_[inmem2] <= 2
 R11: y_[HS] <= 2
 R12: y_[inmem1] <= 2
 R13: y_[mem] <= 2
 R14: y_[VS] <= 2
 R15: y_[odisp] <= 2
 R16: x_[jug2] + 30 xi_equals_p[jug2,0] <= 30
 R17: x_[jug2] + 30 xi_equals_p[jug2,1] <= 31
 R18: x_[jug2] + 30 xi_equals_p[jug2,2] <= 32
 R19: x_[jug1] + 30 xi_equals_p[jug1,0] <= 30
 R20: x_[jug1] + 30 xi_equals_p[jug1,1] <= 31
 R21: x_[jug1] + 30 xi_equals_p[jug1,2] <= 32
 R22: x_[inmem2] + 30 xi_equals_p[inmem2,0] <= 30
 R23: x_[inmem2] + 30 xi_equals_p[inmem2,1] <= 31
 R24: x_[inmem2] + 30 xi_equals_p[inmem2,2] <= 32
 R25: x_[HS] + 30 xi_equals_p[HS,0] <= 30
 R26: x_[HS] + 30 xi_equals_p[HS,1] <= 31
 R27: x_[HS] + 30 xi_equals_p[HS,2] <= 32
 R28: x_[inmem1] + 30 xi_equals_p[inmem1,0] <= 30
 R29: x_[inmem1] + 30 xi_equals_p[inmem1,1] <= 31
 R30: x_[inmem1] + 30 xi_equals_p[inmem1,2] <= 32
 R31: x_[mem] + 30 xi_equals_p[mem,0] <= 30
 R32: x_[mem] + 30 xi_equals_p[mem,1] <= 31
 R33: x_[mem] + 30 xi_equals_p[mem,2] <= 32
 R34: x_[VS] + 30 xi_equals_p[VS,0] <= 30
 R35: x_[VS] + 30 xi_equals_p[VS,1] <= 31
 R36: x_[VS] + 30 xi_equals_p[VS,2] <= 32
 R37: x_[odisp] + 30 xi_equals_p[odisp,0] <= 30
 R38: x_[odisp] + 30 xi_equals_p[odisp,1] <= 31
 R39: x_[odisp] + 30 xi_equals_p[odisp,2] <= 32
 R40: - x_[jug2] + 30 xi_equals_p[jug2,0] <= 30
 R41: - x_[jug2] + 30 xi_equals_p[jug2,1] <= 29
 R42: - x_[jug2] + 30 xi_equals_p[jug2,2] <= 28
 R43: - x_[jug1] + 30 xi_equals_p[jug1,0] <= 30
 R44: - x_[jug1] + 30 xi_equals_p[jug1,1] <= 29
 R45: - x_[jug1] + 30 xi_equals_p[jug1,2] <= 28
 R46: - x_[inmem2] + 30 xi_equals_p[inmem2,0] <= 30
 R47: - x_[inmem2] + 30 xi_equals_p[inmem2,1] <= 29
 R48: - x_[inmem2] + 30 xi_equals_p[inmem2,2] <= 28
 R49: - x_[HS] + 30 xi_equals_p[HS,0] <= 30
 R50: - x_[HS] + 30 xi_equals_p[HS,1] <= 29
 R51: - x_[HS] + 30 xi_equals_p[HS,2] <= 28
 R52: - x_[inmem1] + 30 xi_equals_p[inmem1,0] <= 30
 R53: - x_[inmem1] + 30 xi_equals_p[inmem1,1] <= 29
 R54: - x_[inmem1] + 30 xi_equals_p[inmem1,2] <= 28
 R55: - x_[mem] + 30 xi_equals_p[mem,0] <= 30
 R56: - x_[mem] + 30 xi_equals_p[mem,1] <= 29
 R57: - x_[mem] + 30 xi_equals_p[mem,2] <= 28
 R58: - x_[VS] + 30 xi_equals_p[VS,0] <= 30
 R59: - x_[VS] + 30 xi_equals_p[VS,1] <= 29
 R60: - x_[VS] + 30 xi_equals_p[VS,2] <= 28
 R61: - x_[odisp] + 30 xi_equals_p[odisp,0] <= 30
 R62: - x_[odisp] + 30 xi_equals_p[odisp,1] <= 29
 R63: - x_[odisp] + 30 xi_equals_p[odisp,2] <= 28
 R64: y_[jug2] + 30 yi_equals_q[jug2,0] <= 30
 R65: y_[jug2] + 30 yi_equals_q[jug2,1] <= 31
 R66: y_[jug2] + 30 yi_equals_q[jug2,2] <= 32
 R67: y_[jug1] + 30 yi_equals_q[jug1,0] <= 30
 R68: y_[jug1] + 30 yi_equals_q[jug1,1] <= 31
 R69: y_[jug1] + 30 yi_equals_q[jug1,2] <= 32
 R70: y_[inmem2] + 30 yi_equals_q[inmem2,0] <= 30
 R71: y_[inmem2] + 30 yi_equals_q[inmem2,1] <= 31
 R72: y_[inmem2] + 30 yi_equals_q[inmem2,2] <= 32
 R73: y_[HS] + 30 yi_equals_q[HS,0] <= 30
 R74: y_[HS] + 30 yi_equals_q[HS,1] <= 31
 R75: y_[HS] + 30 yi_equals_q[HS,2] <= 32
 R76: y_[inmem1] + 30 yi_equals_q[inmem1,0] <= 30
 R77: y_[inmem1] + 30 yi_equals_q[inmem1,1] <= 31
 R78: y_[inmem1] + 30 yi_equals_q[inmem1,2] <= 32
 R79: y_[mem] + 30 yi_equals_q[mem,0] <= 30
 R80: y_[mem] + 30 yi_equals_q[mem,1] <= 31
 R81: y_[mem] + 30 yi_equals_q[mem,2] <= 32
 R82: y_[VS] + 30 yi_equals_q[VS,0] <= 30
 R83: y_[VS] + 30 yi_equals_q[VS,1] <= 31
 R84: y_[VS] + 30 yi_equals_q[VS,2] <= 32
 R85: y_[odisp] + 30 yi_equals_q[odisp,0] <= 30
 R86: y_[odisp] + 30 yi_equals_q[odisp,1] <= 31
 R87: y_[odisp] + 30 yi_equals_q[odisp,2] <= 32
 R88: - y_[jug2] + 30 yi_equals_q[jug2,0] <= 30
 R89: - y_[jug2] + 30 yi_equals_q[jug2,1] <= 29
 R90: - y_[jug2] + 30 yi_equals_q[jug2,2] <= 28
 R91: - y_[jug1] + 30 yi_equals_q[jug1,0] <= 30
 R92: - y_[jug1] + 30 yi_equals_q[jug1,1] <= 29
 R93: - y_[jug1] + 30 yi_equals_q[jug1,2] <= 28
 R94: - y_[inmem2] + 30 yi_equals_q[inmem2,0] <= 30
 R95: - y_[inmem2] + 30 yi_equals_q[inmem2,1] <= 29
 R96: - y_[inmem2] + 30 yi_equals_q[inmem2,2] <= 28
 R97: - y_[HS] + 30 yi_equals_q[HS,0] <= 30
 R98: - y_[HS] + 30 yi_equals_q[HS,1] <= 29
 R99: - y_[HS] + 30 yi_equals_q[HS,2] <= 28
 R100: - y_[inmem1] + 30 yi_equals_q[inmem1,0] <= 30
 R101: - y_[inmem1] + 30 yi_equals_q[inmem1,1] <= 29
 R102: - y_[inmem1] + 30 yi_equals_q[inmem1,2] <= 28
 R103: - y_[mem] + 30 yi_equals_q[mem,0] <= 30
 R104: - y_[mem] + 30 yi_equals_q[mem,1] <= 29
 R105: - y_[mem] + 30 yi_equals_q[mem,2] <= 28
 R106: - y_[VS] + 30 yi_equals_q[VS,0] <= 30
 R107: - y_[VS] + 30 yi_equals_q[VS,1] <= 29
 R108: - y_[VS] + 30 yi_equals_q[VS,2] <= 28
 R109: - y_[odisp] + 30 yi_equals_q[odisp,0] <= 30
 R110: - y_[odisp] + 30 yi_equals_q[odisp,1] <= 29
 R111: - y_[odisp] + 30 yi_equals_q[odisp,2] <= 28
 taski_on_1r[jug2]: C16 + C17 + C18 + C19 + C20 + C21 + C22 + C23 + C24
   = 1
 taski_on_1r[jug1]: C25 + C26 + C27 + C28 + C29 + C30 + C31 + C32 + C33
   = 1
 taski_on_1r[inmem2]: C34 + C35 + C36 + C37 + C38 + C39 + C40 + C41 + C42
   = 1
 taski_on_1r[HS]: C43 + C44 + C45 + C46 + C47 + C48 + C49 + C50 + C51 = 1
 taski_on_1r[inmem1]: C52 + C53 + C54 + C55 + C56 + C57 + C58 + C59 + C60
   = 1
 taski_on_1r[mem]: C61 + C62 + C63 + C64 + C65 + C66 + C67 + C68 + C69 = 1
 taski_on_1r[VS]: C70 + C71 + C72 + C73 + C74 + C75 + C76 + C77 + C78 = 1
 taski_on_1r[odisp]: C79 + C80 + C81 + C82 + C83 + C84 + C85 + C86 + C87
   = 1
 1r_atmost_1task[0,0]: C16 + C25 + C34 + C43 + C52 + C61 + C70 + C79 <= 1
 1r_atmost_1task[0,1]: C17 + C26 + C35 + C44 + C53 + C62 + C71 + C80 <= 1
 1r_atmost_1task[0,2]: C18 + C27 + C36 + C45 + C54 + C63 + C72 + C81 <= 1
 1r_atmost_1task[1,0]: C19 + C28 + C37 + C46 + C55 + C64 + C73 + C82 <= 1
 1r_atmost_1task[1,1]: C20 + C29 + C38 + C47 + C56 + C65 + C74 + C83 <= 1
 1r_atmost_1task[1,2]: C21 + C30 + C39 + C48 + C57 + C66 + C75 + C84 <= 1
 1r_atmost_1task[2,0]: C22 + C31 + C40 + C49 + C58 + C67 + C76 + C85 <= 1
 1r_atmost_1task[2,1]: C23 + C32 + C41 + C50 + C59 + C68 + C77 + C86 <= 1
 1r_atmost_1task[2,2]: C24 + C33 + C42 + C51 + C60 + C69 + C78 + C87 <= 1
 R129: x_[jug2] - x_[mem] - dx_[jug2,mem] <= 0
 R130: x_[jug1] - x_[mem] - dx_[jug1,mem] <= 0
 R131: - x_[jug2] + x_[inmem2] - dx_[inmem2,jug2] <= 0
 R132: x_[HS] - x_[VS] - dx_[HS,VS] <= 0
 R133: - x_[inmem2] + x_[inmem1] - dx_[inmem1,inmem2] <= 0
 R134: - x_[HS] + x_[inmem1] - dx_[inmem1,HS] <= 0
 R135: x_[mem] - x_[odisp] - dx_[mem,odisp] <= 0
 R136: - x_[jug1] + x_[VS] - dx_[VS,jug1] <= 0
 R137: - x_[jug2] + x_[mem] - dx_[jug2,mem] <= 0
 R138: - x_[jug1] + x_[mem] - dx_[jug1,mem] <= 0
 R139: x_[jug2] - x_[inmem2] - dx_[inmem2,jug2] <= 0
 R140: - x_[HS] + x_[VS] - dx_[HS,VS] <= 0
 R141: x_[inmem2] - x_[inmem1] - dx_[inmem1,inmem2] <= 0
 R142: x_[HS] - x_[inmem1] - dx_[inmem1,HS] <= 0
 R143: - x_[mem] + x_[odisp] - dx_[mem,odisp] <= 0
 R144: x_[jug1] - x_[VS] - dx_[VS,jug1] <= 0
 R145: y_[jug2] - y_[mem] - dy_[jug2,mem] <= 0
 R146: y_[jug1] - y_[mem] - dy_[jug1,mem] <= 0
 R147: - y_[jug2] + y_[inmem2] - dy_[inmem2,jug2] <= 0
 R148: y_[HS] - y_[VS] - dy_[HS,VS] <= 0
 R149: - y_[inmem2] + y_[inmem1] - dy_[inmem1,inmem2] <= 0
 R150: - y_[HS] + y_[inmem1] - dy_[inmem1,HS] <= 0
 R151: y_[mem] - y_[odisp] - dy_[mem,odisp] <= 0
 R152: - y_[jug1] + y_[VS] - dy_[VS,jug1] <= 0
 R153: - y_[jug2] + y_[mem] - dy_[jug2,mem] <= 0
 R154: - y_[jug1] + y_[mem] - dy_[jug1,mem] <= 0
 R155: y_[jug2] - y_[inmem2] - dy_[inmem2,jug2] <= 0
 R156: - y_[HS] + y_[VS] - dy_[HS,VS] <= 0
 R157: y_[inmem2] - y_[inmem1] - dy_[inmem1,inmem2] <= 0
 R158: y_[HS] - y_[inmem1] - dy_[inmem1,HS] <= 0
 R159: - y_[mem] + y_[odisp] - dy_[mem,odisp] <= 0
 R160: y_[jug1] - y_[VS] - dy_[VS,jug1] <= 0
Bounds
Binaries
 xi_equals_p[jug2,0] xi_equals_p[jug2,1] xi_equals_p[jug2,2]
 xi_equals_p[jug1,0] xi_equals_p[jug1,1] xi_equals_p[jug1,2]
 xi_equals_p[inmem2,0] xi_equals_p[inmem2,1] xi_equals_p[inmem2,2]
 xi_equals_p[HS,0] xi_equals_p[HS,1] xi_equals_p[HS,2]
 xi_equals_p[inmem1,0] xi_equals_p[inmem1,1] xi_equals_p[inmem1,2]
 xi_equals_p[mem,0] xi_equals_p[mem,1] xi_equals_p[mem,2] xi_equals_p[VS,0]
 xi_equals_p[VS,1] xi_equals_p[VS,2] xi_equals_p[odisp,0]
 xi_equals_p[odisp,1] xi_equals_p[odisp,2] yi_equals_q[jug2,0]
 yi_equals_q[jug2,1] yi_equals_q[jug2,2] yi_equals_q[jug1,0]
 yi_equals_q[jug1,1] yi_equals_q[jug1,2] yi_equals_q[inmem2,0]
 yi_equals_q[inmem2,1] yi_equals_q[inmem2,2] yi_equals_q[HS,0]
 yi_equals_q[HS,1] yi_equals_q[HS,2] yi_equals_q[inmem1,0]
 yi_equals_q[inmem1,1] yi_equals_q[inmem1,2] yi_equals_q[mem,0]
 yi_equals_q[mem,1] yi_equals_q[mem,2] yi_equals_q[VS,0] yi_equals_q[VS,1]
 yi_equals_q[VS,2] yi_equals_q[odisp,0] yi_equals_q[odisp,1]
 yi_equals_q[odisp,2]
Generals
 x_[jug2] x_[jug1] x_[inmem2] x_[HS] x_[inmem1] x_[mem] x_[VS] x_[odisp]
 y_[jug2] y_[jug1] y_[inmem2] y_[HS] y_[inmem1] y_[mem] y_[VS] y_[odisp]
General Constraints
 GC0: C16 = AND ( xi_equals_p[jug2,0] , yi_equals_q[jug2,0] )
 GC1: C17 = AND ( xi_equals_p[jug2,0] , yi_equals_q[jug2,1] )
 GC2: C18 = AND ( xi_equals_p[jug2,0] , yi_equals_q[jug2,2] )
 GC3: C19 = AND ( xi_equals_p[jug2,1] , yi_equals_q[jug2,0] )
 GC4: C20 = AND ( xi_equals_p[jug2,1] , yi_equals_q[jug2,1] )
 GC5: C21 = AND ( xi_equals_p[jug2,1] , yi_equals_q[jug2,2] )
 GC6: C22 = AND ( xi_equals_p[jug2,2] , yi_equals_q[jug2,0] )
 GC7: C23 = AND ( xi_equals_p[jug2,2] , yi_equals_q[jug2,1] )
 GC8: C24 = AND ( xi_equals_p[jug2,2] , yi_equals_q[jug2,2] )
 GC9: C25 = AND ( xi_equals_p[jug1,0] , yi_equals_q[jug1,0] )
 GC10: C26 = AND ( xi_equals_p[jug1,0] , yi_equals_q[jug1,1] )
 GC11: C27 = AND ( xi_equals_p[jug1,0] , yi_equals_q[jug1,2] )
 GC12: C28 = AND ( xi_equals_p[jug1,1] , yi_equals_q[jug1,0] )
 GC13: C29 = AND ( xi_equals_p[jug1,1] , yi_equals_q[jug1,1] )
 GC14: C30 = AND ( xi_equals_p[jug1,1] , yi_equals_q[jug1,2] )
 GC15: C31 = AND ( xi_equals_p[jug1,2] , yi_equals_q[jug1,0] )
 GC16: C32 = AND ( xi_equals_p[jug1,2] , yi_equals_q[jug1,1] )
 GC17: C33 = AND ( xi_equals_p[jug1,2] , yi_equals_q[jug1,2] )
 GC18: C34 = AND ( xi_equals_p[inmem2,0] , yi_equals_q[inmem2,0] )
 GC19: C35 = AND ( xi_equals_p[inmem2,0] , yi_equals_q[inmem2,1] )
 GC20: C36 = AND ( xi_equals_p[inmem2,0] , yi_equals_q[inmem2,2] )
 GC21: C37 = AND ( xi_equals_p[inmem2,1] , yi_equals_q[inmem2,0] )
 GC22: C38 = AND ( xi_equals_p[inmem2,1] , yi_equals_q[inmem2,1] )
 GC23: C39 = AND ( xi_equals_p[inmem2,1] , yi_equals_q[inmem2,2] )
 GC24: C40 = AND ( xi_equals_p[inmem2,2] , yi_equals_q[inmem2,0] )
 GC25: C41 = AND ( xi_equals_p[inmem2,2] , yi_equals_q[inmem2,1] )
 GC26: C42 = AND ( xi_equals_p[inmem2,2] , yi_equals_q[inmem2,2] )
 GC27: C43 = AND ( xi_equals_p[HS,0] , yi_equals_q[HS,0] )
 GC28: C44 = AND ( xi_equals_p[HS,0] , yi_equals_q[HS,1] )
 GC29: C45 = AND ( xi_equals_p[HS,0] , yi_equals_q[HS,2] )
 GC30: C46 = AND ( xi_equals_p[HS,1] , yi_equals_q[HS,0] )
 GC31: C47 = AND ( xi_equals_p[HS,1] , yi_equals_q[HS,1] )
 GC32: C48 = AND ( xi_equals_p[HS,1] , yi_equals_q[HS,2] )
 GC33: C49 = AND ( xi_equals_p[HS,2] , yi_equals_q[HS,0] )
 GC34: C50 = AND ( xi_equals_p[HS,2] , yi_equals_q[HS,1] )
 GC35: C51 = AND ( xi_equals_p[HS,2] , yi_equals_q[HS,2] )
 GC36: C52 = AND ( xi_equals_p[inmem1,0] , yi_equals_q[inmem1,0] )
 GC37: C53 = AND ( xi_equals_p[inmem1,0] , yi_equals_q[inmem1,1] )
 GC38: C54 = AND ( xi_equals_p[inmem1,0] , yi_equals_q[inmem1,2] )
 GC39: C55 = AND ( xi_equals_p[inmem1,1] , yi_equals_q[inmem1,0] )
 GC40: C56 = AND ( xi_equals_p[inmem1,1] , yi_equals_q[inmem1,1] )
 GC41: C57 = AND ( xi_equals_p[inmem1,1] , yi_equals_q[inmem1,2] )
 GC42: C58 = AND ( xi_equals_p[inmem1,2] , yi_equals_q[inmem1,0] )
 GC43: C59 = AND ( xi_equals_p[inmem1,2] , yi_equals_q[inmem1,1] )
 GC44: C60 = AND ( xi_equals_p[inmem1,2] , yi_equals_q[inmem1,2] )
 GC45: C61 = AND ( xi_equals_p[mem,0] , yi_equals_q[mem,0] )
 GC46: C62 = AND ( xi_equals_p[mem,0] , yi_equals_q[mem,1] )
 GC47: C63 = AND ( xi_equals_p[mem,0] , yi_equals_q[mem,2] )
 GC48: C64 = AND ( xi_equals_p[mem,1] , yi_equals_q[mem,0] )
 GC49: C65 = AND ( xi_equals_p[mem,1] , yi_equals_q[mem,1] )
 GC50: C66 = AND ( xi_equals_p[mem,1] , yi_equals_q[mem,2] )
 GC51: C67 = AND ( xi_equals_p[mem,2] , yi_equals_q[mem,0] )
 GC52: C68 = AND ( xi_equals_p[mem,2] , yi_equals_q[mem,1] )
 GC53: C69 = AND ( xi_equals_p[mem,2] , yi_equals_q[mem,2] )
 GC54: C70 = AND ( xi_equals_p[VS,0] , yi_equals_q[VS,0] )
 GC55: C71 = AND ( xi_equals_p[VS,0] , yi_equals_q[VS,1] )
 GC56: C72 = AND ( xi_equals_p[VS,0] , yi_equals_q[VS,2] )
 GC57: C73 = AND ( xi_equals_p[VS,1] , yi_equals_q[VS,0] )
 GC58: C74 = AND ( xi_equals_p[VS,1] , yi_equals_q[VS,1] )
 GC59: C75 = AND ( xi_equals_p[VS,1] , yi_equals_q[VS,2] )
 GC60: C76 = AND ( xi_equals_p[VS,2] , yi_equals_q[VS,0] )
 GC61: C77 = AND ( xi_equals_p[VS,2] , yi_equals_q[VS,1] )
 GC62: C78 = AND ( xi_equals_p[VS,2] , yi_equals_q[VS,2] )
 GC63: C79 = AND ( xi_equals_p[odisp,0] , yi_equals_q[odisp,0] )
 GC64: C80 = AND ( xi_equals_p[odisp,0] , yi_equals_q[odisp,1] )
 GC65: C81 = AND ( xi_equals_p[odisp,0] , yi_equals_q[odisp,2] )
 GC66: C82 = AND ( xi_equals_p[odisp,1] , yi_equals_q[odisp,0] )
 GC67: C83 = AND ( xi_equals_p[odisp,1] , yi_equals_q[odisp,1] )
 GC68: C84 = AND ( xi_equals_p[odisp,1] , yi_equals_q[odisp,2] )
 GC69: C85 = AND ( xi_equals_p[odisp,2] , yi_equals_q[odisp,0] )
 GC70: C86 = AND ( xi_equals_p[odisp,2] , yi_equals_q[odisp,1] )
 GC71: C87 = AND ( xi_equals_p[odisp,2] , yi_equals_q[odisp,2] )
End
