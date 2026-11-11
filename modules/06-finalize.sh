#!/usr/bin/env bash

module_finalize(){
  header "Manual checklist (things that cannot be scripted safely)"
  cat <<'EOF'

  1. Sign in to your Apple ID
       System Settings → [your name] → Sign In
  2. Turn on Find My
       System Settings → [your name] → Find My → Find My Mac
  3. Turn on Location Services
       System Settings → Privacy & Security → Location Services
  4. Display → "More Space"
       System Settings → Displays → choose "More Space"
  5. Finder sidebar → add ~/project below Downloads
       In Finder: Go → Home, drag the "project" folder into the sidebar under Downloads
  6. Clock → Announce the time
       System Settings → Control Center → Clock Options → Announce the time → On the hour
  7. Trackpad tap-to-click takes effect after a logout if it did not apply immediately.
  8. Terminal font for Powerlevel10k icons
       Install the MesloLGS NF font, then select it in your terminal profile
       (Terminal: Settings → Profiles → Text; iTerm2: Settings → Profiles → Text)
       Powerlevel10k without it shows boxes instead of icons.

EOF
  ok "Review the items above to finish setup."
}
