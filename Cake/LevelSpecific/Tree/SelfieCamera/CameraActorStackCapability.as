import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraActor;

//Capability only cares about moving images and setting the stack up
class UCameraActorStackCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CameraActorStackCapability");
	default CapabilityTags.Add(n"CameraActor");
	default CapabilityTags.Add(n"SelfieCamera");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ASelfieCameraActor SelfieCamera;

	int MaxStack = 3;

	bool bRunStackHeightCorrection;

	FHazeAcceleratedFloat ZHeight;

	TArray<float> ZHeights;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SelfieCamera = Cast<ASelfieCameraActor>(Owner);
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
		bRunStackHeightCorrection = false;

		ZHeights.Empty();

		for (ASelfieCameraImage Image : SelfieCamera.ImageStack)
		{
			Image.DisableThrowInteraction();
		}

		if (SelfieCamera.ImageStack.Num() >= MaxStack)
		{
			ZHeight.SnapTo(0.f);
			SelfieCamera.ImageStack[0].DestroyActor();
			SelfieCamera.ImageStack.RemoveAt(0);
			bRunStackHeightCorrection = true;

			for (ASelfieCameraImage Image : SelfieCamera.ImageStack)
			{
				ZHeights.Add(Image.ActorLocation.Z); 
			}
		}

		SelfieCamera.ImageStack.Add(SelfieCamera.CurrentImage);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!bRunStackHeightCorrection)
			return;

		int Index = 0;

		ZHeight.AccelerateTo(-SelfieCamera.StackZOffset, 1.f, DeltaTime);
		
		for (ASelfieCameraImage Image : SelfieCamera.ImageStack)
		{
			if (Index < SelfieCamera.ImageStack.Num() - 1)
			{
				float NewZ = ZHeight.Value + ZHeights[Index];
				FVector NewLoc = FVector(Image.ActorLocation.X, Image.ActorLocation.Y, NewZ);
				Image.SetActorLocation(NewLoc); 
			}

			Index++;
		}
	}
}