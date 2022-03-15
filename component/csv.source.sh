#!/bin/bash
##############################################################################
##
##  csv
##
##  Purpose
##    A cohesive component providing primatives to extract or compose
##    CSV (Comma Separated Values) according to https://www.ietf.org/rfc/rfc4180.txt
##  Note
##    Adheres to "SOLID bash" principles:
##    https://github.com/WhisperingChaos/SOLID_Bash#solid_bash
##  ToDo
##    encode "csv_field_append" function.
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
##           that's less strict then the specification  For example: ",,"
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
##           field, specify the variable name whose value is defined by
##           csv_field_REMAINDER.  This feature can be helpful to detect
##           additional unexpected data. 
##  Out
##    $2   - This return variable name is assigned the value of the number
##           of unset variables. 
##    $3-N - The variable names defined by this list will be updated with
##           values extracted from the CSV string as long as this string isn't
##           exhausted.  If a greater number of variables are specified than
##           can be satisfied, the remaining variables are not changed.  This
##           behavior also applies to variable named by csv_field_REMAINDER.
##           Therefore, initialize this variable with some value, like a
##           zero length string so a nonempty remainder can be detected.
##  Return
##    1 - Supplied CSV string fails to conform to CSV specification.
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
  local -n unsetVarCnt=$2

  shift 2
  local -n field
  unsetVarCnt=$#
  local fieldWithQuotes
  local -r dblQt='"'
  while [[ -n "$row" ]] && [[ $# -gt 0 ]]; do

    local -n field=$1

    if [[ "$1" == "$csv_field_REMAINDER" ]]; then
      field="$row"
      (( unsetVarCnt-- )) 
      shift 1
      continue
    fi

    if ! [[ $row =~ $csv_field_TRIM_REGEX ]]; then
      msg_error "CSV row fails to match trim regex. row='$row'  csv_field_TRIM_REGEX='$csv_field_TRIM_REGEX'"
      return 1
    fi

    if [[ -n "${BASH_REMATCH[3]}" ]]; then
      field="${BASH_REMATCH[3]}"
    elif [[ -n "${BASH_REMATCH[10]}" ]]; then
      field=''
    else
      fieldWithQuotes="${BASH_REMATCH[6]}"
      # note used dblQt instead of escaped \" because gedit doesn't 
      # properly highlight syntax that follows the statement below
      # when using \"
      field="${fieldWithQuotes//$dblQt$dblQt/$dblQt}"
    fi

    (( unsetVarCnt-- )) 
    leftTrim="${BASH_REMATCH[1]}"
    row="${row:${#leftTrim}}"
    shift 1
  done
}

msg_error(){
  echo "Error: $1" >&2
}
