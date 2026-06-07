# BulletType.gd
# Enumeration of all bullet types in the game

enum BulletType {
	SMALL_ROUND,       # 小玉: tiny colored circle, 8px diameter
	LARGE_ROUND,       # 中玉: larger circle, 16px
	AMULET,            # 札弾: amulet/knife shaped
	BUBBLE,            # 泡泡: translucent larger circle
	STAR,              # 星弾: star shaped
	ELLIPSE,           # 椭圆: stretched bullet
	NEEDLE,            # 针弾: thin needle
	LASER,             # 激光: beam laser (special rendering)
	PLAYER_BULLET,     # 自机弾: player normal shot
	PLAYER_MISSILE,    # 自机导弹: player missile (power >= 3.00)
}
