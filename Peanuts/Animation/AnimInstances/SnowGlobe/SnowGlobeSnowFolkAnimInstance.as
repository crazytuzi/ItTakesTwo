import Cake.LevelSpecific.SnowGlobe.Snowfolk.SnowFolkSplineFollower;

class USnowGlobeSnowFolkAnimInstance : UHazeAnimInstanceBase
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bIsSkating;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bHasFallen;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bIsHit;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bHitFromLeft;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bSlipping;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bJumpedOn;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bEnableLookAt;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FVector LookAtLocation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bIsMoving;

	//UPROPERTY(BlueprintReadOnly, NotEditable)
    //bool bIsWaiting;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bIsReady;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    float BlendSpaceSpeed;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    float LeanValue;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayerDashed;


	ASnowfolkSplineFollower Snowfolk;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;

		
        Snowfolk = Cast<ASnowfolkSplineFollower>(OwningActor);
        

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (Snowfolk == nullptr)
            return;

		bIsSkating = Snowfolk.MovementComp.bIsSkating;
		bIsHit = Snowfolk.bIsHit;
		bHitFromLeft = Snowfolk.bHitFromLeft;
		bSlipping = Snowfolk.bIsDown;
		bJumpedOn = Snowfolk.bIsJumpedOn;
		bEnableLookAt = Snowfolk.bEnableLookAt;
		LookAtLocation = Snowfolk.LookAtLocation;
		bIsMoving = Snowfolk.bIsMoving;
		//bIsWaiting = Snowfolk.bIsWaiting;
		bIsReady = Snowfolk.bIsReady;
		BlendSpaceSpeed = Snowfolk.BSSpeed;
		LeanValue = Snowfolk.BSLeanValue;
		bPlayerDashed = GetAnimBoolParam(n"PlayerDashed", true);
    }

	UFUNCTION()
	void AnimNotify_HasSlipped()
	{
		bHasFallen = true;
	}

	UFUNCTION()
	void AnimNotify_Skating()
	{
		bHasFallen = false;
	}

    

}