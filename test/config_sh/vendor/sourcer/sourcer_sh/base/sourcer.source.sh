#!/bin/bash
###############################################################################
#
#	Purpose:
#		Construct an aggregrate "component" through hierarchical composition of other
#		components. A component represents a unit of reuse that can be reflected as
#		either an "includible" module or bash command.  An "includible" file
#		bounds a set of cohesive funtions packaged for reuse.
#
#		Creating an aggregrate component relies on first importing "base" component(s)
#		and when necessary, locally "overriding" the behavior of certain functions 
#		to produce the desired behavior of the resultant component.  The overriding
#		behavior is injected by encoding a function of the same name, that accepts
#		the same interface, in one or more includible files that are read in after
#		processing the base includible(s).
#		
#		Base includibles exist in a subdirectory named "base" associated to the
#		parent directory that encapsulates the aggregrate component.  Overriding
#		includibles exist in a subdirectory named "override".  When either a base
#		or overriding includible is itself an aggregrate component, this
#		aggregrate component should itself be comprised of base and potentially
#		overriding components.
#
#		The algorithm below, for a given component, will perform a depth first
#		search to identify the deepest base includible and its associated
#		overriding one before visiting includibles nearer to the component's
#		immediate base and overriding ones.
#
#		In situations involving elemental includibles, they can be deposited
#		directly into a component's base or override directories.
#
#	Assume:
#		- Processing relies on Linux 'ls' command's sort order.  Therefore, source
#		  modules containing function and environment definitions that share the
#		  same name will be resolved by their sort order.  The shared definitions
#		  which appear in the module whose name sorts after the other module(s) will
#		  dominate/define the implementation of the shared names.
# 
#	Convention:
#		https://github.com/WhisperingChaos/SOLID_Bash
#
###############################################################################
declare -g  sourcer__BASE_SUBDIR_NAME='base'
declare -g  sourcer__OVERRIDE_SUBDIR_NAME='override'
declare -gi sourcer__VISIT_LEVEL_MAX=5
declare -gi sourcer__COMPONENTS_PER_LEVEL_MAX=20


sourcer_compose(){
	local -r parentPath="$1"
	local -ri visitLevel=$2+1

	# always deep dive base includibles before processing overrides
	if ! sourcer__visit "$parentPath" $visitLevel "$sourcer__BASE_SUBDIR_NAME"; then
		return 1
	fi
	if ! sourcer__visit "$parentPath" $visitLevel "$sourcer__OVERRIDE_SUBDIR_NAME"; then
		return 1
	fi
}


sourcer__visit(){
	local -r  parentPath="$1"
	local -ri level=$2
	local -r  branch="$3"

	local subDir
	local -i compPerLevel=0
	for subDir in $(ls -1d "$parentPath/$branch/"*/ 2>/dev/null); do
		if   [ "$(basename "$subDir")" = "$sourcer__BASE_SUBDIR_NAME" ]     \
			|| [ "$(basename "$subDir")" = "$sourcer__OVERRIDE_SUBDIR_NAME" ]; then
			# should never be */$branch/$branch/* - must have interviening component
			# name: */$branch/<componentname>/$branch/*. Why? using a composite
			# component within the same executable represents a subtle/advanced
			# form of component aggregation during the creation of a singular
			#	executable that should be somewhat rare.  Requiring an intervening
			# directory suggests this aggregration is intentional, not a mistaken
			# move/copy drop.
			sourcer__visit_immediate_branch_error "$branch" "$parentPath/$branch/$branch/"
			return 1
		fi

		if [ $((++compPerLevel)) -gt $sourcer__COMPONENTS_PER_LEVEL_MAX ]; then 
			sourcer__visit_too_many_components_error "$sourcer__COMPONENTS_PER_LEVEL_MAX" "$subDir"
			return 1
		fi

		if [ $level -ge $sourcer__VISIT_LEVEL_MAX ]; then
			sourcer__visit_too_deep_error "$sourcer__VISIT_LEVEL_MAX" "$subDir"
			return 1
		fi

		if ! sourcer_compose "$subDir" $level; then
			return 1
		fi
	done
	# one or more elemental components (source files) may exist in the $branch directory
	sourcer__visit_filepath_echo "$parentPath/$branch"
}


sourcer__visit_immediate_branch_error(){
	local -r branchName="$1"
	local -r dirPath="$2"

	cat >&2 <<SOURCER__VISIT_IMMEDIATE_BRANCH_ERROR

Error: Ignoring components located in subdirectory: '$branchName' of: '$dirPath'.
  +    If you want compose a component within an existing component, create
  +    an intervening subdirectory whose name reflects a component name that
  +    is not: '$sourcer__BASE_SUBDIR_NAME' nor '$sourcer__OVERRIDE_SUBDIR_NAME'.
SOURCER__VISIT_IMMEDIATE_BRANCH_ERROR
}


sourcer__visit_too_many_components_error(){
	local -ri componentMax=$1
	local -r subdirStop="$2"

	cat >&2 <<SOURCER__VISIT_TOO_MANY_COMPONENTS_ERROR

Error: Maximum component count: $componentMax exceeded for a given level
  +    while starting to process directory: '$subdirStop'.  This and all
  +    component directories that sort after it were not processed.
  +    If you want to exceed this limit use SOLID Open/Close mechanism to
  +    change: 'sourcer__COMPONENTS_PER_LEVEL_MAX' for the desired resultant
  +    component.
SOURCER__VISIT_TOO_MANY_COMPONENTS_ERROR
}


sourcer__visit_too_deep_error(){
	local -ri levelMax=$1
	local -r subdir="$2"
	cat >&2 <<SOURCER__VISIT_TOO_DEEP_ERROR

Error: Ignoring components located in subdirectory: '$subdir' because
  +    directory composition level depth: $levelMax was exceeded.  If 
  +    level depth beyond this maximum is desired, use Open/Close principle
  +    to override 'sourcer__VISIT_LEVEL_MAX' to reflect maximum for this
  +    component.
SOURCER__VISIT_TOO_DEEP_ERROR
}


sourcer__visit_filepath_echo(){
	local -r sourcePath="$1"

	local incDir
	for incDir in $(ls -1 "$sourcePath/"*.source.sh 2>/dev/null); do
		echo "$incDir"
	done
}
