import Cake.FlyingMachine.FlyingMachine;

class UTreeFlyingMachineAnimInstance : UHazeAnimInstanceBase
{

    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Damage;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData BoostFight;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator PropellerRotation;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector2D BlendspaceValues;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bHangGliderMode;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bBoosting;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bTookDamageThisTick;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bBoostMeleeFight;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bSyncAnimations = false;

	AFlyingMachine FlyingMachine;

	const float PropellerSpeed = 800.f;

	bool bPilotIsReady = false;
	float Health;
	float BoostCharge;
	FTimerHandle SyncAnimationsTimerHandle;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        FlyingMachine = Cast<AFlyingMachine>(OwningActor);
		bSyncAnimations = true;
		

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (FlyingMachine == nullptr)
            return;

		// Check if plane took dmg this tick
		bTookDamageThisTick = GetAnimBoolParam(n"HasTakenDamage", true);

		// Check if you're boosting
		bBoosting = GetAnimBoolParam(n"IsBoosting", false);
		bBoostMeleeFight = (FlyingMachine.bIsInMeleeFight && bBoosting);
		
		// Propeller Rotations
		PropellerRotation.Yaw = Math::FWrap(PropellerRotation.Yaw - (PropellerSpeed * ((FlyingMachine.SpeedPercent/3.f) + 1.f) * DeltaTime), 0.f, 360.f);

		// Get blendspace values
		BlendspaceValues.X = FMath::Clamp(OwningActor.ActorRotation.Roll / 60.f, -1.f, 1.f);
		BlendspaceValues.Y = bBoosting ? 2.f : FlyingMachine.SpeedPercent;

		if (bSyncAnimations)
		{
			if (bPilotIsReady)
			{
				bSyncAnimations = false;
			}
		}
		

    }    

}