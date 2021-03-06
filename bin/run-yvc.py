#! /usr/local/bin/python2.5
#
# Copyright (c) 2008,2010 Yahoo! Inc.
#
# Originally written by Jan Schaumann <jschauma@yahoo-inc.com> in July 2008.
#
# The entire functionality of the yvc(1) tool is found in the
# yahoo.yvc.Checker class.  This script just invokes the 'main' function
# provided by yahoo.yvc.

###
### Main
###

if __name__ == "__main__":
    import sys
    from yahoo.yvc import main
    main(sys.argv[1:])
