struct FStructLookAtAnimationData
{
	UPROPERTY()
	FVector LookAtLocation;

	UPROPERTY()
	bool bLookAtEnabled;

}

class UAnimationLookAtComponent : UActorComponent
{
	private bool bUseCustomLookAtLocation;
	private FVector CustomWorldLocation;

	private TArray<UObject> Disablers;
	private TArray<UObject> DisablersCameraBased;

	AHazePlayerCharacter Player;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		Disablers.Empty();
		DisablersCameraBased.Empty();
		bUseCustomLookAtLocation = false;
	}


	// Enable the character look at
	UFUNCTION()
	void EnableLookAt(UObject Instigator)
	{
		Disablers.Remove(Instigator);
	}

	// Enable the character look at
	UFUNCTION()
	void EnableCameraBasedLookAt(UObject Instigator)
	{
		DisablersCameraBased.Remove(Instigator);
	}

	// Disable the character look at
	UFUNCTION()
	void DisableLookAt(UObject Instigator)
	{
		Disablers.AddUnique(Instigator);
	}

	// Disable the character look at
	UFUNCTION()
	void DisableCameraBasedLookAt(UObject Instigator)
	{
		DisablersCameraBased.AddUnique(Instigator);
	}

	// Set a world location that the character will look towards
	UFUNCTION()
	void SetCustomLookAtLocation(FVector WorldLocation)
	{
		bUseCustomLookAtLocation = true;
		CustomWorldLocation = WorldLocation;
	}
	
	// Reset the custom world location, returning to a camera based look at location
	UFUNCTION()
	void ResetCustomLookAtLocation()
	{
		bUseCustomLookAtLocation = false;
		CustomWorldLocation = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintPure)
	bool HasCustomLookAtLocation()
	{
		return bUseCustomLookAtLocation;
	}




	// Get all the relevant animation data for setting up a LookAt node in the ABP
	UFUNCTION(BlueprintPure)
	FStructLookAtAnimationData GetLookAtAnimationData(float YawThreshold = 130.f, float PitchThreshold = 80.f, float VerticalClampMin = -90.f, float VerticalClampMax = 90.f) const
	{
		const FVector EyesLocation = GetActorEyesLocation();

		// Get the look at rotation
		const FRotator LookAtRotation = GetLookAtRotation(EyesLocation);

		FStructLookAtAnimationData LookAtAnimData;

		// Convert the rotation into a world location but with clamped rotation values
		LookAtAnimData.LookAtLocation = ConvertLookAtRotationToWorldLocation(LookAtRotation, EyesLocation, VerticalClampMin, VerticalClampMax);

		// Check if the LookAt node should be enabled or not, based on the LookAtRotation & bLookAtEnabled
		LookAtAnimData.bLookAtEnabled = ShouldLookAtNodeBeEnabled(LookAtRotation, YawThreshold, PitchThreshold);

		return LookAtAnimData;
	}

	// Get all the relevant animation data for setting up a LookAt node in the ABP, with interpolation options
	UFUNCTION(BlueprintPure)
	FStructLookAtAnimationData GetLookAtAnimationDataWithInterp(FVector CurrentLookAtLocation, float DeltaTime, float YawThreshold = 130.f, float PitchThreshold = 80.f, float VerticalClampMin = -90.f, float VerticalClampMax = 90.f, float InterpSpeed = 10.f) const
	{
		FStructLookAtAnimationData LookAtAnimData = GetLookAtAnimationData(YawThreshold, PitchThreshold, VerticalClampMin, VerticalClampMax);
		LookAtAnimData.LookAtLocation = FMath::VInterpTo(CurrentLookAtLocation, LookAtAnimData.LookAtLocation, DeltaTime, InterpSpeed);
		return LookAtAnimData;
	}

	// Get all the relevant animation data for setting up a LookAt node in the ABP
	UFUNCTION(BlueprintPure)
	FStructLookAtAnimationData GetInitialLookAtAnimationData(float YawThreshold = 130.f, float PitchThreshold = 80.f, bool bUseZeroRotation = true) const
	{
		const FVector EyesLocation = GetActorEyesLocation();

		FStructLookAtAnimationData LookAtAnimData;

		const FRotator LookAtRotation = GetLookAtRotation(EyesLocation);
		LookAtAnimData.bLookAtEnabled = ShouldLookAtNodeBeEnabled(LookAtRotation, YawThreshold, PitchThreshold);

		if (LookAtAnimData.bLookAtEnabled && bUseZeroRotation)
			LookAtAnimData.LookAtLocation = ConvertLookAtRotationToWorldLocation(FRotator(), EyesLocation, -90.f, 90.f);
		else
			LookAtAnimData.LookAtLocation = ConvertLookAtRotationToWorldLocation(LookAtRotation, EyesLocation, -90.f, 90.f);

		return LookAtAnimData;
	}


	// Get the location of the eyes for the player
	UFUNCTION()
	private FVector GetActorEyesLocation() const
	{
		FVector Location;
		FRotator Rotation;
		Player.GetActorEyesViewPoint(Location, Rotation);
		return Location;
	}

	// Get the look at world location
	UFUNCTION()
	private FRotator GetLookAtRotation(FVector EyesLocation) const
	{
		FVector LookAtLocation;

		// Check if a custom world location is beeing used
		if (bUseCustomLookAtLocation)
		{
			LookAtLocation = CustomWorldLocation;
		}
		else
		{
			// Camera based look at location
			LookAtLocation = EyesLocation + (EyesLocation - Player.GetPlayerViewLocation());
			LookAtLocation.Z += 150.f;

			// Alternative: (Could only be used as long as a custom world loc is not in use)
			// return (Player.GetActorRotation() - Player.GetPlayerViewRotation()).Normalized;
		}
		
		return Math::MakeRotFromXZ(Player.ActorRotation.UnrotateVector((LookAtLocation - EyesLocation)), Player.ActorUpVector);
	}
	
	// Convert the look at rotation into a world location, with options to clamp the vertical head rotation
	UFUNCTION()
	private FVector ConvertLookAtRotationToWorldLocation(FRotator LookAtRotation, FVector EyesLocation, float ClampVerticalMin = -90.f, float ClampVerticalMax = 90.f) const
	{
		float PitchRotation = FMath::Clamp(LookAtRotation.Pitch, ClampVerticalMin, ClampVerticalMax);
		if (!bUseCustomLookAtLocation)
			PitchRotation /= 2.f;
		FRotator ClampedLookAtRotation = FRotator(PitchRotation, LookAtRotation.Yaw, LookAtRotation.Roll);
		return EyesLocation + (Player.ActorRotation.RotateVector(ClampedLookAtRotation.Vector()) * 500.f);
	}


	// Get whether the LookAt node should be enabled or disabled in the ABP, based on look direction and bLookAtEnabled
	UFUNCTION()
	private bool ShouldLookAtNodeBeEnabled(FRotator LookAtRotation, float YawThreshold, float PitchThreshold) const 
	{
		if (Disablers.Num() > 0)
			return false;

		if (DisablersCameraBased.Num() > 0 && !bUseCustomLookAtLocation)
			return false;

		return (FMath::Abs(LookAtRotation.Yaw) < YawThreshold && FMath::Abs(LookAtRotation.Pitch) < PitchThreshold);
	}
}

UFUNCTION()
void SetAnimationLookAtEnabled(AHazePlayerCharacter Player, bool bEnabled, UObject Instigator)
{
	if (Player == nullptr)
		return;

	UAnimationLookAtComponent LookAtComp = UAnimationLookAtComponent::Get(Player);
	if (LookAtComp == nullptr)
		return;

	if (bEnabled)
		LookAtComp.EnableLookAt(Instigator);
	else
		LookAtComp.DisableLookAt(Instigator);
}

UFUNCTION()
void SetCameraBasedAnimationLookAtEnabled(AHazePlayerCharacter Player, bool bEnabled, UObject Instigator)
{
	if (Player == nullptr)
		return;

	UAnimationLookAtComponent LookAtComp = UAnimationLookAtComponent::Get(Player);
	if (LookAtComp == nullptr)
		return;

	if (bEnabled)
		LookAtComp.EnableCameraBasedLookAt(Instigator);
	else
		LookAtComp.DisableCameraBasedLookAt(Instigator);
}