"""
    pygments.styles.rosepinemoon
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    Rosé Pine Moon dark syntax style.
"""
from pygments.style import Style
from pygments.token import (Keyword, Name, Comment, String, Error, Token,
                            Number, Operator, Generic, Whitespace, Punctuation)

__all__ = ['RosePineMoonStyle']


class RosePineMoonStyle(Style):
    name = 'rosepinemoon'
    background_color = "#232136"   # Base
    highlight_color = "#56526e"    # HighlightHigh

    styles = {
        Token:                "#e0def4",          # Text
        Whitespace:           "",
        Error:                "#eb6f92",          # Love
        Comment:              "italic #6e6a86",   # Muted
        Comment.Preproc:      "#c4a7e7",          # Iris
        Keyword:              "#3e8fb0",          # Pine
        Keyword.Namespace:    "#c4a7e7",          # Iris
        Keyword.Type:         "#9ccfd6",          # Foam
        Operator:             "#908caa",          # Subtle
        Operator.Word:        "#3e8fb0",          # Pine
        Punctuation:          "#908caa",          # Subtle
        Name:                 "#e0def4",          # Text
        Name.Builtin:         "#9ccfd6",          # Foam
        Name.Builtin.Pseudo:  "#9ccfd6",          # Foam
        Name.Class:           "#ea9a97",          # Rose
        Name.Function:        "#ea9a97",          # Rose
        Name.Decorator:       "#c4a7e7",          # Iris
        Name.Exception:       "#eb6f92",          # Love
        Name.Constant:        "#c4a7e7",          # Iris
        Name.Attribute:       "#9ccfd6",          # Foam
        Name.Tag:             "#3e8fb0",          # Pine
        String:               "#f6c177",          # Gold
        String.Doc:           "italic #6e6a86",   # Muted
        String.Escape:        "#ea9a97",          # Rose
        Number:               "#c4a7e7",          # Iris
        Generic.Heading:      "bold #e0def4",
        Generic.Subheading:   "bold #c4a7e7",
        Generic.Deleted:      "#eb6f92",
        Generic.Inserted:     "#9ccfd6",
        Generic.Emph:         "italic",
        Generic.Strong:       "bold",
        Generic.Prompt:       "#6e6a86",
    }
