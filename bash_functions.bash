## Possibly adding a global function that will allow for help outputs to all contain the same output info.


# Colorization - Most people like colors so bringing a rainbow
function MakePretty()
{

        # Colors and formatting things to make the output nicer to read
        div='--------------------------------------------------------------------------------';

        # Taste the rainbow
        # Add color optionns
        BLACK=$(tput setaf 0);          RED=$(tput setaf 1)
        GREEN=$(tput setaf 2);          YELLOW=$(tput setaf 3)
        BLUE=$(tput setaf 4);           PURPLE=$(tput setaf 5)
        CYAN=$(tput setaf 6);           WHITE=$(tput setaf 7)
        # Add text formatting options
        BRIGHT=$(tput bold);            NORMAL=$(tput sgr0)
        BLINK=$(tput blink);            REVERSE=$(tput smso)
        UNDERLINE=$(tput smul);

        if [[ $1 == '-n' ]]; then
                # No color mode :-(
                info(){ echo -e "${1}"; }
                progress(){ echo -e "${1}"; }
                alert(){ echo -e "${1}"; }
                warning(){ echo -e "${1}"; }
                # The same but with a tab indent
                info_tab(){ echo -e "\t${1}"; }
                progress_tab(){ echo -e "\t${1}"; }
                alert_tab(){ echo -e "\t${1}"; }
                warning_tab(){ echo -e "\t${1}"; }
        else
                # Colors for alerting
                info(){ echo -e "${BRIGHT}${GREEN}${1}${NORMAL}"; }
                progress(){ echo -e "${BRIGHT}${BLUE}${1}${NORMAL}"; }
                alert(){ echo -e "${BRIGHT}${YELLOW}${1}${NORMAL}"; }
                warning(){ echo -e "${BRIGHT}${RED}${1}${NORMAL}"; }
                warning_blink(){ echo -e "${BRIGHT}${BLINK}${RED}${1}${NORMAL}"; }
                # The same but with a tab indent
                info_tab(){ echo -e "\t${BRIGHT}${GREEN}${1}${NORMAL}"; }
                progress_tab(){ echo -e "\t${BRIGHT}${BLUE}${1}${NORMAL}"; }
                alert_tab(){ echo -e "\t${BRIGHT}${YELLOW}${1}${NORMAL}"; }
                warning_tab(){ echo -e "\t${BRIGHT}${RED}${1}${NORMAL}"; }
        fi
}


function confirm_load()
{
        test_failure=$( echo "$@" | grep -o "<test>" )

        number_of_procs=$(nproc)
        oneminute_loadaverage=$( w | egrep -o "load average:.*$" | awk '{print $3}' | sed 's/,//g' )

        # Adding test failure into the function
        if [[ -n $test_failure ]]; then
                echo "Setting test failure"
                oneminute_loadaverage=$(( $number_of_procs * 2 ))
        fi

        if awk "BEGIN {exit !($oneminute_loadaverage >= $number_of_procs)}";
        then
                while true; do
                        warning "Current Server Load is over the number of Procs : $number_of_procs.\nWould you like to perform the Opts check anyways? (y|n)\n"
                        read -p ":" _answer
                        _answer=$(echo $_answer|tr '[:upper:]' '[:lower:]')
                        if [[ $_answer == "y" ]]; then
                                break
                        elif [[ $_answer == "n" ]]; then
                                info "Stopping script"
                                exit
                        else
                                warning " Incorrect answer, must be (y or n)"
                                continue
                        fi
                done

        fi
}


function break_line()
{
        local output default_number_of_symbols default_symbol symbol number_of_symbols
        output=""
        default_number_of_symbols=$(( $(tput cols) - 1 ))
        terminal_cols="$default_number_of_symbols"
        default_symbol="-"
        # If a symbol not passed to function use default
        symbol=$(echo $@ |tr ' ' '\n'|egrep -v "[0-9]|full")
        if [[ -z $symbol ]]; then
                symbol=$default_symbol
        fi

        # If number of symbols not passed to function use default
        number_of_symbols=$(echo $@|egrep -o "[0-9]{1,3}|full")
        if [[ $number_of_symbols == "full" ]]; then
                number_of_symbols=$terminal_cols
        elif [[ -z $number_of_symbols ]]; then
                number_of_symbols=$default_number_of_symbols
        fi

        # populate output variable with the number and type of symbol provided
        for x in $( seq 0 $number_of_symbols ); do
                output+="${symbol}"
        done

        # Output the line to terminal
        echo "$output"
}


function clean_script_backup_files()
{
        self="${0##*/}"
        break_line
        iter_var=1
        sleep_pause=$( echo $@|egrep -o "[0-9]" )
        if [[ -z $sleep_pause ]]; then
                sleep_pause=2
        fi

        # Test 2 : global check using find
        echo "This process will only pull the backup files that were found within /etc"
        alert "Pulling a list of the backups, this may take some time."
        self_no_extention=$( echo ${self}| cut -d"." -f1)
        script_backups=$( find /etc -type f -iname "*${self_no_extention}*backup" )

        if [[ -n $script_backups ]]; then
                printf "Here is a current list of the ${self} backup files\n"
                for x in $(echo $script_backups); do
                        echo "$iter_var : $x"
                        iter_var=$(( $iter_var + 1 ))
                done
        else
                printf "No current backups found\n\n"
                exit
        fi
        while true; do
                printf "\nWhich backup's would you like to remove? Please enter in 1-4,9,11,14 type format.\n"
                read -p ":" _backupsremoving
                confirm_valid_requests=$( echo $_backupsremoving | egrep -o "[a-zA-Z]?*" | egrep -v "ALL|FILES" )
                if [[ -n $confirm_valid_requests ]]; then
                        warning "It appears that Letters were provided, you will need to try again using only numbers."
                        continue
                else
                        break
                fi
        done
        _backupsremoving="$(echo $_backupsremoving|egrep -o "(ALL_FILES|[0-9]{1,3}(-[0-9]{1,3}(,| |$)| |,|$)|\*)"|sed 's/,//g')"
        backup_files_removing=""

        if [[ -n $_backupsremoving ]]; then
                for x in $(echo "$_backupsremoving"); do
                        if [[ $x == "ALL_FILES" ]]; then
                                backup_files_removing=$(echo "$script_backups")
                        else
                                check_for_multi=$(echo $x|grep "-")
                                if [[ -n $check_for_multi ]]; then
                                        start_number=$(echo "$check_for_multi"|cut -d"-" -f1)
                                        end_number=$(echo "$check_for_multi"|cut -d"-" -f2)
                                        for y in $(seq $start_number $end_number); do
                                                backup_files_removing=$(echo -e "${backup_files_removing}\n$(echo "$script_backups"|head -${y}|tail -1)")
                                        done
                                else
                                        backup_files_removing=$(echo -e "${backup_files_removing}\n$(echo "$script_backups"|head -${x}|tail -1)")
                                fi
                        fi
                done

        fi

        break_line
        printf "Here is a list of the backups we will be removing, type y to confirm\n"
        printf "$backup_files_removing\n"
        read -p ":" _delete_confirmation

        if [[ $_delete_confirmation == "y" ]]; then
                printf "Removing files\n"
                for x in $(echo "$backup_files_removing"); do

                        printf "Deleteing : $x\n"
                        sleep $sleep_pause
                        find $x -delete
                done
                printf "Removal Complete\n"

        else
                printf "Confirmation not approved (y), not removing files.\n"
        fi
}


function format_output()
{
        inputs="$@"
        line_1=1
        declare -A col_size_max
        terminal_cols=$(( $(tput cols) - 1 ))
        check_for_bulk_columns=$(for x in $( echo -e "$inputs"|awk '{print $1}' ); do echo $x ; done|sort|uniq|egrep -o "bulk_column_output")
        check_for_bulk=$(for x in $( echo -e "$inputs"|awk '{print $1}' ); do echo $x ; done|sort|uniq|egrep -o "bulk_output")
        check_for_columns=$(for x in $( echo -e "$inputs"|awk '{print $1}' ); do echo $x ; done|sort|uniq|egrep -o "<[0-9]{1,2}>"|cut -d">" -f1|cut -d"<" -f2)
        add_space() {
                count=$1
                space=""
                for x in $(seq 1 $count); do
                        space+=" "
                done

                echo "$space"
        }
        if [[ $check_for_bulk == "bulk_output" ]]; then
                col_length=$(( $terminal_cols - 15 ))
                while read line; do
                        first_line_output=$(echo $line | awk '{for (i=2; i<=NF; i++) print $i}')
                        if [[ $line_1 == 1 ]]; then
                                line_1=0
                                break_line "=" $terminal_cols
                                echo $first_line_output
                                break_line "=" $terminal_cols
                        else
                                echo "$line"
                        fi
                done <<<  "$(echo -e "$inputs")"
                break_line $terminal_cols

        elif [[ $check_for_bulk_columns == "bulk_column_output" ]]; then
                max_length=0
                if [[ -n $check_for_columns ]]; then
                        columns=$(echo -n "$check_for_columns")
                else
                        columns=6
                fi
                for x in $(seq 1 $columns); do
                        size=$((  $(for y in $( echo -e "$inputs"|egrep "<column>"|sed 's/<column> //g'|sed 's/<block> //g'|awk -v var="$x" '{print $var}' ); do echo $y |wc -c; done|sort -rn|head -1 )  + 5  ))
                        col_size_max[$x]="$size"
                        max_length=$(( $max_length + ${col_size_max[$x]}  ))
                done
                while read line; do
                        line_output=""
                        first_line_output=$(echo $line | awk '{for (i=2; i<=NF; i++) print $i}')
                        column_sort_check=$(echo $line |egrep "<column>")
                        block_check=$(echo $line |egrep "<block>")
                        if [[ $line_1 == 1 ]]; then
                                line_1=0
                                break_line "=" $terminal_cols
                                echo $first_line_output
                                break_line "=" $terminal_cols
                        elif [[ -n $column_sort_check ]]; then
                                line_output=""
                                for col in $(seq 1 $columns); do
                                        column="$(echo -e "$line" |sed 's/<column> //g'|sed 's/<block> //g'| awk -v var="$col" '{print $var}' )"
                                        line_output+="$(echo "$column$(add_space $(( ${col_size_max[$col]} - $( echo -n "$column" | wc -c ) )) )")"
                                done
                                if [[ -n $block_check ]]; then
                                        break_line $terminal_cols
                                        echo "${line_output}"
                                        break_line $terminal_cols
                                else
                                        echo "${line_output}"
                                fi
                        else
                                echo $line
                        fi
                done <<<  "$(echo -e "$inputs")"
                break_line $terminal_cols

        else
                max_length=0
                if [[ -n $check_for_columns ]]; then
                        columns=$(echo -n "$check_for_columns")
                else
                        columns=6
                fi

                for x in $(seq 1 $columns); do
                        size=$((  $(for y in $( echo -e "$inputs"|awk -v var="$x" '{print $var}' ); do echo $y |wc -c; done|sort -rn|head -1 )  + 5  ))
                        col_size_max[$x]="$size"
                        max_length=$(( $max_length + ${col_size_max[$x]}  ))
                done
                while read line; do
                        line_output=""
                        for col in $(seq 1 $columns); do
                                column="$(echo -e "$line" | awk -v var="$col" '{print $var}' )"
                                line_output+="$(echo "$column$(add_space $(( ${col_size_max[$col]} - $( echo -n "$column" | wc -c ) )) )")"
                        done

                        if [[ $line_1 == 1 ]]; then
                                line_1=0
                                break_line "=" $max_length
                                echo "${line_output}"
                                break_line "=" $max_length
                        else
                                echo "${line_output}"
                        fi
                done <<< $(echo -e "$inputs")
                break_line "-" $max_length
        fi
        unset col_size_max
}


function backup_file()
{
        pre_backup_file="$1"
        self_name=$(echo "$self" | cut -d"." -f1)

        if [[ $2 == "prerestore" ]]; then
                # backup file before restoring one
                # modifies the name of the backup
                if [[ -f $pre_backup_file ]]; then
                        post_backup_file="$(echo "${pre_backup_file}_${self_name}_$(date +"%b-%d-%Y_%T").prerestore_backup")"
                        pre_backup_with_entry_number=$(echo "${entry}/${pre_backup_file}")
                        cp -va ${pre_backup_file} ${post_backup_file} | sed "s/'//g"
                else
                        echo "No File Provided"
                        exit 0
                fi
        else
                # Backup file
                if [[ -f $pre_backup_file ]]; then
                        post_backup_file="$(echo "${pre_backup_file}_${self_name}_$(date +"%b-%d-%Y_%T").backup")"
                        pre_backup_with_entry_number=$(echo "${entry}/${pre_backup_file}")
                        cp -va ${pre_backup_file} ${post_backup_file} | sed "s/'//g"
                else
                        echo "No File Provided"
                        exit 0
                fi
        fi
}


function restore_file()
{
        file_restoring="$1"
        restore_location="$2"
        restore_output=""
        # confirm file restoring is a file, exit if not
        if [[ ! -f $file_restoring ]]; then
                echo "Provided File we are restoring is not valid. Exiting script."
                exit 1
        fi

        # Confirm restore location provided
        if [[ -z $restore_location ]]; then
                # need to pull one from the user
                ## Restore_file : pull restore location from the filename provided
                while true; do
                        echo "Restore location not provided. Please provided the file we are replacing"
                        read -p ": " _location
                        if [[ -z $_location ]]; then
                                echo "No file provided, existing process"
                                exit 1
                        elif [[ -n "$_location" ]]; then
                                touch_test=$(touch $_loction)
                                if [[ -z $touch_test ]]; then
                                        restore_location="$_location"
                                        break
                                else
                                        echo "Invalid Restore location. Please try again"
                                        continue
                                fi
                        else
                                echo "Invalid Restore location. Please try again"
                                continue
                        fi
                done

        fi

        # confirm Live file is a file, exit if not backup if it is
        if [[ ! -f $restore_location ]]; then
                touch_test=$(touch $restore_location)
                if [[ -n $touch_test ]]; then
                        echo "There is an issue with the $restore_location being used. Please try again"
                        exit 1
                fi
        else
                ## backup current live file
                restore_output+="$( backup_file "$restore_location" "prerestore" | sed "s/'//g" )\n"
        fi
        restore_output+="$(cp -va $file_restoring $restore_location | sed "s/'//g")\n"
        echo -e "$restore_output"

}


function screen_ruler() {
        full_terminal_cols=$(( $(tput cols) - 1 ))
        full_term_divide_ten=$(( $full_terminal_cols / 10  ))
        left_over_term_cols=$(( $full_terminal_cols - $(( $full_term_divide_ten * 10 )) ))
        full_line=""
        break_line $full_terminal_cols
        for x in $( seq 1 $full_term_divide_ten ); do
                full_line+="1234567890"
        done
        if [[ $left_over_term_cols != 0 ]]; then
                for x in $( seq 1 $left_over_term_cols ); do
                        full_line+="$x"
                done
        fi
        echo "$full_line"

        seq_num=1
        full_line=""
        for x in $( seq 1 $full_term_divide_ten ); do
                if [[ $seq_num == 10 ]]; then
                        seq_num=0
                fi
                full_line+="$( add_space 9)$seq_num"
                seq_num=$(( $seq_num + 1  ))
        done
        echo "$full_line"
        break_line $full_terminal_cols
}


# used to add a specific amount of Blank space between outputs
function add_space()
{
        count=$1
        space=""
        for x in $(seq 1 $count); do
                space+=" "
        done
        echo "$space"
}


# Cut text to match specific spacing so it can be wrapped
function cut_text_for_wrapping()
{
        #variables pulled from arguments passed to function
        length=$( echo "$1" | egrep -o '[0-9]?*' )
        text_to_wrap=$( echo "$@" | tr '\n' ' ' | awk -v n=2 '{ for (i=n; i<=NF; i++) printf "%s%s", $i, (i<NF ? OFS : ORS)}' )
        text_character_count=$( echo "$text_to_wrap" | wc -c )

        #variables to edit in function
        wrapped_text=""
        cols_processed=0

        # Below can be updated to change the hard limit on length of line
        hard_limit_length=10


        #Confirm correct data has been passed and length isn't under the hardlimit
        if [[ -z $length ]] ; then
                echo "Failure : cut_text_for_wrapping : Length of text line not provided, The first variable passed must be a number."
                exit 1
        elif [[ -z $text_to_wrap ]]; then
                echo "Failure : cut_text_for_wrapping : Text variable not provided."
                exit 1
        elif (( $length <= $hard_limit_length )); then
                # this elif can be removed to have no hard limit.
                echo "Failure : cut_text_for_wrapping : Length of text line must be > $hard_limit_length"
                echo "If you must lower this limit you can edit the hard_limit_length variable in the function"
                exit 1
        fi

        if (( $text_character_count <= $length )); then
                #output full line
                wrapped_text="$text_to_wrap\n"
        else
                while true; do
                        processing_text=$( echo "${text_to_wrap:$cols_processed}" | head -c $length | sed -r 's/^[[:space:]]//g' )
                        line_end=$( echo "$processing_text" |rev |cut -d" " -f1|rev)
                        cols_left_check=$(( $text_character_count - $cols_processed ))
                        if (( $cols_left_check > $length )); then
                                if [[ -n $line_end ]]; then
                                        processing_text=$( echo "$processing_text" |sed "s/${line_end}$//g" )
                                fi
                                cols_processed=$(( $cols_processed + $( echo "$processing_text" | wc -c ) - 1 ))
                                wrapped_text+="$processing_text\n"
                        else
                                wrapped_text+="$processing_text\n"
                                break
                        fi
                done
        fi
        echo -e "$wrapped_text"

}


function help_menu_format() {
        input="$@"
        self="${0##*/}"
        script_name=$(echo "$self" | cut -d"." -f1 )
        file_name="/etc/bash_completion.d/${script_name}"
        #file_name="testing_autocomplete"
        terminal_cols=$(( $(tput cols) - 1 ))
        usage_output=""
        modify_output=""
        system_flag_output=""


        auto_complete_check=$(echo "$input"|grep -o "<auto_complete>")

        declare -A help_menu_examples
        declare -A help_menu_main_flags
        declare -A help_menu_flags
        declare -A help_menu_requires_flags
        declare -A help_menu_helper_flags
        declare -A help_menu_system_flags
        declare -A case_flag_menu

        # Set the Col1/2 start location
        col1_start=15
        col2_start=80
        col2_end=$(( $(tput cols) - 1 ))
        col2_length=$(( col2_end - col2_start ))

        script_def=$( echo "$input" | egrep -o "<def>.*</def>" | sed 's/<def>//g' | sed 's/<\/def>//g' )
        script_examples=$( echo "$input" | egrep -o "<examples>[0-9a-zA-Z -.]?*<details>[0-9a-zA-Z -.]?*</details></examples>" )
        script_flags=$( echo "$input" |  egrep -o "<flags>[0-9a-zA-Z -.|]?*<details>[0-9a-zA-Z -.|]?*</details>(<requires>[0-9a-zA-Z -.|]?*</requires>)?*</flags>" )
        script_main_flags=$( echo "$input" | egrep -o "<main_flags>[0-9a-zA-Z -.|]?*<details>[0-9a-zA-Z -.|]?*</details></main_flags>" )
        script_helper_flags=$( echo "$input" | egrep -o "<helper_flags>[0-9a-zA-Z -.|]?*<details>[0-9a-zA-Z -.|]?*</details></helper_flags>" )
        script_system_flags=$( echo "$input" | egrep -o "<system_flags>[0-9a-zA-Z -.|]?*<details>[0-9a-zA-Z -.|]?*</details></system_flags>" )

        # Create dictionary list of the current examples
        if [[ -n $script_examples ]]; then
                while read line; do
                        examples=$( echo $line | egrep -o "<examples>.*<details>" | sed 's/<examples>//g' | sed 's/<details>//g' )
                        details=$( echo $line | egrep -o "<details>.*</details>" | sed 's/<details>//g' | sed 's/<\/details>//g')
                        help_menu_examples["$examples"]="$details"
                done <<<  "$(echo -e "$script_examples")"
        fi


        # Create dictionary list of the current Main Flags
        if [[ -n $script_main_flags ]]; then
                while read line; do
                        flags=$( echo $line | egrep -o "<main_flags>.*<details>" | sed 's/<main_flags>//g' | sed 's/<details>//g' )
                        details=$( echo $line | egrep -o "<details>.*</details>" | sed 's/<details>//g' | sed 's/<\/details>//g')
                        help_menu_main_flags["${flags}"]="${details}"
                        usage_output+=" ${flags} |"
                done <<<  "$(echo -e "$script_main_flags" | sort )"
        fi

        # Create dictionary of the current helper_Flags
        if [[ -n $script_helper_flags ]]; then
                while read line; do
                        flags=$( echo $line | egrep -o "<helper_flags>.*<details>" | sed 's/<helper_flags>//g' | sed 's/<details>//g' )
                        details=$( echo $line | egrep -o "<details>.*</details>" | sed 's/<details>//g' | sed 's/<\/details>//g')
                        help_menu_helper_flags["${flags}"]="${details}"
                        usage_output+=" ${flags} |"
                done <<<  "$(echo -e "$script_helper_flags" | sort )"
        fi


        # Create dictionary list of the current modify Flags
        if [[ -n $script_flags ]]; then
                while read line; do
                        flags=$( echo $line | egrep -o "<flags>.*<details>" | sed 's/<flags>//g' | sed 's/<details>//g' )
                        details=$( echo $line | egrep -o "<details>.*</details>" | sed 's/<details>//g' | sed 's/<\/details>//g')
                        requires=$(echo $line | egrep -o "<requires>[0-9a-zA-Z -.|]?*</requires>" | sed 's/<requires>//g' | sed 's/<\/requires>//g' )
                        help_menu_flags["${flags}"]="${details}"
                        if [[ -n $requires ]]; then
                                help_menu_requires_flags["${flags}"]="$requires"
                                for y in $( echo "${requires}" | tr '|' '\n' ); do
                                        case_flag_menu[${y}]="$( echo "${case_flag_menu[${y}]} $( echo $flags | tr '|' ' ' | sed -r 's/\([0-9a-zA-Z\-]?*\)//g' )" )"
                                done
                                echo
                        fi
                        modify_output+=" ${flags} |"
                done <<<  "$(echo -e "$script_flags")"
        fi

        # Create dictionary of the current system_Flags
        if [[ -n $script_system_flags ]]; then
                while read line; do
                        flags=$( echo $line | egrep -o "<system_flags>.*<details>" | sed 's/<system_flags>//g' | sed 's/<details>//g' )
                        details=$( echo $line | egrep -o "<details>.*</details>" | sed 's/<details>//g' | sed 's/<\/details>//g')
                        help_menu_system_flags["${flags}"]="${details}"
                        system_flag_output+=" ${flags} |"
                done <<<  "$(echo -e "$script_system_flags" | sort )"
        fi

        if [[ -n $auto_complete_check ]]; then
                main_flags_autocomplete=""
                sub_flags_autocomplete=""
                system_flags_autocomplete=""

                # Check if file exists already.
                if [[ ! -f $file_name ]]; then
                        for x in ${!help_menu_main_flags[@]}; do
                                main_flags_autocomplete+="$( echo "$( echo $x )|" )"
                        done

                        for x in ${!help_menu_helper_flags[@]}; do
                                main_flags_autocomplete+="$( echo "$(echo $x)|" )"
                        done


                        for x in ${!help_menu_flags[@]}; do
                                sub_flags_autocomplete+="$( echo "$( echo $x | sed -r 's/\([0-9a-zA-Z\-]?*\)//g' )|" )"
                        done
                        sub_flags_autocomplete=$( echo "$sub_flags_autocomplete" | tr '|' ' ' | sed -r 's/[[:space:]]$//g' | sed -r 's/^[[:space:]]//g' )

                        for x in ${!help_menu_system_flags[@]}; do
                                system_flags_autocomplete+=$( echo "$(echo $x)|" )
                        done
                        system_flags_autocomplete=$( echo "$system_flags_autocomplete" | tr '|' ' ' | sed -r 's/[[:space:]]$//g' | sed -r 's/^[[:space:]]//g' )
                        main_flags_autocomplete=$( echo "${main_flags_autocomplete}|${system_flags_autocomplete}" | tr '|' ' '| sed -r 's/[[:space:]]$//g' | sed -r 's/^[[:space:]]//g' )

                        second_set_cases=""
                        for key in "${!case_flag_menu[@]}"; do
                                second_set_cases+="\t\t\"${key}\")\n"
                                second_set_cases+="\t\t\tCOMPREPLY=( \$(compgen -W \"${case_flag_menu[${key}]} ${system_flags_autocomplete}\" -- \$CurrentCompletionWord) )\n"
                                second_set_cases+="\t\t\t;;\n"
                                echo
                        done

                        echo -e "$(cat <<EOF_autocomplete
_$script_name ()\n
{\n
\tlocal CurrentCompletionWord PreviousCompletionWord\n
\tCOMPREPLY=()\n
\tCurrentCompletionWord=\${COMP_WORDS[COMP_CWORD]}\n
\tPreviousCompletionWord=\${COMP_WORDS[COMP_CWORD-1]}\n
\tif [ \$COMP_CWORD -eq 1 ]; then\n

\t\tCOMPREPLY=( \$(compgen -W "$main_flags_autocomplete" -- \$CurrentCompletionWord) )\n
\telif [ \$COMP_CWORD -eq 2 ]; then\n
\t\tcase "\$PreviousCompletionWord" in\n
$second_set_cases
\t\t*)\n
\t\t\tCOMPREPLY=( \$(compgen -W "$system_flags_autocomplete" -- \$CurrentCompletionWord) )\n
\t\t\t;;\n
\t\tesac\n
\tfi\n
\treturn 0\n
}\n
complete -F _$script_name $script_name\n
EOF_autocomplete
)" > "$file_name"
                fi

        else

                # Start output of help menu
                if [[ -n $script_def ]]; then
                        break_line "="
                        echo
                        printf "$script_def\n"
                        echo
                fi


                break_line
                usage_output="$( echo "$usage_output" | sed 's/|$//' )"
                #echo "Usage: ${self} [OPTION] [MODIFY_OPTION optional]"
                echo
                echo "Usage:  $self [$( echo "$usage_output" | sed 's/|$//' )]    [ OPTIONAL ($( echo "$modify_output" | sed 's/|$//' ) ) ]    [ $( echo "$system_flag_output" | sed 's/|$//' ) ]"
                echo

                # Processing Examples for the help menu
                if [[ -n ${!help_menu_examples[*]} ]]; then
                        break_line
                        echo
                        printf "Examples :\n"
                        for examples in "${!help_menu_examples[@]}"; do
                                detail_content_wrapped="$( cut_text_for_wrapping $col2_length $( echo "${help_menu_examples[$examples]}" ) )"
                                line1=1
                                while IFS= read -r line; do
                                        if [[ $line1 == 1 ]]; then
                                                echo -e "$( add_space $col1_start )${examples}$( add_space $((  $col2_start - $( echo "${examples}" | wc -c  ) - $col1_start ))  )${line}"
                                                line1=0
                                        else
                                                echo -e "$( add_space $col2_start)${line}" | sed -r 's/^[[:space:]]//g'
                                        fi
                                done < <(printf '%s\n' "$detail_content_wrapped")
                                echo
                        done
                fi


                # Processes Main Flags for help menu
                if [[ -n ${!help_menu_main_flags[*]} ]]; then
                        break_line
                        echo
                        printf "Options : \n"
                        ## Need to break up options into groups
                        for options in "${!help_menu_main_flags[@]}"; do
                                line1=1
                                detail_content_wrapped=$( cut_text_for_wrapping $col2_length $( echo "${help_menu_main_flags[$options]}" ) )
                                while IFS= read -r line; do
                                        if [[ $line1 == 1 ]]; then
                                                echo -e "$( add_space $col1_start )${options}$( add_space $((  $col2_start - $( echo "${options}" | wc -c  ) - $col1_start ))  )${line}"
                                                line1=0
                                        else
                                                echo -e "$( add_space $col2_start)${line}" | sed -r 's/^[[:space:]]//g'
                                        fi
                                done < <(printf '%s\n' "$detail_content_wrapped")
                                echo
                        done
                fi

                # Process helper flags
                if [[ -n ${!help_menu_helper_flags[*]} ]]; then
                        ## Need to break up options into groups
                        for options in "${!help_menu_helper_flags[@]}"; do
                                line1=1
                                detail_content_wrapped=$( cut_text_for_wrapping $col2_length $( echo "${help_menu_helper_flags[$options]}" ) )
                                while IFS= read -r line; do
                                        if [[ $line1 == 1 ]]; then
                                                echo -e "$( add_space $col1_start )${options}$( add_space $((  $col2_start - $( echo "${options}" | wc -c  ) - $col1_start ))  )${line}"
                                                line1=0
                                        else
                                                echo -e "$( add_space $col2_start)${line}" | sed -r 's/^[[:space:]]//g'
                                        fi
                                done < <(printf '%s\n' "$detail_content_wrapped")
                                echo
                        done
                fi


                # Process sub flags for help menu, non-main and non-system options
                if [[ -n ${help_menu_flags[*]} ]]; then
                        break_line
                        echo
                        printf "Modify Options : \n"
                        ## Need to break up options into groups
                        for options in "${!help_menu_flags[@]}"; do
                                line1=1
                                detail_content_wrapped=$( cut_text_for_wrapping $col2_length $( echo "${help_menu_flags[$options]}" ) )
                                while IFS= read -r line; do
                                        if [[ $line1 == 1 ]]; then
                                                echo -e "$( add_space $col1_start )${options}$( add_space $((  $col2_start - $( echo "${options}" | wc -c  ) - $col1_start ))  )${line}"
                                                line1=0
                                        else
                                                echo -e "$( add_space $col2_start)${line}" | sed -r 's/^[[:space:]]//g'
                                        fi

                                done < <(printf '%s\n' "$detail_content_wrapped")
                                # Required Flags
                                required_flags="${help_menu_requires_flags[$options]}"
                                if [[ -n $required_flags ]]; then
                                        flag1=1
                                        for flags in $( echo "$required_flags" ); do
                                                if [[ $flag1 == 1 ]]; then
                                                        echo "$( add_space 79 )Used with : $flags"
                                                        flag1=0
                                                else
                                                        echo "$( add_space 91 )$flags"
                                                fi
                                        done
                                fi
                                echo
                        done
                fi


                # Output the help and verbose flags last.
                if [[ -n ${help_menu_system_flags[*]} ]]; then
                        for options in "${!help_menu_system_flags[@]}"; do
                                line1=1
                                detail_content_wrapped=$( cut_text_for_wrapping $col2_length $( echo "${help_menu_system_flags[$options]}" ) )
                                while IFS= read -r line; do
                                        if [[ $line1 == 1 ]]; then
                                                echo -e "$( add_space $col1_start )${options}$( add_space $((  $col2_start - $( echo "${options}" | wc -c  ) - $col1_start ))  )${line}"
                                                line1=0
                                        else
                                                echo -e "$( add_space $col2_start)${line}" | sed -r 's/^[[:space:]]//g'
                                        fi
                                done < <(printf '%s\n' "$detail_content_wrapped")
                                echo
                        done
                fi
        fi
        unset help_menu_examples
        unset help_menu_flags
        unset help_menu_requires_flags
        unset help_manu_main_flags
        unset help_menu_helper_flags

}


function validate_xml()
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


function extract_file_content()
{
        local arg link;
        local -a gzfiles zipfiles xzfiles regfiles;
        if [[ -n "$1" ]]; then
                for arg in "$@"; do
                        if [[ -L "$arg" ]]; then
                                link="$(readlink "$arg")";
                                if [[ -f "$link" ]]; then
                                        arg="$link";
                                else
                                        arg="${arg%/*}/${link}";
                                fi
                        fi
                        if [[ -f "$arg" ]]; then
                                case "$arg" in
                                        *.gz)
                                                gzfiles+=("$arg")
                                                ;;
                                        *.zip)
                                                zipfiles+=("$arg")
                                                ;;
                                        *.xz)
                                                xzfiles+=("$arg")
                                                ;;
                                        *)
                                                regfiles+=("$arg")
                                                ;;
                                esac;
                        fi;
                done;

                [[ -n "${gzfiles[ARRAY_START]}" ]] && zcat "${gzfiles[@]}";
                [[ -n "${zipfiles[ARRAY_START]}" ]] && zcat "${zipfiles[@]}";
                [[ -n "${xzfiles[ARRAY_START]}" ]] && xzcat "${xzfiles[@]}";
                [[ -n "${regfiles[ARRAY_START]}" ]] && cat "${regfiles[@]}";
        else
                cat;
        fi
}


function extract_file_content_with_filename()
{
        local arg link;
        local -a gzfiles zipfiles xzfiles regfiles;
        if [[ -n "$1" ]]; then
                for arg in "$@"; do
                        if [[ -L "$arg" ]]; then
                                link="$(readlink "$arg")";
                                if [[ -f "$link" ]]; then
                                        arg="$link";
                                else
                                        arg="${arg%/*}/${link}";
                                fi
                        fi
                        if [[ -f "$arg" ]]; then
                                case "$arg" in
                                        *.gz)
                                                gzfiles+=("$arg")
                                                ;;
                                        *.zip)
                                                zipfiles+=("$arg")
                                                ;;
                                        *.xz)
                                                xzfiles+=("$arg")
                                                ;;
                                        *)
                                                regfiles+=("$arg")
                                                ;;
                                esac;
                        fi;
                done;
                if [[ -n "${gzfiles[ARRAY_START]}" ]]; then
                        for x in "${gzfiles[@]}"; do
                                while IFS= read -r line ; do
                                        echo "$x:$line\n"
                                done <<< "$( zcat "${gzfiles[@]}" )"
                        done
                fi
                if [[ -n "${zipfiles[ARRAY_START]}" ]]; then
                        for x in "${zipfiles[@]}"; do
                                while IFS= read -r line ; do
                                        echo "$x:$line\n"
                                done <<< "$( zcat "${zipfiles[@]}" )"
                        done
                fi
                if [[ -n "${xzfiles[ARRAY_START]}" ]]; then
                        for x in "${xzfiles[@]}"; do
                                while IFS= read -r line ; do
                                        echo "$x:$line\n"
                                done <<< $( xzcat "${xzfiles[@]}" )
                        done
                fi
                if [[ -n "${regfiles[ARRAY_START]}" ]]; then
                        for x in "${regfiles[@]}"; do
                                while IFS= read -r line ; do
                                        echo "$x:$line\n"
                                done <<< $( cat "${regfiles[@]}" )
                        done
                fi
        else
                cat;
        fi
}


function progress_bar()
{
        if (( $1 < 2 )); then
                echo -ne '                          [0%]\r'
        elif (( $1 >= 2 )) && (( $1 < 4 )); then
                echo -ne '>                         [2%]\r'
        elif (( $1 >= 4 )) && (( $1 < 6 )); then
                echo -ne '>>                        [4%]\r'
        elif (( $1 >= 6 )) && (( $1 < 8 )); then
                echo -ne '>>>                       [6%]\r'
        elif (( $1 >= 8 )) && (( $1 < 10 )); then
                echo -ne '>>>>                      [8%]\r'
        elif (( $1 >= 10 )) && (( $1 < 20 )); then
                echo -ne '>>>>>                     [10%]\r'
        elif (( $1 >= 20 )) && (( $1 < 40 )); then
                echo -ne '>>>>>>>>                  [20%]\r'
        elif (( $1 >= 40 )) && (( $1 < 60 )); then
                echo -ne '>>>>>>>>>>>>              [40%]\r'
        elif (( $1 >= 60 )) && (( $1 < 80 )); then
                echo -ne '>>>>>>>>>>>>>>>>>>>       [60%]\r'
        elif (( $1 >= 80 )) && (( $1 < 100 )); then
                echo -ne '>>>>>>>>>>>>>>>>>>>>>>>   [80%]\r'
        elif (( $1 >= 100 )); then
                echo -ne '>>>>>>>>>>>>>>>>>>>>>>>>>>[100%]\r'
                echo -ne '\n'
        fi
}

function xhere()
{
        echo "Test : Made it here"
        if [[ $1 == "wait" ]]; then
                echo "Press enter to continue"
                read -p ":" _confirmation
        fi
}
