
import Cake.Weapons.Match.MatchWeaponActor;
import Cake.Weapons.Match.MatchProjectileActor;
import Cake.Weapons.Match.MatchWielderComponent;
import Cake.Weapons.Match.MatchWeaponStatics;
import Cake.Weapons.Match.MatchWeaponSocketDefinition;

import Peanuts.Aiming.AutoAimStatics;
import Vino.Movement.Components.MovementComponent;
import Cake.Weapons.Match.MatchAntiAutoAimTargetComponent;
import Cake.Weapons.Sap.SapBatch;

UCLASS(abstract)
class UMatchWeaponShootCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"MatchWeaponShoot");
	default CapabilityTags.Add(n"MatchWeapon");
	default CapabilityTags.Add(n"Weapon");

	default CapabilityDebugCategory = n"LevelSpecific";

	UPROPERTY(Category = "Throw")
	float TimeBetweenShoots = 0.1f;
	float TimeStampShoots= -TimeBetweenShoots;

	// Settings
	//////////////////////////////////////////////////////////////////////////
	// Transients 

	AMatchWeaponActor Crossbow = nullptr;
	AMatchProjectileActor MatchToReload = nullptr;

	UHazeActiveCameraUserComponent CameraUser = nullptr;
	UPlayerHazeAkComponent PlayerAkComp = nullptr;
	UMatchWielderComponent WielderComp = nullptr;
	AHazePlayerCharacter Player = nullptr;
	UHazeCrumbComponent CrumbComp = nullptr;

	TArray<FMatchTargetData> QueuedTargetData;
	TArray<AMatchProjectileActor> MatchesWaitingTargetData;

	// Transient 
	//////////////////////////////////////////////////////////////////////////
	// Capability Functions

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WielderComp = UMatchWielderComponent::GetOrCreate(Owner);
		CameraUser = UHazeActiveCameraUserComponent::Get(Owner);
		Crossbow = WielderComp.GetMatchWeapon();
		PlayerAkComp = UPlayerHazeAkComponent::Get(Player);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
	}

	// // The remote side won't be able to activate unless this returns true
	// UFUNCTION(BlueprintOverride)
	// bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	// {
	// 	// this replaced the animation driven param (without being tested)
	// 	return !WielderComp.bAimAnimationBlocked;
	// 	// return !IsPlayingShootAnimation();
	// }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(WasActionStarted(ActionNames::WeaponFire) == false)
			return EHazeNetworkActivation::DontActivate;

		if(Time::GetGameTimeSince(TimeStampShoots) < TimeBetweenShoots)
			return EHazeNetworkActivation::DontActivate;

		if(WielderComp.bAiming == false)
			return EHazeNetworkActivation::DontActivate;

		// if(WielderComp.bOverheating)
		// 	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		// OutParams.EnableTransformSynchronizationWithTime();

		int32 MatchShootIndex = -1, MatchReloadIndex = -1;

		// This should always be true because we load the match 
		// with a reload animation when we equip the weapon in BP.
		ensure(Crossbow.GetLoadedMatch() != nullptr);

		MatchShootIndex = WielderComp.GetIndexByMatch(Crossbow.GetLoadedMatch());
		MatchReloadIndex = WielderComp.GetNextReloadMatchIndex();

		if(WielderComp.bOverheating)
			OutParams.AddActionState(n"EmptyShotFired");

		OutParams.AddNumber(n"MatchIndexShoot", MatchShootIndex);
		OutParams.AddNumber(n"MatchIndexReload", MatchReloadIndex);
 		OutParams.AddVector(n"PlayerViewRotationVector", Player.GetPlayerViewRotation().Vector());
	}

	void HandleEmptyShotFired()
	{
		Player.PlayerHazeAkComp.HazePostEvent(Crossbow.EmptyShotFiredEvent);
		// Print("Empty shot fired", 5.f, FLinearColor::Red);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams) 
	{
		const bool bEmptyShotFired = ActivationParams.GetActionState(n"EmptyShotFired");
		if(bEmptyShotFired)
		{
			HandleEmptyShotFired();
			return;
		}

		if (ActivationParams.IsStale())
		{
			StaleActivation();
			return;
		}

		// make sure that we dont shoot to often
		TimeStampShoots = Time::GetGameTimeSeconds();

		// Get the match which HasControl sent over
		MatchToReload = WielderComp.GetMatchByIndex( ActivationParams.GetNumber(n"MatchIndexReload"));

		AMatchProjectileActor MatchToShoot = WielderComp.GetMatchByIndex(
			ActivationParams.GetNumber(n"MatchIndexShoot")
		);

		//	Bail. It should always be valid.
		if (!ensure(MatchToShoot != nullptr))
			return;

		// separated for easier debugging
		if (!ensure(MatchToReload != nullptr))
			return;

		if (Crossbow.GetLoadedMatch() != nullptr && Crossbow.GetLoadedMatch() != MatchToShoot)
		{
			// We should never get here! But we keep this snippet in case 
			// someone does some bad refactoring. It has happened before due
			// to stale capability activations. 
			ensure(false);

 			Crossbow.GetLoadedMatch().ActivateMatch();
 			Crossbow.GetLoadedMatch().DeactivateMatch();
			SwitchMatchSocket(
				Player,
				Crossbow,
				Crossbow.GetLoadedMatch(),
				EMatchWeaponSocketDefinition::WielderQuiverSocket
			);
			Crossbow.GetLoadedMatch().HideMatch(true);
			Crossbow.SetLoadedMatch(nullptr);
		}

		if (Crossbow.GetLoadedMatch() == nullptr)
		{
			MatchToShoot.ActivateMatch();
			MatchToShoot.DeactivateMatch();
			SwitchMatchSocket(
				Player,
				WielderComp.GetMatchWeapon(),
				MatchToShoot,
				EMatchWeaponSocketDefinition::MatchCrossbowSocket
			);
			MatchToShoot.HideMatch(false);
			WielderComp.GetMatchWeapon().SetLoadedMatch(MatchToShoot);
		}

		// rotate replica to the correct rotation 
		if (!HasControl())
 			CameraUser.SnapCamera(ActivationParams.GetVector(n"PlayerViewRotationVector"));

		WielderComp.bAimAnimationBlocked = true;
		HandleShoot();
		HandleReload();

		// Action state so that other capabilities can react to shooting
		Player.SetCapabilityActionState(n"MatchShoot", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams) 
	{
		if (DeactivationParams.IsStale())
		{
			StaleDeactivation();
			return;
		}

		WielderComp.bAimAnimationBlocked = false;
  		MatchToReload = nullptr;
	}

	void StaleActivation()
	{

		if (Crossbow.GetLoadedMatch() != nullptr)
		{
 			Crossbow.GetLoadedMatch().ActivateMatch();
			Crossbow.GetLoadedMatch().DeactivateMatch();
			SwitchMatchSocket(
				Player,
				Crossbow,
				Crossbow.GetLoadedMatch(),
				EMatchWeaponSocketDefinition::WielderQuiverSocket
			);
			Crossbow.GetLoadedMatch().HideMatch(true);
		}
		Crossbow.SetLoadedMatch(nullptr);
	}

	void StaleDeactivation()
	{
		WielderComp.bAimAnimationBlocked = false;
		MatchToReload = nullptr;
	}

	void GatherTargetData_Shoot(FMatchTargetData& TargetData)
	{
		// Didn't hit anything. Just fire and forget.
		// (data needed has been set in aim capability already)
		if(!TargetData.IsHoming())
			return;

		// Complex trace isn't needed for auto aim
		if(TargetData.IsAutoAiming())
			return;

		// complex trace the component we hit while simple tracing to ensure that we hit the visible part of it
		FHitResult ComplexHitData;
		if(TargetData.ComplexTraceTargetComponent(TargetData.TraceStart, TargetData.TraceEnd, ComplexHitData))
		{

			TargetData.SetTargetLocation(
				ComplexHitData.ImpactPoint,
				ComplexHitData.Component,
				ComplexHitData.BoneName
			);

			return;	/// !!!
		}

		// Do a very expensive complex trace against the world to find
		// out what is behind the thing we initially hit. This will only happen 
		// once we press the trigger but it is very long... @TODO profile this!?
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Reserve(2);
		ActorsToIgnore.Add(Player);
		ActorsToIgnore.Add(WielderComp.GetMatchWeapon());
		if(System::LineTraceSingle(
			TargetData.TraceStart,
			TargetData.TraceEnd,
			ETraceTypeQuery::WeaponTrace,
			true, // TraceComplex!!!
			ActorsToIgnore,
			EDrawDebugTrace::None,
			ComplexHitData,
			true
		))
		{

			TargetData.SetTargetLocation(
				ComplexHitData.ImpactPoint,
				ComplexHitData.Component,
				ComplexHitData.BoneName
			);

			// System::DrawDebugPoint(TargetData.GetTargetLocation(), 20.f, FLinearColor::Green, 5.f);
		}
		else
		{
			TargetData.bHoming = false;
		}

		ASapBatch Sap = Cast<ASapBatch>(TargetData.Component.Owner);
		if (Sap != nullptr)
		{
			// @TODO: we should probably ignore the sap when this happen during the shoot capability phase.
			// we'll also need a callback if the sap gets nuked mid match flight
			ensure(Sap.bIsEnabled);
			ensure(!Sap.bHasExploded);
			ensure(!Sap.bWantsToExplode);
		}

	}

	UFUNCTION()
 	void HandleShoot()
	{
		if (HasControl())
		{
			GatherTargetData_Shoot(WielderComp.TargetData);
			NetSendTargetData(WielderComp.TargetData);
			FHazeDelegateCrumbParams CrumbParams;
			CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbShootTargetData"), CrumbParams);
		}
		else
		{
			if (QueuedTargetData.Num() != 0)
			{
				Crossbow.ShootMatch(QueuedTargetData[0]);
				QueuedTargetData.RemoveAt(0);
			}
			else
			{
				auto Match = Crossbow.TakeMatchToShoot();
				ensure(Match != nullptr);
				MatchesWaitingTargetData.Add(Match);
			}
		}

		// Attach next match to wielder hand 
		MatchToReload.DeactivateMatch();
		SwitchMatchSocket(
			Player,
			WielderComp.GetMatchWeapon(),
			MatchToReload,
  			EMatchWeaponSocketDefinition::WielderLeftHandSocket
		);
		MatchToReload.HideMatch(false);
	}

	UFUNCTION(NetFunction)
	void NetSendTargetData(FMatchTargetData TargetData)
	{
		QueuedTargetData.Add(TargetData);
	}

	UFUNCTION()
	void CrumbShootTargetData(const FHazeDelegateCrumbData& CrumbData)
	{
		if (HasControl())
		{
			ensure(QueuedTargetData.Num() == 1);
			Crossbow.ShootMatch(QueuedTargetData[0]);
			QueuedTargetData.RemoveAt(0);
		}
		else if (MatchesWaitingTargetData.Num() != 0)
		{
			ensure(QueuedTargetData.Num() != 0);
			ensure(QueuedTargetData.Num() == 1);
			ensure(MatchesWaitingTargetData.Num() == 1);
			Crossbow.DelayedShootMatch(MatchesWaitingTargetData[0], QueuedTargetData[0]);
			MatchesWaitingTargetData.RemoveAt(0);
			QueuedTargetData.RemoveAt(0);
		}

		if(WielderComp.IsFinalShot())
		{
			PlayerAkComp.HazePostEvent(Crossbow.LastShotFiredEvent);
			//Print("last Shot fire", 1.f, FLinearColor::Yellow);
		}
		else
		{
			//Print("Normal shot fired", 1.f, FLinearColor::Green);
			PlayerAkComp.HazePostEvent(Crossbow.ShotFiredEvent);
		}

		Crossbow.SetAnimBoolParam(n"SniperShoot", true);
		Player.SetAnimBoolParam(n"SniperShoot", true);
	}

	UFUNCTION()
	void HandleReload()
	{
		// Move reloading match from wielder hand to crossbow.
		SwitchMatchSocket(
			Player,
			WielderComp.GetMatchWeapon(),
			MatchToReload,
			EMatchWeaponSocketDefinition::MatchCrossbowSocket
		);
		WielderComp.GetMatchWeapon().SetLoadedMatch(MatchToReload);
	}

}


