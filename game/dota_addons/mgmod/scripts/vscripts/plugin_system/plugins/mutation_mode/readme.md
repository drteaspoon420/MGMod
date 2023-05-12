
# Mutation Mode
* Battle Pass owners can queue for Mutation Mode, an unranked game mode with three random gameplay modifiers. Modifiers change every day.
* Help add modifiers to this table.

|Modifier|Description| Internal Modifiers? |
|-|-|-|
| Killstreak Power | For every hero kill, you do 20% more damage and take 20% more damage. Resets on death.| `modifier_mutation_killstreak_power_aura`, `modifier_mutation_killstreak_power` |
| Death Explosion | Whenever a hero is killed, they do damage in a radius around them.| `modifier_death_explosion_aura`, `modifier_death_explosion_team_aura`, `modifier_death_explosion`, `modifier_death_explosion_delayed`|
| Death Gold Drop | Whenever a hero is killed, they drop a gold sack.| `modifier_mutation_drop_item_on_death_team` |
| Periodic Spellcast | Every minute, a random spell will be cast on everyone. | `modifier_mutation_spellcast` |
| Team Runes | Whenever a rune is activated, it affects everyone on the team. | ? |
| Teammate Resurrection | Players can resurrect teammates by clicking on their tombstone and channeling. | `modifier_mutation_create_tombstone_aura`, `modifier_mutation_create_tombstone_team_aura`, `modifier_create_tombstone` |
| Fast Runes | Runes spawn every 30 seconds. | ? |
| Fast Spells | Cooldowns are reduced by 50%, mana regen is increased by 100%.| `modifier_mutation_cooldown_reduction_team_aura`, `modifier_mutation_cooldown_reduction` |
| Stationary Damage Reduction | When standing still, all damage is reduced by 50%.| `modifier_mutation_stationary_damage_reduction_aura` |
| Jump Start | All heroes start at level 6.| ? |
| Super Runes | Runes are unusually effective.| `modifier_rune_extradamage`, `modifier_rune_flying_haste`, `modifier_rune_super_invis`, `modifier_rune_super_regen`, `modifier_rune_super_arcane` |
| Super Blink | All players have a Blink Dagger that is not disabled on damage.| ? |
| Friendly Fire | All spells and abilities also target and affect teammates.| ? |
| Tree Cutter | All heroes destroy trees in a radius around themselves, but they grow back very quickly.| `modifier_mutation_treecutter_aura`, `modifier_mutation_treecutter` |
| Random Lane Creeps | Lane creeps have been invaded by random neutrals.| ? |
| Map Flip | Radiant is Dire. Dire is Radiant.| ? |
| Pocket Tower | All heroes start with a consumable that will spawn a `The International 2018 Battle Pass/Pocket Tower`.| ? |
| Shared Damage | All damage is split and shared among allied heroes within 400 units.| `modifier_mutation_vampire_aura`, `modifier_mutation_vampire` |
| Pocket Roshan | Summons a `The International 2018 Battle Pass/Pocket Roshan` for 60 seconds.| `modifier_mutation_pocket_roshan_team` |
| Prowler Camps | All neutral creeps are `Ancient Prowler Shaman`.| ? |


List of possible related modifiers
* modifier_mutation_vampire_aura
* modifier_mutation_vampire
* modifier_mutation_spellcast
* modifier_death_explosion_aura
* modifier_death_explosion_team_aura
* modifier_death_explosion
* modifier_death_explosion_delayed
* modifier_mutation_no_health_bars_aura
* modifier_mutation_stationary_damage_reduction_aura
* modifier_mutation_damage_reduction
* modifier_mutation_create_tombstone_aura
* modifier_mutation_create_tombstone_team_aura
* modifier_create_tombstone
* modifier_mutation_killstreak_power_aura
* modifier_mutation_killstreak_power
* modifier_mutation_treecutter_aura
* modifier_mutation_treecutter
* modifier_mutation_free_rapiers_team
* modifier_mutation_cooldown_reduction_team_aura
* modifier_mutation_cooldown_reduction
* modifier_mutation_crit_chance_team_aura
* modifier_mutation_crit_chance
* modifier_mutation_pocket_roshan_team
* modifier_mutation_drop_item_on_death_team
* modifier_rune_extradamage
* modifier_rune_flying_haste
* modifier_rune_super_invis
* modifier_rune_super_regen
* modifier_rune_super_arcane