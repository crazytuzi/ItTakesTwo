import Cake.LevelSpecific.Garden.Greenhouse.JoyButtonMashBlob;

class UGardenJoyPodAnimInstance : UHazeAnimInstanceBase
{

	UPROPERTY(Category = "Animations")
    FHazePlayBlendSpaceData Mh;

	UPROPERTY(Category = "Animations")
    FHazePlaySequenceData HitReaction;

	UPROPERTY(Category = "Animations")
    FHazePlaySequenceData HitReactionVar2;
	
	UPROPERTY(NotEditable, BlueprintReadOnly)
	float ButtonMashProgress;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bHitThisTick;

	UPROPERTY()
	bool bPlayHitReaction;

	UPROPERTY()
	float StartPosition;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float BlobOffsetAlpha = 0;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FHazePlaySequenceData HitReactionAnimation;

	AJoyButtonMashBlob BlobActor;

	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
		
		BlobActor = Cast<AJoyButtonMashBlob>(OwningActor);
		StartPosition = FMath::RandRange(0.0f, 1.0f);
		if (BlobActor != nullptr)
			HitReactionAnimation = BlobActor.BlobLocation ==  EBlobLocations::RightHand ? HitReactionVar2 : HitReaction;
	}

	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (BlobActor == nullptr)
			return;

		ButtonMashProgress = BlobActor.ButtonMashProgress;
		bHitThisTick = GetAnimBoolParam(n"TookDamage", true);
		if (bHitThisTick)
			bPlayHitReaction = true;

		if (BlobActor.BlobLocation ==  EBlobLocations::RightHand)
			BlobOffsetAlpha = ButtonMashProgress;
		
	}
}