class UGardenSmallRootBulbAnimInstance : UHazeAnimInstanceBase
{

    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData HitReaction;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Death;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bHitThisTick;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bAlive;

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (OwningActor == nullptr)
            return;

		bHitThisTick = GetAnimBoolParam(n"TookDamage", true);
		if (bHitThisTick)
			bAlive = !GetAnimBoolParam(n"Died", true);
    }

    

}