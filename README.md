Test parser for Moe written with Antlr4

command line:
```
antlr MoeLexer.g4 MoeParser.g4 -listener -visitor -o Moe -Dlanguage=Cpp 
```

Moe syntax changes to make things more regular:
 - add colon before optional loose type in enums
 - switch case shouldn't use colon to end the case, (wrap the symbol in parens?)
 		ie. case (22) return foo
 			case (21,23) break
 		it probably makes more sense to switch to curly bracing
 			case 22 	{ return foo }
 			case 21, 23 { break }





MoeFormat
- maximum line length enforcement
[ ] Allman brace style (ensure newline after declaration, brace then newline, then zero newlines before comment or code) 
[ ] 	except single line (ensure all cases match the single line requirement?)
[x] decl has space after the identifier, colon with no space before type
[ ] space after pointers or qualifiers inside decl
[ ] space after proc before '('
[ ] space before and after '->' arrow in return type
[x] space before and after operators 
[x] remove unneeded semicolons
[ ] replace four spaces with tabs
[ ] no space before array (after primary_exp)                   
[ ] tab alignment
[ ]	- enum constant values
[ ] - single line switch bodies 
	- 
[ ] Optional hungarian warnings
[ ]	- missing tags
[ ]	- pointer types need p? does this need a typechecker?
