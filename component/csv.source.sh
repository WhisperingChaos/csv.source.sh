#!/bin/bash
##############################################################################
##
##  Namespace
##    csv_field
##  Purpose
##    A cohesive component providing primatives to extract or compose
##    CSV (Comma Separated Values) according to https://www.ietf.org/rfc/rfc4180.txt
##  Note
##    Adheres to "SOLID bash" principles:
##    https://github.com/WhisperingChaos/SOLID_Bash#solid_bash
##
###############################################################################

###############################################################################
##
##  Purpose
##    Parse CSV and extract the values between each comma delimited field.
##    The extracted values are returned to the caller in separate variables.
##  In
##    $1   - A string conformant to CSV spec.  An empty string is considered
##           conformant.  Also, parser implements the imperfect everyday form
##           that's less strict then the specification  For example: two commas
##           ",," without data preceeding or following them
##           are treated as three null fields.  
##    $2   - A variable name to return the number of unset variable names
##           in the list of names that follows this parameter.  A variable
##           is unset when there isn't a corresponding CSV field in the 
##           supplied string.  A corresponding CSV field must be terminated
##           by a deliminating comma.  Except for the last field which
##           is terminated by an EOL.
##    $3-N - Zero, one, or more variable names passed by the caller that
##           receive the parsed values.  To return the rest of the string,
##           that would be parsed to provide a value for the next requested
##           field, specify the variable csv_field_REMAINDER.  Use bash 
##           indirect expansion operator ${!csv_field_REMAINDER} to obtain
##           this variable's value that will be assigned the field's value.
##           This feature can be helpful to detect additional unexpected data. 
##  Out
##    $2   - This return variable name is assigned the value of the number
##           of unset variables. 
##    $3-N - The variable names defined by this list will be updated with
##           values extracted from the CSV string as long as this string isn't
##           exhausted.  If a greater number of variables are specified than
##           can be satisfied, the remaining variables are not changed.  This
##           behavior also applies to variable referenced by csv_field_REMAINDER.
##           Therefore, initialize this variable with some value, like a
##           zero length string so a nonempty remainder can be detected.
##           Ex: local ${csv_field_REMAINDER}=''
##  Return
##    1 - Supplied CSV string fails to conform to CSV specification.
##  Notes:
##    1.  Must position "if" test for reserved csv_field_REMAINDER column name
##        before assingment to nameref "_field", as its readonly attribute will
##        prevent a subsequent assignement of any column names that follow this
##        reserved one.
###############################################################################
##
# CSV fields can either be encapsulated in double quotes or directly specified.
# Use encapsulation when a value contains a double quote or comma.
declare -g -r csv_field_TRIM_REGEX='^((([^,"]+)([,]|$))|(["](([^"]|(""))*)["])([,]|$)|([,]))'
##
# Input variable name that will return the unparsed portion of the string
declare -g -r csv_field_REMAINDER='_remainder'

csv_field_get(){
  local row="$1"
  local -n _unsetVarCnt=$2

  if [[ -z "$2" ]]; then
    csv_field__error "must specify a variable name to return unset variable count as second parameter"
    return 1
  fi
  
  shift 2
  _unsetVarCnt=$#
  local fieldWithQuotes
  local -r dblQt='"'
  while [[ -n "$row" ]] && [[ $# -gt 0 ]]; do
    # see Notes:1.
    if [[ "$1" == "csv_field_REMAINDER" ]]; then
      eval $csv_field_REMAINDER=\"\$row\"
     (( _unsetVarCnt-- ))
      # intentionally permit additional parsing after processig remainder request
      # allows remainder request to appear in any position.  
      shift 1
      continue
    fi

    local -n _field=$1
    if ! [[ $row =~ $csv_field_TRIM_REGEX ]]; then
      csv_field__error "CSV row fails to match trim regex. row='$row'  csv_field_TRIM_REGEX='$csv_field_TRIM_REGEX'"
      return 1
    fi

    if [[ -n "${BASH_REMATCH[3]}" ]]; then
      _field="${BASH_REMATCH[3]}"
    elif [[ -n "${BASH_REMATCH[10]}" ]]; then
      _field=''
    else
      fieldWithQuotes="${BASH_REMATCH[6]}"
      # note used dblQt instead of escaped \" because gedit doesn't 
      # properly highlight syntax that follows the statement below
      # when using \"
      _field="${fieldWithQuotes//$dblQt$dblQt/$dblQt}"
    fi

    (( _unsetVarCnt-- )) 
    leftTrim="${BASH_REMATCH[1]}"
    row="${row:${#leftTrim}}"
    shift 1
  done
}
###############################################################################
##
##  Purpose
##    Performs same parse CSV and extract as csv_field_get, however, it places
##    an empty string value ('') in the passed variables when the CSV row
##    is truncated - leaving nothing to assign these variables.  Remember, an
##    empty string assigned to a declared integer: "local -i variable" is
##    converted into "0".
##  In
##    $1   - A string conformant to CSV spec.  An empty string is considered
##           conformant.  Also, parser implements the imperfect everyday form
##           that's less strict then the specification  For example: two commas
##           ",," without data preceeding or following them
##           are treated as three null fields.  
##    $2-N - Zero, one, or more variable names passed by the caller that
##           receive the parsed values.  To return the rest of the string,
##           that would be parsed to provide a value for the next requested
##           field, specify the variable csv_field_REMAINDER.  Use bash 
##           indirect expansion operator ${!csv_field_REMAINDER} to obtain
##           the field's value.  his feature can be helpful to detect
##           additional unexpected data. 
##  Out
##    $2-N - The variable names defined by this list will be updated with
##           values extracted from the CSV string.  When a greater number
##           of variable names are specified than can be satisfied by the
##           CSV string, the remaining variables are are set to ''.
##  Return
##    1 - Supplied CSV string fails to conform to CSV specification.
###############################################################################
csv_field_get_unset_as_empty(){

  local -i unsetVarCnt=0
  if ! csv_field_get "$1" unsetVarCnt "${@:2}"; then
    return 1
  fi

  if [[ $unsetVarCnt -lt 1 ]]; then
    return 0
  fi

  local -r -i argPosNullifyStart=${#@}-$unsetVarCnt+1
  if ! csv_field__set_empty "${@:$argPosNullifyStart}"; then
    return 1
  fi
}
###############################################################################
##
##  Purpose
##    Build CSV by concatenating one or more fields to the tail
##    of an existing string or empty one.  A comma will be added to an
##    existing string iff it's not already terminated by a comma.  Field
##    values containing a double quote or comma are encapsulated in double
##    quotes to comply with spec.
##  In
##    $1   - A variable name whose value contains an existing string or 
##           empty one. 
##    $2-N - Zero, one, or more values passed by the caller to append
##           to the end of $1. 
##  Out
##    $1   - This variable's value (call by reference) will be updated
##           to reflect the added CSV formatted fields.
###############################################################################
csv_field_append(){
  local -n csvRtn=$1

  if [[ -z "$1" ]]; then
    csv_field__error "must supply variable name to return CSV formated string"
    return 1
  fi

  local fieldVal
  local -r dblQt='"'
  local -r comma=','
  local prefixComma=''
  local -i csvRtnLen=${#csvRtn}
  if [[ ${#csvRtn} -gt 0 ]] \
  && [[ "${csvRtn:$csvRtnLen-1:1}" != "$comma" ]]; then
    prefixComma="$comma";
  fi
  shift
  while [[ $# -gt 0 ]]; do
    if ! expr index "$1" "$comma$dblQt" >/dev/null; then
      csvRtn+="$prefixComma$1"
      prefixComma="$comma"
      shift
      continue
    fi
    fieldVal='"'
    fieldVal+="${1//$dblQt/$dblQt$dblQt}"
    fieldVal+='"'
    csvRtn+="$prefixComma$fieldVal"
    prefixComma="$comma"
    shift
  done
}
############################ private ###########################

###############################################################################
##
##  Purpose
##    Set passed arguments to empty string ('') or (0) if declared an integer.
##  In
##    $1-N - Zero to many variable names.
##  Out
##    $1-N - Zero to many variable names set to empty string ('')
###############################################################################
csv_field__set_empty(){
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "csv_field_REMAINDER" ]]; then
      eval ${csv_field_REMAINDER}=''
    else
      local -n _field=$1
      _field=''
    fi
    shift 1
  done
}
###############################################################################
##
##  Purpose
##    Provide a default, simple error function that can be overridden.
##  In
##    $1 - error message text.
##  Out
##    ERROUT - streamed error message text
###############################################################################
csv_field__error(){
  echo "Error: $1" >&2
}
