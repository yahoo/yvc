#! /bin/sh
#
# Copyright (c) 2008,2009,2010  Yahoo! Inc.
#
# Originally written by Jan Schaumann <jschauma@yahoo-inc.com> in July 2008.
#
# The fetch-vlist tool is used to download the vulnerability lists to be
# used by the 'yvc' tool.  After downloading them, it will verify the PGP
# signature and, if it checks out, install the files in the final
# destination.

# Only used during development:
# set -eu

###
### Globals
###

DONT=""
EXIT_VALUE=0
GPG="gpg"
GPG_FLAGS="--verify -q"
GPG_REDIR="2>/dev/null"
IGNORE_PGP_ERRS=0
PROGNAME="${0##*/}"
TMPFILES=""

##
## Modify this section to specify where to fetch your vlists from.
##
NLISTS=4
VLIST1="http://ftp.netbsd.org/pub/NetBSD/packages/vulns/pkg-vulnerabilities"
VLIST1_LOCATION="/usr/local/var/var/yvc/nbvlist"
VLIST2="http://<somewhere>/yvc/fbvlist"
VLIST2_LOCATION="/usr/local/var/yvc/fbvlist"
VLIST3="http://<somewhere>/yvc/rh4vlist"
VLIST3_LOCATION="/usr/local/var/yvc/rh4vlist"
VLIST4="http://<somewhere>/yvc/rh5vlist"
VLIST4_LOCATION="/usr/local/var/yvc/rh5vlist"

WGET="wget"
WGET_FLAGS="-t 1 -T 10 -q"

###
### Functions
###

# function : cleanup
# purose   : exit handler to remove any temporarily created files

cleanup() {
	rm -f ${TMPFILES}
}

# function : error
# purpose  : print message to stderr and exit 1
# input    : any string
# output   : input is echo'd to stderr, program aborted

error() {
	warn ${1}
	exit 1
}

# function : warn
# purpose  : print message to stderr
# input    : any string
# output   : input is echo'd to stderr
#            sets EXIT_VALUE to 1 to indicate failure

warn() {
	echo "${PROGNAME}: ${1}" >&2
	EXIT_VALUE=1
}

# function : fetchVerifyInstall
# purpose  : fetch, verify and install all vlists
# input    : none
# result   : all files are fetched, verified and installed into their
#            final location; any errors encountered are caught and an
#            appropriate error message printed

fetchVerifyInstall() {
	local n

	n=1
	while [ $n -le ${NLISTS} ]; do
		local tmpfile=$(mktemp /tmp/${PROGNAME}.XXXXXX)
		local list=$(eval echo \$VLIST${n})
		local target=$(eval echo \$VLIST${n}_LOCATION)

		TMPFILES="${TMPFILES} ${tmpfile}"
		n=$(( $n + 1 ))

		fetchList ${tmpfile} ${list} || {
			warn "Unable to fetch ${list}."
			continue
		}

		verifySignature ${tmpfile} || {
			if [ ${IGNORE_PGP_ERRS} -ne 1 ]; then
				warn "Unable to verify signature of ${list}."
				continue
			fi
		}

		installFile ${tmpfile} ${target} || {
			warn "Unable to install ${tmpfile} as ${target}."
			continue
		}
	done
}

# function : fetchList
# purpose  : download the list from the given URL into a temporary
#            location
# input    : temporary file, list URL
# returns  : exit value of wget command

fetchList() {
	local tmpfile=${1}
	local url=${2}

	${DONT} ${WGET} -O ${tmpfile} ${WGET_FLAGS} ${url}
}

# function : installFile
# purpose  : install the temporary file into the final destination if
#            needed
# input    : temporary file, final location

installFile() {
	local tmpfile=${1}
	local final=${2}

	${DONT} cmp -s ${tmpfile} ${final} || {
		${DONT} mv ${tmpfile} ${final} && \
		${DONT} chmod 444 ${final}
	}
}

# function : usage
# purpose  : print a usage summary
# returns  : nothing, usage printed to stdout

usage() {
	echo "Usage: ${PROGNAME} [-dhiv]"
	echo "       -d  don't do anything, just report what would be done"
	echo "       -h  print this help and exit"
	echo "       -i  ignore any pgp errors"
	echo "       -v  be verbose"
}

# function : verifySignature
# purpose  : verify the pgp signature on the given file
# input    : filename
# returns  : retval of gpg command

verifySignature() {
	local file=${1}
	${DONT} eval ${GPG} ${GPG_FLAGS} ${file} ${GPG_REDIR}
}

###
### Main
###

trap cleanup 0

while getopts 'dhiv' opt; do
	case ${opt} in
		d)
			DONT="echo"
		;;
		h|\?)
			usage
			exit 0
			# NOTREACHED
		;;
		i)
			IGNORE_PGP_ERRS=1
		;;
		v)
			WGET_FLAGS="-v"
			GPG_FLAGS="${GPG_FLAGS} -v"
			GPG_REDIR=""
		;;
		*)
			usage
			exit 1
			# NOTREACHED
		;;
	esac
done
shift $(( ${OPTIND} - 1 ))

if [ $# -ne 0 ]; then
	usage
	exit 1
	# NOTREACHED
fi

fetchVerifyInstall

exit ${EXIT_VALUE}
