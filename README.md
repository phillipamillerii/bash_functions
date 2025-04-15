# Base Function Script
## Loading base functions in script
1. Create folder within our new scripts dir
    ```sh
    mkdir core_functions
    ```
2. Create function file within 
    ```sh
    vim core_functions/bash_functions.bash
    ```
3. Within the main Script add the below at the top
    ```sh
    for LoadCoreFunctions in "${BASE_SCRIPT_FOLDER}/core_functions/"*.bash; do source "$LoadCoreFunctions"; done
    ```


## MakePretty
### MakePretty - Basic Usage
1. Add the below after [loading the base function](#loading-base-functions-in-script) in another script. 
    ```sh
    MakePretty
    ```
2. Call the Commands within the script (examples)
    ```sh
    info "text to output"
    ```

### Colors / Modifiers
| Colors | 
|:---|
| BLACK | 
| RED |
| GREEN |
| YELLOW | 
| BLUE |
| PURPLE |
| CYAN | 
| WHITE |

| Modifiers |    
|:---|
| BRIGHT |
| NORMAL |
| BLINK | 
| REVERSE | 
| UNDERLINE |

### Commands to use

| Command | Modifier(s) | Color |         
|:---|:---|:---|
| info | BRIGHT | GREEN |
| progress | BRIGHT | BLUE |
| alert | BRIGHT | YELLOW|
| warning | BRIGHT | RED|
| warning_blink | BRIGHT & BLINK | RED|
| info_tab | Tab & BRIGHT | GREEN|
| progress_tab | Tab & BRIGHT | BLUE|
| alert_tab | Tab & BRIGHT | YELLOW|
| warning_tab | Tab & BRIGHT | RED|

## confirm_load
Checks oneminute_loadaverage against number_of_procs and if it's over the number_of_procs it asks for confirmation, if not it continues with the script.

It is a good idea to call this funciton early in the script. 

## break_line
This will output a line to the screen, and it can be used to help break up outputs. 

This can be called in a few different ways. 
- Without options : Outputs a full terminal line with `-` 
    ```sh
    break_line
    ```
- With a specific symbol : Outputs a full terminal line with the symbol provided
    ```sh
    break_line "+"
    ```
- With a specific number of entries : Outputs a line with the provided number of `-` symbols
    ```sh
    break_line 50
    ```
- With a Specific Number of Entries and a Specific Symbol : Outputs a line with the provided number or symbols provided
    ```sh
    break_line 50 "+"
    ```
    or
   ```sh
    break_line "+" 50 
    ```   
    ( The order the number of symbols and the symbol don't matter )


## backup_file
The goal of this is to create a backup of a file before we update it. It creates a file that includes the script name, the date, and backup. 

### Using Backup function
```sh 
backup_file "/etc/httpd/conf.d/httpd_smartopts.conf"

#Output:
/etc/httpd/conf.d/httpd_smartopts.conf -> /etc/httpd/conf.d/httpd_smartopts.conf_scriptname_Jul-24-2024_07:26:53.backup
```


## clean_script_backup_files
This will check the server for backup files that contain the name of the script it in and ends with backup. Provides you with a list of the backups it found, and ask for a list of the backups they want to remove based on a numbered list. 

### Using clean function
```sh
clean_script_backup_files

#Output:
Pulling a list of the backups, this may take some time.
Here is a current list of the smartopts backup files
1 : /etc/httpd/conf.d/httpd_smartopts.conf_smartopts.May-01-2024_01:31:02.backup
2 : /etc/httpd/conf.d/httpd_smartopts.conf_smartopts.May-20-2024_02:05:57.backup
3 : /etc/httpd/conf.d/httpd_smartopts.conf_smartopts.May-01-2024_01:32:04.backup
4 : /etc/httpd/conf/httpd.conf_smartopts_Jun-18-2024_04:25:03.backup
5 : /etc/httpd/conf/httpd.conf_smartopts_Jun-18-2024_04:25:20.backup
6 : /etc/httpd/conf/httpd.conf_smartopts.Jun-21-2024_05:34:48.prerestore_backup

Which backup's would you like to remove? Please enter in 1-4,9,11,14 type format.
:
```


## restore_file
This is used to restore a backup file. You can provide it with a file name right away, or it will provide you with a numbered list of the script backups files that were created using [Backup Function](#backup_file).

### Using restore function - File to restore provided
It will ask for confirmation to restore to that location

Command
```sh
restore_file /direct/path/to/file_we_are_restoring.conf_smartopts.May-01-2024_01:31:02.backup

#Output:
Restore location not provided. Please provided the file we are replacing
:
```
 

### Using restore function - File and restore location provided
```sh
restore_file /direct/path/to/file_we_are_restoring.conf_smartopts.May-01-2024_01:31:02.backup /direct/path/to/file_we_are_restoring.conf

#Output:
/direct/path/to/file_we_are_restoring.conf_smartopts.May-01-2024_01:31:02.backup -> /direct/path/to/file_we_are_restoring.conf
```


## format_output
This will help format bulk outputs in a similar format. There are a few different options available. 

Output options
- column output
    
    This doesn't require any extra data for the process. Each line will need to be added to a variable, ending with a new line (`\n`) entry. The first line of the output variable will be the title of the table output, and then we need to add the columns of data from that to the variable. 

    Example call:
    ```sh
    output="Col1 col2\n"
    output+="1 2\n"
    output+="3 4\n"
    output+="5 6\n"
    output+="7 8\n"
    format_output "$output"
    
    #Output:
    =========================================
    Col1      col2
    =========================================
    1         2
    3         4
    5         6
    7         8
    -----------------------------------------
    ```
- bulk_output

    This outputs the data in a bulk format with a title section.
    ```sh
    output="<bulk_output> testing some stuff\n"
    output+="just trying to see if this output works a little more\n"
    output+="Line 2 test\n"
    format_output "$output"

    #Output:
    =============================================================================================
    testing some stuff
    =============================================================================================
    just trying to see if this output works a little more
    Line 2 test
    ---------------------------------------------------------------------------------------------
    ```

- bulk_column_output

    This requires that the first line to contain `<bulk_column_output> ` (Including the space after `>`). Any time you want to seperate the line you are outputting from the rest of the data add a `<block> ` (Including the space after `>`) at the start of the line. For the column title you will want to start it with `<block> <column> ` (Including the spaces after `>`), to make it look like a title section for the table. And for each column spaced data you will want to start it with a `<column> ` (Including the space after `>`) then add the data you was to output space delimited. 

    ```sh
    output="<bulk_column_output> testing some stuff\n"
    output+="<block> <column> Col1 col2 col3\n"
    output+="<column> asdfasdf 1 2\n"
    output+="<column> asdfas f3 4\n"
    output+="<column> asdf 5 6\n"
    output+="<column> asdf 7 8\n"
    output+="<block> testing stuff works or now\n"
    output+="just trying to see if this output works a little more\n"
    format_output "$output"

    #Output:
    =============================================================================================
    testing some stuff
    =============================================================================================
    ---------------------------------------------------------------------------------------------
    Col1          col2      col3
    ---------------------------------------------------------------------------------------------
    asdfasdf      1         2
    asdfas        f3        4
    asdf          5         6
    asdf          7         8
    ---------------------------------------------------------------------------------------------
    testing stuff works or now
    ---------------------------------------------------------------------------------------------
    just trying to see if this output works a little more
    ---------------------------------------------------------------------------------------------
    ```


## screen_ruler

This is a utility to help make sure things are being places on the screen in the correct location. The first line gives a 1-10(0) count, and the second line is the counts of 10.

```sh
    ---------------------------------------------------------------------------------------------
    123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123
             1         2         3         4         5         6         7         8         9
    ---------------------------------------------------------------------------------------------
```

## add_space
This is used for outputting blank spaces. This is used by the below functions. 
- [format_output](#format_output)
- [screen_ruler](#screen_ruler)
- [help_menu_format](#help_menu_format)

Usage - add a number of spaces:
```sh
add_space 20
```

Usage - in a function:
```sh
echo -e "|$(add_space 20)Adding data to output|"

#Output:
|                    Adding data to output|
```


## cut_text_for_wrapping
This is used by the [help_menu_format](#help_menu_format) function to help cut text for warpping the text.

Usage - in a fuctnion:
```sh
cut_text_for_wrapping 20 "The quick brown fox jumps over the lazy dog."

#Output:
The quick brown fox
jumps over the lazy
dog.

#Instead of:
The quick brown fox jumps over the lazy dog.
```

You provided the length of space that you want to use to wrap the text. And then it will cut up the text to make it so it's not cutting between words. 

## help_menu_format

        script_def=$( echo "$input" | egrep -o "<def>.*</def>" | sed 's/<def>//g' | sed 's/<\/def>//g' )
        script_examples=$( echo "$input" | egrep -o "<examples>[0-9a-zA-Z -.]?*<details>[0-9a-zA-Z -.]?*</details></examples>" )
        script_flags=$( echo "$input" |  egrep -o "<flags>[0-9a-zA-Z -.|]?*<details>[0-9a-zA-Z -.|]?*</details>(<requires>[0-9a-zA-Z -.|]?*</requires>)?*</flags>" )
        script_main_flags=$( echo "$input" | egrep -o "<main_flags>[0-9a-zA-Z -.|]?*<details>[0-9a-zA-Z -.|]?*</details></main_flags>" )
        script_helper_flags=$( echo "$input" | egrep -o "<helper_flags>[0-9a-zA-Z -.|]?*<details>[0-9a-zA-Z -.|]?*</details></helper_flags>" )
        script_system_flags=$( echo "$input" | egrep -o "<system_flags>[0-9a-zA-Z -.|]?*<details>[0-9a-zA-Z -.|]?*</details></system_flags>" )


## validate_xml()
{

        if [[ -n $XML_FILE ]]; then
                #variable exists, check if it's a file
                if [[ ! -f $XML_FILE ]]; then
                        # Found it's not a file, check if XML_FILE_URL variable is set to pull the file from
                        if [[ -n $XML_FILE_URL ]]; then
                                #attempt to pull the file from the URL if it exists
                                wget -O $XML_FILE $XML_FILE_URL
                        else
                                echo "It would appear that Both the XML_FILE and XML_FILE_URL variables are NOT currently valid. Please set those in the main script and this should resolve the XML import issue."
                                echo "XML_FILE : should be the absolute path to the XML file you would like to load"
                                echo "XML_FILE_URL : Should be a backup location where the file is stored that the script can pull it from if is doesn't exist."
                                exit 1
                        fi
                fi
        elif [[ -z $XML_FILE ]]; then
                # XML_FILE variable is empty or not set
                echo "Must set the XML file varialbe within the main script. Variable to use is \"XML_FILE\"."
                exit 1
        fi
}


## extract_file_content

## extract_file_content_with_filename

## progress_bar

## xhere 
    Test : Made it here"
    "wait"
