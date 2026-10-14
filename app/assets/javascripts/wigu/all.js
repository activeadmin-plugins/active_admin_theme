// Umbrella require for every script the theme ships, so a Sprockets manifest
// carries one line instead of a hand-maintained list that silently drifts:
// theme CSS can depend on a JS-set property (scrollbar_width feeds the pinned
// bars' width), and a missed require degrades visually with no error. Each
// script stays individually requirable for apps that want a subset; see the
// README for what each one does and how to opt out.
//= require wigu/theme_toggle
//= require wigu/server_clock
//= require wigu/scrollbar_width
//= require wigu/table_crisscross
