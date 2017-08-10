#!/bin/sh


# Things this script does:
# Creates a bash_profile if it doesn't exist and chowns it to admin
# Installs homebrew
# Updates homebrew formulae
# brew installs:
#   - git
#   - openssl
#   - vim
#   - node
#   - rbenv
#   - ruby-build
#   - yarn
#   - postgres
#   - redis

fancy_echo() {
  local fmt="$1"; shift
  printf "\n$fmt\n" "$@"
}


append_to_bash_profile() {
  local text="$1"
  local bash_profile="$HOME/.bash_profile"
  local skip_new_line="${2:-0}"


  if ! grep -Fqs "$text" "$bash_profile"; then
    if [ "$skip_new_line" -eq 1 ]; then
      printf "%s\n" "$text" >> "$bash_profile"
    else
      printf "\n%s\n" "$text" >> "$bash_profile"
    fi
  fi
}

gem_install_or_update() {
  if gem list "$1" --installed > /dev/null; then
    gem update "$@"
  else
    gem install "$@"
    rbenv rehash
  fi
}

if [ ! -f "$HOME/.bash_profile" ]; then
  touch "$HOME/.bash_profile"
fi

HOMEBREW_PREFIX="/usr/local"

if [ -d "$HOMEBREW_PREFIX" ]; then
  if ! [ -r "$HOMEBREW_PREFIX" ]; then
    sudo chown -R "$LOGNAME:admin" /usr/local
  fi
else
  sudo mkdir "$HOMEBREW_PREFIX"
  sudo chflags norestricted "$HOMEBREW_PREFIX"
  sudo chown -R "$LOGNAME:admin" "$HOMEBREW_PREFIX"
fi

if ! command -v brew >/dev/null; then
  fancy_echo "Installing Homebrew ..."
    curl -fsS \
      'https://raw.githubusercontent.com/Homebrew/install/master/install' | ruby

    append_to_bash_profile '# recommended by brew doctor'
    append_to_bash_profile 'export PATH="/usr/local/bin:$PATH"' 1

    export PATH="/usr/local/bin:$PATH"
fi

if brew list | grep -Fq brew-cask; then
  fancy_echo "Uninstalling old Homebrew-Cask ..."
  brew uninstall --force brew-cask
fi

fancy_echo "Updating Homebrew formulae ..."
brew update
brew bundle --file=- <<EOF
tap "homebrew/services"

brew "git"
brew "openssl"
brew "vim"
brew "node"
brew "rbenv"
brew "ruby-build"
brew "yarn"
brew "postgres", restart_service: :changed
brew "redis", restart_service: :changed

EOF

fancy_echo "Configuring Ruby ..."
find_latest_ruby() {
  rbenv install -l | grep -v - | tail -1 | sed -e 's/^ *//'
}

ruby_version="$(find_latest_ruby)"
# shellcheck disable=SC2016
append_to_zshrc 'eval "$(rbenv init - --no-rehash)"' 1
eval "$(rbenv init -)"

if ! rbenv versions | grep -Fq "$ruby_version"; then
  RUBY_CONFIGURE_OPTS=--with-openssl-dir=/usr/local/opt/openssl rbenv install -s "$ruby_version"
fi

rbenv global "$ruby_version"
rbenv shell "$ruby_version"
gem update --system
gem_install_or_update 'bundler'


fancy_echo "Things left to do:"
fancy_echo "+ XCode"
fancy_echo "+ Slack"
fancy_echo "+ iTerm2"
