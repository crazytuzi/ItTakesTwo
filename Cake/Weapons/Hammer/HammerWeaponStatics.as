
import Cake.Weapons.Hammer.HammerWeaponActor;
import Cake.Weapons.Hammer.HammerWielderComponent;
import Cake.Weapons.Hammer.HammerSocketDefinition;

UFUNCTION(BlueprintPure, Category = "Weapon|Hammer")
FName GetHammerWeaponNameTag()
{
	return n"HammerWeaponActor";
}

UFUNCTION(Category = "Weapon|Hammer")
AHammerWeaponActor SpawnHammerWeapon(AHazeActor Wielder, TSubclassOf<AHammerWeaponActor> HammerWeaponActorClass)
{
	if (!HammerWeaponActorClass.IsValid())
	{
		PrintWarning("SpawnHammerWeapon() failed because HammerWeapon input was NULL");
		return nullptr;
	}
	else if (Wielder == nullptr)
	{
		PrintWarning("SpawnHammerWeapon() failed because wielder input was NULL");
		return nullptr;
	}

	UHammerWielderComponent WielderComponent = UHammerWielderComponent::GetOrCreate(Wielder);

	AHammerWeaponActor WeaponActor = Cast<AHammerWeaponActor>(SpawnActor(HammerWeaponActorClass.Get()));
	WeaponActor.MakeNetworked(Wielder, HammerWeaponActorClass.Get(), WielderComponent);
	WeaponActor.SetControlSide(Wielder);
	return WeaponActor;
}

UFUNCTION(Category = "Weapon|Hammer", Meta = (AdvancedDisplay = "InSocket", ReturnDisplayName = "HammerWeapon"))
AHammerWeaponActor AddHammerWeaponToWielder(AHazeActor Wielder, AHammerWeaponActor HammerWeapon, EHammerSocketDefinition InSocket = EHammerSocketDefinition::HammerWeapon_Back)
{
	if (HammerWeapon == nullptr)
	{
		PrintWarning("EquipHammerWeapon() failed because HammerWeapon input was NULL");
		return HammerWeapon;
	}

	if (Wielder == nullptr)
	{
		PrintWarning("EquipHammerWeapon() failed because wielder input twas NULL");
		return HammerWeapon;
	}

	HammerWeapon.AttachToActor(Wielder, GetHammerSocketNameFromDefinition(InSocket), EAttachmentRule::SnapToTarget);
	HammerWeapon.SetWielder(Wielder);
	UHammerWielderComponent::GetOrCreate(Wielder).SetHammer(HammerWeapon);
	HammerWeapon.OnHammerEquipped.Broadcast(Cast<AHazePlayerCharacter>(Wielder));

	return HammerWeapon;

}

UFUNCTION(Category = "Weapon|Hammer", Meta = (ReturnDisplayName = "HammerWeapon"))
AHammerWeaponActor RemoveHammerWeaponFromWielder(AHammerWeaponActor HammerWeapon)
{
	if (HammerWeapon == nullptr)
	{
		PrintWarning("UnequipHammerWeapon() failed because HammerWeapon was NULL");
		return HammerWeapon;
	}

	if(HammerWeapon.GetWielder() == nullptr)
	{
		PrintWarning("UnequipHammerWeapon() failed Weapon isn't attached to a wielder");
		return HammerWeapon;
	}

	UHammerWielderComponent WielderComponent = UHammerWielderComponent::Get(HammerWeapon.GetWielder());

	if(WielderComponent == nullptr)
	{
		PrintWarning("UnequipHammerWeapon() failed Weapon doesn't have a wielder");
		return HammerWeapon;
	}

	HammerWeapon.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
	HammerWeapon.OnHammerUnequipped.Broadcast(Cast<AHazePlayerCharacter>(HammerWeapon.GetWielder()));
	HammerWeapon.SetWielder(nullptr);
	WielderComponent.SetHammer(nullptr);
	return HammerWeapon;
}

/* Returns first Hammer weapon if its attached to the wielder */
UFUNCTION(BlueprintPure, Category = "Weapon|Hammer")
AHammerWeaponActor GetHammerWeaponFromWielder(AActor ActorWieldingTheHammer) 
{
	if (ActorWieldingTheHammer != nullptr)
	{
		TArray<AActor> AttachedActors;
		ActorWieldingTheHammer.GetAttachedActors(AttachedActors);
		for (auto AttachedActor : AttachedActors)
		{
			auto HammerWeaponActor = Cast<AHammerWeaponActor>(AttachedActor);
			if (HammerWeaponActor != nullptr)
			{
				return HammerWeaponActor;
			}
		}
	}
	return nullptr;
}

UFUNCTION(BlueprintPure, Category = "Weapon|Hammer")
UHammerWielderComponent GetHammerWielderComponentFromWielder(AActor Wielder) 
{
	return UHammerWielderComponent::Get(Wielder);
}

UFUNCTION(BlueprintPure, Category = "Weapon|Hammer")
UHammerWielderComponent GetOrCreateHammerWielderComponentFromWielder(AActor Wielder) 
{
	return UHammerWielderComponent::GetOrCreate(Wielder);
}

UFUNCTION(BlueprintPure, Category = "Weapon|Hammer")
bool HasHammerEquipped(AHazeActor PotentialHammerWielder)
{
	UHammerWielderComponent WielderComp = UHammerWielderComponent::Get(PotentialHammerWielder);
	if (WielderComp != nullptr)
		return WielderComp.GetHammer() != nullptr;
	return false;
}

UFUNCTION(Category = "Weapon|Hammer")
void SwitchHammerWieldingSocket(AHazeActor Wielder, EHammerSocketDefinition InSocket)
{
	AHammerWeaponActor HammerWeapon = GetHammerWeaponFromWielder(Wielder);
	if (HammerWeapon != nullptr)
	{
		if (HammerWeapon.GetWielder() == Wielder)
		{
			HammerWeapon.AttachToActor(Wielder, GetHammerSocketNameFromDefinition(InSocket), EAttachmentRule::SnapToTarget);
		}
	}
}




