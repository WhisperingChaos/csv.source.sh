#!/bin/bash
###############################################################################
#
#	Purpose:
#		Compose an aggregate component from its consituent elemental ones.
#
#	Note:
#		- source statement below is an aggregate one, as it contains references
#		  to the components used to construct this one.
#
###############################################################################
main(){
	# identify the actual directory location of this executable.  It's aggregate
	# source description will always be in ./sourcer_sh/sourcer_sh.source.sh 
	# relative to its actual directory location.
	declare -r sourcer__EXECUTABLE_DIR="$(dirname "$(readlink -f "$0")")"

	source "$sourcer__EXECUTABLE_DIR/sourcer_sh/sourcer_sh.source.sh"

	sourcer_compose "$1"
}

main "$@"

