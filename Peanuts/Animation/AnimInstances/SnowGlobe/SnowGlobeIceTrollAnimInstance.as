class USnowGlobeIceTrollAnimInstance : UHazeAnimInstanceBase
{

	AHazePlayerCharacter LookAtPlayer;
	
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator EyeRotation;
	

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
    	System::SetTimer(this, n"SwitchLookAtPlayer", 10.f, false);

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (LookAtPlayer == nullptr)
		{
			LookAtPlayer = Game::GetCody();
			return;
		}

		// Calculate the rotation towards the player
		const FVector EyesLocation = OwningActor.ActorLocation + FVector(0, 0, 100);
		const FVector DeltaVecotor = (LookAtPlayer.ActorLocation - EyesLocation);
		EyeRotation = OwningActor.ActorRotation.UnrotateVector(DeltaVecotor).Rotation();

		// Clamp it
		EyeRotation.Pitch = FMath::Clamp(EyeRotation.Pitch, -25.f, 80.f);
		EyeRotation.Yaw = FMath::Clamp(EyeRotation.Yaw, -50.f, 50.f);

    }


	UFUNCTION()
	void SwitchLookAtPlayer()
	{
		if (LookAtPlayer == nullptr)
			return;

		LookAtPlayer = LookAtPlayer.GetOtherPlayer();
		System::SetTimer(this, n"SwitchLookAtPlayer", FMath::RandRange(3.f, 7.f), false);
	}


    

}