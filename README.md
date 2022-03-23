# csv.source.sh
Component offers an api to parse and compose Comma Separated Values (CSV).  The CSV snytax accepted by both the parse and compose APIs must adhere to [IETF RFC 4180](https://www.ietf.org/rfc/rfc4180.txt).

## ToC
[API Index](#api-index)
[API](#api)
[Install](#install)  
[Example](#example)  
[Test](#test)  
[Terms](#terms)  
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
Copy **csv.source.sh** into a directory then use the Bash [source](https://www.gnu.org/software/bash/manual/html_node/Bash-Builtins.html#Bash-Builtins) command to include this package in a Bash testing script before executing fuctions which rely on its [API](#api-index).  Copying using:

  * [```git clone```](https://help.github.com/articles/cloning-a-repository/) to copy entire project contents including its git repository.  Obtains current master which may include untested features.  To synchronize the working directory to reflect the desired release, use ```git checkout tags/<tag_name>```.
  *  [```wget https://github.com/whisperingchaos/csv.source.sh/tarball/master```](https://github.com/whisperingchaos/csv.source.sh/tarball/master) creates a tarball that includes only the project files without the git repository.  Obtains current master branch which may include untested features.
    
#### Developed Using 
GNU bash, version 4.3.48(1)-release

This component relies on [nameref/name reference feature](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameters.html) introduced in version 4.3.
