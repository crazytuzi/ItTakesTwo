import Cake.LevelSpecific.SnowGlobe.Sunchair.SunChairSnowFolkSunbathing;

class USnowGlobeSnowFolkSunbathingAnimInstance : UHazeAnimInstanceBase
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FHazePlaySequenceData HitReaction;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bHitByASnowball;


    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        const SunChairSnowFolkSunbathing SnowFolkActor = Cast<SunChairSnowFolkSunbathing>(OwningActor);
		if (SnowFolkActor == nullptr)
			return;
			
		Mh = SnowFolkActor.Mh;
		HitReaction = SnowFolkActor.HitReaction;

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (OwningActor == nullptr)
            return;

		bHitByASnowball = GetAnimBoolParam(n"bHitBySnowball", true);

    }

    

}