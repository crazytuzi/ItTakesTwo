import Cake.Weapons.Sap.SapWeapon;
import Cake.Weapons.Sap.SapWeaponContainer;
import Cake.Weapons.Sap.SapWeaponWielderComponent;
import Vino.Movement.Swinging.SwingComponent;

UFUNCTION(Category = "Weapon|Sap")
ASapWeapon SpawnAndEquipSapGun(TSubclassOf<ASapWeapon> WeaponClass)
{
	auto Wielder = USapWeaponWielderComponent::Get(Game::GetCody());
	if (Wielder != nullptr)
	{
		UnequipAndDestroySapGun();
	}

	// Spawn the weapon
	ASapWeapon Weapon = Cast<ASapWeapon>(SpawnActor(WeaponClass));
	ensure(Weapon != nullptr);

	// After spawning the weapon, it adds the sheet which adds the wielder
	Wielder = USapWeaponWielderComponent::Get(Game::GetCody());
	ensure(Wielder != nullptr);

	Weapon.MakeNetworked(Game::GetCody(), Wielder, Wielder.WeaponSpawnCount);
	Weapon.Init(Game::GetCody());

	Weapon.MakeNetworked(Wielder, Wielder.WeaponSpawnCount);
	Weapon.SetControlSide(Wielder);

	// Attach it right away, so that cutscenes work as expected when loading
	// from checkpoints, where delaying until capability activation is not great
	Weapon.AttachToComponent(Game::Cody.Mesh, n"RightAttach");
	Weapon.Container.AttachToComponent(Game::Cody.Mesh, n"Backpack");

	USwingingComponent SwingComp = USwingingComponent::GetOrCreate(Game::Cody);
	SwingComp.UseWeaponSwingAttachSocketName();

	Wielder.WeaponSpawnCount++;
	Wielder.Weapon = Weapon;

	return Weapon;
}

UFUNCTION(BlueprintPure, Category = "Weapon|Sap")
ASapWeapon GetEquippedSapWeapon()
{
	auto Wielder = USapWeaponWielderComponent::Get(Game::GetCody());
	if (Wielder == nullptr)
		return nullptr;

	return Wielder.Weapon;
}

UFUNCTION(BlueprintPure, Category = "Weapon|Sap")
ASapWeaponContainer GetEquippedSapWeaponContainer()
{
	auto Weapon = GetEquippedSapWeapon();
	if (Weapon == nullptr)
		return nullptr;

	return Weapon.Container;
}

UFUNCTION(Category = "Weapon|Sap")
void UnequipAndDestroySapGun()
{
	auto Wielder = USapWeaponWielderComponent::Get(Game::GetCody());
	if (Wielder == nullptr)
		return;

	ASapWeapon Weapon = Wielder.Weapon;
	if (Weapon != nullptr)
	{
		Weapon.Container.DestroyActor();
		Weapon.DestroyActor();
	}

	USwingingComponent SwingComp = USwingingComponent::GetOrCreate(Game::Cody);
	SwingComp.UseDefaultSwingAttachSocketName();
}

UFUNCTION(Category = "Weapon|Sap")
void StartSapWeaponFullscreenAiming()
{
	auto Wielder = USapWeaponWielderComponent::Get(Game::Cody);
	if (Wielder == nullptr)
		return;

	Wielder.bFullscreenAim = true;
}

UFUNCTION(BlueprintPure, Category = "Weapon|Sap")
bool IsAimingWithSapWeapon()
{
	auto Wielder = USapWeaponWielderComponent::Get(Game::Cody);

	if (Wielder == nullptr)
		return false;

	return Wielder.bIsAiming;
}

UFUNCTION(Category = "Weapon|Sap")
void StopSapWeaponFullscreenAiming()
{
	auto Wielder = USapWeaponWielderComponent::Get(Game::Cody);
	if (Wielder == nullptr)
		return;

	Wielder.bFullscreenAim = false;
}

UFUNCTION(Category = "Weapon|Sap")
void SetSapWeaponShouldAimPredict(bool bAimPredict)
{
	auto Wielder = USapWeaponWielderComponent::Get(Game::GetCody());
	Wielder.bShouldAimPredict = bAimPredict;
}

UFUNCTION(Category = "Weapon|Sap")
void SetSapWeaponInheritGroundVelocity(bool bInheritVelocity)
{
	auto Wielder = USapWeaponWielderComponent::Get(Game::GetCody());
	Wielder.bShouldInheritGroundVelocity = bInheritVelocity;
}