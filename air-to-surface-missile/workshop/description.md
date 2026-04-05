[TTT2] Air-To-Surface Missile is a modernized, TTT2-optimized re-release of the classic controllable missile strike (similar to the Predator Missile from Modern Warfare).

**How it works**

- Buy it from the traitor equipment shop
- Primary fire: pick a target position, then guide the strike camera (mouse + movement keys)
- Primary fire / Use / timeout: launch the missile
- Secondary fire: abort (if enabled)

**TTT2 optimizations**

- Server-side explosion damage now applies friendlyfire/owner-damage rules directly (no global damage hook)
- Optional line-of-sight checks for blast damage are configurable for performance
- Fixed Linux case-sensitive material paths
- Fixed debug-drawing networking and several cleanup edge cases

**ConVars**

- ttt_asm_shift_speed_modifier (default: 2)
- ttt_asm_alt_speed_modifier (default: 0.25)
- ttt_asm_mouse_speed_modifier (default: 3)
- ttt_asm_aim_time (default: 15)
- ttt_asm_missile_blast_damage (default: 110)
- ttt_asm_missile_blast_radius (default: 384)
- ttt_asm_allow_abort (default: 1)
- ttt_asm_allow_abort_mid_flight (default: 0)
- ttt_asm_allow_camera_move_mid_flight (default: 1)
- ttt_asm_show_colleagues (default: 1)
- ttt_asm_damage_owner (default: 1)
- ttt_asm_friendlyfire (default: 1)
- ttt_asm_show_debug (default: 0)
- ttt_asm_explosion_respect_walls (default: 1)
- ttt_asm_explosion_wallcheck_samples (default: 6)
- ttt_asm_log_level (default: 2)
