import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlComponent;

class UClockWorkPocketWatchAnimInstance : UHazeAnimInstanceBase
{

    UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float TurnProgress;

	UTimeControlComponent TimeControlComp;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;

		const AHazePlayerCharacter Cody = Game::GetCody();
        if (Cody != nullptr)
        	TimeControlComp = UTimeControlComponent::Get(Cody);

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (TimeControlComp == nullptr)
            return;

		if (TimeControlComp.IsActiveTimeControlMoving())
			TurnProgress = Math::FWrap(TimeControlComp.GetActiveTimeControlProgress() / TimeControlComp.GetLockedOnComponent().TimeStepMultiplier, 0.f, 1.f);

    }

    

}