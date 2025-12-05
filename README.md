# About spot_marker
Allow teammates to create spot markers visible only to them.

## Commands
`!mark` - Create spot marker (Use `bind <key> sm_mark`)

## Screen
<img width="2560" height="1440" alt="image" src="https://github.com/user-attachments/assets/674d8aa7-38da-4483-b805-1bad191b8fab" />

## ConVars
| ConVar                           | Default Value          | Description                                                                 |
|----------------------------------|------------------------|-----------------------------------------------------------------------------|
| `sm_spot_marker_duration`        | `3.0`                  | Duration (seconds) of the spot marker.                                      |
| `sm_spot_marker_cooldown`        | `1.0`                  | Cooldown (seconds) to use the spot marker.                                  |
| `sm_spot_marker_sound`           | `ui/alert_clink.wav`   | Path to sound. Empty = OFF.                                                 |
| `sm_spot_marker_message`         | `1`                    | Display message. `0 = OFF`, `1 = CHAT`.                                     |
| `sm_spot_marker_alive_only`      | `1`                    | Allow the command only for alive players. `0 = OFF`, `1 = ON`.              |
| `sm_spot_marker_sprite_model`    | `vgui/icon_download.vmt` | Sprite model.                                                              |
| `sm_spot_marker_sprite_color`    | `255 255 0`            | Sprite color. Use `"random"` for random colors. Or three values `<0-255> <0-255> <0-255>`. |
| `sm_spot_marker_sprite_alpha`    | `255`                  | Sprite alpha transparency. `0 = Invisible`, `255 = Fully Visible`. Note: Some models don’t support alpha. |
| `sm_spot_marker_sprite_fade_distance` | `-1`              | Minimum distance before sprite fades. `-1 = Always visible`.                 |
| `sm_spot_marker_sprite_z_axis`   | `25.0`                 | Additional Z axis offset for the sprite.                                    |
| `sm_spot_marker_sprite_speed`    | `1.0`                  | Speed of sprite movement along Z axis. `0 = OFF`.                           |
| `sm_spot_marker_sprite_min_max`  | `5.0`                  | Min/Max distance from original position before inverting vertical direction. `0 = OFF`. |
