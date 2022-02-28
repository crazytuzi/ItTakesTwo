
class USniperAnimInstance : UHazeAnimInstanceBase
{	
	UPROPERTY(BlueprintReadOnly)
	bool bIsShooting = false;

	// Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{		
		if(OwningActor == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(OwningActor == nullptr)
			return;

		bIsShooting = GetAnimBoolParam(n"SniperShoot",true);
	}
	
}