import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraActor;

class UCameraActorMoveImageCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CameraActorMoveImageCapability");
	default CapabilityTags.Add(n"CameraActor");
	default CapabilityTags.Add(n"SelfieCamera");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 120;

	ASelfieCameraActor SelfieCamera;

	int ImagePosIndex;

	FHazeAcceleratedVector AccelLoc;
	FHazeAcceleratedRotator AccelRot;
	
	FVector StartingPicLoc;
	FRotator StartingPicRot;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SelfieCamera = Cast<ASelfieCameraActor>(Owner);

		StartingPicLoc = SelfieCamera.ImageStart.WorldLocation;
		StartingPicRot = SelfieCamera.ActorRotation;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (SelfieCamera.SelfieCameraState == ESelfieCameraState::MoveImage)
			return EHazeNetworkActivation::ActivateFromControl;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (SelfieCamera.SelfieCameraState != ESelfieCameraState::MoveImage)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SelfieCamera.SetImageFallLoc(SelfieCamera.ImageStack.Num() * SelfieCamera.StackZOffset);
		SelfieCamera.BindThrowImageEvents();
		
		if (SelfieCamera.PlayerCompInUse != nullptr)
			SelfieCamera.PlayerCompInUse.bCanLook = true;

		SelfieCamera.CurrentImage.SetActorHiddenInGame(false);

		ImagePosIndex = 1;

		AccelLoc.SnapTo(StartingPicLoc);
		AccelRot.SnapTo(StartingPicRot);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ImagePosIndex = 0;
		SelfieCamera.EnableAllInteractions();
		SelfieCamera.CurrentImage.EnableThrowInteraction();

		if (SelfieCamera.PlayerCompInUse != nullptr)
		{
			AHazePlayerCharacter CurrentPlayer = Cast<AHazePlayerCharacter>(SelfieCamera.PlayerCompInUse.Owner);
			SelfieCamera.PlayerCompInUse.ShowPlayerTakePic(CurrentPlayer);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		LerpToFirst(DeltaTime);
		LerpToFinal(DeltaTime);

		SelfieCamera.CurrentImage.SetActorLocationAndRotation(AccelLoc.Value, AccelRot.Value);
	}
	
	void LerpToFirst(float DeltaTime)
	{
		if (SelfieCamera.CurrentImage == nullptr)
			return;

		if (ImagePosIndex != 1)
			return;

		AccelLoc.AccelerateTo(SelfieCamera.FirstWorldLoc, 1.8f, DeltaTime);
		AccelRot.AccelerateTo(SelfieCamera.FirstWorldRot, 1.5f, DeltaTime);

		float Distance = (SelfieCamera.FirstWorldLoc - SelfieCamera.CurrentImage.ActorLocation).Size();

		if (Distance <= 20.f)
			ImagePosIndex = 2;
	}

	void LerpToFinal(float DeltaTime)
	{
		if (SelfieCamera.CurrentImage == nullptr)
			return;

		if (ImagePosIndex != 2)
			return;

		AccelLoc.AccelerateTo(SelfieCamera.FinalWorldLoc, 3.2f, DeltaTime);
		AccelRot.AccelerateTo(SelfieCamera.FinalWorldRot, 2.6f, DeltaTime);

		float Distance = (SelfieCamera.FinalWorldLoc - SelfieCamera.CurrentImage.ActorLocation).Size();

		if (Distance <= 25.f)
		{			
			if (HasControl())
			{
				NetFadeImage();
			}

			SelfieCamera.SelfieCameraState = ESelfieCameraState::Default;
		}
	}

	UFUNCTION(NetFunction)
	void NetFadeImage()
	{
		SelfieCamera.CurrentImage.bFadeImageIn = true;
	}
}