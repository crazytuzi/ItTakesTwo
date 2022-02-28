import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraActor;

class UCameraActorRotationCorrectionCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CameraActorRotationCorrectionCapability");
	default CapabilityTags.Add(n"CameraActor");
	default CapabilityTags.Add(n"SelfieCamera");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ASelfieCameraActor SelfieCamera;

	float StartingYaw;
	float StartingPitch;

	float CurrentYaw;
	float CurrentPitch;

	float InterpTime = 25.f;

	bool bMovedImage;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SelfieCamera = Cast<ASelfieCameraActor>(Owner);
		StartingYaw = SelfieCamera.ActorRotation.Yaw;
		StartingPitch = SelfieCamera.CameraPivot.WorldRotation.Pitch;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (SelfieCamera.SelfieCameraState == ESelfieCameraState::CorrectRotation)
			return EHazeNetworkActivation::ActivateFromControl;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (SelfieCamera.SelfieCameraState != ESelfieCameraState::CorrectRotation)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentYaw = SelfieCamera.ActorRotation.Yaw;
		CurrentPitch = SelfieCamera.CameraPivot.WorldRotation.Pitch;
		bMovedImage = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		CurrentYaw = FMath::FInterpConstantTo(CurrentYaw, StartingYaw, DeltaTime, InterpTime);
		CurrentPitch = FMath::FInterpConstantTo(CurrentPitch, StartingPitch, DeltaTime, InterpTime);

		SelfieCamera.SetActorRotation(FRotator(0.f, CurrentYaw, 0.f));
		SelfieCamera.CameraPivot.SetRelativeRotation(FRotator(CurrentPitch, 0.f, 0.f));

		float DifferenceYaw = CurrentYaw - StartingYaw;
		float DifferencePitch = CurrentPitch - StartingPitch;

		if (DifferenceYaw <= 0.1f && DifferencePitch <= 0.1f && !bMovedImage)
		{
			bMovedImage = true;
			System::SetTimer(this, n"DelayedMoveImageOut", 1.f, false);
		}
	}

	UFUNCTION()
	void DelayedMoveImageOut()
	{
		SelfieCamera.SelfieCameraState = ESelfieCameraState::MoveImage;
	}
}