class_name GameEnums
extends RefCounted

enum RoleCategory { TANK, HEALER, DPS, SUPPORT_PUZZLE }
enum TriggerType { TIMER, ON_HIT, ON_MECHANIC_EVENT }
enum ResponderMode { BY_ROLE, WHOLE_RAID }
enum SelectionMode { ALL_MATCHING, RANDOM_ONE }
enum ExclusionRule { NONE, NOT_CURRENT_TANK }
