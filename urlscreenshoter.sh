#!/bin/zsh

# Default values
output_folder="."

# Parse command-line options
while getopts ":o:n:" opt; do
  case $opt in
    o)
      output_folder="$OPTARG"
      ;;
    n)
      screenshots_folder="screenshots_$OPTARG"
      html_file="result_$OPTARG.html"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Create the output folder if it doesn't exist
mkdir -p "$output_folder"

# Create the HTML file structure with CSS styling for a grid
echo "<html>
<head>
  <title>Screenshot and Web Information</title>
  <style>
    .screenshot-box {
      display: flex;
      flex-direction: column;
      align-items: center;
      margin: 20px;
    }

    img {
      max-width: 100%; /* Set maximum width for images */
      height: auto;    /* Maintain aspect ratio */
    }
  </style>
</head>
<body>" > "${output_folder}/${html_file}"

# Create the screenshots folder
mkdir -p "${output_folder}/${screenshots_folder}"

# Read URLs from standard input
while read -r url; do
  filename="${screenshots_folder}/$(date +"%Y%m%d%H%M%S")_$(echo $url | sed 's/[^a-zA-Z0-9]/_/g')"

  # Capture screenshot in the screenshots folder
  screenshot_file="${output_folder}/${filename}.png"
  chromium --headless --disable-gpu --screenshot="$screenshot_file" "$url"

  # Use curl to get HTTP status code
  http_code=$(curl -Is "$url" | head -1 | awk '{print $2}')

  # Extract title from the page
  title=$(chromium --headless --disable-gpu --dump-dom "$url" | grep -oP '<title>\K.*?(?=<\/title>)')

  # Append information to the HTML file in a box
  echo "<div class='screenshot-box'>
    <h2>$title</h2>
    <p><strong>HTTP Status Code:</strong> $http_code</p>
    <img src='${filename}.png' alt='Screenshot for $url' />
  </div><hr>" >> "${output_folder}/${html_file}"

  # Notify user
  echo "Information captured for $url."
done

# Close the HTML file
echo "</body>
</html>" >> "${output_folder}/${html_file}"

# Notify user
echo "HTML file generated: ${output_folder}/${html_file}"
echo "Screenshots saved in: ${output_folder}/${screenshots_folder}"

