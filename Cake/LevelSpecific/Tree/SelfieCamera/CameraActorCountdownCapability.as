import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraActor;

class UCameraActorCountdownCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CameraActorCountdownCapability");
	default CapabilityTags.Add(n"CameraActor");
	default CapabilityTags.Add(n"SelfieCamera");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ASelfieCameraActor SelfieCamera;

	float CurrentTimer;
	float DefaultCurrentTimer = 1.f;
	int TimerCount;
	int DefaultTimerCount = 5;

	bool bRunLogic;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SelfieCamera = Cast<ASelfieCameraActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (SelfieCamera.SelfieCameraState == ESelfieCameraState::Countdown)
			return EHazeNetworkActivation::ActivateFromControl;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (SelfieCamera.SelfieCameraState != ESelfieCameraState::Countdown)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		DefaultCurrentTimer = 1.f;
		CurrentTimer = DefaultCurrentTimer;
		TimerCount = DefaultTimerCount;
		bRunLogic = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!bRunLogic)
			return;

		CurrentTimer -= DeltaTime;
		
		if (CurrentTimer <= 0.f)
		{
			if (TimerCount > 1)
			{
				SelfieCamera.TimerLightActivate(SelfieCamera.ColorNormal);	
				SelfieCamera.AudioCountdownBeep();
				TimerCount--;
				DefaultCurrentTimer *= 0.95f;
				CurrentTimer = DefaultCurrentTimer;
			}
			else
			{
				bRunLogic = false;
				SelfieCamera.AudioCountdownBeep();
				System::SetTimer(this, n"DelayedCaptureImage", 1.f, false);
				SelfieCamera.TimerLightActivate(SelfieCamera.ColorReady);
				SelfieCamera.TakeImageArea.TakeImageSequenceActivated();
			}	
		}
	}

	UFUNCTION()
	void DelayedCaptureImage()
	{
		SelfieCamera.CaptureImage();
		SelfieCamera.SelfieCameraState = ESelfieCameraState::CorrectRotation;
	}
}