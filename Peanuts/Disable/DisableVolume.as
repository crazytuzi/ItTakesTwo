import Peanuts.Triggers.PlayerTrigger;

// Volume which disables all Disablees when both players are outside of volume.
// In network entering/leaving is handled by player crumbs and disablement is
// triggered by netfunction, so there can be a single crumb + net delay until
// disablees are enabled/disabled. Build volume appropriately to account for this.
class ADisableVolume : APlayerTrigger
{
	default BrushColor = FLinearColor(1.f, 0.1f, 0.f);

	// Actors which will be disabled when both players are outside of the volume
	UPROPERTY(Category = Disable)
	TArray<AHazeActor> Disablees;

	// Set to true if players are assumed to spawn within this volume.
	UPROPERTY(Category = Disable)
	bool bStartEnabled = false;

	TPerPlayer<bool> IsInside;
	default IsInside[0] = false;
	default IsInside[1] = false;

	bool bDisabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (HasControl() && !bDisabled && !bStartEnabled)
		{
			// Disable until players enter volume.  
			NetDisableActors();
		}

		Super::BeginPlay();
	}

    void EnterTrigger(AActor Actor) override
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		if (ensure(Player != nullptr))
		{
			IsInside[Player] = true;
			if (!IsInside[Player.OtherPlayer])
			{
				// First player entered volume
				if (HasControl())
					NetEnableActors(); 
			}
		}
        Super::EnterTrigger(Actor);
    }

    void LeaveTrigger(AActor Actor) override
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		if (ensure(Player != nullptr))
		{
			IsInside[Player] = false;
			if (!IsInside[Player.OtherPlayer])  
			{
				// Last player left volume
				if (HasControl())
					NetDisableActors(); 
			}
		}
        Super::LeaveTrigger(Actor);
    }

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetEnableActors()
	{
		// Only enable when we have disabled
		if (bDisabled)
			Disable::EnableActors(Disablees, this);
		bDisabled = false;
		bStartEnabled = true;
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetDisableActors()
	{
		bDisabled = true;
		bStartEnabled = false;
		Disable::DisableActors(Disablees, this);
	}
}
