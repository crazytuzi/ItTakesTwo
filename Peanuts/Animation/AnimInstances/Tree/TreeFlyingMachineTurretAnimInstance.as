import Cake.FlyingMachine.Turret.FlyingMachineTurret;

class UTreeFlyingMachineTurretAnimInstance : UHazeAnimInstanceBase
{

    UPROPERTY(BlueprintReadOnly, Category = "Animation")
    FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animation")
    FHazePlaySequenceData FireLeft;

	UPROPERTY(BlueprintReadOnly, Category = "Animation")
    FHazePlaySequenceData FireRight;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator AimYaw;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator AimPitch;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bFireLeftThisTick;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bFireRightThisTick;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bSyncAnimations = false;

	UPROPERTY()
	bool bPlayFireRightAnim;

	UPROPERTY()
	bool bPlayFireLeftAnim;

	bool bPlayerIsReady;
	AFlyingMachineTurret Turret;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        Turret = Cast<AFlyingMachineTurret>(OwningActor);
		bSyncAnimations = true;
    }
    

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the turret
		if (Turret == nullptr)
            return;
		

		AimYaw.Yaw = Turret.AimYaw;
		AimPitch.Pitch = Turret.AimPitch;

		bFireLeftThisTick = GetAnimBoolParam(n"FireLeft", true);
		if (bFireLeftThisTick)
			bPlayFireLeftAnim = true;
			
		bFireRightThisTick = GetAnimBoolParam(n"FireRight", true);
		if (bFireRightThisTick)
			bPlayFireRightAnim = true;

		if (bSyncAnimations)
		{
			if (bPlayerIsReady)
			{
				bSyncAnimations = false;
			}	
		}

    }

    

}