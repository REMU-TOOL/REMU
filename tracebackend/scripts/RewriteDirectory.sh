#!/bin/sh

txt2str() {
    if [ "$#" -ne 2 ]; then
        echo "Usage: $0 input_file output_file"
        exit 1
    fi

    input_file="$1"
    output_file="$2"

    # check input file exist
    if [ ! -f "$input_file" ]; then
        echo "Error: Input file '$input_file' does not exist."
        exit 1
    fi

    # add string prefix and suffix
    header="R\"(\n"
    footer="\n)\""

    printf "$header" > "$output_file"
    cat "$input_file" >> "$output_file"
    printf "$footer" >> "$output_file"
}

# Check the number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 input_direcory output_directory"
    exit 1
fi

input_directory="$1"
output_directory="$2"

# Check if the directory exists
if [ ! -d "$input_directory" ]; then
    echo "Error: Directory '$input_directory' does not exist."
    exit 1
fi

if [ ! -d "$output_directory" ]; then
    mkdir -p $output_directory
fi

# Traverse all files in the directory
for file in "$input_directory"/*; do
    if [ -f "$file" ]; then
        # Extract the filename without extension
        base_name=$(basename "$file")
        file_name="${base_name%.*}"
        
        # Build the output filename with .inc extension
        output_file="${output_directory}/${file_name}.inc"
        
        # Call the prepend_append.sh script
        txt2str "$file" "$output_file"
    fi
done