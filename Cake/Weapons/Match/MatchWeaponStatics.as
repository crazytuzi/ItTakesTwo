
import Cake.Weapons.Match.MatchWeaponActor;
import Cake.Weapons.Match.MatchProjectileActor;
import Cake.Weapons.Match.MatchWielderComponent;
import Cake.Weapons.Match.MatchWeaponSocketDefinition;
import Vino.Movement.Swinging.SwingComponent;
import Cake.Weapons.Match.MatchWeaponSettings;
import Cake.Weapons.Match.MatchQuiverActor;

/**
 * Helper functions that are supposed to be used from 
 * capabilities, blueprints and actors - not from components
 */

/* It also unequip and destroys the previous weapon */
UFUNCTION(Category = "Weapon|MatchWeapon", Meta = (ReturnDisplayName = "MatchWeapon"))
AMatchWeaponActor SpawnAndEquipDasMatchWeapon(UMatchWeaponComposeableSettings InSettings)
{
	if(InSettings == nullptr)
		return nullptr;

	AHazePlayerCharacter Wielder = Game::GetMay();
	UMatchWielderComponent WielderComponent = UMatchWielderComponent::GetOrCreate(Wielder);

	UnequipAndDestroyDasMatchWeapon();

	WielderComponent.Settings = InSettings;

	AMatchWeaponActor Weapon = SpawnMatchWeapon(Wielder, InSettings.MatchWeaponActorClass);
	AddMatchWeaponToWielder(Wielder, Weapon, EMatchWeaponSocketDefinition::WielderRightHandSocket);

	WielderComponent.AddQuiver(InSettings.QuiverMesh);

	AMatchProjectileActor MatchToBeLoadead = nullptr;
	for(int i = 0; i < InSettings.NumMatchesToRecycle; ++i)
	{
		AMatchProjectileActor SpawnedMatch = SpawnMatch(Wielder, InSettings.MatchProjectileActorClass);
		AddMatchToWielder(Wielder, SpawnedMatch, EMatchWeaponSocketDefinition::WielderQuiverSocket);
		MatchToBeLoadead = SpawnedMatch;
	}

	SwitchMatchSocket(Wielder, Weapon, MatchToBeLoadead, EMatchWeaponSocketDefinition::MatchCrossbowSocket);
	Weapon.SetLoadedMatch(MatchToBeLoadead);
	MatchToBeLoadead.SetActorHiddenInGame(false);

	Wielder.AddCapabilitySheet(InSettings.CapabilitySheet, EHazeCapabilitySheetPriority::Normal, WielderComponent);

	// // move to capabilty?=
	// Wielder.AddLocomotionAsset(InSettings.LocomotionAsset_NotAiming, WielderComponent);

	return Weapon;
}

UFUNCTION(Category = "Weapon|MatchWeapon")
void UnequipAndDestroyDasMatchWeapon()
{
	AHazePlayerCharacter Wielder = Game::GetMay();

	UMatchWielderComponent WielderComponent = UMatchWielderComponent::GetOrCreate(Wielder);
	if(WielderComponent.Settings == nullptr)
		return;

	Wielder.RemoveAllCapabilitySheetsByInstigator(WielderComponent);

	WielderComponent.RemoveQuiver();

	AMatchWeaponActor Weapon = WielderComponent.GetMatchWeapon();
	if(Weapon != nullptr)
	{
		RemoveMatchWeaponFromWielder(Weapon);
		Weapon.DestroyActor();
	}

	TArray<AMatchProjectileActor> Matches = GetMatches(Wielder);

	for(int i = Matches.Num()-1; i >= 0; i--)
	{
		if(Matches[i] != nullptr)
		{
			AMatchProjectileActor MatchToBeDestroyed = RemoveMatchFromWielder(Wielder, Matches[i]);
			MatchToBeDestroyed.DestroyActor();
		}
	}

	WielderComponent.Reset();
	WielderComponent.Settings = nullptr;
}

UFUNCTION(Category = "Weapon|MatchWeapon", Meta = (ReturnDisplayName = "Match"))
AMatchProjectileActor SpawnMatch(AHazeActor Wielder, TSubclassOf<AMatchProjectileActor > MatchProjectileActorClass)
{
 	UMatchWielderComponent WielderComponent = UMatchWielderComponent::GetOrCreate(Wielder);
	AMatchProjectileActor Match = Cast<AMatchProjectileActor>(SpawnActor(MatchProjectileActorClass.Get()));
	Match.MakeNetworked(WielderComponent, MatchProjectileActorClass.Get(), WielderComponent.SpawnedMatchCount++);
	Match.SetControlSide(Wielder);
	return Match;
}

UFUNCTION(Category = "Weapon|MatchWeapon", Meta = (AdvancedDisplay = "InSocket", ReturnDisplayName = "Match"))
AMatchProjectileActor AddMatchToWielder(
	AHazeActor Wielder,
	AMatchProjectileActor Match,
	EMatchWeaponSocketDefinition InSocket = EMatchWeaponSocketDefinition::WielderQuiverSocket
)
{
	Match.DisableAndCachePhysicsSettings();

	// !!! Attaching the matches to the wielder is a legacy thing
//	const FName SocketName = GetMatchWeaponSocketNameFromDefinition(InSocket);
//	Match.AttachToActor(Wielder, SocketName, EAttachmentRule::SnapToTarget);

	UMatchWielderComponent WielderComp = UMatchWielderComponent::GetOrCreate(Wielder);
 	WielderComp.AddMatch(Match);
	Match.DeactivateMatch();
	Match.DisableActor(Match);
	Match.AddIgnoreActor(Wielder);

	////////////////////////////////////////////////////////////////////////////
	// Was added due to debugging purposes
	// for(AMatchProjectileActor AddedMatch_X : WielderComp.Matches)
	// {
	// 	for(AMatchProjectileActor AddedMatch_Y : WielderComp.Matches)
	// 	{
	// 		AddedMatch_X.AddIgnoreActor(AddedMatch_Y);
	// 		AddedMatch_Y.AddIgnoreActor(AddedMatch_X);
	// 	}
	// }
	// TArray<AActor> AttachedActors;
	// Wielder.GetAttachedActors(AttachedActors);
	// for(const AActor AttachedActor : AttachedActors)
	// {
	// 	AMatchWeaponActor Weapon = Cast<AMatchWeaponActor>(AttachedActor);
	// 	if(Weapon != nullptr)
	// 	{
	// 		Match.AddIgnoreActor(Weapon);
	// 		break;
	// 	}
	// }
	////////////////////////////////////////////////////////////////////////////

	return Match;
 }

UFUNCTION(Category = "Weapon|MatchWeapon", meta = (ReturnDisplayName = "Removed Match"))
AMatchProjectileActor RemoveMatchFromWielder(AHazeActor Wielder, AMatchProjectileActor Match)
 {
 	UMatchWielderComponent WielderComponent = UMatchWielderComponent::Get(Wielder);
	WielderComponent.RemoveMatch(Match);
	auto Rule = EDetachmentRule::KeepWorld;
 	Match.DetachFromActor(Rule,Rule,Rule);
	Match.RemoveIgnoreActor(Match);
	Match.RemoveIgnoreActor(Wielder);
	Match.ApplyCachedPhysicsSettings();
	return Match;
 }

UFUNCTION(Category = "Weapon|MatchWeapon", meta = (ReturnDisplayName = "Detached Match"))
AMatchProjectileActor DetachMatch(AMatchProjectileActor Match)
 {
	auto Rule = EDetachmentRule::KeepWorld;
 	Match.DetachFromActor(Rule,Rule,Rule);
	Match.ApplyCachedPhysicsSettings();
	return Match;
 }

UFUNCTION(Category = "Weapon|MatchWeapon")
void SwitchMatchSocket(
	AHazeActor Wielder,
	AMatchWeaponActor MatchWeapon,
	AMatchProjectileActor Match,
	EMatchWeaponSocketDefinition InSocketDefinition
)
 {

 	 if (InSocketDefinition == EMatchWeaponSocketDefinition::MatchCrossbowSocket)
 	 {
		Match.AttachToActor(
			MatchWeapon,
			GetMatchWeaponSocketNameFromDefinition(InSocketDefinition),
			EAttachmentRule::SnapToTarget
		);
 	 }

	 //
	 // !!! Attaching non active matches to the wielder is a legacy thing.
	 //
 
//	 const FName Socket = GetMatchWeaponSocketNameFromDefinition(InSocketDefinition);
// 	 AActor Actor = nullptr;
// 	 if (InSocketDefinition == EMatchWeaponSocketDefinition::MatchCrossbowSocket)
// 	 {
// 		Actor = MatchWeapon;
// 	 }
// 	 else if (InSocketDefinition == EMatchWeaponSocketDefinition::WielderQuiverSocket
// 		   || InSocketDefinition == EMatchWeaponSocketDefinition::WielderLeftHandSocket
// 		   || InSocketDefinition == EMatchWeaponSocketDefinition::WielderRightHandSocket)
// 	 {
// 		 Actor = Wielder;
// 	 }
// 
// 	ensure(Actor != nullptr);
// 	Match.AttachToActor(Actor, Socket, EAttachmentRule::SnapToTarget);

  }

 // MATCH 
 //////////////////////////////////////////////////////////////////////////
 // MATCH WEAPON
 
 UFUNCTION(Category = "Weapon|MatchWeapon")
 void SwitchMatchWeaponSocket(
	 AHazeActor Wielder,
	 AMatchWeaponActor MatchWeapon,
	 EMatchWeaponSocketDefinition InSocketDefinition
 )
 {
	 if (MatchWeapon.GetWielder() != Wielder)
	 {
		 ensure(false); // not the same wielder 
		 return;
	 }

	 const FName Socket = GetMatchWeaponSocketNameFromDefinition(InSocketDefinition);
	 MatchWeapon.AttachToActor(Wielder, Socket, EAttachmentRule::SnapToTarget);
 }

UFUNCTION(Category = "Weapon|MatchWeapon", Meta = (ReturnDisplayName = "MatchWeapon"))
AMatchWeaponActor SpawnMatchWeapon(AHazeActor Wielder, TSubclassOf<AMatchWeaponActor> MatchWeaponActorClass)
{
 	UMatchWielderComponent WielderComponent = UMatchWielderComponent::GetOrCreate(Wielder);
	AMatchWeaponActor MatchWeapon = Cast<AMatchWeaponActor>(SpawnActor(MatchWeaponActorClass.Get()));
	MatchWeapon.MakeNetworked(WielderComponent, MatchWeaponActorClass.Get(), WielderComponent.SpawnedWeaponCount++);
	MatchWeapon.SetControlSide(Wielder);
	return MatchWeapon;
}

 UFUNCTION(Category = "Weapon|MatchWeapon", Meta = (AdvancedDisplay = "InSocket", ReturnDisplayName = "MatchWeapon"))
 AMatchWeaponActor AddMatchWeaponToWielder(AHazeActor Wielder, AMatchWeaponActor MatchWeapon,
	 EMatchWeaponSocketDefinition InSocket = EMatchWeaponSocketDefinition::WielderBackSocket)
 {
	const FName SocketName = GetMatchWeaponSocketNameFromDefinition(InSocket);
	MatchWeapon.AttachToActor(Wielder, SocketName, EAttachmentRule::SnapToTarget);
	MatchWeapon.SetWielder(Wielder);
 	UMatchWielderComponent::GetOrCreate(Wielder).SetMatchWeapon(MatchWeapon);

	USwingingComponent WielderSwingComp = USwingingComponent::GetOrCreate(Wielder);
	WielderSwingComp.UseWeaponSwingAttachSocketName();

	return MatchWeapon;
 }
 
 UFUNCTION(Category = "Weapon|MatchWeapon", Meta = (ReturnDisplayName = "MatchWeapon"))
AMatchWeaponActor RemoveMatchWeaponFromWielder(AMatchWeaponActor MatchWeapon)
 {
	AHazeActor Wielder = MatchWeapon.GetWielder();

	USwingingComponent WielderSwingComp = USwingingComponent::Get(Wielder);
	WielderSwingComp.UseDefaultSwingAttachSocketName();

 	UMatchWielderComponent WielderComponent = UMatchWielderComponent::Get(Wielder);
 	WielderComponent.SetMatchWeapon(nullptr);
 	MatchWeapon.SetWielder(nullptr);
	auto Rule = EDetachmentRule::KeepWorld;
 	MatchWeapon.DetachFromActor(Rule,Rule,Rule);

	return MatchWeapon;
 }

UFUNCTION(BlueprintPure, Category = "Weapon|MatchWeapon")
bool HasMatchWeaponEquipped(AHazeActor PotentialMatchWeaponWielder)
{
	UMatchWielderComponent WielderComp = UMatchWielderComponent::Get(PotentialMatchWeaponWielder);
	if (WielderComp != nullptr)
		return WielderComp.GetMatchWeapon() != nullptr;
	return false;
}

UFUNCTION(BlueprintPure, Category = "Weapon|MatchWeapon")
AMatchWeaponActor GetMatchWeapon() 
{
	return UMatchWielderComponent::GetOrCreate(Game::GetMay()).GetMatchWeapon();
}

UFUNCTION(BlueprintPure, Category = "Weapon|MatchWeapon")
AMatchWeaponQuiver GetMatchWeaponQuiver() 
{
	// @TODO: replace quiver mesh with quiver actor...
	// 
	// this function was pre-added with the sole purpose of 
	// allowing us to feed it into sequencer before the change is made
	// 
	return nullptr;
}

UFUNCTION(BlueprintPure, Category = "Weapon|MatchWeapon")
UStaticMeshComponent GetMatchQuiver() 
{
	return UMatchWielderComponent::GetOrCreate(Game::GetMay()).QuiverMesh;
}

UFUNCTION(BlueprintPure, Category = "Weapon|MatchWeapon")
AMatchWeaponActor GetMatchWeaponFromWielder(AActor ActorWieldingTheMatchWeapon) 
{
	ensure(ActorWieldingTheMatchWeapon != nullptr);

	TArray<AActor> AttachedActors;
	ActorWieldingTheMatchWeapon.GetAttachedActors(AttachedActors);
	for (auto AttachedActor : AttachedActors)
	{
		auto MatchWeaponActor = Cast<AMatchWeaponActor>(AttachedActor);
		if (MatchWeaponActor != nullptr)
		{
			return MatchWeaponActor;
		}
	}
	return nullptr;
}

UFUNCTION(BlueprintPure, Category = "Weapon|MatchWeapon")
UMatchWielderComponent GetOrCreateMatchWielderComponentFromWielder(AActor Wielder) 
{
	return UMatchWielderComponent::GetOrCreate(Wielder);
}

UFUNCTION(BlueprintPure, Category = "Weapon|MatchWeapon")
TArray<AMatchProjectileActor> GetMatches(AHazeActor InWielder)
{
	TArray<AMatchProjectileActor> MatchesEquipped;
 	UMatchWielderComponent WielderComp = UMatchWielderComponent::Get(InWielder);
	if (WielderComp != nullptr)
		WielderComp.GetMatches(MatchesEquipped);
	return MatchesEquipped;
}

UFUNCTION(BlueprintPure, Category = "Weapon|MatchWeapon")
TArray<AMatchProjectileActor> GetMatchesActivated(AHazeActor InWielder)
{
	TArray<AMatchProjectileActor> MatchesActivated;
 	UMatchWielderComponent WielderComp = UMatchWielderComponent::Get(InWielder);
	if (WielderComp != nullptr)
		WielderComp.GetMatchesActivated(MatchesActivated);
	return MatchesActivated;
}

UFUNCTION(BlueprintPure, Category = "Weapon|MatchWeapon")
TArray<AMatchProjectileActor> GetMatchesDeactivated(AHazeActor InWielder)
{
	TArray<AMatchProjectileActor> MatchesActivated;
 	UMatchWielderComponent WielderComp = UMatchWielderComponent::Get(InWielder);
	if (WielderComp != nullptr)
		WielderComp.GetMatchesDeactivated(MatchesActivated);
	return MatchesActivated;
}

UFUNCTION(Category = "Weapon|MatchWeapon")
void StartMatchWeaponFullscreenAiming(AHazeActor InWielder)
{
	auto WielderComp = UMatchWielderComponent::Get(InWielder);
	if (WielderComp == nullptr)
		return;

	WielderComp.bFullscreenAim = true;
}

UFUNCTION(Category = "Weapon|MatchWeapon")
void StopMatchWeaponFullscreenAiming(AHazeActor InWielder)
{
	auto WielderComp = UMatchWielderComponent::Get(InWielder);
	if (WielderComp == nullptr)
		return;

	WielderComp.bFullscreenAim = false;
}

UFUNCTION(BlueprintPure, Category = "Weapon|MatchWeapon")
bool IsAimingWithMatchWeapon()
{
	auto WielderComp = UMatchWielderComponent::Get(Game::May);
	if (WielderComp == nullptr)
		return false;

	return WielderComp.bAiming;
}