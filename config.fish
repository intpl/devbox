function oc; opencode --auto $argv; end

function v; vim $argv; end
function vi; vim -u NONE $argv; end
function cdi;cd ~/work/; end
function cdv;cd ~/code/void-packages; end
function svim; sudo -E vim $argv; end

function ll; eza -l $argv; end
function la; eza -la $argv; end
function l; eza -a $argv; end
function lt; eza -T $argv; end
function lh; du -h . --max-depth=1; end
function mkdircd; mkdir $argv; cd $argv; end

function xi; sudo apt update ; sudo apt install $argv; end
function xisu; sudo apt update ; sudo apt full-upgrade;end
function xrs; sudo apt search $argv; end
function aptgetupdateshit; xisu;end

function posix-source
  for i in (cat $argv)
    set arr (echo $i |tr = \n)
    set -gx $arr[1] $arr[2]
  end
end

function fishcognito
  echo "private mode"
  env fish_history='' fish
  echo "normal mode"
end

function parse_git_branch
  set -l branch (git rev-parse --abbrev-ref HEAD 2> /dev/null)
  set -l git_diff (git diff)

  if test -n "$git_diff"
    echo (set_color brred)$branch(set_color normal)
  else
    echo (set_color green)$branch(set_color normal)
  end
end

function fish_prompt
  set -l git_dir (git rev-parse --git-dir 2> /dev/null)

  set_color blue
  printf 'podman dev :: '
  set_color normal

  if test -n "$git_dir"
    printf '%s%s:%s%s' (set_color $fish_color_cwd) (prompt_pwd) (parse_git_branch) (set_color normal)
  else
    printf '%s%s%s' (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
  end

  printf '%s > %s' (set_color blue) (set_color normal)
end

function fish_greeting
end

export FZF_DEFAULT_COMMAND='fd --type f --color=never'
export FZF_ALT_C_COMMAND='fd --type d . --color=never'
export TAG_SEARCH_PROG="rg"
export FZF_DEFAULT_OPTS='-x'

set -U FZF_LEGACY_KEYBINDINGS 0

# colorized man pages
set -x LESS_TERMCAP_mb (printf "\e[01;31m")
set -x LESS_TERMCAP_md (printf "\e[01;31m")
set -x LESS_TERMCAP_me (printf "\e[0m")
set -x LESS_TERMCAP_se (printf "\e[0m")
set -x LESS_TERMCAP_so (printf "\e[01;44;33m")
set -x LESS_TERMCAP_ue (printf "\e[0m")
set -x LESS_TERMCAP_us (printf "\e[01;32m")

set -x LC_ALL en_US.UTF-8
set -x LC_CTYPE en_US.UTF-8

set --export PATH $HOME/.config/emacs/bin $PATH
set --export PATH $HOME/.local/bin $PATH


function new_project
    if test (count $argv) -eq 0
        echo "Usage: new_project <project-name>"
        return 1
    end

    mkdir $argv[1]
    cd $argv[1]
    git init
    git commit --allow-empty -m "init"
end
