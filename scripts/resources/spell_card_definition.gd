# SpellCardDefinition.gd
# Resource defining a boss spell card attack
class_name SpellCardDefinition
extends Resource

@export var spell_id: String = ""
@export var spell_name: String = "Unknown Spell"
@export var boss_hp_threshold: float = 0.5  # Triggers when boss HP < this ratio
@export var duration: float = 45.0  # Time limit in seconds
@export var patterns: Array[PatternDefinition] = []
@export var pattern_sequence: Array[int] = []  # Indices into patterns array
@export var capture_bonus: int = 100000
@export var background_color: Color = Color(0.1, 0.0, 0.2, 1.0)
