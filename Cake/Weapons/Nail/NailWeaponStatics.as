import Cake.Weapons.Nail.NailWeaponActor;
import Cake.Weapons.Nail.NailWielderComponent;
import Cake.Weapons.Nail.NailSocketDefinition;
import Vino.Tutorial.TutorialNailThrowCapability;
import Cake.Weapons.Nail.NailSettings;

/**
 * Helper functions that are supposed to be used from capabilities, blueprints and actors - not from components
 */

UFUNCTION(BlueprintPure, Category = "Weapon|Nail")
FName GetNailWeaponNameTag()
{
	return n"NailWeaponActor";
}

UFUNCTION(Category = "Weapon|Nail")
ANailWeaponActor EquipNailWeapons_AS(AHazePlayerCharacter Wielder, UNailWeaponSettings Settings, int NumNailsToEquip = 3, bool bEquipByRecall = false) 
{
	if(!devEnsure(Settings != nullptr, "EquipNailWeapons() was called with NULL settings"))
		return nullptr;

	UNailWielderComponent WielderComp = UNailWielderComponent::GetOrCreate(Wielder);

	for(int i = 1; i <= NumNailsToEquip; ++i)
	{
		ANailWeaponActor Nail = SpawnNailWeapon(Wielder, Settings.NailWeaponActorClass);
		if(bEquipByRecall == false)
			AddNailWeaponToWielder(Wielder, Nail);
		else
			AddNailWeaponToWielderByRecall(Wielder, Nail);
	}

	Wielder.AddCapabilitySheet(Settings.CapabilitySheet, Instigator = WielderComp);
	WielderComp.NailHolster = Wielder.AddStaticMesh(Settings.NailHolserStaticMesh, n"Hips");
	Wielder.AddLocomotionAsset(Settings.IdleLocomotionAsset, WielderComp, 100);

	return nullptr;
}

UFUNCTION(Category = "Weapon|Nail")
void UnequipNailWeapons_AS(UNailWeaponSettings Settings) 
{
	AHazePlayerCharacter Wielder = Game::GetCody();
	TArray<ANailWeaponActor> AllNails = GetAllNails(Wielder);

	for (int i = AllNails.Num() - 1; i >= 0 ; i--)
		RemoveNailWeaponFromWielder(AllNails[i]);

	UNailWielderComponent NailWielderComp = UNailWielderComponent::Get(Wielder); 

	Wielder.RemoveAllCapabilitySheetsByInstigator(Instigator = NailWielderComp);

	bool bRemovedMesh = Wielder.RemoveStaticMesh(Settings.NailHolserStaticMesh);
	while(bRemovedMesh)
		bRemovedMesh = Wielder.RemoveStaticMesh(Settings.NailHolserStaticMesh);
	NailWielderComp.NailHolster = nullptr;

	Wielder.RemoveLocomotionAsset(Settings.IdleLocomotionAsset, NailWielderComp);

	NailWielderComp.Reset();

	for (int i = AllNails.Num() - 1; i >= 0 ; i--)
	{
		if (AllNails[i] != nullptr && AllNails[i].IsActorBeingDestroyed() == false)
		{
			AllNails[i].DestroyActor();
		}
	}
}

UFUNCTION(Category = "Weapon|Nail")
ANailWeaponActor SpawnNailWeapon(AHazeActor Wielder, TSubclassOf<ANailWeaponActor> NailWeaponActorClass)
{
	if (!NailWeaponActorClass.IsValid())
	{
		devEnsure(false, "SpawnNailWeapon() failed because weapon class was NULL");
		return nullptr;
	}
	else if (Wielder == nullptr)
	{
		devEnsure(false, "SpawnNailWeapon() failed because wielder twas NULL");
		return nullptr;
	}

	auto Component = UNailWielderComponent::GetOrCreate(Wielder);

	ANailWeaponActor WeaponActor = Cast<ANailWeaponActor>(SpawnActor(NailWeaponActorClass.Get(), bDeferredSpawn = true));
	WeaponActor.MakeNetworked(Component, NailWeaponActorClass.Get(), Component.SpawnedNailCount++);
	WeaponActor.SetControlSide(Wielder);
	FinishSpawningActor(WeaponActor);

	WeaponActor.Mesh.AddTickPrerequisiteComponent(Cast<AHazePlayerCharacter>(Wielder).Mesh);

	return WeaponActor;
}

UFUNCTION(Category = "Weapon|Nail", Meta = (AdvancedDisplay = "InSocket"))
void AddNailWeaponToWielderByRecall(AHazeActor Wielder, ANailWeaponActor NailWeapon, ENailSocketDefinition InSocket = ENailSocketDefinition::NailWeapon_Quiver)
{
	if (NailWeapon == nullptr)
	{
		PrintWarning("EquipNailWeapon() failed because HammerWeapon input was NULL");
		return;
	}
	else if (Wielder == nullptr)
	{
		PrintWarning("EquipNailWeapon() failed because wielder input twas NULL");
		return;
	}

	UNailWielderComponent WielderComp = UNailWielderComponent::GetOrCreate(Wielder); 

	if(WielderComp.IsNailBeingRecalled(NailWeapon))
	{
		devEnsure(false, "Nail is being recalled twice.. \n
		This will cause problems down the line. Aborting nail recall. \n 
		Please let Sydney know about this");
		return;
	}

	if(WielderComp.IsNailEquipped(NailWeapon))
	{
		devEnsure(false, "Trying to recall nail when it is already equipped.. \n
		This will cause problems down the line. Aborting nail recall. \n 
		Please let Sydney know about this");
		return;
	}

	// we want to detach it immediately and enable physics
	// The recall capability will initiate the recall itself. 
	NailWeapon.SetWielder(Wielder);
	WielderComp.AddNailWeapon(NailWeapon);
	RemoveNailWeaponFromWielder(NailWeapon);

	RecallNailToWielder(Wielder, NailWeapon);
}

UFUNCTION(Category = "Weapon|Nail", Meta = (AdvancedDisplay = "InSocket"))
void AddNailWeaponToWielder(AHazeActor Wielder, ANailWeaponActor NailWeapon, ENailSocketDefinition InSocket = ENailSocketDefinition::NailWeapon_Quiver)
{
	if (NailWeapon == nullptr)
	{
		devEnsure(false, "EquipNailWeapon() failed because the weapon was NULL");
		return;
	}
	else if (Wielder == nullptr)
	{
		devEnsure(false, "EquipNailWeapon() failed because wielder was NULL");
		return;
	}

	UNailWielderComponent WielderComp = UNailWielderComponent::GetOrCreate(Wielder); 

	if(WielderComp.IsNailEquipped(NailWeapon))
	{
		devEnsure(false, "Trying  AddNailWeaponToWielder multiple times.. \n
		Sign of things being handled in the wrong way.. \n 
		Please let Sydney know about this");
		return;
	}

	WielderComp.EquipNailWeapon(NailWeapon, InSocket);
}

UFUNCTION(Category = "Weapon|Nail", Meta = (ReturnDisplayName = "NailWeapon"))
ANailWeaponActor RemoveNailWeaponFromWielder(ANailWeaponActor NailWeapon)
{
	if (NailWeapon == nullptr)
	{
		PrintWarning("UnequipNailWeapon() failed because NailWeapon was NULL");
		return NailWeapon;
	}

	if(NailWeapon.GetWielder() == nullptr)
	{
		// PrintWarning("UnequipNailWeapon() failed Weapon isn't attached to a wielder");
		return NailWeapon;
	}

	UNailWielderComponent WielderComponent = UNailWielderComponent::Get(NailWeapon.GetWielder());

	if(WielderComponent == nullptr)
	{
		PrintWarning("UnequipNailWeapon() failed Weapon doesn't have a wielder");
		return NailWeapon;
	}

	WielderComponent.RemoveWeapon(NailWeapon);
	NailWeapon.SetWielder(nullptr);
	NailWeapon.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
	NailWeapon.Mesh.EnableAndApplyCachedPhysicsSettings();

	return NailWeapon;
}

UFUNCTION(Category = "Weapon|Nail")
void RecallAllNailsToWielder(AHazeActor Wielder) 
{
	auto NailsThrown = GetNailsThrown(Wielder);
	for (int i = NailsThrown.Num() - 1; i >= 0; --i)
	{
		UNailWielderComponent::Get(Wielder).RequestNailRecall(NailsThrown[i]);
	}
}

UFUNCTION(Category = "Weapon|Nail")
void RecallNailToWielder(AHazeActor Wielder, ANailWeaponActor ThrownNail) 
{
	auto NailsThrown = GetNailsThrown(Wielder);
	if (NailsThrown.FindIndex(ThrownNail) != -1)
	{
		UNailWielderComponent::Get(Wielder).RequestNailRecall(ThrownNail);
	}
}

UFUNCTION(BlueprintPure, Category = "Weapon|Nail")
UNailWielderComponent GetOrCreateNailWielderComponentFromWielder(AActor Wielder) 
{
	return UNailWielderComponent::GetOrCreate(Wielder);
}

/* returns first nail weapon found on the wielder */
UFUNCTION(BlueprintPure, Category = "Weapon|Nail")
ANailWeaponActor GetNailEquippedToHandFromWielder(AActor ActorWieldingTheNail)
{
	if (ActorWieldingTheNail != nullptr)
	{
		UNailWielderComponent WielderComponent = UNailWielderComponent::Get(ActorWieldingTheNail);
		if (WielderComponent != nullptr && WielderComponent.NailEquippedToHand != nullptr)
		{
			return Cast<ANailWeaponActor>(WielderComponent.NailEquippedToHand);
		}
	}
	return nullptr;
}

UFUNCTION(BlueprintPure, Category = "Weapon|Nail")
TArray<ANailWeaponActor> GetAllNails(AHazeActor InWielder)
{
 	UNailWielderComponent WielderComp = UNailWielderComponent::Get(InWielder);
	if(WielderComp != nullptr)
	{
		TArray<ANailWeaponActor> AllNails;

		// same as reserve, in AS.
		AllNails.Empty(3);

		if(WielderComp.NailEquippedToHand != nullptr)
			AllNails.Add(WielderComp.NailEquippedToHand);

		if(WielderComp.NailsThrown.Num() > 0)
			AllNails.Append(WielderComp.NailsThrown);

		if(WielderComp.NailsEquippedToBack.Num() > 0)
			AllNails.Append(WielderComp.NailsEquippedToBack);

		if(WielderComp.NailsBeingRecalled.Num() > 0)
		{
			for(const auto& NailRecallData : WielderComp.NailsBeingRecalled)
			{
				AllNails.Add(NailRecallData.Nail);
			}
		}

		return AllNails;
	}

	return TArray<ANailWeaponActor>();
}

UFUNCTION(BlueprintPure, Category = "Weapon|Nail")
TArray<ANailWeaponActor> GetNailsThrown(AHazeActor InWielder)
{
 	UNailWielderComponent WielderComp = UNailWielderComponent::Get(InWielder);
	if (WielderComp != nullptr)
		return WielderComp.NailsThrown;
	return TArray<ANailWeaponActor>();
}

UFUNCTION(BlueprintPure, Category = "Weapon|Nail")
TArray<ANailWeaponActor> GetNailsEquipped(AHazeActor InWielder)
{
 	UNailWielderComponent WielderComp = UNailWielderComponent::Get(InWielder);
	if (WielderComp != nullptr)
	{
		if (WielderComp.NailEquippedToHand != nullptr)
		{
			TArray<ANailWeaponActor> NailsEquipped = WielderComp.NailsEquippedToBack;
			NailsEquipped.Add(WielderComp.NailEquippedToHand);
			return NailsEquipped;
		}
		else
		{
			return WielderComp.NailsEquippedToBack;
		}
	}

	return TArray<ANailWeaponActor>();
}

UFUNCTION(BlueprintPure)
int GetNumNailsBeingRecalled()
{
 	UNailWielderComponent WielderComp = UNailWielderComponent::Get(Game::GetCody());
	if (WielderComp != nullptr)
		return WielderComp.NailsBeingRecalled.Num();
	return 0;
}

UFUNCTION(BlueprintPure, Category = "Weapon|Nail")
TArray<ANailWeaponActor> GetNailsBeingRecalled(AHazeActor InWielder)
{
	TArray<ANailWeaponActor> NailsRecalled;
 	UNailWielderComponent WielderComp = UNailWielderComponent::Get(InWielder);
	if (WielderComp != nullptr)
	{
		// same as reserve, in AS. 
		NailsRecalled.Empty(WielderComp.NailsBeingRecalled.Num());
		for(const auto& NailRecallData : WielderComp.NailsBeingRecalled)
		{
			NailsRecalled.Add(NailRecallData.Nail);
		}
	}
	return NailsRecalled;
}

UFUNCTION(BlueprintPure)
int GetNumNailsEquipped()
{
 	UNailWielderComponent WielderComp = UNailWielderComponent::Get(Game::GetCody());
	if (WielderComp != nullptr)
		return WielderComp.GetNumNailsEquipped();
	return 0;
}

/* nails on back + hand */
UFUNCTION(BlueprintPure, Category = "Weapon|Nail")
bool HasNailsEquipped(AHazeActor PotentialNailWielder)
{
	UNailWielderComponent WielderComp = UNailWielderComponent::Get(PotentialNailWielder);
	if (WielderComp != nullptr)
		return WielderComp.GetNumNailsEquipped() > 0;
	return false;
}

UFUNCTION(Category = "Weapon|Nail")
void SwitchNailWieldingSocket(AHazeActor InWielder, ANailWeaponActor InNailWeapon, ENailSocketDefinition InSocket)
{
 	UNailWielderComponent WielderComp = UNailWielderComponent::Get(InWielder);
	WielderComp.SwitchNailAttachSocket(InNailWeapon, InSocket);
}

bool GetCrosshairOriginAndDirection(AHazePlayerCharacter InPlayer, FVector& Origin, FVector& Direction)
{
	if (InPlayer == nullptr)
	{
		Print("CrosshairTrace failed. No Player wielder.");
		ensure(false);
		return false;
	}

	const FVector2D CrosshairLocation_UV = FVector2D(0.5f, 0.5f);
	if (!SceneView::DeprojectScreenToWorld_Relative
	(
		InPlayer,
		CrosshairLocation_UV,
		Origin,
		Direction
	))
	{
		Print("CrosshairTrace failed. Deprojection failed");
		ensure(false);
		return false;
	}

	return true;
}

UFUNCTION(BlueprintPure, Category = "Weapon|Nail")
ANailWeaponActor GetLastNailThrown(AHazeActor Wielder)
{
 	UNailWielderComponent WielderComp = UNailWielderComponent::Get(Wielder);
	if (WielderComp == nullptr)
		return nullptr;

	if (WielderComp.HasThrownNails())
		return WielderComp.NailsThrown.Last();

	return nullptr;
}

UFUNCTION(Category = "Weapon|Nail")
void StartNailTutorialInternal(AHazePlayerCharacter Player, TSubclassOf<UTutorialNailThrowCapability> CapabilityType)
{
	Player.AddCapability(CapabilityType);
}

UFUNCTION(Category = "Weapon|Nail")
void StopNailTutorialInternal(AHazePlayerCharacter Player, TSubclassOf<UTutorialNailThrowCapability> CapabilityType)
{
	Player.RemoveCapability(CapabilityType);
}

UFUNCTION(BlueprintPure, Category = "Weapon|MatchWeapon")
UStaticMeshComponent GetNailHolster() 
{
	return UNailWielderComponent::GetOrCreate(Game::GetCody()).NailHolster;
}

