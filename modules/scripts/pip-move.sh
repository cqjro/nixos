#!/usr/bin/env bash
# Usage: pip-move.sh <direction>  (left|down|up|right)

DIRECTION=$1
GAP=20
WIN_TITLE="Picture-in-Picture"

# Get window info
WIN_JSON=$(hyprctl clients -j | jq '.[] | select(.title == "'"$WIN_TITLE"'")')
WIN_X=$(echo "$WIN_JSON" | jq '.at[0]')
WIN_Y=$(echo "$WIN_JSON" | jq '.at[1]')
WIN_W=$(echo "$WIN_JSON" | jq '.size[0]')
WIN_H=$(echo "$WIN_JSON" | jq '.size[1]')

# Get the monitor the window is currently on
MON_JSON=$(hyprctl monitors -j | jq '.[] | select(
  .x <= '"$WIN_X"' and (.x + .width) > '"$WIN_X"' and
  .y <= '"$WIN_Y"' and (.y + .height) > '"$WIN_Y"'
)')

MON_X=$(echo "$MON_JSON" | jq '.x')
MON_Y=$(echo "$MON_JSON" | jq '.y')
MON_W=$(echo "$MON_JSON" | jq '.width')
MON_H=$(echo "$MON_JSON" | jq '.height')
MON_ID=$(echo "$MON_JSON" | jq '.id')

# Corner positions within current monitor
LEFT_X=$((MON_X + GAP))
RIGHT_X=$((MON_X + MON_W - WIN_W - GAP))
TOP_Y=$((MON_Y + GAP))
BOT_Y=$((MON_Y + MON_H - WIN_H - GAP))

# Determine if we're at the border in the given direction
at_left_border()  { [ "$WIN_X" -le $((MON_X + GAP + 5)) ]; }
at_right_border() { [ "$WIN_X" -ge $((MON_X + MON_W - WIN_W - GAP - 5)) ]; }
at_top_border()   { [ "$WIN_Y" -le $((MON_Y + GAP + 5)) ]; }
at_bot_border()   { [ "$WIN_Y" -ge $((MON_Y + MON_H - WIN_H - GAP - 5)) ]; }

move_to() {
  hyprctl dispatch movewindowpixel exact $1 $2,title:"$WIN_TITLE"
}

move_to_monitor() {
  local TARGET_MON=$1
  local CORNER_X=$2
  local CORNER_Y=$3
  hyprctl dispatch movewindow mon:"$TARGET_MON",title:"$WIN_TITLE"
  sleep 0.1  # let Hyprland finish the monitor move
  # Recalculate position on new monitor
  NEW_MON_JSON=$(hyprctl monitors -j | jq '.[] | select(.id == '"$TARGET_MON"')')
  NEW_MON_X=$(echo "$NEW_MON_JSON" | jq '.x')
  NEW_MON_Y=$(echo "$NEW_MON_JSON" | jq '.y')
  NEW_MON_W=$(echo "$NEW_MON_JSON" | jq '.width')
  NEW_MON_H=$(echo "$NEW_MON_JSON" | jq '.height')
  case $CORNER_X in
    left)  NX=$((NEW_MON_X + GAP)) ;;
    right) NX=$((NEW_MON_X + NEW_MON_W - WIN_W - GAP)) ;;
  esac
  case $CORNER_Y in
    top)  NY=$((NEW_MON_Y + GAP)) ;;
    bot)  NY=$((NEW_MON_Y + NEW_MON_H - WIN_H - GAP)) ;;
  esac
  hyprctl dispatch movewindowpixel exact "$NX" "$NY",title:"$WIN_TITLE"
}

# Find adjacent monitor in a direction
find_monitor() {
  local DIR=$1
  hyprctl monitors -j | jq --argjson mid "$MON_ID" \
    --argjson mx "$MON_X" --argjson my "$MON_Y" \
    --argjson mw "$MON_W" --argjson mh "$MON_H" '
    .[] | select(.id != $mid) |
    if "'"$DIR"'" == "left"  then select(.x < $mx) | {id, dist: ($mx - .x - .width)}
    elif "'"$DIR"'" == "right" then select(.x >= ($mx + $mw)) | {id, dist: (.x - $mx - $mw)}
    elif "'"$DIR"'" == "up"  then select(.y < $my) | {id, dist: ($my - .y - .height)}
    elif "'"$DIR"'" == "down" then select(.y >= ($my + $mh)) | {id, dist: (.y - $my - $mh)}
    else empty end
  ' | jq -s 'sort_by(.dist) | first | .id'
}

case $DIRECTION in
  left)
    if at_left_border; then
      TARGET=$(find_monitor left)
      [ -n "$TARGET" ] && [ "$TARGET" != "null" ] && move_to_monitor "$TARGET" right \
        $(at_top_border && echo top || echo bot)
    else
      # Snap to left side, preserve vertical position (top or bottom)
      $(at_top_border && true || false) && move_to "$LEFT_X" "$TOP_Y" || move_to "$LEFT_X" "$BOT_Y"
    fi
    ;;
  right)
    if at_right_border; then
      TARGET=$(find_monitor right)
      [ -n "$TARGET" ] && [ "$TARGET" != "null" ] && move_to_monitor "$TARGET" left \
        $(at_top_border && echo top || echo bot)
    else
      $(at_top_border && true || false) && move_to "$RIGHT_X" "$TOP_Y" || move_to "$RIGHT_X" "$BOT_Y"
    fi
    ;;
  up)
    if at_top_border; then
      TARGET=$(find_monitor up)
      [ -n "$TARGET" ] && [ "$TARGET" != "null" ] && move_to_monitor "$TARGET" \
        $(at_left_border && echo left || echo right) bot
    else
      $(at_left_border && true || false) && move_to "$LEFT_X" "$TOP_Y" || move_to "$RIGHT_X" "$TOP_Y"
    fi
    ;;
  down)
    if at_bot_border; then
      TARGET=$(find_monitor down)
      [ -n "$TARGET" ] && [ "$TARGET" != "null" ] && move_to_monitor "$TARGET" \
        $(at_left_border && echo left || echo right) top
    else
      $(at_left_border && true || false) && move_to "$LEFT_X" "$BOT_Y" || move_to "$RIGHT_X" "$BOT_Y"
    fi
    ;;
esac
