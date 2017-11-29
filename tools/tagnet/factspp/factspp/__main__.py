"""
__main__.py: invoke rules emulator as an application

Command line parameters are parsed and passed to the
emulator, which handles the bulk of the program.

@author: Dan Maltbie, (c) 2017
"""
import argparse

from __init__ import preprocessor
from __init__ import __version__ as VERSION


def main():
    global  __version__
    parser = argparse.ArgumentParser(
        description='Tagnet Name Preprocessor')
    parser.add_argument('input',
                        type=argparse.FileType('rb'),
                        help='input file')
    parser.add_argument('-V', '--version',
                        action='version',
                        version='%(prog)s ' + VERSION)
    parser.add_argument('-v', '--verbosity',
                        action='count',
                        default=0,
                        help="increase output verbosity")
    args = parser.parse_args()
    preprocessor(args)

main()