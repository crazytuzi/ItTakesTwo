import Peanuts.Triggers.HazeTriggerBase;

event void FPlayerTriggerEvent(AHazePlayerCharacter Player);

class APlayerTrigger : AHazeTriggerBase
{
	default BrushComponent.SetCollisionProfileName(n"TriggerPlayerOnly");
	default bGenerateOverlapEventsDuringLevelStreaming = false;

    UPROPERTY(BlueprintReadOnly, Category = "Player Trigger")
    bool bTriggerForCody = true;

    UPROPERTY(BlueprintReadOnly, Category = "Player Trigger")
    bool bTriggerForMay = true;

    UPROPERTY(Category = "Player Trigger")
    FPlayerTriggerEvent OnPlayerEnter;

    UPROPERTY(Category = "Player Trigger")
    FPlayerTriggerEvent OnPlayerLeave;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// We manually update player overlaps on beginplay,
		// this avoids an expensive UpdateOverlaps call by allowing
		// us to set bGenerateOverlapEventsDuringLevelStreaming to false.
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Trace::ComponentOverlapComponent(BrushComponent, Player.CapsuleComponent))
				BrushComponent.ManualInsertRealComponentOverlap(Player.CapsuleComponent);
		}
	}

    bool ShouldTrigger(AActor Actor) override
    {
        auto Player = Cast<AHazePlayerCharacter>(Actor);
        if (Player == nullptr)
            return false;

        if (bTriggerForCody && Player.IsCody())
            return true;
        if (bTriggerForMay && Player.IsMay())
            return true;

        return false;
    }

    void EnterTrigger(AActor Actor) override
    {
        OnPlayerEnter.Broadcast(Cast<AHazePlayerCharacter>(Actor));
    }

    void LeaveTrigger(AActor Actor) override
    {
        OnPlayerLeave.Broadcast(Cast<AHazePlayerCharacter>(Actor));
    }

	UFUNCTION()
	void SetEnabledForPlayer(AHazePlayerCharacter Player, bool bEnabled = false)
	{
		if (Player == nullptr)
			return;

		if (Player.IsMay())
		{
			if (bTriggerForMay != bEnabled)
				bTriggerForMay = bEnabled;
			else
				return;
		}
		else
		{
			if (bTriggerForCody != bEnabled)
				bTriggerForCody = bEnabled;
			else
				return;
		}

		if (bEnabled && IsOverlappingActor(Player))
			ActorBeginOverlap(Player);
	}
};