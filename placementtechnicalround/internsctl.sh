#!/bin/bash
SCRIPT_VERSION="0.1.0"
display_help() {
    # Display man page
    man ./internsctl.man
}
display_version() {
    echo "v$SCRIPT_VERSION"
}
display_cpu() {
    lscpu
}
display_mem() {
    free
} 
file_usage() {
  echo "Usage: $0 file getinfo [options] <file-name>"
  echo "Options:"
  echo "  --size, -s           Print size"
  echo "  --permissions, -p    Print file permissions"
  echo "  --owner, -o          Print file owner"
  echo "  --last-modified, -m  Print last modified date"
  exit 1
}
print_size=0
print_permissions=0
print_owner=0
print_last_modified=0
print_all=0
get_info() {
  local file="$1"
  if [ ! -e "$file" ]; then
    echo "File '$file' does not exist."
    exit 1
  fi
  echo "File: $file"
  if [ "$print_size" -eq 1 ] || [ "$print_all" -eq 1 ]; then
    echo "Size(B): $(stat -c %s "$file")"
  fi
  if [ "$print_permissions" -eq 1 ] || [ "$print_all" -eq 1 ]; then
    echo "Access: $(stat -c %A "$file")"
  fi
  if [ "$print_owner" -eq 1 ] || [ "$print_all" -eq 1 ]; then
    echo "Owner: $(stat -c %U "$file")"
  fi
  if [ "$print_last_modified" -eq 1 ] || [ "$print_all" -eq 1 ]; then
    echo "Modify: $(stat -c %y "$file")"
  fi
}
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h | --help | -\?)
            display_help
            exit 0
            ;;
        -v | --version)
            display_version
            exit 0
            ;;
        *)
            break
            ;;
    esac
    shift
done
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 ((cpu|memory) getinfo) | (user (create|list) | file getinfo [options] <file-name>)"
    exit 1
fi
command=$1
subcommand=$2
if [[ $command != "cpu" && $command != "memory" && $command != "user" && $command != "file" ]]; then
    echo "Error: Invalid command. Use cpu | memory | user | file"
    exit 1
fi
if [[ $command == "cpu" ]]; then
    if [[ $subcommand != "getinfo" ]]; then
        echo "Usage: internsctl cpu getinfo"
        exit 1
    fi
    display_cpu
elif [[ $command == "memory" ]]; then
    if [[ $subcommand != "getinfo" ]]; then
        echo "Usage: internsctl memory getinfo"
        exit 1
    fi
    display_mem
elif [[ $command == "user" ]]; then
    if [[ $subcommand == "list" ]]; then
        if [[ $3 == "--sudo-only" ]]; then
            getent group sudo | cut -d: -f4
            exit 1
        fi
        echo "Listing users"
        getent passwd | cut -d: -f1,6
        exit 1
    elif [[ $subcommand == "create" ]]; then
        new_user=$3
        if [[ -z "$new_user" ]]; then
            echo "Error: Username not provided."
            exit 1
        fi
        # Create the user and set up the home directory
        sudo useradd -m "$new_user"
        if [[ $? -eq 0 ]]; then
            echo "User '$new_user' created successfully."
        else
            echo "Error: Failed to create user '$new_user'."
            exit 1
        fi
        exit 1
    fi
elif [[ $command == "file" ]]; then
    if [[ $subcommand != "getinfo" ]]; then
        echo "Error: usage: $0 file getinfo [--options] <filename>"
    fi
    shift 2
    while [[ $# -gt 0 ]]; do
    case "$1" in
        -s | --size)
        print_size=1
        shift
        ;;
        -p | --permissions)
        print_permissions=1
        shift
        ;;
        -o | --owner)
        print_owner=1
        shift
        ;;
        -m | --last-modified)
        print_last_modified=1
        shift
        ;;
        *)
        if [ -z "$file" ]; then
            file="$1"
        else
            echo "Unknown option or too many arguments: $1"
            usage
        fi
        shift
        ;;
    esac
    done
    if [ -z "$file" ]; then
        echo "File name is required."
        usage
    fi
    if [ "$print_size" -eq 0 ] && [ "$print_permissions" -eq 0 ] && [ "$print_owner" -eq 0 ] && [ "$print_last_modified" -eq 0 ]; then
        print_all=1
    fi
    get_info "$file"
    exit 1
fi