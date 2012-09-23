vimColorsToQtCreator
===================

Convert vim color schemes so they can be used in Qt Creator.

Usage
-----

    ./vimColorsToQtC.pl {colorscheme} [light|dark]

Examples:

    ./vimColorsToQtC.pl molokai
    ./vimColorsToQtC.pl soso
    ./vimColorsToQtC.pl solarized dark

Copy output files into Qt Creator's styles directory (usually "$HOME/.config/Nokia/qtcreator/styles").

Pay respect to the authors of the Vim color schemes.

