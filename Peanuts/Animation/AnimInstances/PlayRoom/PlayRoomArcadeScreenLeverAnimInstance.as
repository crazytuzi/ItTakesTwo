import Cake.LevelSpecific.PlayRoom.PillowFort.TechDoubleInteract.TVHackingRemote;
class UPlayRoomArcadeScreenLeverAnimInstance : UHazeAnimInstanceBase
{

	UPROPERTY(BlueprintReadOnly)
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly)
	FHazePlaySequenceData Trigger;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator LeverRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bUseTrigger;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayTriggerAnimation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayerIsInteracting;


    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (OwningActor == nullptr)
            return;
		
		bPlayerIsInteracting  = GetAnimBoolParam(n"HasInteractingPlayer");
		if (!bPlayerIsInteracting)
		{
			if (LeverRotation != FRotator::ZeroRotator)
				LeverRotation = FMath::RInterpTo(LeverRotation, FRotator::ZeroRotator, DeltaTime, 3.f);
			return;
		}
			

		const float PlayerInputX = GetAnimFloatParam(n"JoystickInputX", true);
		const float PlayerInputY = GetAnimFloatParam(n"JoystickInputY", true);
		bUseTrigger = GetAnimBoolParam(n"JoystickTrigger", true);
		if (bUseTrigger)
			bPlayTriggerAnimation = true;
			
		LeverRotation = FMath::RInterpTo(LeverRotation, FRotator(-PlayerInputY * 20, 0.f, PlayerInputX * 20), DeltaTime, 5.f);
    }

	UFUNCTION()
	void StopPlayingTriggerAnimation()
	{
		bPlayTriggerAnimation = false;
	}

}