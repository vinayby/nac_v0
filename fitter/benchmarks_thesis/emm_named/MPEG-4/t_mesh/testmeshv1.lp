\ Model meshILPv1
\ LP format - for model browsing. Use MPS format to capture full model detail.
Minimize
  910 dx_[sdram,upsamp] + 32 dx_[sdram,bab] + dx_[sdram,adsp]
   + 60 dx_[medcpu,sdram] + 40 dx_[medcpu,sram1] + 670 dx_[sram2,upsamp]
   + 250 dx_[sram2,idct] + 173 dx_[sram2,bab] + 500 dx_[sram2,risc]
   + 600 dx_[rast,sdram] + 40 dx_[rast,sram1] + dx_[au,sdram]
   + 190 dx_[vu,sdram] + 910 dy_[sdram,upsamp] + 32 dy_[sdram,bab]
   + dy_[sdram,adsp] + 60 dy_[medcpu,sdram] + 40 dy_[medcpu,sram1]
   + 670 dy_[sram2,upsamp] + 250 dy_[sram2,idct] + 173 dy_[sram2,bab]
   + 500 dy_[sram2,risc] + 600 dy_[rast,sdram] + 40 dy_[rast,sram1]
   + dy_[au,sdram] + 190 dy_[vu,sdram]
Subject To
 R0: x_[sdram] <= 3
 R1: x_[adsp] <= 3
 R2: x_[idct] <= 3
 R3: x_[upsamp] <= 3
 R4: x_[medcpu] <= 3
 R5: x_[risc] <= 3
 R6: x_[sram2] <= 3
 R7: x_[rast] <= 3
 R8: x_[sram1] <= 3
 R9: x_[au] <= 3
 R10: x_[vu] <= 3
 R11: x_[bab] <= 3
 R12: y_[sdram] <= 3
 R13: y_[adsp] <= 3
 R14: y_[idct] <= 3
 R15: y_[upsamp] <= 3
 R16: y_[medcpu] <= 3
 R17: y_[risc] <= 3
 R18: y_[sram2] <= 3
 R19: y_[rast] <= 3
 R20: y_[sram1] <= 3
 R21: y_[au] <= 3
 R22: y_[vu] <= 3
 R23: y_[bab] <= 3
 R24: x_[sdram] + 40 xi_equals_p[sdram,0] <= 40
 R25: x_[sdram] + 40 xi_equals_p[sdram,1] <= 41
 R26: x_[sdram] + 40 xi_equals_p[sdram,2] <= 42
 R27: x_[sdram] + 40 xi_equals_p[sdram,3] <= 43
 R28: x_[adsp] + 40 xi_equals_p[adsp,0] <= 40
 R29: x_[adsp] + 40 xi_equals_p[adsp,1] <= 41
 R30: x_[adsp] + 40 xi_equals_p[adsp,2] <= 42
 R31: x_[adsp] + 40 xi_equals_p[adsp,3] <= 43
 R32: x_[idct] + 40 xi_equals_p[idct,0] <= 40
 R33: x_[idct] + 40 xi_equals_p[idct,1] <= 41
 R34: x_[idct] + 40 xi_equals_p[idct,2] <= 42
 R35: x_[idct] + 40 xi_equals_p[idct,3] <= 43
 R36: x_[upsamp] + 40 xi_equals_p[upsamp,0] <= 40
 R37: x_[upsamp] + 40 xi_equals_p[upsamp,1] <= 41
 R38: x_[upsamp] + 40 xi_equals_p[upsamp,2] <= 42
 R39: x_[upsamp] + 40 xi_equals_p[upsamp,3] <= 43
 R40: x_[medcpu] + 40 xi_equals_p[medcpu,0] <= 40
 R41: x_[medcpu] + 40 xi_equals_p[medcpu,1] <= 41
 R42: x_[medcpu] + 40 xi_equals_p[medcpu,2] <= 42
 R43: x_[medcpu] + 40 xi_equals_p[medcpu,3] <= 43
 R44: x_[risc] + 40 xi_equals_p[risc,0] <= 40
 R45: x_[risc] + 40 xi_equals_p[risc,1] <= 41
 R46: x_[risc] + 40 xi_equals_p[risc,2] <= 42
 R47: x_[risc] + 40 xi_equals_p[risc,3] <= 43
 R48: x_[sram2] + 40 xi_equals_p[sram2,0] <= 40
 R49: x_[sram2] + 40 xi_equals_p[sram2,1] <= 41
 R50: x_[sram2] + 40 xi_equals_p[sram2,2] <= 42
 R51: x_[sram2] + 40 xi_equals_p[sram2,3] <= 43
 R52: x_[rast] + 40 xi_equals_p[rast,0] <= 40
 R53: x_[rast] + 40 xi_equals_p[rast,1] <= 41
 R54: x_[rast] + 40 xi_equals_p[rast,2] <= 42
 R55: x_[rast] + 40 xi_equals_p[rast,3] <= 43
 R56: x_[sram1] + 40 xi_equals_p[sram1,0] <= 40
 R57: x_[sram1] + 40 xi_equals_p[sram1,1] <= 41
 R58: x_[sram1] + 40 xi_equals_p[sram1,2] <= 42
 R59: x_[sram1] + 40 xi_equals_p[sram1,3] <= 43
 R60: x_[au] + 40 xi_equals_p[au,0] <= 40
 R61: x_[au] + 40 xi_equals_p[au,1] <= 41
 R62: x_[au] + 40 xi_equals_p[au,2] <= 42
 R63: x_[au] + 40 xi_equals_p[au,3] <= 43
 R64: x_[vu] + 40 xi_equals_p[vu,0] <= 40
 R65: x_[vu] + 40 xi_equals_p[vu,1] <= 41
 R66: x_[vu] + 40 xi_equals_p[vu,2] <= 42
 R67: x_[vu] + 40 xi_equals_p[vu,3] <= 43
 R68: x_[bab] + 40 xi_equals_p[bab,0] <= 40
 R69: x_[bab] + 40 xi_equals_p[bab,1] <= 41
 R70: x_[bab] + 40 xi_equals_p[bab,2] <= 42
 R71: x_[bab] + 40 xi_equals_p[bab,3] <= 43
 R72: - x_[sdram] + 40 xi_equals_p[sdram,0] <= 40
 R73: - x_[sdram] + 40 xi_equals_p[sdram,1] <= 39
 R74: - x_[sdram] + 40 xi_equals_p[sdram,2] <= 38
 R75: - x_[sdram] + 40 xi_equals_p[sdram,3] <= 37
 R76: - x_[adsp] + 40 xi_equals_p[adsp,0] <= 40
 R77: - x_[adsp] + 40 xi_equals_p[adsp,1] <= 39
 R78: - x_[adsp] + 40 xi_equals_p[adsp,2] <= 38
 R79: - x_[adsp] + 40 xi_equals_p[adsp,3] <= 37
 R80: - x_[idct] + 40 xi_equals_p[idct,0] <= 40
 R81: - x_[idct] + 40 xi_equals_p[idct,1] <= 39
 R82: - x_[idct] + 40 xi_equals_p[idct,2] <= 38
 R83: - x_[idct] + 40 xi_equals_p[idct,3] <= 37
 R84: - x_[upsamp] + 40 xi_equals_p[upsamp,0] <= 40
 R85: - x_[upsamp] + 40 xi_equals_p[upsamp,1] <= 39
 R86: - x_[upsamp] + 40 xi_equals_p[upsamp,2] <= 38
 R87: - x_[upsamp] + 40 xi_equals_p[upsamp,3] <= 37
 R88: - x_[medcpu] + 40 xi_equals_p[medcpu,0] <= 40
 R89: - x_[medcpu] + 40 xi_equals_p[medcpu,1] <= 39
 R90: - x_[medcpu] + 40 xi_equals_p[medcpu,2] <= 38
 R91: - x_[medcpu] + 40 xi_equals_p[medcpu,3] <= 37
 R92: - x_[risc] + 40 xi_equals_p[risc,0] <= 40
 R93: - x_[risc] + 40 xi_equals_p[risc,1] <= 39
 R94: - x_[risc] + 40 xi_equals_p[risc,2] <= 38
 R95: - x_[risc] + 40 xi_equals_p[risc,3] <= 37
 R96: - x_[sram2] + 40 xi_equals_p[sram2,0] <= 40
 R97: - x_[sram2] + 40 xi_equals_p[sram2,1] <= 39
 R98: - x_[sram2] + 40 xi_equals_p[sram2,2] <= 38
 R99: - x_[sram2] + 40 xi_equals_p[sram2,3] <= 37
 R100: - x_[rast] + 40 xi_equals_p[rast,0] <= 40
 R101: - x_[rast] + 40 xi_equals_p[rast,1] <= 39
 R102: - x_[rast] + 40 xi_equals_p[rast,2] <= 38
 R103: - x_[rast] + 40 xi_equals_p[rast,3] <= 37
 R104: - x_[sram1] + 40 xi_equals_p[sram1,0] <= 40
 R105: - x_[sram1] + 40 xi_equals_p[sram1,1] <= 39
 R106: - x_[sram1] + 40 xi_equals_p[sram1,2] <= 38
 R107: - x_[sram1] + 40 xi_equals_p[sram1,3] <= 37
 R108: - x_[au] + 40 xi_equals_p[au,0] <= 40
 R109: - x_[au] + 40 xi_equals_p[au,1] <= 39
 R110: - x_[au] + 40 xi_equals_p[au,2] <= 38
 R111: - x_[au] + 40 xi_equals_p[au,3] <= 37
 R112: - x_[vu] + 40 xi_equals_p[vu,0] <= 40
 R113: - x_[vu] + 40 xi_equals_p[vu,1] <= 39
 R114: - x_[vu] + 40 xi_equals_p[vu,2] <= 38
 R115: - x_[vu] + 40 xi_equals_p[vu,3] <= 37
 R116: - x_[bab] + 40 xi_equals_p[bab,0] <= 40
 R117: - x_[bab] + 40 xi_equals_p[bab,1] <= 39
 R118: - x_[bab] + 40 xi_equals_p[bab,2] <= 38
 R119: - x_[bab] + 40 xi_equals_p[bab,3] <= 37
 R120: y_[sdram] + 40 yi_equals_q[sdram,0] <= 40
 R121: y_[sdram] + 40 yi_equals_q[sdram,1] <= 41
 R122: y_[sdram] + 40 yi_equals_q[sdram,2] <= 42
 R123: y_[sdram] + 40 yi_equals_q[sdram,3] <= 43
 R124: y_[adsp] + 40 yi_equals_q[adsp,0] <= 40
 R125: y_[adsp] + 40 yi_equals_q[adsp,1] <= 41
 R126: y_[adsp] + 40 yi_equals_q[adsp,2] <= 42
 R127: y_[adsp] + 40 yi_equals_q[adsp,3] <= 43
 R128: y_[idct] + 40 yi_equals_q[idct,0] <= 40
 R129: y_[idct] + 40 yi_equals_q[idct,1] <= 41
 R130: y_[idct] + 40 yi_equals_q[idct,2] <= 42
 R131: y_[idct] + 40 yi_equals_q[idct,3] <= 43
 R132: y_[upsamp] + 40 yi_equals_q[upsamp,0] <= 40
 R133: y_[upsamp] + 40 yi_equals_q[upsamp,1] <= 41
 R134: y_[upsamp] + 40 yi_equals_q[upsamp,2] <= 42
 R135: y_[upsamp] + 40 yi_equals_q[upsamp,3] <= 43
 R136: y_[medcpu] + 40 yi_equals_q[medcpu,0] <= 40
 R137: y_[medcpu] + 40 yi_equals_q[medcpu,1] <= 41
 R138: y_[medcpu] + 40 yi_equals_q[medcpu,2] <= 42
 R139: y_[medcpu] + 40 yi_equals_q[medcpu,3] <= 43
 R140: y_[risc] + 40 yi_equals_q[risc,0] <= 40
 R141: y_[risc] + 40 yi_equals_q[risc,1] <= 41
 R142: y_[risc] + 40 yi_equals_q[risc,2] <= 42
 R143: y_[risc] + 40 yi_equals_q[risc,3] <= 43
 R144: y_[sram2] + 40 yi_equals_q[sram2,0] <= 40
 R145: y_[sram2] + 40 yi_equals_q[sram2,1] <= 41
 R146: y_[sram2] + 40 yi_equals_q[sram2,2] <= 42
 R147: y_[sram2] + 40 yi_equals_q[sram2,3] <= 43
 R148: y_[rast] + 40 yi_equals_q[rast,0] <= 40
 R149: y_[rast] + 40 yi_equals_q[rast,1] <= 41
 R150: y_[rast] + 40 yi_equals_q[rast,2] <= 42
 R151: y_[rast] + 40 yi_equals_q[rast,3] <= 43
 R152: y_[sram1] + 40 yi_equals_q[sram1,0] <= 40
 R153: y_[sram1] + 40 yi_equals_q[sram1,1] <= 41
 R154: y_[sram1] + 40 yi_equals_q[sram1,2] <= 42
 R155: y_[sram1] + 40 yi_equals_q[sram1,3] <= 43
 R156: y_[au] + 40 yi_equals_q[au,0] <= 40
 R157: y_[au] + 40 yi_equals_q[au,1] <= 41
 R158: y_[au] + 40 yi_equals_q[au,2] <= 42
 R159: y_[au] + 40 yi_equals_q[au,3] <= 43
 R160: y_[vu] + 40 yi_equals_q[vu,0] <= 40
 R161: y_[vu] + 40 yi_equals_q[vu,1] <= 41
 R162: y_[vu] + 40 yi_equals_q[vu,2] <= 42
 R163: y_[vu] + 40 yi_equals_q[vu,3] <= 43
 R164: y_[bab] + 40 yi_equals_q[bab,0] <= 40
 R165: y_[bab] + 40 yi_equals_q[bab,1] <= 41
 R166: y_[bab] + 40 yi_equals_q[bab,2] <= 42
 R167: y_[bab] + 40 yi_equals_q[bab,3] <= 43
 R168: - y_[sdram] + 40 yi_equals_q[sdram,0] <= 40
 R169: - y_[sdram] + 40 yi_equals_q[sdram,1] <= 39
 R170: - y_[sdram] + 40 yi_equals_q[sdram,2] <= 38
 R171: - y_[sdram] + 40 yi_equals_q[sdram,3] <= 37
 R172: - y_[adsp] + 40 yi_equals_q[adsp,0] <= 40
 R173: - y_[adsp] + 40 yi_equals_q[adsp,1] <= 39
 R174: - y_[adsp] + 40 yi_equals_q[adsp,2] <= 38
 R175: - y_[adsp] + 40 yi_equals_q[adsp,3] <= 37
 R176: - y_[idct] + 40 yi_equals_q[idct,0] <= 40
 R177: - y_[idct] + 40 yi_equals_q[idct,1] <= 39
 R178: - y_[idct] + 40 yi_equals_q[idct,2] <= 38
 R179: - y_[idct] + 40 yi_equals_q[idct,3] <= 37
 R180: - y_[upsamp] + 40 yi_equals_q[upsamp,0] <= 40
 R181: - y_[upsamp] + 40 yi_equals_q[upsamp,1] <= 39
 R182: - y_[upsamp] + 40 yi_equals_q[upsamp,2] <= 38
 R183: - y_[upsamp] + 40 yi_equals_q[upsamp,3] <= 37
 R184: - y_[medcpu] + 40 yi_equals_q[medcpu,0] <= 40
 R185: - y_[medcpu] + 40 yi_equals_q[medcpu,1] <= 39
 R186: - y_[medcpu] + 40 yi_equals_q[medcpu,2] <= 38
 R187: - y_[medcpu] + 40 yi_equals_q[medcpu,3] <= 37
 R188: - y_[risc] + 40 yi_equals_q[risc,0] <= 40
 R189: - y_[risc] + 40 yi_equals_q[risc,1] <= 39
 R190: - y_[risc] + 40 yi_equals_q[risc,2] <= 38
 R191: - y_[risc] + 40 yi_equals_q[risc,3] <= 37
 R192: - y_[sram2] + 40 yi_equals_q[sram2,0] <= 40
 R193: - y_[sram2] + 40 yi_equals_q[sram2,1] <= 39
 R194: - y_[sram2] + 40 yi_equals_q[sram2,2] <= 38
 R195: - y_[sram2] + 40 yi_equals_q[sram2,3] <= 37
 R196: - y_[rast] + 40 yi_equals_q[rast,0] <= 40
 R197: - y_[rast] + 40 yi_equals_q[rast,1] <= 39
 R198: - y_[rast] + 40 yi_equals_q[rast,2] <= 38
 R199: - y_[rast] + 40 yi_equals_q[rast,3] <= 37
 R200: - y_[sram1] + 40 yi_equals_q[sram1,0] <= 40
 R201: - y_[sram1] + 40 yi_equals_q[sram1,1] <= 39
 R202: - y_[sram1] + 40 yi_equals_q[sram1,2] <= 38
 R203: - y_[sram1] + 40 yi_equals_q[sram1,3] <= 37
 R204: - y_[au] + 40 yi_equals_q[au,0] <= 40
 R205: - y_[au] + 40 yi_equals_q[au,1] <= 39
 R206: - y_[au] + 40 yi_equals_q[au,2] <= 38
 R207: - y_[au] + 40 yi_equals_q[au,3] <= 37
 R208: - y_[vu] + 40 yi_equals_q[vu,0] <= 40
 R209: - y_[vu] + 40 yi_equals_q[vu,1] <= 39
 R210: - y_[vu] + 40 yi_equals_q[vu,2] <= 38
 R211: - y_[vu] + 40 yi_equals_q[vu,3] <= 37
 R212: - y_[bab] + 40 yi_equals_q[bab,0] <= 40
 R213: - y_[bab] + 40 yi_equals_q[bab,1] <= 39
 R214: - y_[bab] + 40 yi_equals_q[bab,2] <= 38
 R215: - y_[bab] + 40 yi_equals_q[bab,3] <= 37
 taski_on_1r[sdram]: C24 + C25 + C26 + C27 + C28 + C29 + C30 + C31 + C32
   + C33 + C34 + C35 + C36 + C37 + C38 + C39 = 1
 taski_on_1r[adsp]: C40 + C41 + C42 + C43 + C44 + C45 + C46 + C47 + C48
   + C49 + C50 + C51 + C52 + C53 + C54 + C55 = 1
 taski_on_1r[idct]: C56 + C57 + C58 + C59 + C60 + C61 + C62 + C63 + C64
   + C65 + C66 + C67 + C68 + C69 + C70 + C71 = 1
 taski_on_1r[upsamp]: C72 + C73 + C74 + C75 + C76 + C77 + C78 + C79 + C80
   + C81 + C82 + C83 + C84 + C85 + C86 + C87 = 1
 taski_on_1r[medcpu]: C88 + C89 + C90 + C91 + C92 + C93 + C94 + C95 + C96
   + C97 + C98 + C99 + C100 + C101 + C102 + C103 = 1
 taski_on_1r[risc]: C104 + C105 + C106 + C107 + C108 + C109 + C110 + C111
   + C112 + C113 + C114 + C115 + C116 + C117 + C118 + C119 = 1
 taski_on_1r[sram2]: C120 + C121 + C122 + C123 + C124 + C125 + C126 + C127
   + C128 + C129 + C130 + C131 + C132 + C133 + C134 + C135 = 1
 taski_on_1r[rast]: C136 + C137 + C138 + C139 + C140 + C141 + C142 + C143
   + C144 + C145 + C146 + C147 + C148 + C149 + C150 + C151 = 1
 taski_on_1r[sram1]: C152 + C153 + C154 + C155 + C156 + C157 + C158 + C159
   + C160 + C161 + C162 + C163 + C164 + C165 + C166 + C167 = 1
 taski_on_1r[au]: C168 + C169 + C170 + C171 + C172 + C173 + C174 + C175
   + C176 + C177 + C178 + C179 + C180 + C181 + C182 + C183 = 1
 taski_on_1r[vu]: C184 + C185 + C186 + C187 + C188 + C189 + C190 + C191
   + C192 + C193 + C194 + C195 + C196 + C197 + C198 + C199 = 1
 taski_on_1r[bab]: C200 + C201 + C202 + C203 + C204 + C205 + C206 + C207
   + C208 + C209 + C210 + C211 + C212 + C213 + C214 + C215 = 1
 1r_atmost_1task[0,0]: C24 + C40 + C56 + C72 + C88 + C104 + C120 + C136
   + C152 + C168 + C184 + C200 <= 1
 1r_atmost_1task[0,1]: C25 + C41 + C57 + C73 + C89 + C105 + C121 + C137
   + C153 + C169 + C185 + C201 <= 1
 1r_atmost_1task[0,2]: C26 + C42 + C58 + C74 + C90 + C106 + C122 + C138
   + C154 + C170 + C186 + C202 <= 1
 1r_atmost_1task[0,3]: C27 + C43 + C59 + C75 + C91 + C107 + C123 + C139
   + C155 + C171 + C187 + C203 <= 1
 1r_atmost_1task[1,0]: C28 + C44 + C60 + C76 + C92 + C108 + C124 + C140
   + C156 + C172 + C188 + C204 <= 1
 1r_atmost_1task[1,1]: C29 + C45 + C61 + C77 + C93 + C109 + C125 + C141
   + C157 + C173 + C189 + C205 <= 1
 1r_atmost_1task[1,2]: C30 + C46 + C62 + C78 + C94 + C110 + C126 + C142
   + C158 + C174 + C190 + C206 <= 1
 1r_atmost_1task[1,3]: C31 + C47 + C63 + C79 + C95 + C111 + C127 + C143
   + C159 + C175 + C191 + C207 <= 1
 1r_atmost_1task[2,0]: C32 + C48 + C64 + C80 + C96 + C112 + C128 + C144
   + C160 + C176 + C192 + C208 <= 1
 1r_atmost_1task[2,1]: C33 + C49 + C65 + C81 + C97 + C113 + C129 + C145
   + C161 + C177 + C193 + C209 <= 1
 1r_atmost_1task[2,2]: C34 + C50 + C66 + C82 + C98 + C114 + C130 + C146
   + C162 + C178 + C194 + C210 <= 1
 1r_atmost_1task[2,3]: C35 + C51 + C67 + C83 + C99 + C115 + C131 + C147
   + C163 + C179 + C195 + C211 <= 1
 1r_atmost_1task[3,0]: C36 + C52 + C68 + C84 + C100 + C116 + C132 + C148
   + C164 + C180 + C196 + C212 <= 1
 1r_atmost_1task[3,1]: C37 + C53 + C69 + C85 + C101 + C117 + C133 + C149
   + C165 + C181 + C197 + C213 <= 1
 1r_atmost_1task[3,2]: C38 + C54 + C70 + C86 + C102 + C118 + C134 + C150
   + C166 + C182 + C198 + C214 <= 1
 1r_atmost_1task[3,3]: C39 + C55 + C71 + C87 + C103 + C119 + C135 + C151
   + C167 + C183 + C199 + C215 <= 1
 R244: x_[sdram] - x_[upsamp] - dx_[sdram,upsamp] <= 0
 R245: x_[sdram] - x_[bab] - dx_[sdram,bab] <= 0
 R246: x_[sdram] - x_[adsp] - dx_[sdram,adsp] <= 0
 R247: - x_[sdram] + x_[medcpu] - dx_[medcpu,sdram] <= 0
 R248: x_[medcpu] - x_[sram1] - dx_[medcpu,sram1] <= 0
 R249: - x_[upsamp] + x_[sram2] - dx_[sram2,upsamp] <= 0
 R250: - x_[idct] + x_[sram2] - dx_[sram2,idct] <= 0
 R251: x_[sram2] - x_[bab] - dx_[sram2,bab] <= 0
 R252: - x_[risc] + x_[sram2] - dx_[sram2,risc] <= 0
 R253: - x_[sdram] + x_[rast] - dx_[rast,sdram] <= 0
 R254: x_[rast] - x_[sram1] - dx_[rast,sram1] <= 0
 R255: - x_[sdram] + x_[au] - dx_[au,sdram] <= 0
 R256: - x_[sdram] + x_[vu] - dx_[vu,sdram] <= 0
 R257: - x_[sdram] + x_[upsamp] - dx_[sdram,upsamp] <= 0
 R258: - x_[sdram] + x_[bab] - dx_[sdram,bab] <= 0
 R259: - x_[sdram] + x_[adsp] - dx_[sdram,adsp] <= 0
 R260: x_[sdram] - x_[medcpu] - dx_[medcpu,sdram] <= 0
 R261: - x_[medcpu] + x_[sram1] - dx_[medcpu,sram1] <= 0
 R262: x_[upsamp] - x_[sram2] - dx_[sram2,upsamp] <= 0
 R263: x_[idct] - x_[sram2] - dx_[sram2,idct] <= 0
 R264: - x_[sram2] + x_[bab] - dx_[sram2,bab] <= 0
 R265: x_[risc] - x_[sram2] - dx_[sram2,risc] <= 0
 R266: x_[sdram] - x_[rast] - dx_[rast,sdram] <= 0
 R267: - x_[rast] + x_[sram1] - dx_[rast,sram1] <= 0
 R268: x_[sdram] - x_[au] - dx_[au,sdram] <= 0
 R269: x_[sdram] - x_[vu] - dx_[vu,sdram] <= 0
 R270: y_[sdram] - y_[upsamp] - dy_[sdram,upsamp] <= 0
 R271: y_[sdram] - y_[bab] - dy_[sdram,bab] <= 0
 R272: y_[sdram] - y_[adsp] - dy_[sdram,adsp] <= 0
 R273: - y_[sdram] + y_[medcpu] - dy_[medcpu,sdram] <= 0
 R274: y_[medcpu] - y_[sram1] - dy_[medcpu,sram1] <= 0
 R275: - y_[upsamp] + y_[sram2] - dy_[sram2,upsamp] <= 0
 R276: - y_[idct] + y_[sram2] - dy_[sram2,idct] <= 0
 R277: y_[sram2] - y_[bab] - dy_[sram2,bab] <= 0
 R278: - y_[risc] + y_[sram2] - dy_[sram2,risc] <= 0
 R279: - y_[sdram] + y_[rast] - dy_[rast,sdram] <= 0
 R280: y_[rast] - y_[sram1] - dy_[rast,sram1] <= 0
 R281: - y_[sdram] + y_[au] - dy_[au,sdram] <= 0
 R282: - y_[sdram] + y_[vu] - dy_[vu,sdram] <= 0
 R283: - y_[sdram] + y_[upsamp] - dy_[sdram,upsamp] <= 0
 R284: - y_[sdram] + y_[bab] - dy_[sdram,bab] <= 0
 R285: - y_[sdram] + y_[adsp] - dy_[sdram,adsp] <= 0
 R286: y_[sdram] - y_[medcpu] - dy_[medcpu,sdram] <= 0
 R287: - y_[medcpu] + y_[sram1] - dy_[medcpu,sram1] <= 0
 R288: y_[upsamp] - y_[sram2] - dy_[sram2,upsamp] <= 0
 R289: y_[idct] - y_[sram2] - dy_[sram2,idct] <= 0
 R290: - y_[sram2] + y_[bab] - dy_[sram2,bab] <= 0
 R291: y_[risc] - y_[sram2] - dy_[sram2,risc] <= 0
 R292: y_[sdram] - y_[rast] - dy_[rast,sdram] <= 0
 R293: - y_[rast] + y_[sram1] - dy_[rast,sram1] <= 0
 R294: y_[sdram] - y_[au] - dy_[au,sdram] <= 0
 R295: y_[sdram] - y_[vu] - dy_[vu,sdram] <= 0
Bounds
Binaries
 xi_equals_p[sdram,0] xi_equals_p[sdram,1] xi_equals_p[sdram,2]
 xi_equals_p[sdram,3] xi_equals_p[adsp,0] xi_equals_p[adsp,1]
 xi_equals_p[adsp,2] xi_equals_p[adsp,3] xi_equals_p[idct,0]
 xi_equals_p[idct,1] xi_equals_p[idct,2] xi_equals_p[idct,3]
 xi_equals_p[upsamp,0] xi_equals_p[upsamp,1] xi_equals_p[upsamp,2]
 xi_equals_p[upsamp,3] xi_equals_p[medcpu,0] xi_equals_p[medcpu,1]
 xi_equals_p[medcpu,2] xi_equals_p[medcpu,3] xi_equals_p[risc,0]
 xi_equals_p[risc,1] xi_equals_p[risc,2] xi_equals_p[risc,3]
 xi_equals_p[sram2,0] xi_equals_p[sram2,1] xi_equals_p[sram2,2]
 xi_equals_p[sram2,3] xi_equals_p[rast,0] xi_equals_p[rast,1]
 xi_equals_p[rast,2] xi_equals_p[rast,3] xi_equals_p[sram1,0]
 xi_equals_p[sram1,1] xi_equals_p[sram1,2] xi_equals_p[sram1,3]
 xi_equals_p[au,0] xi_equals_p[au,1] xi_equals_p[au,2] xi_equals_p[au,3]
 xi_equals_p[vu,0] xi_equals_p[vu,1] xi_equals_p[vu,2] xi_equals_p[vu,3]
 xi_equals_p[bab,0] xi_equals_p[bab,1] xi_equals_p[bab,2]
 xi_equals_p[bab,3] yi_equals_q[sdram,0] yi_equals_q[sdram,1]
 yi_equals_q[sdram,2] yi_equals_q[sdram,3] yi_equals_q[adsp,0]
 yi_equals_q[adsp,1] yi_equals_q[adsp,2] yi_equals_q[adsp,3]
 yi_equals_q[idct,0] yi_equals_q[idct,1] yi_equals_q[idct,2]
 yi_equals_q[idct,3] yi_equals_q[upsamp,0] yi_equals_q[upsamp,1]
 yi_equals_q[upsamp,2] yi_equals_q[upsamp,3] yi_equals_q[medcpu,0]
 yi_equals_q[medcpu,1] yi_equals_q[medcpu,2] yi_equals_q[medcpu,3]
 yi_equals_q[risc,0] yi_equals_q[risc,1] yi_equals_q[risc,2]
 yi_equals_q[risc,3] yi_equals_q[sram2,0] yi_equals_q[sram2,1]
 yi_equals_q[sram2,2] yi_equals_q[sram2,3] yi_equals_q[rast,0]
 yi_equals_q[rast,1] yi_equals_q[rast,2] yi_equals_q[rast,3]
 yi_equals_q[sram1,0] yi_equals_q[sram1,1] yi_equals_q[sram1,2]
 yi_equals_q[sram1,3] yi_equals_q[au,0] yi_equals_q[au,1] yi_equals_q[au,2]
 yi_equals_q[au,3] yi_equals_q[vu,0] yi_equals_q[vu,1] yi_equals_q[vu,2]
 yi_equals_q[vu,3] yi_equals_q[bab,0] yi_equals_q[bab,1] yi_equals_q[bab,2]
 yi_equals_q[bab,3]
Generals
 x_[sdram] x_[adsp] x_[idct] x_[upsamp] x_[medcpu] x_[risc] x_[sram2]
 x_[rast] x_[sram1] x_[au] x_[vu] x_[bab] y_[sdram] y_[adsp] y_[idct]
 y_[upsamp] y_[medcpu] y_[risc] y_[sram2] y_[rast] y_[sram1] y_[au] y_[vu]
 y_[bab]
General Constraints
 GC0: C24 = AND ( xi_equals_p[sdram,0] , yi_equals_q[sdram,0] )
 GC1: C25 = AND ( xi_equals_p[sdram,0] , yi_equals_q[sdram,1] )
 GC2: C26 = AND ( xi_equals_p[sdram,0] , yi_equals_q[sdram,2] )
 GC3: C27 = AND ( xi_equals_p[sdram,0] , yi_equals_q[sdram,3] )
 GC4: C28 = AND ( xi_equals_p[sdram,1] , yi_equals_q[sdram,0] )
 GC5: C29 = AND ( xi_equals_p[sdram,1] , yi_equals_q[sdram,1] )
 GC6: C30 = AND ( xi_equals_p[sdram,1] , yi_equals_q[sdram,2] )
 GC7: C31 = AND ( xi_equals_p[sdram,1] , yi_equals_q[sdram,3] )
 GC8: C32 = AND ( xi_equals_p[sdram,2] , yi_equals_q[sdram,0] )
 GC9: C33 = AND ( xi_equals_p[sdram,2] , yi_equals_q[sdram,1] )
 GC10: C34 = AND ( xi_equals_p[sdram,2] , yi_equals_q[sdram,2] )
 GC11: C35 = AND ( xi_equals_p[sdram,2] , yi_equals_q[sdram,3] )
 GC12: C36 = AND ( xi_equals_p[sdram,3] , yi_equals_q[sdram,0] )
 GC13: C37 = AND ( xi_equals_p[sdram,3] , yi_equals_q[sdram,1] )
 GC14: C38 = AND ( xi_equals_p[sdram,3] , yi_equals_q[sdram,2] )
 GC15: C39 = AND ( xi_equals_p[sdram,3] , yi_equals_q[sdram,3] )
 GC16: C40 = AND ( xi_equals_p[adsp,0] , yi_equals_q[adsp,0] )
 GC17: C41 = AND ( xi_equals_p[adsp,0] , yi_equals_q[adsp,1] )
 GC18: C42 = AND ( xi_equals_p[adsp,0] , yi_equals_q[adsp,2] )
 GC19: C43 = AND ( xi_equals_p[adsp,0] , yi_equals_q[adsp,3] )
 GC20: C44 = AND ( xi_equals_p[adsp,1] , yi_equals_q[adsp,0] )
 GC21: C45 = AND ( xi_equals_p[adsp,1] , yi_equals_q[adsp,1] )
 GC22: C46 = AND ( xi_equals_p[adsp,1] , yi_equals_q[adsp,2] )
 GC23: C47 = AND ( xi_equals_p[adsp,1] , yi_equals_q[adsp,3] )
 GC24: C48 = AND ( xi_equals_p[adsp,2] , yi_equals_q[adsp,0] )
 GC25: C49 = AND ( xi_equals_p[adsp,2] , yi_equals_q[adsp,1] )
 GC26: C50 = AND ( xi_equals_p[adsp,2] , yi_equals_q[adsp,2] )
 GC27: C51 = AND ( xi_equals_p[adsp,2] , yi_equals_q[adsp,3] )
 GC28: C52 = AND ( xi_equals_p[adsp,3] , yi_equals_q[adsp,0] )
 GC29: C53 = AND ( xi_equals_p[adsp,3] , yi_equals_q[adsp,1] )
 GC30: C54 = AND ( xi_equals_p[adsp,3] , yi_equals_q[adsp,2] )
 GC31: C55 = AND ( xi_equals_p[adsp,3] , yi_equals_q[adsp,3] )
 GC32: C56 = AND ( xi_equals_p[idct,0] , yi_equals_q[idct,0] )
 GC33: C57 = AND ( xi_equals_p[idct,0] , yi_equals_q[idct,1] )
 GC34: C58 = AND ( xi_equals_p[idct,0] , yi_equals_q[idct,2] )
 GC35: C59 = AND ( xi_equals_p[idct,0] , yi_equals_q[idct,3] )
 GC36: C60 = AND ( xi_equals_p[idct,1] , yi_equals_q[idct,0] )
 GC37: C61 = AND ( xi_equals_p[idct,1] , yi_equals_q[idct,1] )
 GC38: C62 = AND ( xi_equals_p[idct,1] , yi_equals_q[idct,2] )
 GC39: C63 = AND ( xi_equals_p[idct,1] , yi_equals_q[idct,3] )
 GC40: C64 = AND ( xi_equals_p[idct,2] , yi_equals_q[idct,0] )
 GC41: C65 = AND ( xi_equals_p[idct,2] , yi_equals_q[idct,1] )
 GC42: C66 = AND ( xi_equals_p[idct,2] , yi_equals_q[idct,2] )
 GC43: C67 = AND ( xi_equals_p[idct,2] , yi_equals_q[idct,3] )
 GC44: C68 = AND ( xi_equals_p[idct,3] , yi_equals_q[idct,0] )
 GC45: C69 = AND ( xi_equals_p[idct,3] , yi_equals_q[idct,1] )
 GC46: C70 = AND ( xi_equals_p[idct,3] , yi_equals_q[idct,2] )
 GC47: C71 = AND ( xi_equals_p[idct,3] , yi_equals_q[idct,3] )
 GC48: C72 = AND ( xi_equals_p[upsamp,0] , yi_equals_q[upsamp,0] )
 GC49: C73 = AND ( xi_equals_p[upsamp,0] , yi_equals_q[upsamp,1] )
 GC50: C74 = AND ( xi_equals_p[upsamp,0] , yi_equals_q[upsamp,2] )
 GC51: C75 = AND ( xi_equals_p[upsamp,0] , yi_equals_q[upsamp,3] )
 GC52: C76 = AND ( xi_equals_p[upsamp,1] , yi_equals_q[upsamp,0] )
 GC53: C77 = AND ( xi_equals_p[upsamp,1] , yi_equals_q[upsamp,1] )
 GC54: C78 = AND ( xi_equals_p[upsamp,1] , yi_equals_q[upsamp,2] )
 GC55: C79 = AND ( xi_equals_p[upsamp,1] , yi_equals_q[upsamp,3] )
 GC56: C80 = AND ( xi_equals_p[upsamp,2] , yi_equals_q[upsamp,0] )
 GC57: C81 = AND ( xi_equals_p[upsamp,2] , yi_equals_q[upsamp,1] )
 GC58: C82 = AND ( xi_equals_p[upsamp,2] , yi_equals_q[upsamp,2] )
 GC59: C83 = AND ( xi_equals_p[upsamp,2] , yi_equals_q[upsamp,3] )
 GC60: C84 = AND ( xi_equals_p[upsamp,3] , yi_equals_q[upsamp,0] )
 GC61: C85 = AND ( xi_equals_p[upsamp,3] , yi_equals_q[upsamp,1] )
 GC62: C86 = AND ( xi_equals_p[upsamp,3] , yi_equals_q[upsamp,2] )
 GC63: C87 = AND ( xi_equals_p[upsamp,3] , yi_equals_q[upsamp,3] )
 GC64: C88 = AND ( xi_equals_p[medcpu,0] , yi_equals_q[medcpu,0] )
 GC65: C89 = AND ( xi_equals_p[medcpu,0] , yi_equals_q[medcpu,1] )
 GC66: C90 = AND ( xi_equals_p[medcpu,0] , yi_equals_q[medcpu,2] )
 GC67: C91 = AND ( xi_equals_p[medcpu,0] , yi_equals_q[medcpu,3] )
 GC68: C92 = AND ( xi_equals_p[medcpu,1] , yi_equals_q[medcpu,0] )
 GC69: C93 = AND ( xi_equals_p[medcpu,1] , yi_equals_q[medcpu,1] )
 GC70: C94 = AND ( xi_equals_p[medcpu,1] , yi_equals_q[medcpu,2] )
 GC71: C95 = AND ( xi_equals_p[medcpu,1] , yi_equals_q[medcpu,3] )
 GC72: C96 = AND ( xi_equals_p[medcpu,2] , yi_equals_q[medcpu,0] )
 GC73: C97 = AND ( xi_equals_p[medcpu,2] , yi_equals_q[medcpu,1] )
 GC74: C98 = AND ( xi_equals_p[medcpu,2] , yi_equals_q[medcpu,2] )
 GC75: C99 = AND ( xi_equals_p[medcpu,2] , yi_equals_q[medcpu,3] )
 GC76: C100 = AND ( xi_equals_p[medcpu,3] , yi_equals_q[medcpu,0] )
 GC77: C101 = AND ( xi_equals_p[medcpu,3] , yi_equals_q[medcpu,1] )
 GC78: C102 = AND ( xi_equals_p[medcpu,3] , yi_equals_q[medcpu,2] )
 GC79: C103 = AND ( xi_equals_p[medcpu,3] , yi_equals_q[medcpu,3] )
 GC80: C104 = AND ( xi_equals_p[risc,0] , yi_equals_q[risc,0] )
 GC81: C105 = AND ( xi_equals_p[risc,0] , yi_equals_q[risc,1] )
 GC82: C106 = AND ( xi_equals_p[risc,0] , yi_equals_q[risc,2] )
 GC83: C107 = AND ( xi_equals_p[risc,0] , yi_equals_q[risc,3] )
 GC84: C108 = AND ( xi_equals_p[risc,1] , yi_equals_q[risc,0] )
 GC85: C109 = AND ( xi_equals_p[risc,1] , yi_equals_q[risc,1] )
 GC86: C110 = AND ( xi_equals_p[risc,1] , yi_equals_q[risc,2] )
 GC87: C111 = AND ( xi_equals_p[risc,1] , yi_equals_q[risc,3] )
 GC88: C112 = AND ( xi_equals_p[risc,2] , yi_equals_q[risc,0] )
 GC89: C113 = AND ( xi_equals_p[risc,2] , yi_equals_q[risc,1] )
 GC90: C114 = AND ( xi_equals_p[risc,2] , yi_equals_q[risc,2] )
 GC91: C115 = AND ( xi_equals_p[risc,2] , yi_equals_q[risc,3] )
 GC92: C116 = AND ( xi_equals_p[risc,3] , yi_equals_q[risc,0] )
 GC93: C117 = AND ( xi_equals_p[risc,3] , yi_equals_q[risc,1] )
 GC94: C118 = AND ( xi_equals_p[risc,3] , yi_equals_q[risc,2] )
 GC95: C119 = AND ( xi_equals_p[risc,3] , yi_equals_q[risc,3] )
 GC96: C120 = AND ( xi_equals_p[sram2,0] , yi_equals_q[sram2,0] )
 GC97: C121 = AND ( xi_equals_p[sram2,0] , yi_equals_q[sram2,1] )
 GC98: C122 = AND ( xi_equals_p[sram2,0] , yi_equals_q[sram2,2] )
 GC99: C123 = AND ( xi_equals_p[sram2,0] , yi_equals_q[sram2,3] )
 GC100: C124 = AND ( xi_equals_p[sram2,1] , yi_equals_q[sram2,0] )
 GC101: C125 = AND ( xi_equals_p[sram2,1] , yi_equals_q[sram2,1] )
 GC102: C126 = AND ( xi_equals_p[sram2,1] , yi_equals_q[sram2,2] )
 GC103: C127 = AND ( xi_equals_p[sram2,1] , yi_equals_q[sram2,3] )
 GC104: C128 = AND ( xi_equals_p[sram2,2] , yi_equals_q[sram2,0] )
 GC105: C129 = AND ( xi_equals_p[sram2,2] , yi_equals_q[sram2,1] )
 GC106: C130 = AND ( xi_equals_p[sram2,2] , yi_equals_q[sram2,2] )
 GC107: C131 = AND ( xi_equals_p[sram2,2] , yi_equals_q[sram2,3] )
 GC108: C132 = AND ( xi_equals_p[sram2,3] , yi_equals_q[sram2,0] )
 GC109: C133 = AND ( xi_equals_p[sram2,3] , yi_equals_q[sram2,1] )
 GC110: C134 = AND ( xi_equals_p[sram2,3] , yi_equals_q[sram2,2] )
 GC111: C135 = AND ( xi_equals_p[sram2,3] , yi_equals_q[sram2,3] )
 GC112: C136 = AND ( xi_equals_p[rast,0] , yi_equals_q[rast,0] )
 GC113: C137 = AND ( xi_equals_p[rast,0] , yi_equals_q[rast,1] )
 GC114: C138 = AND ( xi_equals_p[rast,0] , yi_equals_q[rast,2] )
 GC115: C139 = AND ( xi_equals_p[rast,0] , yi_equals_q[rast,3] )
 GC116: C140 = AND ( xi_equals_p[rast,1] , yi_equals_q[rast,0] )
 GC117: C141 = AND ( xi_equals_p[rast,1] , yi_equals_q[rast,1] )
 GC118: C142 = AND ( xi_equals_p[rast,1] , yi_equals_q[rast,2] )
 GC119: C143 = AND ( xi_equals_p[rast,1] , yi_equals_q[rast,3] )
 GC120: C144 = AND ( xi_equals_p[rast,2] , yi_equals_q[rast,0] )
 GC121: C145 = AND ( xi_equals_p[rast,2] , yi_equals_q[rast,1] )
 GC122: C146 = AND ( xi_equals_p[rast,2] , yi_equals_q[rast,2] )
 GC123: C147 = AND ( xi_equals_p[rast,2] , yi_equals_q[rast,3] )
 GC124: C148 = AND ( xi_equals_p[rast,3] , yi_equals_q[rast,0] )
 GC125: C149 = AND ( xi_equals_p[rast,3] , yi_equals_q[rast,1] )
 GC126: C150 = AND ( xi_equals_p[rast,3] , yi_equals_q[rast,2] )
 GC127: C151 = AND ( xi_equals_p[rast,3] , yi_equals_q[rast,3] )
 GC128: C152 = AND ( xi_equals_p[sram1,0] , yi_equals_q[sram1,0] )
 GC129: C153 = AND ( xi_equals_p[sram1,0] , yi_equals_q[sram1,1] )
 GC130: C154 = AND ( xi_equals_p[sram1,0] , yi_equals_q[sram1,2] )
 GC131: C155 = AND ( xi_equals_p[sram1,0] , yi_equals_q[sram1,3] )
 GC132: C156 = AND ( xi_equals_p[sram1,1] , yi_equals_q[sram1,0] )
 GC133: C157 = AND ( xi_equals_p[sram1,1] , yi_equals_q[sram1,1] )
 GC134: C158 = AND ( xi_equals_p[sram1,1] , yi_equals_q[sram1,2] )
 GC135: C159 = AND ( xi_equals_p[sram1,1] , yi_equals_q[sram1,3] )
 GC136: C160 = AND ( xi_equals_p[sram1,2] , yi_equals_q[sram1,0] )
 GC137: C161 = AND ( xi_equals_p[sram1,2] , yi_equals_q[sram1,1] )
 GC138: C162 = AND ( xi_equals_p[sram1,2] , yi_equals_q[sram1,2] )
 GC139: C163 = AND ( xi_equals_p[sram1,2] , yi_equals_q[sram1,3] )
 GC140: C164 = AND ( xi_equals_p[sram1,3] , yi_equals_q[sram1,0] )
 GC141: C165 = AND ( xi_equals_p[sram1,3] , yi_equals_q[sram1,1] )
 GC142: C166 = AND ( xi_equals_p[sram1,3] , yi_equals_q[sram1,2] )
 GC143: C167 = AND ( xi_equals_p[sram1,3] , yi_equals_q[sram1,3] )
 GC144: C168 = AND ( xi_equals_p[au,0] , yi_equals_q[au,0] )
 GC145: C169 = AND ( xi_equals_p[au,0] , yi_equals_q[au,1] )
 GC146: C170 = AND ( xi_equals_p[au,0] , yi_equals_q[au,2] )
 GC147: C171 = AND ( xi_equals_p[au,0] , yi_equals_q[au,3] )
 GC148: C172 = AND ( xi_equals_p[au,1] , yi_equals_q[au,0] )
 GC149: C173 = AND ( xi_equals_p[au,1] , yi_equals_q[au,1] )
 GC150: C174 = AND ( xi_equals_p[au,1] , yi_equals_q[au,2] )
 GC151: C175 = AND ( xi_equals_p[au,1] , yi_equals_q[au,3] )
 GC152: C176 = AND ( xi_equals_p[au,2] , yi_equals_q[au,0] )
 GC153: C177 = AND ( xi_equals_p[au,2] , yi_equals_q[au,1] )
 GC154: C178 = AND ( xi_equals_p[au,2] , yi_equals_q[au,2] )
 GC155: C179 = AND ( xi_equals_p[au,2] , yi_equals_q[au,3] )
 GC156: C180 = AND ( xi_equals_p[au,3] , yi_equals_q[au,0] )
 GC157: C181 = AND ( xi_equals_p[au,3] , yi_equals_q[au,1] )
 GC158: C182 = AND ( xi_equals_p[au,3] , yi_equals_q[au,2] )
 GC159: C183 = AND ( xi_equals_p[au,3] , yi_equals_q[au,3] )
 GC160: C184 = AND ( xi_equals_p[vu,0] , yi_equals_q[vu,0] )
 GC161: C185 = AND ( xi_equals_p[vu,0] , yi_equals_q[vu,1] )
 GC162: C186 = AND ( xi_equals_p[vu,0] , yi_equals_q[vu,2] )
 GC163: C187 = AND ( xi_equals_p[vu,0] , yi_equals_q[vu,3] )
 GC164: C188 = AND ( xi_equals_p[vu,1] , yi_equals_q[vu,0] )
 GC165: C189 = AND ( xi_equals_p[vu,1] , yi_equals_q[vu,1] )
 GC166: C190 = AND ( xi_equals_p[vu,1] , yi_equals_q[vu,2] )
 GC167: C191 = AND ( xi_equals_p[vu,1] , yi_equals_q[vu,3] )
 GC168: C192 = AND ( xi_equals_p[vu,2] , yi_equals_q[vu,0] )
 GC169: C193 = AND ( xi_equals_p[vu,2] , yi_equals_q[vu,1] )
 GC170: C194 = AND ( xi_equals_p[vu,2] , yi_equals_q[vu,2] )
 GC171: C195 = AND ( xi_equals_p[vu,2] , yi_equals_q[vu,3] )
 GC172: C196 = AND ( xi_equals_p[vu,3] , yi_equals_q[vu,0] )
 GC173: C197 = AND ( xi_equals_p[vu,3] , yi_equals_q[vu,1] )
 GC174: C198 = AND ( xi_equals_p[vu,3] , yi_equals_q[vu,2] )
 GC175: C199 = AND ( xi_equals_p[vu,3] , yi_equals_q[vu,3] )
 GC176: C200 = AND ( xi_equals_p[bab,0] , yi_equals_q[bab,0] )
 GC177: C201 = AND ( xi_equals_p[bab,0] , yi_equals_q[bab,1] )
 GC178: C202 = AND ( xi_equals_p[bab,0] , yi_equals_q[bab,2] )
 GC179: C203 = AND ( xi_equals_p[bab,0] , yi_equals_q[bab,3] )
 GC180: C204 = AND ( xi_equals_p[bab,1] , yi_equals_q[bab,0] )
 GC181: C205 = AND ( xi_equals_p[bab,1] , yi_equals_q[bab,1] )
 GC182: C206 = AND ( xi_equals_p[bab,1] , yi_equals_q[bab,2] )
 GC183: C207 = AND ( xi_equals_p[bab,1] , yi_equals_q[bab,3] )
 GC184: C208 = AND ( xi_equals_p[bab,2] , yi_equals_q[bab,0] )
 GC185: C209 = AND ( xi_equals_p[bab,2] , yi_equals_q[bab,1] )
 GC186: C210 = AND ( xi_equals_p[bab,2] , yi_equals_q[bab,2] )
 GC187: C211 = AND ( xi_equals_p[bab,2] , yi_equals_q[bab,3] )
 GC188: C212 = AND ( xi_equals_p[bab,3] , yi_equals_q[bab,0] )
 GC189: C213 = AND ( xi_equals_p[bab,3] , yi_equals_q[bab,1] )
 GC190: C214 = AND ( xi_equals_p[bab,3] , yi_equals_q[bab,2] )
 GC191: C215 = AND ( xi_equals_p[bab,3] , yi_equals_q[bab,3] )
End
