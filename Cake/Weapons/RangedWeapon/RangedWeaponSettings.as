
enum ERangedWeaponFireMode
{
	Auto,
	Single
}

UCLASS(meta=(ComposeSettingsOnto = "URangedWeaponSettings"))
class URangedWeaponSettings : UHazeComposableSettings
{
	UPROPERTY(Category = Ammo)
	int AmmoTotal = 100;

	// Check true and the total pool of ammo will never be consumed.
	UPROPERTY(Category = Ammo)
	bool bInfiniteAmmoTotal = false;

	UPROPERTY(Category = Ammo)
	int AmmoClip = 10;

	// Check true and the clip will never consume bullets.
	UPROPERTY(Category = Ammo)
	bool bInfiniteAmmoClip = false;

	// How fast the weapon can fire, time it needs to wait between each bullet.
	UPROPERTY(Category = FireRate)
	float FireRate = 0.05f;

	// TODO: Not yet implemented.
	UPROPERTY(Category = Accuracy)
	float Spread = 0.0f;
}
