#    This file is part of Metasm, the Ruby assembly manipulation suite
#    Copyright (C) 2007 Yoann GUILLOT
#
#    Licence is LGPL, see LICENCE in the top-level directory


require 'metasm/exe_format/main'

module Metasm
class ELF < ExeFormat
	CLASS = { 0 => 'NONE', 1 => '32', 2 => '64', 200 => '64_icc' }
	DATA  = { 0 => 'NONE', 1 => 'LSB', 2 => 'MSB' }
	VERSION = { 0 => 'INVALID', 1 => 'CURRENT' }
	ABI = { 0 => 'SYSV', 1 => 'HPUX', 2 => 'NETBSD', 3 => 'LINUX',
		6 => 'SOLARIS', 7 => 'AIX', 8 => 'IRIX', 9 => 'FREEBSD',
		10 => 'TRU64', 11 => 'MODESTO', 12 => 'OPENBSD', 97 => 'ARM',
		255 => 'STANDALONE'}
	TYPE = { 0 => 'NONE', 1 => 'REL', 2 => 'EXEC', 3 => 'DYN', 4 => 'CORE' }
	TYPE_LOPROC = 0xff00
	TYPE_HIPROC = 0xffff

	MACHINE = {
		 0 => 'NONE',   1 => 'M32',     2 => 'SPARC',   3 => '386',
		 4 => '68K',    5 => '88K',     6 => '486',     7 => '860',
		 8 => 'MIPS',   9 => 'S370',   10 => 'MIPS_RS3_LE',
		15 => 'PARISC',
		17 => 'VPP500',18 => 'SPARC32PLUS', 19 => '960',
		20 => 'PPC',   21 => 'PPC64',  22 => 'S390',
		36 => 'V800',  37 => 'FR20',   38 => 'RH32',   39 => 'MCORE',
		40 => 'ARM',   41 => 'ALPHA_STD', 42 => 'SH', 43 => 'SPARCV9',
		44 => 'TRICORE', 45 => 'ARC',  46 => 'H8_300', 47 => 'H8_300H',
		48 => 'H8S',   49 => 'H8_500', 50 => 'IA_64',  51 => 'MIPS_X',
		52 => 'COLDFIRE', 53 => '68HC12', 54 => 'MMA', 55 => 'PCP',
		56 => 'NCPU',  57 => 'NDR1',   58 => 'STARCORE', 59 => 'ME16',
		60 => 'ST100', 61 => 'TINYJ',  62 => 'X86_64', 63 => 'PDSP',
		66 => 'FX66',  67 => 'ST9PLUS',
		68 => 'ST7',   69 => '68HC16', 70 => '68HC11', 71 => '68HC08',
		72 => '68HC05',73 => 'SVX',    74 => 'ST19',   75 => 'VAX',
		76 => 'CRIS',  77 => 'JAVELIN',78 => 'FIREPATH', 79 => 'ZSP',
		80 => 'MMIX',  81 => 'HUANY',  82 => 'PRISM',  83 => 'AVR',
		84 => 'FR30',  85 => 'D10V',   86 => 'D30V',   87 => 'V850',
		88 => 'M32R',  89 => 'MN10300',90 => 'MN10200',91 => 'PJ',
		92 => 'OPENRISC', 93 => 'ARC_A5', 94 => 'XTENSA',
		99 => 'PJ',
		0x9026 => 'ALPHA'
	}

	FLAGS = Hash.new({}).merge(
		'SPARC' => {0x100 => '32PLUS', 0x200 => 'SUN_US1',
			0x400 => 'HAL_R1', 0x800 => 'SUN_US3',
			0x8000_0000 => 'LEDATA'},
		'SPARCV9' => {0 => 'TSO', 1 => 'PSO', 2 => 'RMO'},	# XXX not a flag
		'MIPS' => {1 => 'NOREORDER', 2 => 'PIC', 4 => 'CPIC',
			8 => 'XGOT', 16 => '64BIT_WHIRL', 32 => 'ABI2',
			64 => 'ABI_ON32'}
	)

	DYNAMIC_TAG = { 0 => 'NULL', 1 => 'NEEDED', 2 => 'PLTRELSZ', 3 =>
		'PLTGOT', 4 => 'HASH', 5 => 'STRTAB', 6 => 'SYMTAB', 7 => 'RELA',
		8 => 'RELASZ', 9 => 'RELAENT', 10 => 'STRSZ', 11 => 'SYMENT',
		12 => 'INIT', 13 => 'FINI', 14 => 'SONAME', 15 => 'RPATH',
		16 => 'SYMBOLIC', 17 => 'REL', 18 => 'RELSZ', 19 => 'RELENT',
		20 => 'PLTREL', 21 => 'DEBUG', 22 => 'TEXTREL', 23 => 'JMPREL',
		24 => 'BIND_NOW',
		25 => 'INIT_ARRAY', 26 => 'FINI_ARRAY',
		27 => 'INIT_ARRAYSZ', 28 => 'FINI_ARRAYSZ',
		29 => 'RUNPATH', 30 => 'FLAGS', 31 => 'ENCODING',
		32 => 'PREINIT_ARRAY', 33 => 'PREINIT_ARRAYSZ',
		0x6fff_fdf5 => 'GNU_PRELINKED',
		0x6fff_fdf6 => 'GNU_CONFLICTSZ', 0x6fff_fdf7 => 'LIBLISTSZ',
		0x6fff_fdf8 => 'CHECKSUM',       0x6fff_fdf9 => 'PLTPADSZ',
		0x6fff_fdfa => 'MOVEENT',        0x6fff_fdfb => 'MOVESZ',
		0x6fff_fdfc => 'FEATURE_1',      0x6fff_fdfd => 'POSFLAG_1',
		0x6fff_fdfe => 'SYMINSZ',        0x6fff_fdff => 'SYMINENT',
		0x6fff_fef5 => 'GNU_HASH',
		0x6fff_fef6 => 'TLSDESC_PLT',    0x6fff_fef7 => 'TLSDESC_GOT',
		0x6fff_fef8 => 'GNU_CONFLICT',   0x6fff_fef9 => 'GNU_LIBLIST',
		0x6fff_fefa => 'CONFIG',         0x6fff_fefb => 'DEPAUDIT',
		0x6fff_fefc => 'AUDIT',          0x6fff_fefd => 'PLTPAD',
		0x6fff_fefe => 'MOVETAB',        0x6fff_feff => 'SYMINFO',
		0x6fff_fff0 => 'VERSYM',         0x6fff_fff9 => 'RELACOUNT',
		0x6fff_fffa => 'RELCOUNT',       0x6fff_fffb => 'FLAGS_1',
		0x6fff_fffc => 'VERDEF',         0x6fff_fffd => 'VERDEFNUM',
		0x6fff_fffe => 'VERNEED',        0x6fff_ffff => 'VERNEEDNUM'
	}
	DYNAMIC_TAG_LOPROC = 0x7000_0000
	DYNAMIC_TAG_HIPROC = 0x7fff_ffff

	DYNAMIC_FLAGS = { 1 => 'ORIGIN', 2 => 'SYMBOLIC', 4 => 'TEXTREL',
		8 => 'BIND_NOW', 0x10 => 'STATIC_TLS' }
	DYNAMIC_FLAGS_1 = { 1 => 'NOW', 2 => 'GLOBAL', 4 => 'GROUP',
		8 => 'NODELETE', 0x10 => 'LOADFLTR', 0x20 => 'INITFIRST',
		0x40 => 'NOOPEN', 0x80 => 'ORIGIN', 0x100 => 'DIRECT',
		0x200 => 'TRANS', 0x400 => 'INTERPOSE', 0x800 => 'NODEFLIB',
		0x1000 => 'NODUMP', 0x2000 => 'CONFALT', 0x4000 => 'ENDFILTEE',
		0x8000 => 'DISPRELDNE', 0x10000 => 'DISPRELPND' }
	DYNAMIC_FEATURE_1 = { 1 => 'PARINIT', 2 => 'CONFEXP' }
	DYNAMIC_POSFLAG_1 = { 1 => 'LAZYLOAD', 2 => 'GROUPPERM' }

	PH_TYPE = { 0 => 'NULL', 1 => 'LOAD', 2 => 'DYNAMIC', 3 => 'INTERP',
		4 => 'NOTE', 5 => 'SHLIB', 6 => 'PHDR', 7 => 'TLS',
		0x6474e550 => 'GNU_EH_FRAME', 0x6474e551 => 'GNU_STACK',
		0x6474e552 => 'GNU_RELRO' }
	PH_TYPE_LOPROC = 0x7000_0000
	PH_TYPE_HIPROC = 0x7fff_ffff
	PH_FLAGS = { 1 => 'X', 2 => 'W', 4 => 'R' }

	SH_TYPE = { 0 => 'NULL', 1 => 'PROGBITS', 2 => 'SYMTAB', 3 => 'STRTAB',
		4 => 'RELA', 5 => 'HASH', 6 => 'DYNAMIC', 7 => 'NOTE',
		8 => 'NOBITS', 9 => 'REL', 10 => 'SHLIB', 11 => 'DYNSYM',
		14 => 'INIT_ARRAY', 15 => 'FINI_ARRAY', 16 => 'PREINIT_ARRAY',
		17 => 'GROUP', 18 => 'SYMTAB_SHNDX',
		0x6fff_fff6 => 'GNU_HASH', 0x6fff_fff7 => 'GNU_LIBLIST',
		0x6fff_fff8 => 'GNU_CHECKSUM',
		0x6fff_fffd => 'GNU_verdef', 0x6fff_fffe => 'GNU_verneed',
		0x6fff_ffff => 'GNU_versym' }
	SH_TYPE_LOOS   = 0x6000_0000
	SH_TYPE_HIOS   = 0x6fff_ffff
	SH_TYPE_LOPROC = 0x7000_0000
	SH_TYPE_HIPROC = 0x7fff_ffff
	SH_TYPE_LOUSER = 0x8000_0000
	SH_TYPE_HIUSER = 0xffff_ffff

	SH_FLAGS = { 1 => 'WRITE', 2 => 'ALLOC', 4 => 'EXECINSTR',
		0x10 => 'MERGE', 0x20 => 'STRINGS', 0x40 => 'INFO_LINK',
		0x80 => 'LINK_ORDER', 0x100 => 'OS_NONCONFORMING',
		0x200 => 'GROUP', 0x400 => 'TLS' }
	SH_FLAGS_MASKPROC = 0xf000_0000

	SH_INDEX = { 0 => 'UNDEF',
		0xfff1 => 'ABS', 0xfff2 => 'COMMON',
		0xffff => 'XINDEX', }
	SH_INDEX_LORESERVE = 0xff00
	SH_INDEX_LOPROC    = 0xff00
	SH_INDEX_HIPROC    = 0xff1f
	SH_INDEX_LOOS      = 0xff20
	SH_INDEX_HIOS      = 0xff3f
	SH_INDEX_HIRESERVE = 0xffff

	SYMBOL_BIND = { 0 => 'LOCAL', 1 => 'GLOBAL', 2 => 'WEAK' }
	SYMBOL_BIND_LOPROC = 13
	SYMBOL_BIND_HIPROC = 15

	SYMBOL_TYPE = { 0 => 'NOTYPE', 1 => 'OBJECT', 2 => 'FUNC',
		3 => 'SECTION', 4 => 'FILE', 5 => 'COMMON', 6 => 'TLS' }
	SYMBOL_TYPE_LOPROC = 13
	SYMBOL_TYPE_HIPROC = 15

	SYMBOL_VISIBILITY = { 0 => 'DEFAULT', 1 => 'INTERNAL', 2 => 'HIDDEN', 3 => 'PROTECTED' }

	RELOCATION_TYPE = Hash.new({}).merge(	# key are in MACHINE.values
		'386' => { 0 => 'NONE', 1 => '32', 2 => 'PC32', 3 => 'GOT32',
			4 => 'PLT32', 5 => 'COPY', 6 => 'GLOB_DAT',
			7 => 'JMP_SLOT', 8 => 'RELATIVE', 9 => 'GOTOFF',
			10 => 'GOTPC', 11 => '32PLT', 12 => 'TLS_GD_PLT',
			13 => 'TLS_LDM_PLT', 14 => 'TLS_TPOFF', 15 => 'TLS_IE',
			16 => 'TLS_GOTIE', 17 => 'TLS_LE', 18 => 'TLS_GD',
			19 => 'TLS_LDM', 20 => '16', 21 => 'PC16', 22 => '8',
			23 => 'PC8', 24 => 'TLS_GD_32', 25 => 'TLS_GD_PUSH',
			26 => 'TLS_GD_CALL', 27 => 'TLS_GD_POP',
			28 => 'TLS_LDM_32', 29 => 'TLS_LDM_PUSH',
			30 => 'TLS_LDM_CALL', 31 => 'TLS_LDM_POP',
			32 => 'TLS_LDO_32', 33 => 'TLS_IE_32',
			34 => 'TLS_LE_32', 35 => 'TLS_DTPMOD32',
			36 => 'TLS_DTPOFF32', 37 => 'TLS_TPOFF32' },
		'ARM' => { 0 => 'NONE', 1 => 'PC24', 2 => 'ABS32', 3 => 'REL32',
			4 => 'PC13', 5 => 'ABS16', 6 => 'ABS12',
			7 => 'THM_ABS5', 8 => 'ABS8', 9 => 'SBREL32',
			10 => 'THM_PC22', 11 => 'THM_PC8', 12 => 'AMP_VCALL9',
			13 => 'SWI24', 14 => 'THM_SWI8', 15 => 'XPC25',
			16 => 'THM_XPC22', 20 => 'COPY', 21 => 'GLOB_DAT',
			22 => 'JUMP_SLOT', 23 => 'RELATIVE', 24 => 'GOTOFF',
			25 => 'GOTPC', 26 => 'GOT32', 27 => 'PLT32',
			100 => 'GNU_VTENTRY', 101 => 'GNU_VTINHERIT',
			250 => 'RSBREL32', 251 => 'THM_RPC22', 252 => 'RREL32',
			253 => 'RABS32', 254 => 'RPC24', 255 => 'RBASE' },
		'IA_64' => { 0 => 'NONE',
			0x21 => 'IMM14', 0x22 => 'IMM22', 0x23 => 'IMM64',
			0x24 => 'DIR32MSB', 0x25 => 'DIR32LSB',
			0x26 => 'DIR64MSB', 0x27 => 'DIR64LSB',
			0x2a => 'GPREL22', 0x2b => 'GPREL64I',
			0x2c => 'GPREL32MSB', 0x2d => 'GPREL32LSB',
			0x2e => 'GPREL64MSB', 0x2f => 'GPREL64LSB',
			0x32 => 'LTOFF22', 0x33 => 'LTOFF64I',
			0x3a => 'PLTOFF22', 0x3b => 'PLTOFF64I',
			0x3e => 'PLTOFF64MSB', 0x3f => 'PLTOFF64LSB',
			0x43 => 'FPTR64I', 0x44 => 'FPTR32MSB',
			0x45 => 'FPTR32LSB', 0x46 => 'FPTR64MSB',
			0x47 => 'FPTR64LSB',
			0x48 => 'PCREL60B', 0x49 => 'PCREL21B',
			0x4a => 'PCREL21M', 0x4b => 'PCREL21F',
			0x4c => 'PCREL32MSB', 0x4d => 'PCREL32LSB',
			0x4e => 'PCREL64MSB', 0x4f => 'PCREL64LSB',
			0x52 => 'LTOFF_FPTR22', 0x53 => 'LTOFF_FPTR64I',
			0x54 => 'LTOFF_FPTR32MSB', 0x55 => 'LTOFF_FPTR32LSB',
			0x56 => 'LTOFF_FPTR64MSB', 0x57 => 'LTOFF_FPTR64LSB',
			0x5c => 'SEGREL32MSB', 0x5d => 'SEGREL32LSB',
			0x5e => 'SEGREL64MSB', 0x5f => 'SEGREL64LSB',
			0x64 => 'SECREL32MSB', 0x65 => 'SECREL32LSB',
			0x66 => 'SECREL64MSB', 0x67 => 'SECREL64LSB',
			0x6c => 'REL32MSB', 0x6d => 'REL32LSB',
			0x6e => 'REL64MSB', 0x6f => 'REL64LSB',
			0x74 => 'LTV32MSB', 0x75 => 'LTV32LSB',
			0x76 => 'LTV64MSB', 0x77 => 'LTV64LSB',
			0x79 => 'PCREL21BI', 0x7a => 'PCREL22',
			0x7b => 'PCREL64I', 0x80 => 'IPLTMSB',
			0x81 => 'IPLTLSB', 0x85 => 'SUB',
			0x86 => 'LTOFF22X', 0x87 => 'LDXMOV',
			0x91 => 'TPREL14', 0x92 => 'TPREL22',
			0x93 => 'TPREL64I', 0x96 => 'TPREL64MSB',
			0x97 => 'TPREL64LSB', 0x9a => 'LTOFF_TPREL22',
			0xa6 => 'DTPMOD64MSB', 0xa7 => 'DTPMOD64LSB',
			0xaa => 'LTOFF_DTPMOD22', 0xb1 => 'DTPREL14',
			0xb2 => 'DTPREL22', 0xb3 => 'DTPREL64I',
			0xb4 => 'DTPREL32MSB', 0xb5 => 'DTPREL32LSB',
			0xb6 => 'DTPREL64MSB', 0xb7 => 'DTPREL64LSB',
			0xba => 'LTOFF_DTPREL22' },
		'M32' => { 0 => 'NONE', 1 => '32', 2 => '32_S', 3 => 'PC32_S',
			4 => 'GOT32_S', 5 => 'PLT32_S', 6 => 'COPY',
			7 => 'GLOB_DAT', 8 => 'JMP_SLOT', 9 => 'RELATIVE',
			10 => 'RELATIVE_S' },
		'MIPS' => {
			0 => 'NONE', 1 => '16', 2 => '32', 3 => 'REL32', 
			4 => '26', 5 => 'HI16', 6 => 'LO16', 7 => 'GPREL16', 
			8 => 'LITERAL', 9 => 'GOT16', 10 => 'PC16',
			11 => 'CALL16', 12 => 'GPREL32',
			16 => 'SHIFT5', 17 => 'SHIFT6', 18 => '64',
			19 => 'GOT_DISP', 20 => 'GOT_PAGE', 21 => 'GOT_OFST',
			22 => 'GOT_HI16', 23 => 'GOT_LO16', 24 => 'SUB',
			25 => 'INSERT_A', 26 => 'INSERT_B', 27 => 'DELETE',
			28 => 'HIGHER', 29 => 'HIGHEST', 30 => 'CALL_HI16',
			31 => 'CALL_LO16', 32 => 'SCN_DISP', 33 => 'REL16',
			34 => 'ADD_IMMEDIATE', 35 => 'PJUMP', 36 => 'RELGOT',
			37 => 'JALR', 38 => 'TLS_DTPMOD32', 39 => 'TLS_DTPREL32',
			40 => 'TLS_DTPMOD64', 41 => 'TLS_DTPREL64',
			42 => 'TLS_GD', 43 => 'TLS_LDM', 44 => 'TLS_DTPREL_HI16',
			45 => 'TLS_DTPREL_LO16', 46 => 'TLS_GOTTPREL',
			47 => 'TLS_TPREL32', 48 => 'TLS_TPREL64',
			49 => 'TLS_TPREL_HI16', 50 => 'TLS_TPREL_LO16',
			51 => 'GLOB_DAT', 52 => 'NUM' },
		'PPC' => { 0 => 'NONE',
			1 => 'ADDR32', 2 => 'ADDR24', 3 => 'ADDR16',
			4 => 'ADDR16_LO', 5 => 'ADDR16_HI', 6 => 'ADDR16_HA',
			7 => 'ADDR14', 8 => 'ADDR14_BRTAKEN', 9 => 'ADDR14_BRNTAKEN',
			10 => 'REL24', 11 => 'REL14',
			12 => 'REL14_BRTAKEN', 13 => 'REL14_BRNTAKEN',
			14 => 'GOT16', 15 => 'GOT16_LO',
			16 => 'GOT16_HI', 17 => 'GOT16_HA',
			18 => 'PLTREL24', 19 => 'COPY',
			20 => 'GLOB_DAT', 21 => 'JMP_SLOT',
			22 => 'RELATIVE', 23 => 'LOCAL24PC',
			24 => 'UADDR32', 25 => 'UADDR16',
			26 => 'REL32', 27 => 'PLT32',
			28 => 'PLTREL32', 29 => 'PLT16_LO',
			30 => 'PLT16_HI', 31 => 'PLT16_HA',
			32 => 'SDAREL16', 33 => 'SECTOFF',
			34 => 'SECTOFF_LO', 35 => 'SECTOFF_HI',
			36 => 'SECTOFF_HA', 67 => 'TLS',
			68 => 'DTPMOD32', 69 => 'TPREL16',
			70 => 'TPREL16_LO', 71 => 'TPREL16_HI',
			72 => 'TPREL16_HA', 73 => 'TPREL32',
			74 => 'DTPREL16', 75 => 'DTPREL16_LO',
			76 => 'DTPREL16_HI', 77 => 'DTPREL16_HA',
			78 => 'DTPREL32', 79 => 'GOT_TLSGD16',
			80 => 'GOT_TLSGD16_LO', 81 => 'GOT_TLSGD16_HI',
			82 => 'GOT_TLSGD16_HA', 83 => 'GOT_TLSLD16',
			84 => 'GOT_TLSLD16_LO', 85 => 'GOT_TLSLD16_HI',
			86 => 'GOT_TLSLD16_HA', 87 => 'GOT_TPREL16',
			88 => 'GOT_TPREL16_LO', 89 => 'GOT_TPREL16_HI',
			90 => 'GOT_TPREL16_HA', 101 => 'EMB_NADDR32',
			102 => 'EMB_NADDR16', 103 => 'EMB_NADDR16_LO',
			104 => 'EMB_NADDR16_HI', 105 => 'EMB_NADDR16_HA',
			106 => 'EMB_SDAI16', 107 => 'EMB_SDA2I16',
			108 => 'EMB_SDA2REL', 109 => 'EMB_SDA21',
			110 => 'EMB_MRKREF', 111 => 'EMB_RELSEC16',
			112 => 'EMB_RELST_LO', 113 => 'EMB_RELST_HI',
			114 => 'EMB_RELST_HA', 115 => 'EMB_BIT_FLD',
			116 => 'EMB_RELSDA' },
		'SPARC' => { 0 => 'NONE', 1 => '8', 2 => '16', 3 => '32',
			4 => 'DISP8', 5 => 'DISP16', 6 => 'DISP32',
			7 => 'WDISP30', 8 => 'WDISP22', 9 => 'HI22',
			10 => '22', 11 => '13', 12 => 'LO10', 13 => 'GOT10',
			14 => 'GOT13', 15 => 'GOT22', 16 => 'PC10',
			17 => 'PC22', 18 => 'WPLT30', 19 => 'COPY',
			20 => 'GLOB_DAT', 21 => 'JMP_SLOT', 22 => 'RELATIVE',
			23 => 'UA32', 24 => 'PLT32', 25 => 'HIPLT22',
			26 => 'LOPLT10', 27 => 'PCPLT32', 28 => 'PCPLT22',
			29 => 'PCPLT10', 30 => '10', 31 => '11', 32 => '64',
			33 => 'OLO10', 34 => 'HH22', 35 => 'HM10', 36 => 'LM22',
			37 => 'PC_HH22', 38 => 'PC_HM10', 39 => 'PC_LM22',
			40 => 'WDISP16', 41 => 'WDISP19', 42 => 'GLOB_JMP',
			43 => '7', 44 => '5', 45 => '6', 46 => 'DISP64',
			47 => 'PLT64', 48 => 'HIX22', 49 => 'LOX10', 50 => 'H44',
			51 => 'M44', 52 => 'L44', 53 => 'REGISTER', 54 => 'UA64',
			55 => 'UA16', 56 => 'TLS_GD_HI22', 57 => 'TLS_GD_LO10',
			58 => 'TLS_GD_ADD', 59 => 'TLS_GD_CALL',
			60 => 'TLS_LDM_HI22', 61 => 'TLS_LDM_LO10',
			62 => 'TLS_LDM_ADD', 63 => 'TLS_LDM_CALL',
			64 => 'TLS_LDO_HIX22', 65 => 'TLS_LDO_LOX10',
			66 => 'TLS_LDO_ADD', 67 => 'TLS_IE_HI22',
			68 => 'TLS_IE_LO10', 69 => 'TLS_IE_LD',
			70 => 'TLS_IE_LDX', 71 => 'TLS_IE_ADD',
			72 => 'TLS_LE_HIX22', 73 => 'TLS_LE_LOX10',
			74 => 'TLS_DTPMOD32', 75 => 'TLS_DTPMOD64',
			76 => 'TLS_DTPOFF32', 77 => 'TLS_DTPOFF64',
			78 => 'TLS_TPOFF32', 79 => 'TLS_TPOFF64' },
		'X86_64' => { 0 => 'NONE',
			1 => '64', 2 => 'PC32', 3 => 'GOT32', 4 => 'PLT32',
			5 => 'COPY', 6 => 'GLOB_DAT', 7 => 'JMP_SLOT',
			8 => 'RELATIVE', 9 => 'GOTPCREL', 10 => '32',
			11 => '32S', 12 => '16', 13 => 'PC16', 14 => '8',
			15 => 'PC8', 16 => 'DTPMOD64', 17 => 'DTPOFF64',
			18 => 'TPOFF64', 19 => 'TLSGD', 20 => 'TLSLD',
			21 => 'DTPOFF32', 22 => 'GOTTPOFF', 23 => 'TPOFF32' }
	)

	class Header
		attr_accessor :type, :machine, :version, :entry, :phoff, :shoff, :flags, :ehsize, :phentsize, :phnum, :shentsize, :shnum, :shstrndx
		attr_accessor :magic, :e_class, :data, :i_version, :abi, :abi_version, :ident

		def self.size elf
			x = elf.bitsize >> 3
			40 + 3*x
		end
	end
	class Segment
		attr_accessor :type, :offset, :vaddr, :paddr, :filesz, :memsz, :flags, :align
		attr_accessor :encoded

		def self.size elf
			x = elf.bitsize >> 3
			8 + 6*x
		end
	end
	class Section
		attr_accessor :name_p, :name, :type, :flags, :addr, :offset, :size, :link, :info, :addralign, :entsize
		attr_accessor :encoded

		def self.size elf
			x = elf.bitsize >> 3
			16 + 6*x
		end
	end
	class Symbol
		attr_accessor :name_p, :name, :size, :bind, :value, :type, :other, :shndx
		attr_accessor :thunk

		def self.size elf
			x = elf.bitsize >> 3
			12 + x
		end
		def set_info(elf, info)
			@bind = elf.int_to_hash((info >> 4) & 15, SYMBOL_BIND)
			@type = elf.int_to_hash(info & 15, SYMBOL_TYPE)
		end
		def get_info(elf)
			((elf.int_from_hash(@bind, SYMBOL_BIND) & 15) << 4) |
			(elf.int_from_hash(@type, SYMBOL_TYPE) & 15)
		end
	end
	class Relocation
		attr_accessor :offset, :type, :symbol, :addend
		def self.size elf
			x = elf.bitsize >> 3
			2*x
		end
		def self.size_a elf
			x = elf.bitsize >> 3
			3*x
		end
		def set_info(elf, info, symtab)
			v = (elf.bitsize == 32 ? 8 : 32)
			@type = elf.int_to_hash((info & ((1 << v) - 1)), RELOCATION_TYPE[elf.header.machine])
			@symbol = (info >> v) & 0xffff_ffff
			@symbol = symtab[@symbol] if symtab[@symbol]
		end
		def get_info(elf, symtab)
			v = (elf.bitsize == 32 ? 8 : 32)
			s = symbol || 0
			s = symtab.index(s) if s.kind_of? Symbol
			(s << v) |
			(elf.int_from_hash(@type, RELOCATION_TYPE[elf.header.machine]) & ((1 << v)-1))
		end
	end

	def self.hash_symbol_name(name)
		name.unpack('C*').inject(0) { |hash, char|
			break hash if char == 0
			hash <<= 4
			hash += char
			hash ^= (hash >> 24) & 0xf0
			hash &= 0x0fff_ffff
		}
	end

	def self.gnu_hash_symbol_name(name)
		name.unpack('C*').inject(5381) { |hash, char|
			break hash if char == 0
			hash *= 33
			hash += char
			hash &= 0xffff_ffff
		}
	end

	attr_accessor :header, :segments, :sections, :tag, :symbols, :relocations, :endianness, :bitsize
	def initialize(cpu=nil)
		@header = Header.new
		@tag = {}
		@symbols = [Symbol.new]
		 @symbols.first.shndx = 'UNDEF'
		@relocations = []
		@sections = [Section.new]
		 @sections.first.type = 'NULL'
		@segments = []
		if cpu
			@endianness = cpu.endianness
			@bitsize = cpu.size
			case cpu
			when Ia32; @header.machine = '386'
			end
		else
			@endianness = :little
			@bitsize = 32
		end
		super
	end
end
end

# TODO symbol version info
__END__
/*
 * Version structures.  There are three types of version structure:
 *
 *  o	A definition of the versions within the image itself.
 *	Each version definition is assigned a unique index (starting from
 *	VER_NDX_BGNDEF)	which is used to cross-reference symbols associated to
 *	the version.  Each version can have one or more dependencies on other
 *	version definitions within the image.  The version name, and any
 *	dependency names, are specified in the version definition auxiliary
 *	array.  Version definition entries require a version symbol index table.
 *
 *  o	A version requirement on a needed dependency.  Each needed entry
 *	specifies the shared object dependency (as specified in DT_NEEDED).
 *	One or more versions required from this dependency are specified in the
 *	version needed auxiliary array.
 *
 *  o	A version symbol index table.  Each symbol indexes into this array
 *	to determine its version index.  Index values of VER_NDX_BGNDEF or
 *	greater indicate the version definition to which a symbol is associated.
 *	(the size of a symbol index entry is recorded in the sh_info field).
 */
#ifndef	_ASM

typedef struct {			/* Version Definition Structure. */
	Elf32_Half	vd_version;	/* this structures version revision */
	Elf32_Half	vd_flags;	/* version information */
	Elf32_Half	vd_ndx;		/* version index */
	Elf32_Half	vd_cnt;		/* no. of associated aux entries */
	Elf32_Word	vd_hash;	/* version name hash value */
	Elf32_Word	vd_aux;		/* no. of bytes from start of this */
					/*	verdef to verdaux array */
	Elf32_Word	vd_next;	/* no. of bytes from start of this */
} Elf32_Verdef;				/*	verdef to next verdef entry */

typedef struct {			/* Verdef Auxiliary Structure. */
	Elf32_Word	vda_name;	/* first element defines the version */
					/*	name. Additional entries */
					/*	define dependency names. */
	Elf32_Word	vda_next;	/* no. of bytes from start of this */
} Elf32_Verdaux;			/*	verdaux to next verdaux entry */


typedef	struct {			/* Version Requirement Structure. */
	Elf32_Half	vn_version;	/* this structures version revision */
	Elf32_Half	vn_cnt;		/* no. of associated aux entries */
	Elf32_Word	vn_file;	/* name of needed dependency (file) */
	Elf32_Word	vn_aux;		/* no. of bytes from start of this */
					/*	verneed to vernaux array */
	Elf32_Word	vn_next;	/* no. of bytes from start of this */
} Elf32_Verneed;			/*	verneed to next verneed entry */

typedef struct {			/* Verneed Auxiliary Structure. */
	Elf32_Word	vna_hash;	/* version name hash value */
	Elf32_Half	vna_flags;	/* version information */
	Elf32_Half	vna_other;
	Elf32_Word	vna_name;	/* version name */
	Elf32_Word	vna_next;	/* no. of bytes from start of this */
} Elf32_Vernaux;			/*	vernaux to next vernaux entry */

typedef	Elf32_Half 	Elf32_Versym;	/* Version symbol index array */

typedef struct {
	Elf32_Half	si_boundto;	/* direct bindings - symbol bound to */
	Elf32_Half	si_flags;	/* per symbol flags */
} Elf32_Syminfo;


#if (defined(_LP64) || ((__STDC__ - 0 == 0) && (!defined(_NO_LONGLONG))))
typedef struct {
	Elf64_Half	vd_version;	/* this structures version revision */
	Elf64_Half	vd_flags;	/* version information */
	Elf64_Half	vd_ndx;		/* version index */
	Elf64_Half	vd_cnt;		/* no. of associated aux entries */
	Elf64_Word	vd_hash;	/* version name hash value */
	Elf64_Word	vd_aux;		/* no. of bytes from start of this */
					/*	verdef to verdaux array */
	Elf64_Word	vd_next;	/* no. of bytes from start of this */
} Elf64_Verdef;				/*	verdef to next verdef entry */

typedef struct {
	Elf64_Word	vda_name;	/* first element defines the version */
					/*	name. Additional entries */
					/*	define dependency names. */
	Elf64_Word	vda_next;	/* no. of bytes from start of this */
} Elf64_Verdaux;			/*	verdaux to next verdaux entry */

typedef struct {
	Elf64_Half	vn_version;	/* this structures version revision */
	Elf64_Half	vn_cnt;		/* no. of associated aux entries */
	Elf64_Word	vn_file;	/* name of needed dependency (file) */
	Elf64_Word	vn_aux;		/* no. of bytes from start of this */
					/*	verneed to vernaux array */
	Elf64_Word	vn_next;	/* no. of bytes from start of this */
} Elf64_Verneed;			/*	verneed to next verneed entry */

typedef struct {
	Elf64_Word	vna_hash;	/* version name hash value */
	Elf64_Half	vna_flags;	/* version information */
	Elf64_Half	vna_other;
	Elf64_Word	vna_name;	/* version name */
	Elf64_Word	vna_next;	/* no. of bytes from start of this */
} Elf64_Vernaux;			/*	vernaux to next vernaux entry */

typedef	Elf64_Half	Elf64_Versym;

typedef struct {
	Elf64_Half	si_boundto;	/* direct bindings - symbol bound to */
	Elf64_Half	si_flags;	/* per symbol flags */
} Elf64_Syminfo;
#endif	/* (defined(_LP64) || ((__STDC__ - 0 == 0) ... */

#endif

/*
 * Versym symbol index values.  Values greater than VER_NDX_GLOBAL
 * and less then VER_NDX_LORESERVE associate symbols with user
 * specified version descriptors.
 */
#define	VER_NDX_LOCAL		0	/* symbol is local */
#define	VER_NDX_GLOBAL		1	/* symbol is global and assigned to */
					/*	the base version */
#define	VER_NDX_LORESERVE	0xff00	/* beginning of RESERVED entries */
#define	VER_NDX_ELIMINATE	0xff01	/* symbol is to be eliminated */

/*
 * Verdef and Verneed (via Veraux) flags values.
 */
#define	VER_FLG_BASE		0x1	/* version definition of file itself */
#define	VER_FLG_WEAK		0x2	/* weak version identifier */

/*
 * Verdef version values.
 */
#define	VER_DEF_NONE		0	/* Ver_def version */
#define	VER_DEF_CURRENT		1
#define	VER_DEF_NUM		2

/*
 * Verneed version values.
 */
#define	VER_NEED_NONE		0	/* Ver_need version */
#define	VER_NEED_CURRENT	1
#define	VER_NEED_NUM		2


/*
 * Syminfo flag values
 */
#define	SYMINFO_FLG_DIRECT	0x0001	/* direct bound symbol */
#define	SYMINFO_FLG_PASSTHRU	0x0002	/* pass-thru symbol for translator */
#define	SYMINFO_FLG_COPY	0x0004	/* symbol is a copy-reloc */
#define	SYMINFO_FLG_LAZYLOAD	0x0008	/* symbol bound to object to be lazy */
					/*	loaded */

/*
 * key values for Syminfo.si_boundto
 */
#define	SYMINFO_BT_SELF		0xffff	/* symbol bound to self */
#define	SYMINFO_BT_PARENT	0xfffe	/* symbol bound to parent */
#define	SYMINFO_BT_LOWRESERVE	0xff00	/* beginning of reserved entries */

/*
 * Syminfo version values.
 */
#define	SYMINFO_NONE		0	/* Syminfo version */
#define	SYMINFO_CURRENT		1
#define	SYMINFO_NUM		2

 P