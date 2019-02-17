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

lexer grammar MoeLexer;
channels { WHITESPACE, COMMENT }

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
INTEGER_LIT: [1-9][0-9]* ;
FLOAT_LIT: [0-9]+ '.'[0-9]+ ;
NL: [\r\n] -> channel(WHITESPACE) ;
WS: [ \t]+ -> channel(WHITESPACE) ; // skip spaces, tabs, newlines
BLOCK_COMMENT: '/*' .*? '*/' -> channel(COMMENT) ;
LINE_COMMENT: '//' ~[\r\n]* -> channel(COMMENT) ;
LABEL_TOK: '`' ;

EQUAL: '=' ;
DOT_DOT: '..' ;
ARROW: '->' ;
COMMA: ',' ;
PAREN_OPEN: '(' ;
PAREN_CLOSE: ')' ;
BRACKET_OPEN: '[' ;
BRACKET_CLOSE: ']' ;
CURLY_OPEN: '{' ;
CURLY_CLOSE: '}' ;
PERIOD: '.' ;
EXCLAIMATION: '!' ;
ADD: '+' ;
SUB: '-' ;
MUL: '*' ;
DIV: '/' ;
MOD: '%' ;
AND: '&' ;
OR: '|' ;
AND_AND: '&&' ;
OR_OR: '||' ;
XOR: '^' ;
SHIFT_LEFT: '<<' ;
SHIFT_RIGHT: '>>' ;
LESS: '<' ;
GREATER: '>' ;
LESS_EQUAL: '<=' ;
GREATER_EQUAL: '>=' ;
EQUAL_EQUAL: '==' ;
ADD_EQUAL: '+=' ;
MUL_EQUAL: '*=' ;
SUB_EQUAL: '-=' ;
DIV_EQUAL: '/=' ;
MOD_EQUAL: '%=' ;
AND_EQUAL: '&=' ;
OR_EQUAL: '|=' ;
XOR_EQUAL: '^=' ;
NOT_EQUAL: '!=' ;
COLON_EQUAL: ':=' ; 
ADD_ADD: '++' ;
SUB_SUB: '--' ;
TRIPLE_SUB: '---' ;
SEMICOLON: ';' ;
COLON: ':' ;
DEREF: '@' ;
GENERIC: '$' ;
TILDE: '~';
