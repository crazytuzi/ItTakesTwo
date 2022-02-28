import Cake.LevelSpecific.Garden.Greenhouse.BossDestroyableBeamPlant;

class UGardenJoyBossBeamPlant : UHazeAnimInstanceBase
{

	UPROPERTY(Category = "Animations")
    FHazePlaySequenceData Hidden;

	UPROPERTY(Category = "Animations")
    FHazePlaySequenceData Appear;

	UPROPERTY(Category = "Animations")
    FHazePlaySequenceData ShootMh;

	UPROPERTY(Category = "Animations")
    FHazePlayBlendSpaceData ShootMhBlendspace;

	// Additive animation
	UPROPERTY(Category = "Animations")
    FHazePlaySequenceData HitReaction;

	UPROPERTY(Category = "Animations")
    FHazePlaySequenceData Exit;


	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bPlantActive = false;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bHitThisTick;

	UPROPERTY()
	bool bPlayHitReaction;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector FollowTargetLocation;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FRotator HeadOffset;

	ABossDestroyableBeamPlant BeamPlant;


	// On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
		
		BeamPlant = Cast<ABossDestroyableBeamPlant>(OwningActor);
		
	}

	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{

		if (BeamPlant == nullptr)
			return;

		bPlantActive = BeamPlant.bPlantActive;

		bHitThisTick = GetAnimBoolParam(n"TookDamage", true);
		if (bHitThisTick && bPlantActive)
			bPlayHitReaction = true;

		FollowTargetLocation = BeamPlant.FollowTargetLocation;
		HeadOffset.Pitch = BeamPlant.HeadTiltOffset * 110.f;
		
	}
}