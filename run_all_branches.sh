#!/bin/bash

# List of branches to run the script on
branches=("dy" "dy-align" "dy-align-blk" "guided" "guided-align" "guided-align-blk" "static" "static-align" "static-align-blk")

# Path to the run_conv_server.sh script
script_path="./run_conv_server.sh"

# Loop through each branch
for branch in "${branches[@]}"; do
    echo "Checking out branch: $branch"
    git checkout $branch

    # Run the script
    echo "Running script on branch: $branch"
    bash $script_path

    # Add and commit the results to the repository
    git add *.csv
    git commit -m "Save output data for branch ${branch}"
done

# Push all changes to the remote repository
git push origin --all

echo "All branches processed and results pushed to remote repository."