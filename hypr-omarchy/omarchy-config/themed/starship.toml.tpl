add_newline = false

format = """
$username$directory$git_branch$git_status$python$nodejs$bun$golang$rust$zig$fill$cmd_duration$time
$character
"""

[custom.git_dirty]
when = "git diff --quiet || exit 1"
command = "echo dirty"

[custom.git_ahead]
when = "git status -sb | grep -q '\\[ahead'"
command = "echo ahead"

[custom.git_conflict]
when = "git diff --name-only --diff-filter=U | grep -q ."
command = "echo conflict"

[custom.git_safe]
when = "! git diff --quiet && false"
command = "false"

[custom.git_danger]
when = "git diff --name-only --diff-filter=U | grep -q ."
format = "[󰊢 $git_status](bg:{{ bright_red }} fg:{{ background }})[](fg:{{ bright_red }} bg:{{ accent }})"

[custom.git_dirty_block]
when = "git diff --quiet || exit 1"
format = "[󰊢 $git_status](bg:{{ bright_yellow }} fg:{{ background }})[](fg:{{ bright_yellow }} bg:{{ accent }})"

[python]
symbol = "🐍"
style = "fg:{{ bright_yellow }}"
format = "[ $symbol $version ]($style)"

[nodejs]
symbol = "🟢"
style = "fg:{{ green }}"
format = "[ $symbol $version ]($style)"

[bun]
symbol = "🥟"
style = "fg:{{ magenta }}"
format = "[ $symbol $version ]($style)"

[golang]
symbol = "🐹"
style = "fg:{{ light_foreground }}"
format = "[ $symbol $version ]($style)"

[rust]
symbol = "🦀"
style = "fg:{{ bright_red }}"
format = "[ $symbol $version ]($style)"

[zig]
symbol = "⚡"
style = "fg:{{ accent }}"
format = "[ $symbol $version ]($style)"

[fill]
symbol = " "
style = "bg:none"

# -----------------------------
# Identity & location
# -----------------------------
[username]
show_always = true
style_user = "bg:{{ accent }} fg:{{ background }}"
format = "(fg:{{ accent }})[ $user]($style)[](fg:{{ accent }} bg:{{ background }})"

[directory]
style = "bg:{{ background }} fg:{{ light_foreground }}"
format = "[󰉋 $path]($style)"

# -----------------------------
# Git
# -----------------------------
[git_branch]
symbol = ""
style = "bg:{{ selection }} fg:{{ green }}"
format = "[](fg:{{ background }} bg:{{ selection }})[$symbol $branch]($style)"

[git_status]
style = "bg:{{ muted }} fg:{{ foreground }}"
format = "[](fg:{{ selection }} bg:{{ muted }})[󰊢 $all_status$ahead_behind]($style)[](fg:{{ muted }} bg:{{ background }})"

conflicted = "[!](fg:{{ bright_red }} bg:{{ muted }}) "
modified   = "[●](fg:{{ bright_yellow }} bg:{{ muted }}) "
staged     = "[+](fg:{{ green }} bg:{{ muted }}) "
untracked  = "[?](fg:{{ light_foreground }} bg:{{ muted }}) "
deleted    = "[✖](fg:{{ bright_red }} bg:{{ muted }}) "
renamed    = "[➜](fg:{{ accent }} bg:{{ muted }}) "
stashed    = "[≡](fg:{{ magenta }} bg:{{ muted }}) "

ahead      = "[⇡](fg:{{ green }} bg:{{ muted }}) "
behind     = "[⇣](fg:{{ bright_red }} bg:{{ muted }}) "

# -----------------------------
# Performance & Time
# -----------------------------

[cmd_duration]
min_time = 2000
style = "bg:{{ accent }} fg:{{ background }}"
format = "[ $duration ]($style)[](fg:{{ accent }} bg:{{ background }})"

[time]
disabled = true
time_format = "%H:%M"
style = "bg:{{ darker_background }} fg:{{ foreground }}"
format = "[  $time]($style)[](fg:{{ darker_background }})"

# -----------------------------
# Prompt character
# -----------------------------
[character]
success_symbol = "[❯](fg:{{ light_foreground }})"
error_symbol = "[❯❯](fg:{{ bright_red }})"

# -----------------------------
# Error status
# -----------------------------
[status]
disabled = false
format = " [$symbol$status]($style)"
symbol = "✖"
style = "bold red"
