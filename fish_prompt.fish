###############################################################################
#
# Prompt theme name:
#   leftspencer (from budspencer)
#
# Description:
#   a sophisticated lefty airline/powerline theme
#
# Author:
#   Joseph Tannhuber <sepp.tannhuber@yahoo.de>
#   Yuoa <burrily@gmail.com>
#
# Sections:
#   -> Color definitions
#   -> Files
#   -> Functions
#     -> Ring bell
#     -> Window title
#     -> Help
#     -> Environment
#     -> Pre execute
#     -> Directory history
#     -> Command history
#     -> Bookmarks
#     -> Sessions
#     -> Commandline editing with $EDITOR
#     -> Virtual Env segment
#     -> Git segment
#     -> Bind-mode segment
#     -> Symbols segment
#     -> Toggle functions
#     -> Command duration segment
#     -> PWD segment
#   -> Prompt initialization
#   -> Left prompt
#
###############################################################################

###############################################################################
# => Color definitions
###############################################################################

# Define colors
set -U leftspencer_night 000000 083743 445659 fdf6e3 b58900 cb4b16 dc121f af005f 6c71c4 268bd2 2aa198 859900
set -U leftspencer_day 000000 333333 666666 ffffff ffff00 ff6600 ff0000 ff0033 3300ff 00aaff 00ffff 00ff00
if not set -q leftspencer_colors
  # Values are: black dark_gray light_gray white yellow orange red magenta violet blue cyan green
  set -U leftspencer_colors $leftspencer_night
end

# Cursor color changes according to vi-mode
# Define values for: normal_mode insert_mode visual_mode
set -U leftspencer_cursors "\033]12;#$leftspencer_colors[10]\007" "\033]12;#$leftspencer_colors[5]\007" "\033]12;#$leftspencer_colors[8]\007" "\033]12;#$leftspencer_colors[9]\007"

###############################################################################
# => Files
###############################################################################

# Config file
set -g leftspencer_config "$HOME/.config/fish/leftspencer_config.fish"

# Temporary files
set -g leftspencer_tmpfile '/tmp/'(echo %self)'_leftspencer_edit.fish'

###############################################################################
# => Functions
###############################################################################

##############
# => Ring bell
##############
if set -q leftspencer_nobell
  function __leftspencer_urgency -d 'Do nothing.'
  end
else
  function __leftspencer_urgency -d 'Ring the bell in order to set the urgency hint flag.'
    echo -n \a
  end
end

#################
# => Window title
#################
function wt -d 'Set window title'
  set -g window_title $argv
  function fish_title
    echo -n $window_title
  end
end

#########
# => Help
#########
function leftspencer_help -d 'Show helpfile'
  set -l readme_file "$OMF_PATH/themes/leftspencer/README.md"
  if set -q PAGER
    if [ -e $readme_file ]
      eval $PAGER $readme_file
      else
        set_color $fish_color_error[1]
        echo "$readme_file wasn't found."
      end
  else
    open $readme_file
  end
end

################
# => Environment
################
function day -d "Set color palette for bright environment."
  set leftspencer_colors $leftspencer_day
  set leftspencer_cursors "\033]12;#$leftspencer_colors[10]\007" "\033]12;#$leftspencer_colors[5]\007" "\033]12;#$leftspencer_colors[8]\007" "\033]12;#$leftspencer_colors[9]\007"
end

function night -d "Set color palette for dark environment."
  set leftspencer_colors $leftspencer_night
  set leftspencer_cursors "\033]12;#$leftspencer_colors[10]\007" "\033]12;#$leftspencer_colors[5]\007" "\033]12;#$leftspencer_colors[8]\007" "\033]12;#$leftspencer_colors[9]\007"
end

################
# => Pre execute
################
function __leftspencer_preexec -d 'Execute after hitting <Enter> before doing anything else'
  set -l cmd (commandline | sed 's|\s\+|\x1e|g')
  if [ $_ = 'fish' ]
    if [ -z $cmd[1] ]
      set -e cmd[1]
    end
    if [ -z $cmd[1] ]
      return
    end
    set -e leftspencer_prompt_error[1]
    if not type -q $cmd[1]
      if [ -d $cmd[1] ]
        set leftspencer_prompt_error (cd $cmd[1] ^&1)
        and commandline ''
        commandline -f repaint
        return
      end
    end
    switch $cmd[1]
      case 'c'
        if begin
            [ (count $cmd) -gt 1 ]
            and [ $cmd[2] -gt 0 ]
            and [ $cmd[2] -lt $pcount ]
          end
          commandline $prompt_hist[$cmd[2]]
          echo $prompt_hist[$cmd[2]] | xsel
          commandline -f repaint
          return
        end
      case 'cd'
        if [ (count $cmd) -le 2 ]
          set leftspencer_prompt_error (eval $cmd ^&1)
          and commandline ''
          if [ (count $leftspencer_prompt_error) -gt 1 ]
            set leftspencer_prompt_error $leftspencer_prompt_error[1]
          end
          commandline -f repaint
          return
        end
      case 'day' 'night'
        if [ (count $cmd) -eq 1 ]
          eval $cmd
          commandline ''
          commandline -f repaint
          return
        end
    end
  end
  commandline -f execute
end

#####################
# => Fish termination
#####################
function __leftspencer_on_termination -s HUP -s INT -s QUIT -s TERM --on-process %self -d 'Execute when shell terminates'
  set -l item (contains -i %self $leftspencer_sessions_active_pid ^ /dev/null)
  __leftspencer_detach_session $item
end

######################
# => Directory history
######################
function __leftspencer_create_dir_hist -v PWD -d 'Create directory history without duplicates'
  if [ "$pwd_hist_lock" = false ]
    if contains $PWD $$dir_hist
      set -e $dir_hist[1][(contains -i $PWD $$dir_hist)]
    end
    set $dir_hist $$dir_hist $PWD
    set -g dir_hist_val (count $$dir_hist)
  end
end

function __leftspencer_cd_prev -d 'Change to previous directory, press H in NORMAL mode.'
  if [ $dir_hist_val -gt 1 ]
    set dir_hist_val (expr $dir_hist_val - 1)
    set pwd_hist_lock true
    cd $$dir_hist[1][$dir_hist_val]
    commandline -f repaint
  end
end

function __leftspencer_cd_next -d 'Change to next directory, press L in NORMAL mode.'
  if [ $dir_hist_val -lt (count $$dir_hist) ]
    set dir_hist_val (expr $dir_hist_val + 1)
    set pwd_hist_lock true
    cd $$dir_hist[1][$dir_hist_val]
    commandline -f repaint
  end
end

function d -d 'List directory history, jump to directory in list with d <number>'
  set -l num_items (expr (count $$dir_hist) - 1)
  if [ $num_items -eq 0 ]
    set_color $fish_color_error[1]
    echo 'Directory history is empty. '(set_color normal)'It will be created automatically.'
    return
  end
  if begin
      [ (count $argv) -eq 1 ]
      and [ $argv[1] -ge 0 ]
      and [ $argv[1] -lt $num_items ]
    end
    cd $$dir_hist[1][(expr $num_items - $argv[1])]
  else
    for i in (seq $num_items)
      if [ (expr \( $num_items - $i \) \% 2) -eq 0 ]
        set_color normal
      else
        set_color $leftspencer_colors[4]
      end
      echo '▶' (expr $num_items - $i)\t$$dir_hist[1][$i] | sed "s|$HOME|~|"
    end
    if [ $num_items -eq 1 ]
      set last_item ''
    else
      set last_item '-'(expr $num_items - 1)
    end
    echo -en $leftspencer_cursors[2]
    set input_length (expr length (expr $num_items - 1))
    read -p 'echo -n (set_color -b $leftspencer_colors[2] $leftspencer_colors[5])" ♻ Goto [e|0"$last_item"] "(set_color -b normal $leftspencer_colors[2])" "(set_color $leftspencer_colors[5])' -n $input_length -l dir_num
    switch $dir_num
      case (seq 0 (expr $num_items - 1))
        cd $$dir_hist[1][(expr $num_items - $dir_num)]
      case 'e'
        read -p 'echo -n (set_color -b $leftspencer_colors[2] $leftspencer_colors[5])" ♻ Erase [0"$last_item"] "(set_color -b normal $leftspencer_colors[2])" "(set_color $leftspencer_colors[5])' -n $input_length -l dir_num
        set -e $dir_hist[1][(expr $num_items - $dir_num)] ^ /dev/null
        set dir_hist_val (count $$dir_hist)
        tput cuu1
    end
    for i in (seq (expr $num_items + 1))
      tput cuu1
    end
    tput ed
    tput cuu1
  end
  set pcount (expr $pcount - 1)
  set no_prompt_hist 'T'
end

####################
# => Command history
####################
function __leftspencer_create_cmd_hist -e fish_prompt -d 'Create command history without duplicates'
  if [ $_ = 'fish' ]
    set -l IFS ''
    set -l cmd (echo $history[1] | fish_indent | expand -t 4)
    # Create prompt history
    if begin
        [ $pcount -gt 0 ]
        and [ $no_prompt_hist = 'F' ]
      end
      set prompt_hist[$pcount] $cmd
    else
      set no_prompt_hist 'F'
    end
    set pcount (expr $pcount + 1)
    # Create command history
    if not begin
        expr $cmd : '[cdms] ' > /dev/null
        or contains $cmd $leftspencer_nocmdhist
      end
      if contains $cmd $$cmd_hist
        set -e $cmd_hist[1][(contains -i $cmd $$cmd_hist)]
      end
      set $cmd_hist $$cmd_hist $cmd
    end
  end
  set fish_bind_mode insert
  #echo -n \a
  __leftspencer_urgency
end

function c -d 'List command history, load command from prompt with c <prompt number>'
  set -l num_items (count $$cmd_hist)
  if [ $num_items -eq 0 ]
    set_color $fish_color_error[1]
    echo 'Command history is empty. '(set_color normal)'It will be created automatically.'
    return
  end
  for i in (seq $num_items)
    if [ (expr \( $num_items - $i \) \% 2) -eq 0 ]
      set_color normal
    else
      set_color $leftspencer_colors[4]
    end
    echo -n '▶ '(expr $num_items - $i)
    set -l item (echo $$cmd_hist[1][$i])
    echo -n \t$item\n
  end
  if [ $num_items -eq 1 ]
    set last_item ''
  else
    set last_item '-'(expr $num_items - 1)
  end
  echo -en $leftspencer_cursors[4]
  set input_length (expr length (expr $num_items - 1))
  read -p 'echo -n (set_color -b $leftspencer_colors[2] $leftspencer_colors[9])" ↩ Exec [e|0"$last_item"] "(set_color -b normal $leftspencer_colors[2])" "(set_color $leftspencer_colors[9])' -n $input_length -l cmd_num
  switch $cmd_num
    case (seq 0 (expr $num_items - 1))
      commandline $$cmd_hist[1][(expr $num_items - $cmd_num)]
      echo $$cmd_hist[1][(expr $num_items - $cmd_num)] | xsel
      for i in (seq (count (echo $$cmd_hist\n)))
        tput cuu1
      end
    case 'e'
      read -p 'echo -n (set_color -b $leftspencer_colors[2] $leftspencer_colors[9])" ↩ Erase [0"$last_item"] "(set_color -b normal $leftspencer_colors[2])" "(set_color $leftspencer_colors[9])' -n $input_length -l cmd_num
      for i in (seq (count (echo $$cmd_hist\n)))
        tput cuu1
      end
      tput cuu1
      set -e $cmd_hist[1][(expr $num_items - $cmd_num)] ^ /dev/null
  end
  tput ed
  tput cuu1
  set pcount (expr $pcount - 1)
  set no_prompt_hist 'T'
end

##############
# => Bookmarks
##############
function mark -d 'Create bookmark for present working directory.'
  if not contains $PWD $bookmarks
    set -U bookmarks $PWD $bookmarks
    set pwd_hist_lock true
    commandline -f repaint
  end
end

function unmark -d 'Remove bookmark for present working directory.'
  if contains $PWD $bookmarks
    set -e bookmarks[(contains -i $PWD $bookmarks)]
    set pwd_hist_lock true
    commandline -f repaint
  end
end

function m -d 'List bookmarks, jump to directory in list with m <number>'
  set -l num_items (count $bookmarks)
  if [ $num_items -eq 0 ]
    set_color $fish_color_error[1]
    echo 'Bookmark list is empty. '(set_color normal)'Enter '(set_color $fish_color_command[1])'mark '(set_color normal)'in INSERT mode or '(set_color $fish_color_command[1])'m '(set_color normal)'in NORMAL mode, if you want to add the current directory to your bookmark list.'
    return
  end
  if begin
      [ (count $argv) -eq 1 ]
      and [ $argv[1] -ge 0 ]
      and [ $argv[1] -lt $num_items ]
    end
    cd $bookmarks[(expr $num_items - $argv[1])]
  else
    for i in (seq $num_items)
      if [ $PWD = $bookmarks[$i] ]
        set_color $leftspencer_colors[10]
      else
        if [ (expr \( $num_items - $i \) \% 2) -eq 0 ]
          set_color normal
        else
          set_color $leftspencer_colors[4]
        end
      end
      echo '▶ '(expr $num_items - $i)\t$bookmarks[$i] | sed "s|$HOME|~|"
    end
    if [ $num_items -eq 1 ]
      set last_item ''
    else
      set last_item '-'(expr $num_items - 1)
    end
    echo -en $leftspencer_cursors[1]
    set input_length (expr length (expr $num_items - 1))
    read -p 'echo -n (set_color -b $leftspencer_colors[2] $leftspencer_colors[10])" ⌘ Goto [0"$last_item"] "(set_color -b normal $leftspencer_colors[2])" "(set_color $leftspencer_colors[10])' -n $input_length -l dir_num
    switch $dir_num
      case (seq 0 (expr $num_items - 1))
        cd $bookmarks[(expr $num_items - $dir_num)]
    end
    for i in (seq (expr $num_items + 1))
      tput cuu1
    end
    tput ed
    tput cuu1
  end
end

#############
# => Sessions
#############
function __leftspencer_delete_zombi_sessions -d 'Delete zombi sessions'
  for i in $leftspencer_sessions_active_pid
    if not contains $i %fish
      set -l item (contains -i $i $leftspencer_sessions_active_pid)
      set -e leftspencer_sessions_active_pid[$item]
      set -e leftspencer_sessions_active[$item]
    end
  end
end

function __leftspencer_create_new_session -d 'Create a new session'
  set -U leftspencer_session_cmd_hist_$argv[1] $$cmd_hist
  set -U leftspencer_session_dir_hist_$argv[1] $$dir_hist
  set -U leftspencer_sessions $argv[1] $leftspencer_sessions
end

function __leftspencer_erase_session -d 'Erase current session'
  if [ (count $argv) -eq 1 ]
    set_color $fish_color_error[1]
    echo 'Missing argument: name of session to erase'
    return
  end
  if contains $argv[2] $leftspencer_sessions_active
    set_color $fish_color_error[1]
    echo "Session '$argv[2]' cannot be erased because it's currently active."
    return
  end
  if contains $argv[2] $leftspencer_sessions
    set -e leftspencer_session_cmd_hist_$argv[2]
    set -e leftspencer_session_dir_hist_$argv[2]
    set -e leftspencer_sessions[(contains -i $argv[2] $leftspencer_sessions)]
  else
    set_color $fish_color_error[1]
    echo "Session '$argv[2]' not found. "(set_color normal)'Enter '(set_color $fish_color_command[1])'s '(set_color normal)'to show a list of all recorded sessions.'
  end
end

function __leftspencer_detach_session -d 'Detach current session'
  set cmd_hist cmd_hist_nosession
  set dir_hist dir_hist_nosession
  if [ -z $$dir_hist ] ^ /dev/null
    set $dir_hist $PWD
  end
  set dir_hist_val (count $$dir_hist)
  set -e leftspencer_sessions_active_pid[$argv] ^ /dev/null
  set -e leftspencer_sessions_active[$argv] ^ /dev/null
  set leftspencer_session_current ''
  cd $$dir_hist[1][$dir_hist_val]
  set no_prompt_hist 'T'
end

function __leftspencer_attach_session -d 'Attach session'
  set argv (echo -sn $argv\n | sed 's|[^[:alnum:]]|_|g')
  if contains $argv[1] $leftspencer_sessions_active
    wmctrl -a "✻ $argv[1]"
  else
    wt "✻ $argv[1]"
    __leftspencer_detach_session $argv[-1]
    set leftspencer_sessions_active $leftspencer_sessions_active $argv[1]
    set leftspencer_sessions_active_pid $leftspencer_sessions_active_pid %self
    set leftspencer_session_current $argv[1]
    if not contains $argv[1] $leftspencer_sessions
      __leftspencer_create_new_session $argv[1]
    end
    set cmd_hist leftspencer_session_cmd_hist_$argv[1]
    set dir_hist leftspencer_session_dir_hist_$argv[1]
    if [ -z $$dir_hist ] ^ /dev/null
      set $dir_hist $PWD
    end
    set dir_hist_val (count $$dir_hist)
    cd $$dir_hist[1][$dir_hist_val] ^ /dev/null
  end
  set no_prompt_hist 'T'
end

function s -d 'Create, delete or attach session'
  __leftspencer_delete_zombi_sessions
  if [ (count $argv) -eq 0 ]
    set -l active_indicator
    set -l num_items (count $leftspencer_sessions)
    if [ $num_items -eq 0 ]
      set_color $fish_color_error[1]
      echo -n 'Session list is empty. '
      set_color normal
      echo -n 'Enter '
      set_color $fish_color_command[1]
      echo -n 's '
      set_color $fish_color_param[1]
      echo -n 'session-name'
      set_color normal
      echo ' to record the current session.'
      return
    end
    for i in (seq $num_items)
      if [ $leftspencer_sessions[$i] = $leftspencer_session_current ]
        set_color $leftspencer_colors[8]
      else
        if [ (expr \( $num_items - $i \) \% 2) -eq 0 ]
          set_color normal
        else
          set_color $leftspencer_colors[4]
        end
      end
      if contains $leftspencer_sessions[$i] $leftspencer_sessions_active
        set active_indicator '✻ '
      else
        set active_indicator ' '
      end
      echo '▶ '(expr $num_items - $i)\t$active_indicator$leftspencer_sessions[$i]
    end
    if [ $num_items -eq 1 ]
      set last_item ''
    else
      set last_item '-'(expr $num_items - 1)
    end
    echo -en $leftspencer_cursors[3]
    set input_length (expr length (expr $num_items - 1))
    read -p 'echo -n (set_color -b $leftspencer_colors[2] $leftspencer_colors[8])" ✻ Attach [e|0"$last_item"] "(set_color -b normal $leftspencer_colors[2])" "(set_color $leftspencer_colors[8])' -n $input_length -l session_num
    set pcount (expr $pcount - 1)
    switch $session_num
      case (seq 0 (expr $num_items - 1))
        set argv[1] $leftspencer_sessions[(expr $num_items - $session_num)]
        for i in (seq (expr $num_items + 1))
          tput cuu1
        end
        tput ed
        tput cuu1
      case 'e'
        read -p 'echo -n (set_color -b $leftspencer_colors[2] $leftspencer_colors[8])" ✻ Erase [0"$last_item"] "(set_color -b normal $leftspencer_colors[2])" "(set_color $leftspencer_colors[8])' -n $input_length -l session_num
        if [ (expr $num_items - $session_num) -gt 0 ]
          __leftspencer_erase_session -e $leftspencer_sessions[(expr $num_items - $session_num)]
        end
        for i in (seq (expr $num_items + 3))
          tput cuu1
        end
        tput ed
        return
      case '*'
        for i in (seq (expr $num_items + 1))
          tput cuu1
        end
        tput ed
        tput cuu1
        return
    end
  end
  set -l item (contains -i %self $leftspencer_sessions_active_pid ^ /dev/null)
  switch $argv[1]
    case '-e'
      __leftspencer_erase_session $argv
    case '-d'
      wt 'fish'
      __leftspencer_detach_session $item
      tput cuu1
      tput ed
      set pcount (expr $pcount - 1)
    case '-*'
      set_color $fish_color_error[1]
      echo "Invalid argument: $argv[1]"
    case '*'
      __leftspencer_attach_session $argv $item
  end
end

#####################################
# => Commandline editing with $EDITOR
#####################################
function __leftspencer_edit_commandline -d 'Open current commandline with your editor'
  commandline > $leftspencer_tmpfile
  eval $EDITOR $leftspencer_tmpfile
  set -l IFS ''
  if [ -s $leftspencer_tmpfile ]
    commandline (sed 's|^\s*||' $leftspencer_tmpfile)
  else
    commandline ''
  end
  rm $leftspencer_tmpfile
end

########################
# => Virtual Env segment
########################
function __leftspencer_prompt_virtual_env -d 'Return the current virtual env name'
  if set -q VIRTUAL_ENV
    set_color -b $leftspencer_colors[9]
    echo -n ''
    echo -n ' '(basename "$VIRTUAL_ENV")' '
    set_color -b $leftspencer_colors[1] $leftspencer_colors[9]
  end
end
################
# => Git segment
################
function __leftspencer_is_git_ahead_or_behind -d 'Check if there are unpulled or unpushed commits'
  if set -l ahead_or_behind (command git rev-list --count --left-right 'HEAD...@{upstream}' ^ /dev/null)
    echo $ahead_or_behind | sed 's|\s\+|\n|g'
  else
    echo 0\n0
  end
end

function __leftspencer_git_status -d 'Check git status'
  set -l git_status (command git status --porcelain ^/dev/null | cut -c 1-2)
  set -l added (echo -sn $git_status\n | egrep -c "[ACDMT][ MT]|[ACMT]D")
  set -l deleted (echo -sn $git_status\n | egrep -c "[ ACMRT]D")
  set -l modified (echo -sn $git_status\n | egrep -c ".[MT]")
  set -l renamed (echo -sn $git_status\n | egrep -c "R.")
  set -l unmerged (echo -sn $git_status\n | egrep -c "AA|DD|U.|.U")
  set -l untracked (echo -sn $git_status\n | egrep -c "\?\?")
  echo -n $added\n$deleted\n$modified\n$renamed\n$unmerged\n$untracked
end

function __leftspencer_is_git_stashed -d 'Check if there are stashed commits'
  command git log --format="%gd" -g $argv 'refs/stash' -- ^ /dev/null | wc -l | tr -d '[:space:]'
end

function __leftspencer_prompt_git_symbols -d 'Displays the git symbols'
  set -l is_repo (command git rev-parse --is-inside-work-tree ^/dev/null)
  if [ -z $is_repo ]
    return
  end

  set -l git_ahead_behind (__leftspencer_is_git_ahead_or_behind)
  set -l git_status (__leftspencer_git_status)
  set -l git_stashed (__leftspencer_is_git_stashed)
  
  if [ (expr $git_ahead_behind[1] + $git_ahead_behind[2] + $git_status[1] + $git_status[2] + $git_status[3] + $git_status[4] + $git_status[5] + $git_status[6] + $git_stashed) -ne 0 ]
    switch $pwd_style
      case long short
        if [ $symbols_style = 'symbols' ]
          if [ $git_ahead_behind[1] -gt 0 ]
            set_color -o $leftspencer_colors[5]
            echo -n ' ↑'
          end
          if [ $git_ahead_behind[2] -gt 0 ]
            set_color -o $leftspencer_colors[5]
            echo -n ' ↓'
          end
          if [ $git_status[1] -gt 0 ]
            set_color -o $leftspencer_colors[12]
            echo -n ' +'
          end
          if [ $git_status[2] -gt 0 ]
            set_color -o $leftspencer_colors[7]
            echo -n ' –'
          end
          if [ $git_status[3] -gt 0 ]
            set_color -o $leftspencer_colors[10]
            echo -n ' ✱'
          end
          if [ $git_status[4] -gt 0 ]
            set_color -o $leftspencer_colors[8]
            echo -n ' →'
          end
          if [ $git_status[5] -gt 0 ]
            set_color -o $leftspencer_colors[9]
            echo -n ' ═'
          end
          if [ $git_status[6] -gt 0 ]
            set_color -o $leftspencer_colors[4]
            echo -n ' ●'
          end
          if [ $git_stashed -gt 0 ]
            set_color -o $leftspencer_colors[11]
            echo -n ' ✭'
          end
        else
          if [ $git_ahead_behind[1] -gt 0 ]
            set_color $leftspencer_colors[5]
            echo -n ' '$git_ahead_behind[1]
          end
          if [ $git_ahead_behind[2] -gt 0 ]
            set_color $leftspencer_colors[5]
            echo -n ' '$git_ahead_behind[2]
          end
          if [ $git_status[1] -gt 0 ]
            set_color $leftspencer_colors[12]
            echo -n ' '$git_status[1]
          end
          if [ $git_status[2] -gt 0 ]
            set_color $leftspencer_colors[7]
            echo -n ' '$git_status[2]
          end
          if [ $git_status[3] -gt 0 ]
            set_color $leftspencer_colors[10]
            echo -n ' '$git_status[3]
          end
          if [ $git_status[4] -gt 0 ]
            set_color $leftspencer_colors[8]
            echo -n ' '$git_status[4]
          end
          if [ $git_status[5] -gt 0 ]
            set_color $leftspencer_colors[9]
            echo -n ' '$git_status[5]
          end
          if [ $git_status[6] -gt 0 ]
            set_color $leftspencer_colors[4]
            echo -n ' '$git_status[6]
          end
          if [ $git_stashed -gt 0 ]
            set_color $leftspencer_colors[11]
            echo -n ' '$git_stashed
          end
        end
        set_color -b $leftspencer_colors[3] normal
        echo -n ' '
    end
  end
end

function __leftspencer_prompt_git_branch -d 'Return the current branch name'
  set -l branch (command git symbolic-ref HEAD ^ /dev/null | sed -e 's|^refs/heads/||')
  if not test $branch > /dev/null
    set -l position (command git describe --contains --all HEAD ^ /dev/null)
    if not test $position > /dev/null
      set -l commit (command git rev-parse HEAD ^ /dev/null | sed 's|\(^.......\).*|\1|')
      if test $commit
        set_color -b $leftspencer_colors[11]
		echo -n ''
        switch $pwd_style
          case short long
            set_color $leftspencer_colors[4]
			echo -n -s (__leftspencer_prompt_git_symbols)
			echo -n ' ➦ '$commit' '(set_color $leftspencer_colors[11])
          case none
            set_color $leftspencer_current_bindmode_color
            echo -n ''
        end
        set_color normal
        set_color $leftspencer_colors[11]
      end
    else
      set_color -b $leftspencer_colors[9]
	  echo -n ''
      switch $pwd_style
        case short long
		  set_color $leftspencer_colors[4]
		  echo -n -s (__leftspencer_prompt_git_symbols)
          echo -n '  '$position' '(set_color $leftspencer_colors[9])
        case none
          set_color $leftspencer_current_bindmode_color
          echo -n ''
      end
      set_color normal
      set_color $leftspencer_colors[9]
    end
  else
    set_color -b $leftspencer_colors[3]
	echo -n ''
    switch $pwd_style
      case short long
	    set_color $leftspencer_colors[1]
		echo -n -s (__leftspencer_prompt_git_symbols)
        echo -n ' '$branch' '(set_color $leftspencer_colors[3])
      case none
        set_color $leftspencer_current_bindmode_color
        echo -n ''
    end
    set_color normal
    set_color $leftspencer_colors[3]
  end
end

######################
# => Bind-mode segment
######################
function __leftspencer_prompt_bindmode -d 'Displays the current mode'
  switch $fish_bind_mode
    case default
      set leftspencer_current_bindmode_color $leftspencer_colors[10]
      echo -en $leftspencer_cursors[1]
    case insert
      set leftspencer_current_bindmode_color $leftspencer_colors[5]
      echo -en $leftspencer_cursors[2]
      if [ "$pwd_hist_lock" = true ]
        set pwd_hist_lock false
        __leftspencer_create_dir_hist
      end
    case visual
      set leftspencer_current_bindmode_color $leftspencer_colors[8]
      echo -en $leftspencer_cursors[3]
  end
  if [ (count $leftspencer_prompt_error) -eq 1 ]
    set leftspencer_current_bindmode_color $leftspencer_colors[7]
  end
  set_color -b $leftspencer_current_bindmode_color $leftspencer_colors[1]
  switch $pwd_style
    case short long
      echo -n " $pcount "
  end
  set_color -b normal $leftspencer_current_bindmode_color
end

####################
# => Symbols segment
####################
function __leftspencer_prompt_left_symbols -d 'Display symbols'
    set -l symbols_urgent 'F'
    set -l symbols (set_color -b $leftspencer_colors[2])''

    set -l jobs (jobs | wc -l | tr -d '[:space:]')
    if [ -e ~/.taskrc ]
        set todo (task due.before:sunday ^ /dev/null | tail -1 | cut -f1 -d' ')
        set overdue (task due.before:today ^ /dev/null | tail -1 | cut -f1 -d' ')
    end
    if [ -e ~/.reminders ]
        set appointments (rem -a | cut -f1 -d' ')
    end
    if [ (count $todo) -eq 0 ]
        set todo 0
    end
    if [ (count $overdue) -eq 0 ]
        set overdue 0
    end
    if [ (count $appointments) -eq 0 ]
        set appointments 0
    end

    if [ $symbols_style = 'symbols' ]
        if [ $leftspencer_session_current != '' ]
            set symbols $symbols(set_color -o $leftspencer_colors[8])' ✻'
            set symbols_urgent 'T'
        end
        if contains $PWD $bookmarks
            set symbols $symbols(set_color -o $leftspencer_colors[10])' ⌘'
        end
        if set -q -x VIM
            set symbols $symbols(set_color -o $leftspencer_colors[9])' V'
            set symbols_urgent 'T'
        end
        if set -q -x RANGER_LEVEL
            set symbols $symbols(set_color -o $leftspencer_colors[9])' R'
            set symbols_urgent 'T'
        end
        if [ $jobs -gt 0 ]
            set symbols $symbols(set_color -o $leftspencer_colors[11])' ⚙'
            set symbols_urgent 'T'
        end
        if [ ! -w . ]
            set symbols $symbols(set_color -o $leftspencer_colors[6])' '
        end
        if [ $todo -gt 0 ]
            set symbols $symbols(set_color -o $leftspencer_colors[4])
        end
        if [ $overdue -gt 0 ]
            set symbols $symbols(set_color -o $leftspencer_colors[8])
        end
        if [ (expr $todo + $overdue) -gt 0 ]
            set symbols $symbols' ⚔'
            set symbols_urgent 'T'
        end
        if [ $appointments -gt 0 ]
            set symbols $symbols(set_color -o $leftspencer_colors[5])' ⚑'
            set symbols_urgent 'T'
        end
        if [ $last_status -eq 0 ]
            set symbols $symbols(set_color -o $leftspencer_colors[12])' ✔'
        else
            set symbols $symbols(set_color -o $leftspencer_colors[7])' ✘'
        end
        if [ $USER = 'root' ]
            set symbols $symbols(set_color -o $leftspencer_colors[6])' ⚡'
            set symbols_urgent 'T'
        end
    else
        if [ $leftspencer_session_current != '' ] ^ /dev/null
            set symbols $symbols(set_color $leftspencer_colors[8])' '(expr (count $leftspencer_sessions) - (contains -i $leftspencer_session_current $leftspencer_sessions))
            set symbols_urgent 'T'
        end
        if contains $PWD $bookmarks
            set symbols $symbols(set_color $leftspencer_colors[10])' '(expr (count $bookmarks) - (contains -i $PWD $bookmarks))
        end
        if set -q -x VIM
            set symbols $symbols(set_color -o $leftspencer_colors[9])' V'(set_color normal)(set_color -b $leftspencer_colors[2])
            set symbols_urgent 'T'
        end
        if set -q -x RANGER_LEVEL
            set symbols $symbols(set_color $leftspencer_colors[9])' '$RANGER_LEVEL
            set symbols_urgent 'T'
        end
        if [ $jobs -gt 0 ]
            set symbols $symbols(set_color $leftspencer_colors[11])' '$jobs
            set symbols_urgent 'T'
        end
        if [ ! -w . ]
            set symbols $symbols(set_color -o $leftspencer_colors[6])' '(set_color normal)(set_color -b $leftspencer_colors[2])
        end
        if [ $todo -gt 0 ]
            set symbols $symbols(set_color $leftspencer_colors[4])
        end
        if [ $overdue -gt 0 ]
            set symbols $symbols(set_color $leftspencer_colors[8])
        end
        if [ (expr $todo + $overdue) -gt 0 ]
            set symbols $symbols" $todo"
            set symbols_urgent 'T'
        end
        if [ $appointments -gt 0 ]
            set symbols $symbols(set_color $leftspencer_colors[5])" $appointments"
            set symbols_urgent 'T'
        end
        if [ $last_status -eq 0 ]
            set symbols $symbols(set_color $leftspencer_colors[12])' '$last_status
        else
            set symbols $symbols(set_color $leftspencer_colors[7])' '$last_status
        end
        if [ $USER = 'root' ]
            set symbols $symbols(set_color -o $leftspencer_colors[6])' ⚡'
            set symbols_urgent 'T'
        end
    end
    set symbols $symbols(set_color $leftspencer_colors[2])' '(set_color normal)(set_color $leftspencer_colors[2])
    switch $pwd_style
        case none
            if test $symbols_urgent = 'T'
                set symbols (set_color -b $leftspencer_colors[2])''(set_color normal)(set_color $leftspencer_colors[2])
            else
                set symbols ''
            end
    end
    echo -n $symbols
end

#####################
# => Toggle functions
#####################
function __leftspencer_toggle_symbols -d 'Toggles style of symbols, press # in NORMAL or VISUAL mode'
  if [ $symbols_style = 'symbols' ]
    set symbols_style 'numbers'
  else
    set symbols_style 'symbols'
  end
  set pwd_hist_lock true
  commandline -f repaint
end

function __leftspencer_toggle_pwd -d 'Toggles style of pwd segment, press space bar in NORMAL or VISUAL mode'
  for i in (seq (count $leftspencer_pwdstyle))
    if [ $leftspencer_pwdstyle[$i] = $pwd_style ]
      set pwd_style $leftspencer_pwdstyle[(expr $i \% (count $leftspencer_pwdstyle) + 1)]
      set pwd_hist_lock true
      commandline -f repaint
      break
      end
  end
end

#############################
# => Command duration segment
#############################
function __leftspencer_cmd_duration -d 'Displays the elapsed time of last command'
  set -l seconds ''
  set -l minutes ''
  set -l hours ''
  set -l days ''
  set -l cmd_duration (expr $CMD_DURATION / 1000)
  if [ $cmd_duration -gt 0 ]
    set seconds (expr $cmd_duration \% 68400 \% 3600 \% 60)'s'
    if [ $cmd_duration -ge 60 ]
      set minutes (expr $cmd_duration \% 68400 \% 3600 / 60)'m'
      if [ $cmd_duration -ge 3600 ]
        set hours (expr $cmd_duration \% 68400 / 3600)'h'
        if [ $cmd_duration -ge 68400 ]
          set days (expr $cmd_duration / 68400)'d'
              end
          end
      end
      set_color -b $leftspencer_colors[2]
      echo -n ''
      switch $pwd_style
        case short long
          if [ $last_status -ne 0 ]
            echo -n (set_color -b $leftspencer_colors[2] $leftspencer_colors[7])' '$days$hours$minutes$seconds' '
          else
            echo -n (set_color -b $leftspencer_colors[2] $leftspencer_colors[12])' '$days$hours$minutes$seconds' '
          end
      end
    set_color -b $leftspencer_colors[1]
	set_color $leftspencer_colors[2]
    echo -n ' '
  else
    set_color -b $leftspencer_colors[1]
    echo -n ' '
  end
end

################
# => PWD segment
################
function __leftspencer_prompt_pwd -d 'Displays the present working directory'
  set -l user_host ' '
  if set -q SSH_CLIENT
    if [ $symbols_style = 'symbols' ]
      switch $pwd_style
        case short
          set user_host " $USER@"(hostname -s)':'
        case long
          set user_host " $USER@"(hostname -f)':'
      end
    else
      set user_host " $USER@"(hostname -i)':'
    end
  end
  set_color $leftspencer_colors[2]
  set_color -b $leftspencer_current_bindmode_color
  echo -n ''
  set_color normal
  set_color -b $leftspencer_current_bindmode_color $leftspencer_colors[1]
  if [ (count $leftspencer_prompt_error) != 1 ]
    switch $pwd_style
      case short
        echo -n $user_host(prompt_pwd)' '
      case long
        echo -n $user_host(pwd)' '
    end
  else
    echo -n " $leftspencer_prompt_error "
    set -e leftspencer_prompt_error[1]
  end
  set_color $leftspencer_current_bindmode_color
end

###############################################################################
# => Prompt initialization
###############################################################################

# Initialize some global variables
set -g leftspencer_prompt_error
set -g leftspencer_current_bindmode_color
set -U leftspencer_sessions_active $leftspencer_sessions_active
set -U leftspencer_sessions_active_pid $leftspencer_sessions_active_pid
set -g leftspencer_session_current ''
set -g cmd_hist_nosession
set -g cmd_hist cmd_hist_nosession
set -g CMD_DURATION 0
set -g dir_hist_nosession
set -g dir_hist dir_hist_nosession
set -g pwd_hist_lock true
set -g pcount 1
set -g prompt_hist
set -g no_prompt_hist 'F'
set -g symbols_style 'symbols'

# Load user defined key bindings
if functions --query fish_user_key_bindings
  fish_user_key_bindings
end

# Set favorite editor
if not set -q EDITOR
  set -g EDITOR nvim
end

# Source config file
if [ -e $leftspencer_config ]
  source $leftspencer_config
end

# Don't save in command history
if not set -q leftspencer_nocmdhist
  set -U leftspencer_nocmdhist 'c' 'd' 'll' 'ls' 'm' 's'
end

# Set PWD segment style
if not set -q leftspencer_pwdstyle
  set -U leftspencer_pwdstyle short long none
end
set pwd_style $leftspencer_pwdstyle[1]

# Cd to newest bookmark if this is a login shell
if not begin
    set -q -x LOGIN
    or set -q -x RANGER_LEVEL
    or set -q -x VIM
  end ^ /dev/null
  if set -q bookmarks[1]
    cd $bookmarks[1]
  end
end
set -x LOGIN $USER

###############################################################################
# => Left prompt
###############################################################################

function fish_prompt -d 'Write out the left prompt of the leftspencer theme'
  set -g last_status $status
  echo -n -s (__leftspencer_prompt_bindmode) (__leftspencer_prompt_virtual_env) (__leftspencer_prompt_git_branch) (__leftspencer_prompt_left_symbols) (__leftspencer_prompt_pwd) (__leftspencer_cmd_duration) (set_color normal)
end
