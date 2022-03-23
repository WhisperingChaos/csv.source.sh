[![Actions Status](https://github.com/whisperingchaos/csv.source.sh/workflows/test/badge.svg)](https://github.com/WhisperingChaos/csv.source.sh/actions)

# csv.source.sh
Component offers an API to parse and build a buffer of Comma Separated Values (CSV).  The CSV snytax accepted by parse must adhere to [IETF RFC 4180](https://www.ietf.org/rfc/rfc4180.txt) while build produces one compliant to it.

## ToC
[API Index](#api-index)  
[API](#api)  
[Install](#install)  
[Test](#test)  
[License MIT](LICENSE)  


### API Index
[csv_field_append](#csv_field_append)

[csv_field_get](#csv_field_get)

### API

#### csv_field_append
https://github.com/WhisperingChaos/csv.source.sh/blob/340e4678d4e502373a6b2a89795227b0ade37fe0/component/csv.source.sh#L108-L124
#### csv_field_get
https://github.com/WhisperingChaos/csv.source.sh/blob/340e4678d4e502373a6b2a89795227b0ade37fe0/component/csv.source.sh#L17-L51

### Install
#### Simple
Copy **csv.source.sh** into a directory then use the Bash [source](https://www.gnu.org/software/bash/manual/html_node/Bash-Builtins.html#Bash-Builtins) command to include this package in a Bash testing script before executing fuctions which rely on its [API](#api-index).  Copying using:

  * [```git clone```](https://help.github.com/articles/cloning-a-repository/) to copy entire project contents including its git repository.  Obtains current master which may include untested features.  To synchronize the working directory to reflect the desired release, use ```git checkout tags/<tag_name>```.
  *  [```wget https://github.com/whisperingchaos/csv.source.sh/tarball/master```](https://github.com/whisperingchaos/csv.source.sh/tarball/master) creates a tarball that includes only the project files without the git repository.  Obtains current master branch which may include untested features.
#### SOLID Composition
TODO
#### Developed Using 
GNU bash, version 4.3.48(1)-release

This component relies on [nameref/name reference feature](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameters.html) introduced in version 4.3.
### Test
After [installing](#install), change directory to **csv.source.sh**'s ```test```. Then run:
  * ```./config.sh``` followed by
  * [**./csv_source_test.sh**](test/csv_source_test.sh).  It should complete successfully and not produce any messages.
```
host:~/Desktop/projects/csv.source.sh/test$ ./csv.source_test.sh
host:~/Desktop/projects/csv.source.sh/test$ 
```
