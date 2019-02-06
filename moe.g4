/* Copyright (C) 2019 Evan Christensen
|
| Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
| documentation files (the "Software"), to deal in the Software without restriction, including without limitation the 
| rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit 
| persons to whom the Software is furnished to do so, subject to the following conditions:
| 
| The above copyright notice and this permission notice shall be included in all copies or substantial portions of the 
| Software.
| 
| THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE 
| WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
| COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
| OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Moe grammar file for Antlr 4


grammar Moe;

// parser rules

file
 : entry* EOF ;

entry 
 : import_directive 
 | statement
 ;

import_directive
 : IMPORT STRING_LIT
 | FOREIGN_LIBRARY STRING_LIT
 | STATIC_LIBRARY STRING_LIT
 | DYNAMIC_LIBRARY STRING_LIT
 ;

 def_test : IDENT PROC '(' parameter_list ')' ('->' typespec)? compound_statement?;
// : IDENT PROC		'(' parameter_list ')' ('->' typespec)? (procedure_flags)* (compound_statement)* ;

/*
statement
 : def_test | ';' ;
 */
statement
 : decl
 | definition
 | expression_statement
 | label_statement
 | selection_statement
 | iteration_statement
 | jump_statement
 ;

decl
 : parameter
 ;
 
parameter
 : '..'
 | using_statement
 | parameter_ident_list (IMMUTABLE)? ':' typespec ('=' default_expression)?
 | (IMMUTABLE)? ':' typespec ('=' default_expression)?
 | parameter_ident_list (IMMUTABLE)? ':=' expression 
 ;

procedure_reference_decl
 : '(' parameter_list ')' ('->' typespec)? (procedure_flags)*
 ;

generic_decl
 : '$' IDENT
 ;

array_decl
 : '[' '..' ']'
 | '[' expression ']'
 | '[' ']'
 ;

typespec
 : IDENT '(' argument_list ')'
 | IDENT ('.' IDENT)*
 | procedure_reference_decl
 | generic_decl 
 | '&' typespec
 | CONST typespec
 | INARG typespec
 | array_decl typespec
 ;

overload_operator 
 : '!'| '+'| '-'| '|'| '^'| '*'| '/'| '%'| '&'| '<<'| '>>'| '>'| '<'| '<='| '>='| '=='| '!='| '+='| '-='| '*='| '/='| '='| ':='| '++'| '--'| '@'| '~'| '!'
 ;

overload_name
 : OPERATOR overload_operator 
 ;

procedure_flags
 : FOREIGN
 | CDECL
 | STDCALL
 | INLINE
 | NO_INLINE
 | COMMUTATIVE
 ;

enum_constant
 : IDENT ':=' expression
 ;

enum_constant_list 
 : enum_constant (',' enum_constant)*
 ;

using_statement
 : USING IDENT ':' typespec
 | USING typespec
 ;

parameter_ident
 : ('$')? IDENT 		// matches against nothing?
 ;

parameter_ident_list
 : parameter_ident (',' parameter_ident)*
 ;

default_expression
 : '---'
 | expression
 ;


parameter_list
 : parameter
 | parameter ',' parameter
 ;

struct_member_list // TODO - change the proc name in parser.cpp
 : decl
 | definition
 ;

definition
 : IDENT PROC		'(' parameter_list ')' ('->' typespec)? (procedure_flags)* (compound_statement)*
 | overload_name 	'(' parameter_list ')' ('->' typespec)? (procedure_flags)* (compound_statement)*
 | IDENT STRUCT '(' parameter_list ')' '{' struct_member_list '}'
 | IDENT STRUCT '{' struct_member_list '}'
 | IDENT ENUM (typespec)? '{' enum_constant_list '}'				// should have ':' typespec for consistency, also... the parse is a bit sketchy, assuming '{' won't parse as a typespec
 | IDENT FLAG_ENUM (typespec)? '{' enum_constant_list '}'			// should have ':' typespec for consistency, also... the parse is a bit sketchy, assuming '{' won't parse as a typespec
 | IDENT TYPEDEF typespec
 ;

argument 
 : '`' IDENT logicalOr_exp   // error? can we toss extra labels in here??
 | logicalOr_exp 
 ;

argument_list
 : argument (',' argument)*
 ;

primary_exp
 : IDENT
 | TRUE_TOKEN
 | FALSE_TOKEN
 | LINE_DIRECTIVE
 | FILE_DIRECTIVE
 | NULL_TOKEN
 | INTEGER_LIT
 | ':' typespec '{' expression_list '}'
 | '{' expression_list '}'
 | FLOAT_LIT
 | STRING_LIT
 | CHAR_LIT
 | '(' expression ')'
 ;

postfix_exp
 : primary_exp '[' expression ']' 
 | primary_exp '(' argument_list ')'
 | primary_exp '(' ')'
 | primary_exp '.'
 | primary_exp '++'
 | primary_exp '--'
 | primary_exp
 ;

unary_exp
 : SIZEOF '(' unary_exp ')'
 | ALIGNOF '(' unary_exp ')'
 | TYPEINFO '(' unary_exp ')'
 | '@' unary_exp
 | '&' unary_exp
 | '+' unary_exp
 | '-' unary_exp
 | '~' unary_exp
 | '!' unary_exp
 | '++' unary_exp
 | '--' unary_exp
 | postfix_exp
 ;

cast_exp
 : CAST '(' typespec ')' cast_exp
 | ACAST cast_exp
 | unary_exp
 ;

 shift_token : '<<' | '>>' ;
shift_exp
 : cast_exp (shift_token cast_exp)? ;

multiplicative_token : '*' | '/' | '%' | '&';
multiplicative_exp
 : shift_exp (multiplicative_token shift_exp)? ;

additive_token : '+' | '-' | '|' | '^' ;
additive_exp
 : multiplicative_exp (additive_token multiplicative_exp)? ;

 relational_token: '<' | '>' | '<=' | '>=' | '==' | '!=' ;
relational_exp
 : additive_exp (relational_token additive_exp)? ;

logicalAnd_exp
 : relational_exp ('&&' relational_exp)?
 ;

logicalOr_exp
 : logicalAnd_exp ('||' logicalOr_exp)?
 ;

assignment_token: '=' | '*=' | '/=' | '%=' | '+=' | '-=' | '&=' | '|=' | '^=' ; 
assignment_exp
 : logicalOr_exp (assignment_token logicalOr_exp)? ;

expression 
 : '`' IDENT assignment_exp			// if FEXP_AllowLiteralMemberLabel
 | assignment_exp
 ;

expression_statement
 : ';'								// empty statement
 | expression
 ;

expression_list
 : expression (',' expression)*
 ;

label_statement
 : '`' IDENT
 ;

if_statement
 : IF expression compound_statement (ELSE if_statement? )?
 ;

case_label
 : expression
 | expression ',' case_label
 ;

case_statement 
 : CASE case_label ':' statement
 | ELSE ':' statement
 ;

switch_statement
 : SWITCH expression '{' case_statement+ '}'
 ;

selection_statement
 : if_statement
 | switch_statement 
 ;

compound_statement
  : '{' statement* '}'
  ;

iteration_statement
 : FOR parameter ';' expression ';' expression compound_statement
 | FOR expression ';' expression ';' expression compound_statement
 | FOR_EACH parameter compound_statement
 | FOR_EACH cast_exp '=' expression compound_statement
 | WHILE expression compound_statement
 ;

jump_statement
 : CONTINUE IDENT?
 | BREAK IDENT?
 | FALLTHROUGH IDENT?
 | RETURN expression?
 ;

//LEXER RULES


//IDENT: [\p{Alpha}\p{General_Category=Other_Letter}] [\p{Alpha}\p{General_Category=Other_Letter}_0-9]* ;
//IDENT: [\p{Alpha}\p{General_Category=Other_Letter}] [\p{Alpha}\p{General_Category=Other_Letter}_0-9]* ;

SWITCH: 'switch' ;
CASE: 'case' ;
IF: 'if' ;
ELSE: 'else' ;
FOR: 'for' ;
FOR_EACH: 'for_each' ;
WHILE: 'while' ;
CONTINUE: 'continue' ;
BREAK: 'break' ;
FALLTHROUGH: 'fallthrough' ;
RETURN: 'return' ;
IMPORT: 'import' ;
FOREIGN_LIBRARY: 'foreign_library' ;
STATIC_LIBRARY: 'static_library' ;
DYNAMIC_LIBRARY: 'dynamic_library' ;
CAST: 'cast' ;
ACAST: 'acast' ;
SIZEOF: 'sizeof' ;
ALIGNOF: 'alignof' ;
TYPEINFO: 'typeinfo' ;
IMMUTABLE: 'immutable' ;
PROC: 'proc' ;
STRUCT: 'struct' ;
ENUM: 'enum' ;
FLAG_ENUM: 'flag_enum' ;
TYPEDEF: 'typedef' ;
USING: 'using' ;
CONST: 'const' ;
INARG: 'inarg' ;
OPERATOR: 'operator' ;
FOREIGN: '#foreign' ;
CDECL: '#cdecl' ;
STDCALL: '#stdcall' ;
INLINE: 'inline' ;
NO_INLINE: 'no_inline' ;
COMMUTATIVE: '#commutative' ;
NULL_TOKEN: 'null' ;
TRUE_TOKEN: 'true' ;
FALSE_TOKEN: 'false' ;
FILE_DIRECTIVE: '#file' ;
LINE_DIRECTIVE: '#line' ;

IDENT : [A-Za-z_][A-Za-z_0-9]* ;
STRING_LIT: '"' .*? '"' ;
CHAR_LIT: '\'' .*? '\'' ;
INTEGER_LIT: [0-9]+ ;
FLOAT_LIT: [0-9]+ .[0-9] ;
NL: [\r\n] -> channel(HIDDEN) ;
WS: [ \t]+ -> skip ; // skip spaces, tabs, newlines
BLOCK_COMMENT: '/*' .*? '*/' -> skip ;
LINE_COMMENT: '//' ~[\r\n]* -> skip ;
