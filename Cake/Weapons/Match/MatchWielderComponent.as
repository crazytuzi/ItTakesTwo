import Cake.Weapons.Match.MatchWeaponActor;
import Cake.Weapons.Match.MatchProjectileActor;
import Vino.Camera.Components.CameraUserComponent;
import Cake.Weapons.Match.MatchWeaponSettings;

event void FMatchChargeUpdated(const int ChargesFloored);

UCLASS(HideCategories = "Cooking Collision ComponentReplication Sockets Tags Sockets")
class UMatchWielderComponent : UActorComponent 
{
	/* reference to all match actors that have been equipped. */
	TArray<AMatchProjectileActor> Matches;

	private TArray<AMatchProjectileActor> MatchesActivated;
	private TArray<AMatchProjectileActor> MatchesDeactivated;
	private AMatchWeaponActor MatchWeaponActor = nullptr;

 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FMatchChargeUpdated OnMatchChargeUpdated;

	UPROPERTY()
	UStaticMeshComponent QuiverMesh;

	UPROPERTY()
	bool bAiming = false;

	UPROPERTY()
	bool bOverheating = false;

	// Angles (Yaw and Pitch) the wielder is currently 
	// aiming at (primarily used for aim and blend-spaces)
	UPROPERTY()
	FVector2D AimAngles;

	UPROPERTY()
	float Charges = 3.f;

	bool bAimAnimationBlocked = false;
	bool bFullscreenAim = false;
	FVector2D AimPositionPercent = FVector2D(0.f, 0.f);
	float ShuffleRotation = 0.f;
	FHazeAcceleratedRotator LookAtRot;
	float OverheatAccumulated = 0.f;

	UMatchWeaponComposeableSettings Settings;

	FMatchTargetData TargetData;

	int SpawnedMatchCount = 0;
	int SpawnedWeaponCount = 0;

	/*
		!!! Make sure to reset all new variables in this function !!!

		We use this function because we are not allowed
		to destroy components manually, in network, in between player resets. 

		(Due to components having their network identifier on the player, which resets during the player reset)
	*/
	void Reset()
	{
		bAiming = false;
		bOverheating = false;
		AimAngles = FVector2D::ZeroVector;
		Charges = 3.f;
		bAimAnimationBlocked = false;
		bFullscreenAim = false;
		TargetData = FMatchTargetData();
		AimPositionPercent = FVector2D(0.f, 0.f);
		ShuffleRotation = 0.f;
		LookAtRot = FHazeAcceleratedRotator();
		OverheatAccumulated = 0.f;
	}

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
    {
		for(AMatchProjectileActor Match : Matches)
		{
			if (Match != nullptr && Match.IsActorBeingDestroyed() == false)
			{
				Match.DestroyActor();
			}
		}

		if (MatchWeaponActor != nullptr && MatchWeaponActor.IsActorBeingDestroyed() == false)
			MatchWeaponActor.DestroyActor();

		AHazePlayerCharacter Wielder = Game::GetMay();
		if(Wielder != nullptr)
		{
			Wielder.OnPreSequencerControl.Unbind(this, n"HandlePreSequencerControl");
			Wielder.OnPostSequencerControl.Unbind(this, n"HandlePostSequencerControl");
		}
    }

	void AddQuiver(UStaticMesh QuiverAsset)
	{
		AHazePlayerCharacter Wielder = Game::GetMay();
		QuiverMesh = Wielder.AddStaticMesh(QuiverAsset, SocketNames::Backpack_Socket);

		Wielder.OnPreSequencerControl.AddUFunction(this, n"HandlePreSequencerControl");
		Wielder.OnPostSequencerControl.AddUFunction(this, n"HandlePostSequencerControl");
	}

	void RemoveQuiver()
	{
		AHazePlayerCharacter Wielder = Game::GetMay();

		// if the settings isn't valid then we're calling this in the wrong order
		ensure(Settings != nullptr);

		// remove the one reference in the current settings
		Wielder.RemoveStaticMesh(Settings.QuiverMesh);

		QuiverMesh = nullptr;

		Wielder.OnPreSequencerControl.Unbind(this, n"HandlePreSequencerControl");
		Wielder.OnPostSequencerControl.Unbind(this, n"HandlePostSequencerControl");
	}

	UFUNCTION()	
	void HandlePreSequencerControl(FHazePreSequencerControlParams Params)
	{
		if(QuiverMesh != nullptr)
			QuiverMesh.SetHiddenInGame(true, false);
	}

	UFUNCTION()	
	void HandlePostSequencerControl(FHazePostSequencerControlParams Params)
	{
		if(QuiverMesh != nullptr)
			QuiverMesh.SetHiddenInGame(false, false);
	}

	UFUNCTION()
	void SetMatchWeapon(AMatchWeaponActor InMatchWeapon) property
	{
		MatchWeaponActor = InMatchWeapon;
	}

	UFUNCTION()
	void AddMatch(AMatchProjectileActor InMatch)
	{
		// Clean up stale references
		Matches.RemoveSwap(nullptr);

		if (InMatch == nullptr)
		{ 
			Warning(GetName() + "AddMatch() failed. Input InMatch == null");
			return;
		}

		Matches.AddUnique(InMatch);
		InMatch.OnMatchActivated.AddUFunction(this, n"HandleMatchActivated");
		InMatch.OnMatchDeactivated.AddUFunction(this, n"HandleMatchDeactivated");
	}

	UFUNCTION()
	void RemoveMatch(AMatchProjectileActor InMatch)
	{
		if (InMatch == nullptr)
		{
			Warning(GetName() + "RemoveMatch() failed. Input InMatch == null");
			return;
		}

		Matches.Remove(InMatch);
		MatchesActivated.Remove(InMatch);
		MatchesDeactivated.Remove(InMatch);
		InMatch.OnMatchActivated.Unbind(this, n"HandleMatchActivated");
		InMatch.OnMatchDeactivated.Unbind(this, n"HandleMatchDeactivated");
	}

	UFUNCTION()
	void HandleMatchActivated(AMatchProjectileActor InMatch)
	{
		if (InMatch == nullptr)
			return;

		ensure(MatchesActivated.Contains(InMatch) == false);

		MatchesActivated.Add(InMatch);
		MatchesDeactivated.Remove(InMatch);
	}

	UFUNCTION()
	void HandleMatchDeactivated(AMatchProjectileActor InMatch)
	{
		if (InMatch == nullptr)
			return;

		ensure(MatchesDeactivated.Contains(InMatch) == false);

		MatchesDeactivated.Add(InMatch);
		MatchesActivated.Remove(InMatch);
	}

	void GetNextShootAndReloadMatch(
		AMatchProjectileActor& MShot,
		AMatchProjectileActor& MReload
	) const
	{
		if (Matches.Num() == 1)
		{
			MShot = MReload = Matches[0];
		}
		else if (Matches.Num() > 1)
		{
			if (MatchesDeactivated.Num() == 1)
			{
				MShot = MatchesDeactivated.Last(0);
				MReload = MatchesActivated[0];
			}
			else if (MatchesDeactivated.Num() == 0)
			{
				MShot = MatchesActivated[0];
				MReload = MatchesActivated[1];
			}
			else 
			{
				MShot = MatchesDeactivated.Last(0);
				MReload = MatchesDeactivated.Last(1);
			}
		}
	}

	int32 GetNextReloadMatchIndex() const property
	{
		if (Matches.Num() == 1)
		{
			return 0;
		}
		else if (Matches.Num() > 1)
		{
 			if (MatchesDeactivated.Num() <= 1)
			{
				return Matches.FindIndex(MatchesActivated[0]);
			}
			else if(GetMatchWeapon().GetLoadedMatch() != nullptr)
			{
				for (int i = MatchesDeactivated.Num() - 1; i >= 0 ; i--)
				{
					// the Match which is loaded in the weapon is technically 
					// deactivated - so we'll have to make an exception here.
					if(MatchesDeactivated[i] != GetMatchWeapon().GetLoadedMatch())
					{
						return Matches.FindIndex(MatchesDeactivated[i]);
					}
				}
			}
			else 
			{
 				return Matches.FindIndex(MatchesDeactivated[0]);
			}
		}

		// Should never get here.
		ensure(false);

		return 0;
	}

	void GetNextShootAndReloadMatchIndex(int32& ShotIndex, int32& ReloadIndex) const
	{
		if (Matches.Num() == 1)
		{
			ShotIndex = ReloadIndex = 0;
		}
		else if (Matches.Num() > 1)
		{
			if (MatchesDeactivated.Num() == 1)
			{
				ShotIndex = Matches.FindIndex(MatchesDeactivated.Last(0));
				ReloadIndex = Matches.FindIndex(MatchesActivated[0]);
			}
			else if (MatchesDeactivated.Num() == 0)
			{
// 				ShotIndex = Matches.FindIndex(MatchesActivated[0]);
// 				ReloadIndex = Matches.FindIndex(MatchesActivated[1]);

				ShotIndex = Matches.FindIndex(MatchesActivated[1]);
				ReloadIndex = Matches.FindIndex(MatchesActivated[0]);
			}
			else 
			{
// 				ShotIndex = Matches.FindIndex(MatchesDeactivated.Last(0));
// 				ReloadIndex = Matches.FindIndex(MatchesDeactivated.Last(1));

				ShotIndex = Matches.FindIndex(MatchesDeactivated.Last(1));
				ReloadIndex = Matches.FindIndex(MatchesDeactivated.Last(0));
			}
		}
		ensure(ShotIndex != -1);
		ensure(ReloadIndex != -1);
	}

	UFUNCTION(BlueprintPure)
	int32 GetIndexByMatch(AMatchProjectileActor InMatch) const
	{
		return Matches.FindIndex(InMatch);
	}

	UFUNCTION(BlueprintPure)
	AMatchProjectileActor GetMatchByIndex(int32 Index) const
	{
		return Matches[Index];
	}

	UFUNCTION(BlueprintPure)
	int32 GetNumMatches() const property 
	{
		return Matches.Num();
	}

	UFUNCTION(BlueprintPure)
	int32 GetNumMatchesDeactivated() const property 
	{
		return MatchesDeactivated.Num();
	}

	UFUNCTION(BlueprintPure)
	int32 GetNumMatchesActivated() const property 
	{
		return MatchesDeactivated.Num();
	}

// 	UFUNCTION(BlueprintPure)
// 	AMatchProjectileActor GetLastDeactivatedMatch() const 
// 	{
// 		return MatchesDeactivated.Last();
// 	}

// 	UFUNCTION(BlueprintPure)
// 	AMatchProjectileActor GetFirstActivatedMatch() const 
// 	{
// 		return MatchesActivated[0];
// 	}

	UFUNCTION(BlueprintPure)
	AMatchProjectileActor GetLastMatchEquipped() const property 
	{
		return Matches.Last();
	}

	UFUNCTION(BlueprintPure)
	AMatchWeaponActor GetMatchWeapon() const property
	{
		return MatchWeaponActor;
	}

	UFUNCTION(BlueprintPure)
	bool IsFinalShot() const
	{
		return Charges <= 1.f;
	}

	UFUNCTION(BlueprintPure)
	bool HasMatches() const
	{
		return Matches.Num() > 0;
	}

	UFUNCTION(BlueprintPure)
	bool HasMatchWeapon() const 
	{
		return GetMatchWeapon() != nullptr;
	}

	void GetMatches(TArray<AMatchProjectileActor>& OutMatches) const 
	{
		OutMatches = Matches;
	}

	void GetMatchesActivated(TArray<AMatchProjectileActor>& OutMatches) const 
	{
		OutMatches = MatchesActivated;
	}

	void GetMatchesDeactivated(TArray<AMatchProjectileActor>& OutMatches) const 
	{
		OutMatches = MatchesDeactivated;
	}

	bool ShouldFullscreenAim() const
	{
		return bFullscreenAim;
	}
}
