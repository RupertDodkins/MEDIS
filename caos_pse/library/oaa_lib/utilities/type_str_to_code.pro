function type_str_to_code, str
	case strlowcase(str) of
		"undefined" : return,0
		"byte"      : return,1
		"int"       : return,2
		"long"      : return,3
		"float"     : return,4
		"double"    : return,5
		"complex"   : return,6
		"string"    : return,7
		"structure" : return,8
		"dcomplex"  : return,9
		"pointer"   : return,10
		"reference" : return,11
		"uint"      : return,12
		"ulong"     : return,13
		"long64"    : return,14
		"ulong64"   : return,15
		else        : return,-1
	endcase
end
