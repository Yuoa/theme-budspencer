set fish_key_bindings fish_vi_key_bindings
bind '#' __leftspencer_toggle_symbols
bind -M visual '#' __leftspencer_toggle_symbols
bind ' ' __leftspencer_toggle_pwd
bind -M visual ' ' __leftspencer_toggle_pwd
bind L __leftspencer_cd_next
bind H __leftspencer_cd_prev
bind m mark
bind M unmark
bind . __leftspencer_edit_commandline
bind -M insert \r __leftspencer_preexec
bind \r __leftspencer_preexec
