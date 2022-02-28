import Peanuts.Animation.Features.Garden.LocomotionFeatureGardenSnailRace;

class UGardenSnailRacePlayerAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureGardenSnailRace LocomotionFeature;

 	UPROPERTY(NotEditable, BlueprintReadOnly)
	float StartPosition;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	float TurnRate;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	float SquishValue;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bBoost;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bIsStunned;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bGameIsStartingOnRemote;


    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeatureGardenSnailRace>(GetFeatureAsClass(ULocomotionFeatureGardenSnailRace::StaticClass()));
		StartPosition = GetAnimFloatParam(n"StartPosition", true);

    }

	// On Initialize
	UFUNCTION(BlueprintOverride)	
	float GetBlendTime() const
	{
		return 0.03f;
    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (LocomotionFeature == nullptr)
            return;
		
		bBoost = GetAnimBoolParam(n"bBoost", true);
		bIsStunned = GetAnimBoolParam(n"bIsStunned", true);
		SquishValue = GetAnimFloatParam(n"SquishValue", true);
		
		bGameIsStartingOnRemote = (SquishValue == 1.25f);
		
    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
        return true;
    }

}