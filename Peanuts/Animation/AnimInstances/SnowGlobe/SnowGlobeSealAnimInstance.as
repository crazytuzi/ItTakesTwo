import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.HarpoonHarpSeal;
class USnowGlobeSealAnimInstance : UHazeAnimInstanceBase
{

    UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData Excited;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData FishThrown;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData CatchFish;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData HitWithClaw;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData BouncedOn;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bBouncedOn;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bHitWithClaw;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bExcited;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bPlayBouncedOnAnimation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bFishThrown;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bEatFish;

	bool bIsEatingFish;
	AHarpoonHarpSeal Seal;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        Seal = Cast<AHarpoonHarpSeal>(OwningActor);

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (Seal == nullptr)
            return;


		bExcited = Seal.bPlayerHasFish;
		bFishThrown = GetAnimBoolParam(n"ReadyForFish", true);
		bEatFish = GetAnimBoolParam(n"EatFish", true);
		if (bEatFish)
			bIsEatingFish = true;
			

		bHitWithClaw = GetAnimBoolParam(n"ClawHit", true) && !bIsEatingFish;
		bBouncedOn = GetAnimBoolParam(n"BouncedOn", true);
		if (bBouncedOn)
			bPlayBouncedOnAnimation = true;

    }

    
	UFUNCTION()
	void AnimNotify_StopPlayingBounce()
	{
		if (!bBouncedOn)
			bPlayBouncedOnAnimation = false;
	}

	UFUNCTION()
	void AnimNotify_StoppedEatingFish()
	{
		bIsEatingFish = false;
		// Seal.DeactivateEatenFish(); //Did not always fire on both sides in network
	}


}