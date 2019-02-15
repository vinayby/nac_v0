# -*- mode: python -*-

block_cipher = None


a = Analysis(['nac'],
             pathex=['main/plyplus/', 'main/', '.'],
             binaries=[],
             datas=[  ('./main/plyplus/plyplus/grammars/python.g', 'plyplus/grammars'),
                      ('./main/plyplus/plyplus/grammars/*.g', 'plyplus/grammars'),
                      ('./main/grammar/na.grammar', 'grammar/'),
                      ('./main/codegen/templates/', 'codegen/templates/'),
                      ('libs/bsv', 'libs/bsv'), 
                      ('libs/libna', 'libs/libna'), 
                      ('libs/verilog', 'libs/verilog'),
                      ('libs/vhls_include', 'libs/vhls_include'),
                      ('libs/xdc', 'libs/xdc'),
                      ('utils', 'utils'),
                      ('scripts/*.py', 'scripts/')
                    ], 
             hiddenimports=[],
             hookspath=[],
             runtime_hooks=[],
             excludes=[],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher)
pyz = PYZ(a.pure, a.zipped_data,
             cipher=block_cipher)
exe = EXE(pyz,
          a.scripts,
          a.binaries,
          a.zipfiles,
          a.datas,
          name='nac',
          debug=False,
          strip=True,
          upx=True,
          runtime_tmpdir=None,
          console=True )
