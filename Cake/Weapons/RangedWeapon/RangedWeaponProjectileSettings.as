import Cake.Weapons.RangedWeapon.RangedWeaponProjectile;

enum ERangedWeaponProjectileType
{
	Hitscan,
	Projectile
}

UCLASS(meta=(ComposeSettingsOnto = "URangedWeaponProjectileSettings"))
class URangedWeaponProjectileSettings : UHazeComposableSettings
{
	UPROPERTY(Category = Projectile)
	ERangedWeaponProjectileType ProjectileType = ERangedWeaponProjectileType::Hitscan;

	// Only valid if ProjectileType is set to Projectile.
	UPROPERTY(Category = Projectile)
	TSubclassOf<ARangedWeaponProjectile> ProjectileClass;

	UPROPERTY(Category = Damage)
	float Damage = 1.0f;

	UPROPERTY(Category = Range)
	float Range = 100000.0f;
}

