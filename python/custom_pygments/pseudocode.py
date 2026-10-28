"""
    pygments.lexers.pseudocode
    ~~~~~~~~~~~~~~~~~~~~~~~~~~

    Lexer for academic-style pseudocode algorithm descriptions.
    Highlights keywords, assignments, comments, functions, and literals.
"""

from pygments.lexer import RegexLexer, bygroups, words
from pygments.token import (
    Keyword, Name, Comment, String, Number, Operator,
    Punctuation, Text, Whitespace
)

__all__ = ['PseudocodeLexer']


class PseudocodeLexer(RegexLexer):
    """
    Lexer for pseudocode/algorithm descriptions commonly used in
    academic papers and technical presentations.
    """
    name = 'Pseudocode'
    aliases = ['pseudo', 'pseudocode', 'algorithm']
    filenames = ['*.pseudo', '*.algo']

    tokens = {
        'root': [
            # Comments (// style and # style)
            (r'//.*$', Comment.Single),
            (r'#.*$', Comment.Single),

            # Multi-line comments /* */
            (r'/\*', Comment.Multiline, 'comment'),

            # Control flow keywords
            (words((
                'If', 'if', 'IF',
                'Then', 'then', 'THEN',
                'Else', 'else', 'ELSE',
                'ElseIf', 'Elseif', 'elseif', 'elif', 'ELSEIF',
                'EndIf', 'Endif', 'endif', 'ENDIF', 'End If', 'end if',
                'For', 'for', 'FOR',
                'ForEach', 'Foreach', 'foreach', 'FOREACH', 'For each', 'for each',
                'While', 'while', 'WHILE',
                'Do', 'do', 'DO',
                'Until', 'until', 'UNTIL',
                'Loop', 'loop', 'LOOP',
                'EndFor', 'Endfor', 'endfor', 'ENDFOR', 'End For', 'end for',
                'EndWhile', 'Endwhile', 'endwhile', 'ENDWHILE',
                'EndLoop', 'Endloop', 'endloop', 'ENDLOOP',
                'Break', 'break', 'BREAK',
                'Continue', 'continue', 'CONTINUE',
                'Return', 'return', 'RETURN',
                'End', 'end', 'END',
            ), prefix=r'\b', suffix=r'\b'), Keyword),

            # Boolean/logic keywords
            (words((
                'AND', 'And', 'and',
                'OR', 'Or', 'or',
                'NOT', 'Not', 'not',
                'TRUE', 'True', 'true',
                'FALSE', 'False', 'false',
                'NULL', 'Null', 'null', 'nil', 'None',
            ), prefix=r'\b', suffix=r'\b'), Keyword.Constant),

            # Function/procedure keywords
            (words((
                'Function', 'function', 'FUNCTION',
                'Procedure', 'procedure', 'PROCEDURE',
                'Algorithm', 'algorithm', 'ALGORITHM',
                'Input', 'input', 'INPUT',
                'Output', 'output', 'OUTPUT',
                'Begin', 'begin', 'BEGIN',
                'Call', 'call', 'CALL',
            ), prefix=r'\b', suffix=r'\b'), Keyword.Declaration),

            # Assignment operators (<-, :=, =, ←)
            (r'<-|←|:=', Operator),

            # Comparison and arithmetic operators
            (r'==|!=|<=|>=|<|>|\+|-|\*|/|%|\^', Operator),

            # Arrow for results/implications
            (r'->', Operator),

            # Logical operators as symbols
            (r'&&|\|\||!', Operator),

            # Numbers (integers and floats, including hex)
            (r'0x[0-9A-Fa-f]+', Number.Hex),
            (r'\b\d+\.\d+\b', Number.Float),
            (r'\b\d+\b', Number.Integer),

            # Strings
            (r'"[^"]*"', String.Double),
            (r"'[^']*'", String.Single),

            # Function calls: word followed by (
            (r'(\w+)(\s*)(\()', bygroups(Name.Function, Whitespace, Punctuation)),

            # Array access: word followed by [
            (r'(\w+)(\s*)(\[)', bygroups(Name.Variable, Whitespace, Punctuation)),

            # Punctuation
            (r'[(){}\[\]:;,.]', Punctuation),

            # Identifiers (variables, etc.)
            (r'[A-Za-z_][A-Za-z0-9_]*', Name.Variable),

            # Whitespace
            (r'\s+', Whitespace),

            # Catch-all for other text
            (r'.', Text),
        ],
        'comment': [
            (r'\*/', Comment.Multiline, '#pop'),
            (r'[^*]+', Comment.Multiline),
            (r'\*', Comment.Multiline),
        ],
    }
