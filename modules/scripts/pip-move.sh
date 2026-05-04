#!/usr/bin/env bash
DIRECTION=$1
GAP=20
WIN_TITLE="Picture-in-Picture"

# Get window info
WIN_JSON=$(hyprctl clients -j | jq '.[] | select(.title == "Picture-in-Picture")')
WIN_X=$(echo "$WIN_JSON" | jq '.at[0]')
WIN_Y=$(echo "$WIN_JSON" | jq '.at[1]')
WIN_W=$(echo "$WIN_JSON" | jq '.size[0]')
WIN_H=$(echo "$WIN_JSON" | jq '.size[1]')
MON_ID=$(echo "$WIN_JSON" | jq '.monitor')

# Get monitor info directly by ID
MON_JSON=$(hyprctl monitors -j | jq ".[] | select(.id == $MON_ID)")
MON_X=$(echo "$MON_JSON" | jq '.x')
MON_Y=$(echo "$MON_JSON" | jq '.y')
MON_W=$(echo "$MON_JSON" | jq '.width')
MON_H=$(echo "$MON_JSON" | jq '.height')
MON_SCALE=$(echo "$MON_JSON" | jq '.scale')

# Scale width/height by monitor scale for logical coordinates
MON_W=$(echo "$MON_W $MON_SCALE" | awk '{printf "%d", $1 / $2}')
MON_H=$(echo "$MON_H $MON_SCALE" | awk '{printf "%d", $1 / $2}')

# Corner positions (absolute)
LEFT_X=$((MON_X + GAP))
RIGHT_X=$((MON_X + MON_W - WIN_W - GAP))
TOP_Y=$((MON_Y + GAP))
BOT_Y=$((MON_Y + MON_H - WIN_H - GAP))

at_left_border()  { [ "$WIN_X" -le $((LEFT_X + 5)) ]; }
at_right_border() { [ "$WIN_X" -ge $((RIGHT_X - 5)) ]; }
at_top_border()   { [ "$WIN_Y" -le $((TOP_Y + 5)) ]; }
at_bot_border()   { [ "$WIN_Y" -ge $((BOT_Y - 5)) ]; }

move_to() {
  hyprctl dispatch movewindowpixel exact $1 $2,title:"$WIN_TITLE"
}

move_to_monitor() {
  local TARGET_MON_ID=$1
  local CORNER_X=$2
  local CORNER_Y=$3

  hyprctl dispatch movewindow mon:"$TARGET_MON_ID",title:"$WIN_TITLE"
  sleep 0.15

  local NM=$(hyprctl monitors -j | jq ".[] | select(.id == $TARGET_MON_ID)")
  local NMX=$(echo "$NM" | jq '.x')
  local NMY=$(echo "$NM" | jq '.y')
  local NMW=$(echo "$NM" | jq '.width')
  local NMH=$(echo "$NM" | jq '.height')
  local NMS=$(echo "$NM" | jq '.scale')
  NMW=$(echo "$NMW $NMS" | awk '{printf "%d", $1 / $2}')
  NMH=$(echo "$NMH $NMS" | awk '{printf "%d", $1 / $2}')

  local NX NY
  [ "$CORNER_X" = "left" ]  && NX=$((NMX + GAP))               || NX=$((NMX + NMW - WIN_W - GAP))
  [ "$CORNER_Y" = "top" ]   && NY=$((NMY + GAP))               || NY=$((NMY + NMH - WIN_H - GAP))

  hyprctl dispatch movewindowpixel exact "$NX" "$NY",title:"$WIN_TITLE"
}

find_monitor() {
  local DIR=$1
  hyprctl monitors -j | jq --argjson mid "$MON_ID" \
    --argjson mx "$MON_X" --argjson my "$MON_Y" \
    --argjson mw "$MON_W" --argjson mh "$MON_H" '
    .[] | select(.id != $mid) |
    if   "'"$DIR"'" == "left"  then select(.x < $mx)           | {id, dist: ($mx - .x - (.width/.scale))}
    elif "'"$DIR"'" == "right" then select(.x >= ($mx + $mw))  | {id, dist: (.x - $mx - $mw)}
    elif "'"$DIR"'" == "up"    then select(.y < $my)           | {id, dist: ($my - .y - (.height/.scale))}
    elif "'"$DIR"'" == "down"  then select(.y >= ($my + $mh))  | {id, dist: (.y - $my - $mh)}
    else empty end
  ' | jq -s 'sort_by(.dist) | first | .id // empty'
}

vert()  { at_top_border && echo top  || echo bot; }
horiz() { at_left_border && echo left || echo right; }

case $DIRECTION in
  left)
    if at_left_border; then
      TARGET=$(find_monitor left)
      [ -n "$TARGET" ] && move_to_monitor "$TARGET" right "$(vert)"
    else
      move_to "$LEFT_X" "$(at_top_border && echo $TOP_Y || echo $BOT_Y)"
    fi ;;
  right)
    if at_right_border; then
      TARGET=$(find_monitor right)
      [ -n "$TARGET" ] && move_to_monitor "$TARGET" left "$(vert)"
    else
      move_to "$RIGHT_X" "$(at_top_border && echo $TOP_Y || echo $BOT_Y)"
    fi ;;
  up)
    if at_top_border; then
      TARGET=$(find_monitor up)
      [ -n "$TARGET" ] && move_to_monitor "$TARGET" "$(horiz)" bot
    else
      move_to "$(at_left_border && echo $LEFT_X || echo $RIGHT_X)" "$TOP_Y"
    fi ;;
  down)
    if at_bot_border; then
      TARGET=$(find_monitor down)
      [ -n "$TARGET" ] && move_to_monitor "$TARGET" "$(horiz)" top
    else
      move_to "$(at_left_border && echo $LEFT_X || echo $RIGHT_X)" "$BOT_Y"
    fi ;;
esac
