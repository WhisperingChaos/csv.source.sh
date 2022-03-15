declare -g sourcer__BASE_DIR_NAME='base'
declare -g sourcer__build_SOURCER_SH_NAME='sourcer.sh'
declare -g sourcer__build_SOURCER_SH_NAME_DIR=${sourcer__build_SOURCER_SH_NAME%.*}


sourcer__build_parameter_check(){
	local -r sourcerShFilePathRtn=$1
	local -r sourceFilePathRtn=$2
	local -r sourceRoot="${4:-"$(dirname "$0")"}"
	local -r sourcerShDir="${3:-$sourceRoot/$sourcer__build_SOURCER_SH_NAME_DIR}"

	if ! [ -e "$sourcerShDir/$sourcer__build_SOURCER_SH_NAME" ]; then
		sourcer__build_sourcer_noexist "$sourcerShDir"
		return 1
	fi

	if ! [ -e "$sourceRoot/$sourcer__BASE_DIR_NAME" ]; then
		sourcer__build_source_noexist "$sourceRoot"
		return 1
	fi

	if ! command -v $sourcerShFilePathRtn; then
		eval $sourcerShFilePathRtn=\"\$sourcerShDir\/\$sourcer__build_SOURCER_SH_NAME\"
	fi
	if ! command -v $sourceFilePathRtn; then
		eval $sourceFilePathRtn=\"\$sourceRoot\"
	fi
}


sourcer__build_sourcer_noexist(){
	local -r sourcerShDir="$1"

	cat >&2<<SOURCER__SOURCER_SH_NOEXIST

Error: Unable to locate '$sourcer__build_SOURCER_SH_NAME' in directory: '$sourcerShDir'. 
SOURCER__SOURCER_SH_NOEXIST
}

sourcer__build_source_noexist(){
	local -r sourceRoot="$1"

	cat >&2<<SOURCER__BUILD_SOURCE_NOEXIST

Error: Unable to locate initial '$sourcer__BASE_DIR_NAME' source directory: '$sourceRoot/$sourcer__BASE_DIR_NAME'. 
SOURCER__BUILD_SOURCE_NOEXIST
}

# This function permits adapting (overridding) the regex expressions used during
# the scanning process.  Presents another way of overridding objects without
# having to include them as global variables in a unique namespace.
sourcer__build_funcvar_exception_pipe(){
	local -r sourceFlPth="$1"

	# notice extra grouping "()" operators - allows 3 more groups before identifier
	# in overriding regex before its necessary to change function that uses these
	# expressions.
	local -r funcRegex='^(function[[:space:]]+)*(((([_[:alnum:]]+))))[[:space:]]*\(\).*$'
	local -r varNameRegex='[_\.[:alnum:]]+'
	local -r glbVarDeclareRegex='^((declare[[:space:]].+[[:space:]]+)|(declare[[:space:]]+))(((('"$varNameRegex"'))))=.*$'
#TODO - determine if really necessary to scan for global definitions that are
# likely defined within a function.  Therefore, their existance is dynamic,
# as these definitions most likely won't appear until long after the completion
# of component composition, if at all...
#	local -r glbVarDeclaregxRegex='[[:space:]].+((declare[[:space:]](-[gx.]|.+)[[:space:]]+)|(declare[[:space:]]+))(((('"$varNameRegex"'))))=.*$'
	local -r glbVarExportRegex='^((export[[:space:]].+[[:space:]]+)|(export[[:space:]]+))(((('"$varNameRegex"'))))=.*$'
	local -r glbVarRegex='^(((('"$varNameRegex"'))))=.*$'

	sourcer__build_funcvar_exception_pipe_pipe "$sourceFlPth"
}


sourcer__build_funcvar_exception_pipe_pipe(){
	local -r sourceFlPth="$1"

	if [[ "$sourcer__BASE_DIR_NAME" != "$(basename "$(dirname "$sourceFlPth")")" ]]; then
		local -r shouldExist='true'
	else
		local -r shouldExist='false'
	fi

	# don't interfer with user's pipe option setting.
	local pipeOption	
	sourcer__pipe_option_save 'pipeOption'
	set -o pipefail
	cat $sourceFlPth 	                                                    \
	| sed  -rn                                                            \
			-e 's/'"$funcRegex"'/f:\5/ p'                                     \
			-e 's/'"$glbVarDeclareRegex"'/v:\7/ p'                            \
			-e 's/'"$glbVarExportRegex"'/v:\7/ p'                             \
			-e 's/'"$glbVarRegex"'/v:\4/ p'                                   \
	| sourcer__build_funcvar_exist_tag                                    \
	| sourcer__build_funcvar_exception_filter "$shouldExist"              \
	| sourcer__build_funcvar_exception_tag "$shouldExist" "$sourceFlPth"  \
	| sourcer__build_funcvar_exception_report "$shouldExist" "$sourceFlPth"
	local -ri rtnCd=$?
	sourcer__pipe_option_restore 'pipeOption'
	return $rtnCd
}


sourcer__pipe_option_save(){
	eval $1=\"\$\(\set\ \+o \| \grep pipefail\)\"
}


sourcer__pipe_option_restore(){
	eval \$$1
}


sourcer__build_funcvar_exist_tag(){

	local funvar
	local typeInd
	local name
	local nameExist
	while read -r funvar; do
		typeInd="${funvar:0:1}"
		name="${funvar:2}"
		nameExist='n'
		if   [[ "$typeInd" = "f" ]]; then 
			declare -f -F "$name" >/dev/null 2>/dev/null && nameExist='e'
		elif [[ "$typeInd" = "v" ]]; then 
			declare -p "$name"    >/dev/null 2>/dev/null && nameExist='e'
		else
			sourcer__build_unknown_type_error "$typeInd" "$funvar"
			return 1
		fi
		echo "$nameExist"':'"$funvar"
	done
}


sourcer__build_unknown_type_error(){
	local -r typeInd="$1"
	local -r funvar="$2"

	cat >&2 <<SOURCER__BUILD_UNKNOWN_TYPE_ERROR

Error: Logic problem unknown type: '$typeInd' for funvar: '$funvar' hasn't been defined.
SOURCER__BUILD_UNKNOWN_TYPE_ERROR
}

sourcer__build_funcvar_exception_filter(){
	local	shouldExist="$1"

	if [[ "$shouldExist" != 'true' ]]; then
		shouldExist='false'
	fi
	local -r shouldExist

	local funvar
	local nameExist
	while read -r funvar; do
		nameExist=${funvar:0:1}
		if $shouldExist; then 
			[[ $nameExist = 'e' ]] && continue
		else
			[[ $nameExist = 'n' ]] && continue
		fi
		echo "$funvar"
	done 
}


sourcer__build_funcvar_exception_tag(){
	local shouldExist="$1"
	local -r sourceFlPth="$2"

	if [[ "$shouldExist" != 'true' ]]; then
		shouldExist='false'
	fi
	local -r shouldExist

	local funvar
	local typeInd
	local name
	while read -r funvar; do
		typeInd=${funvar:2:1}
		name=${funvar:4}
		sourcer__build_funcvar_exception_categorize "$shouldExist" "$typeInd" "$name" "$sourceFlPth"
		case $? in
 			0) continue
			;;
			1) echo 'e:'"$funvar"
			;;
			2) echo 'w:'"$funvar"
			;;
			*) echo 'e:'"$funvar"
			;;
		esac
	done 
}
###############################################################################
#
#	Purpose:
#		Enable fine grained categorization of conflict exceptions.  A conflict
#		can occur while combining package files:
#		-	A 'base' package should not usually redefine preexisting
#		  functions nor global variables.
#		- An 'override' package should usually redefine preexisting functions
#		  or global variables.
#
# Note:
#		-	Returning an error will continue conflict processing for the current 
#		  package but will halt further processing for subsequent ones.
#
#	In:
#		- $1 'true' - Indicates processing 'override'.  Should have existed but wasn't found.
#		     'false'- Indicates processing 'base'.  Should not exist but did.
#		- $2 'f' - function name
#		     'v' - global variable
#		- $3 The name of the function/global variable.
#		- $4 The filepath name of the package that defined the function/variable
#
#	Return:
#		0 - ignore exception - don't report it
#		1 - treat exception as an error - report it & terminate processing.
#		2 - treat exception as a warning - report it but continue processing
#
###############################################################################	
# enable a simple form of function overriding for this specific function as it's likely
# it will be overridden while rest remains the same.
if ! declare -f -F sourcer__build_funcvar_exception_categorize >/dev/null 2>/dev/null; then 
sourcer__build_funcvar_exception_categorize(){
	# default implementation - report all exceptions as warnings
	return 2
}
fi


sourcer__build_funcvar_exception_report(){
	local shouldExist="$1"
	local	-r sourceFlPth="$2"

	if [[ "$shouldExist" != 'true' ]]; then
		shouldExist='false'
	fi
	local -r shouldExist

	local conflictCat
	local typeInd
	local name
	local funvar
	local -i rtnCd=0
	while read -r funvar; do
		conflictCat=${funvar:0:1}
		typeInd=${funvar:4:1}
		name=${funvar:6}
		sourcer__build_funcvar_exception_detail "$conflictCat" "$typeInd" "$name" \
			"$shouldExist" "$sourceFlPth"
		if [[ "$conflictCat" = 'e' ]]; then
			rtnCd=1
		fi
	done
	
	return $rtnCd
}


sourcer__build_funcvar_exception_detail(){
	local -r conflictCat="$1" 
	local -r typeInd="$2"
	local	-r name="$3"
	local -r shouldExist="$4"
	local -r sourceFlPth="$5"

	local msgType="Warning"
	[[ "$conflictCat" = 'e' ]] && msgType="Error"
	local typeName='unknown'
	[[ "$typeInd" = 'f' ]] && typeName='function'
	[[ "$typeInd" = 'v' ]] && typeName='variable'
	local existStatus='not '
	$shouldExist && existStatus=''

	cat >&2 <<SOURCER__BUILD_FUNCVAR_EXECPTION_DETAIL
${msgType}: Source file: '$sourceFlPth' contains $typeName 
  +    named: '$name' that should ${existStatus}already exist.
SOURCER__BUILD_FUNCVAR_EXECPTION_DETAIL
}


sourcer__build_help(){

	cat <<SOURCER__BUILD_HELP

[sourcer__build_CONFLICT_EXCEPTION={'enable'}|:-'disable']
[sourcer__build_funcvar_exception_categorize(){ your implementation here; }]
source [<path>]sourcer.build.source.sh [<pathToSourcer>] [<pathToComponentRoot>] [<pathToOverride>]

  sourcer__build_CONFLICT_EXCEPTION  Environment Variable - Enables/Disables
          reporting of problematic matched/unmached definitions/overrides.  All
          functions and global variables defined in a 'base' package namespace
          should not conflict (not match) any names processed so far.
          In a similar manner, functions and global variables defined in 'override'
          package should conflict (match) with already existing ones.  The default
          behavior 'disable's conflict processing.  This environment variable
          must exist before processing the 'source' command but need not be specified
          in the component's definition.  Recommend creating it in terminal shell
          while testing and setting it's value to 'enable'.

  sourcer__build_funcvar_exception_categorize()  Enables fine grained exception
          categorization.  An exception can be categorized as either (return code):
            0 - ignore anticipated exception - don't report it
            1 - treat exception as an error - report it & terminate processing.
            2 - treate exception as a warning - report it but continue processing
          This package's default implementation categorizes any conflict as a warning.
          Override this function with desired implementation adhering to function's 
          interface as described in this package.
          
  <path>  Path to directory containing 'sourcer.build.source.sh' - optional.  If not
          specified then this module is available through \$PATH.

  <pathToSourcer>  Path to '$sourcer__build_SOURCER_SH_NAME' - optional.
          If not specified this script will search within the directory
          defining the component being constructed: "<pathToComponentRoot>/$sourcer__build_SOURCER_SH_NAME_DIR/$sourcer__build_SOURCER_SH_NAME".
          This search mechanism enables each component to implement its own
          '$sourcer__build_SOURCER_SH_NAME'.
          Usually Optional, unless any parameters are specified after it.

  <pathToComponentRoot> Path to directory defining component - optional.
          The following subdirectory: '$sourcer__BASE_DIR_NAME'
          must exist in this path.  If not specified script will assume
          dirname "\$0": '$(dirname "$0").

  <pathToOverride>  Path to a file whose contents will override the implementation
          of this source file: ${BASH_SOURCE[0]}. Optional.

These parameters are positional, therefore, if a later parameter must be specified
then any parameter appearing before it must also be defined.  Specify an empty
string: '' to assign a parameter's default value.

SOURCER__BUILD_HELP
}


declare -g sourcer__build_OVERRIDE_IMPLEMENTATION='disable'
###############################################################################
#	All functions and variables that can be overridden should appear above the
#	'source' statement immediately below. 
###############################################################################
if [[ -n "$3" ]]; then
	if ! source "$3"; then return 1; fi
fi
###############################################################################
#	Anything below can also be overridden by the 'source'd override package.
#	To do so set sourcer__build_OVERRIDE_IMPLEMENTATION='enable' terminates
# execution when returning from overridding package.
###############################################################################
if [[ "$sourcer__build_OVERRIDE_IMPLEMENTATION" = 'enable' ]]; then
	return
fi

if [[ "$1" = "-h" ]] || [[ "$1" = "--help" ]]; then
	sourcer__build_help
	return
fi
# include components required to create this executable without encapsulating
# the code in a function as 'declare'd variables, that would be considered global
# given their definition in the 'source'd file would be assigned a scope local to
# the encapsulating function.  Once this function terminates, the variables are 
# no longer in scope.  This would be considered unexpected behavior and probably
# reported as a bug. That said, the commands in this source not encapsulated inside
# a function function could be encapsulated in one as long as every globally
# 'declare'd variable included the -g option: 'declare -g <VariableName>' but
# one would have to remember to include the -g option, otherwise, one would
# experience unexpected results that might consume much time to debug,
# as a bash developer's knowledge would suggest the -g option was unnecessary.
declare -g sourcer__build_SOURCER_FILENAME
declare -g sourcer__build_SOURCE_COMPONENT_ROOT
if ! sourcer__build_parameter_check 'sourcer__build_SOURCER_FILENAME' \
	'sourcer__build_SOURCE_COMPONENT_ROOT'  "$@"; then
	return 1
fi
declare -g sourcer__build_CONFLICT_EXCEPTION=${sourcer__build_CONFLICT_EXCEPTION:-'disable'}
declare -g sourcer__build_MOD
if	[[ "$sourcer__build_CONFLICT_EXCEPTION" = 'enable' ]]; then
	for sourcer__build_MOD in $( "$sourcer__build_SOURCER_FILENAME" \ 		"$sourcer__build_SOURCE_COMPONENT_ROOT"); do
		if ! sourcer__build_funcvar_exception_pipe "$sourcer__build_MOD"; then
				return 1
		fi
		source "$sourcer__build_MOD"
	done
	return
fi

for sourcer__build_MOD in $( "$sourcer__build_SOURCER_FILENAME" \ 	"$sourcer__build_SOURCE_COMPONENT_ROOT"); do
	source "$sourcer__build_MOD"
done
