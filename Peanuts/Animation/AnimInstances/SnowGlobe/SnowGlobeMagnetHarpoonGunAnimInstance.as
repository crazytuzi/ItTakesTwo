import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetHarpoonActor;
class USnowGlobeMagnetHarpoonGunAnimInstance : UHazeAnimInstanceBase
{
    UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData Fire;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData Release;

	UPROPERTY(BlueprintReadOnly)
    FRotator CannonMount;

	UPROPERTY(BlueprintReadOnly)
    FRotator CannonBase;

	UPROPERTY(BlueprintReadOnly)
    bool bFire;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bRelease;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bEnableRotation = false;

	AMagnetHarpoonActor MagnetHarpoon;

	AHazePlayerCharacter Player;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        MagnetHarpoon = Cast<AMagnetHarpoonActor>(OwningActor);
		bEnableRotation = false;
    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (MagnetHarpoon == nullptr)
            return;

		
		Player = MagnetHarpoon.UsingPlayer;
		if (Player == nullptr)
			return;

		bEnableRotation = true;

		FRotator WorldRot = MagnetHarpoon.HarpoonRotation.Value - OwningActor.ActorRotation; //Don't use this if you want local rotation //From Anders
		WorldRot.Normalize();

		CannonMount.Yaw = WorldRot.Yaw;
		CannonBase.Pitch = WorldRot.Pitch;

		bFire = GetAnimBoolParam(n"HarpoonFired", true);
		bRelease = GetAnimBoolParam(n"FishReleased", true);
    }
}