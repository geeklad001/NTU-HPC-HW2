#!/bin/bash

# List of branches to run the script on
branches=("dy" "guided" "static")

# Path to the run_conv_server.sh script
non_openmp_script_path="./run_conv_non_openmp.sh"
openmp_script_path="./run_conv_openmp.sh"

# Loop through each branch
bash $non_openmp_script_path
for branch in "${branches[@]}"; do
    echo "Checking out branch: $branch"
    git checkout $branch

    # Run the script
    echo "Running script on branch: $branch"
    bash $openmp_script_path

    # Add and commit the results to the repository
    git add *.csv
    git commit -m "Save output data for branch ${branch}"
done

# Push all changes to the remote repository
git push origin --all

echo "All branches processed and results pushed to remote repository."