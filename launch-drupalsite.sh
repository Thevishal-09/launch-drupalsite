#!/usr/bin/env bash

###
# Launches Drupal using DDEV.
#
# This requires that DDEV be installed and available in the PATH, and only works in
# Unix-like environments (Linux, macOS, or the Windows Subsystem for Linux). This will
# initialize DDEV configuration, start the containers, install dependencies, and open
# Drupal in the browser.
###

# Abort this entire script if any one command fails.
set -e

# Check if DDEV is installed.
if ! command -v ddev >/dev/null; then
  echo "DDEV needs to be installed. Visit https://ddev.com/get-started for instructions."
  exit 1
fi

# Check if Composer is installed.
if ! command -v composer >/dev/null; then
  echo "Composer needs to be installed. Visit https://getcomposer.org/download/ for instructions."
  exit 1
fi

# Get the name of the current directory.
NAME=$(basename $PWD)
# If there are any other DDEV projects with this name, add a numeric suffix.
declare -i n=$(ddev list | grep --count "$NAME")
if [ $n -gt 0 ]; then
  NAME=$NAME-$(expr $n + 1)
fi

# Configure DDEV if not already done.
test -d .ddev || ddev config --project-type=drupal11 --docroot=web --php-version=8.3 --ddev-version-constraint=">=1.24.0" --project-name="$NAME"

# Start the DDEV containers.
ddev start

# Install Composer dependencies if composer.lock doesn't exist.
test -f composer.lock || ddev composer install

# Install Drush if not already installed
if ! ddev composer show drush/drush >/dev/null; then
  echo "Installing Drush..."
  ddev composer require drush/drush
fi

# Install Drupal site if not already installed.
if ! ddev drush status | grep -q 'Drupal version'; then
  echo "Installing Drupal site..."
  ddev drush site:install standard \
    --db-url=mysql://db:db@db/db \
    --site-name="My Drupal Site" \
    --account-name=admin \
    --account-pass=admin \
    --locale=en
fi

# Launch the Drupal site in the browser.
ddev launch

# Show the status of the DDEV environment.
ddev status

