import Cake.LevelSpecific.Garden.Greenhouse.Joy;
import Peanuts.Audio.AudioStatics;

class UGardenBossJoyAudioCapability : UHazeCapability
{
	AJoy Joy;

	UPROPERTY(NotVisible)
	UHazeAkComponent JoyLeftHandHazeAkComp;

	UPROPERTY(NotVisible)
	UHazeAkComponent JoyRightHandHazeAkComp;

	UPROPERTY(NotVisible)
	UHazeAkComponent JoyHeadHazeAkComp;

	UPROPERTY(Category = "Movement")
	UAkAudioEvent LeftHandMovementEvent;

	UPROPERTY(Category = "Movement")
	UAkAudioEvent RightHandMovementEvent;

	UPROPERTY(Category = "Movement")
	UAkAudioEvent HeadMovementEvent;

	UPROPERTY(Category = "Blobs")
	UAkAudioEvent StartRightHandBlobButtonMashEvent;

	UPROPERTY(Category = "Blobs")
	UAkAudioEvent StopRightHandBlobButtonMashEvent;

	UPROPERTY(Category = "Blobs")
	UAkAudioEvent StartBackBlobButtonMashEvent;
	
	UPROPERTY(Category = "Blobs")
	UAkAudioEvent StopBackBlobButtonMashEvent;

	UPROPERTY(Category = "Blobs")
	UAkAudioEvent StartHeadBlobButtonMashEvent;
	
	UPROPERTY(Category = "Blobs")
	UAkAudioEvent StopHeadBlobButtonMashEvent;

	private bool bWasButtonMashing = false;
	private UHazeAkComponent CurrentButtonMashBlobAkComp;
	private UAkAudioEvent BlobStartButtonMashEvent;
	private UAkAudioEvent BlobStopButtonMashEvent;

	private FVector LastLeftArmLocation;
	private FVector LastRightArmLocation;
	private FVector LastHeadLocation;
	 
	float LastButtonProgressValue = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Joy = Cast<AJoy>(Owner);

		JoyLeftHandHazeAkComp = UHazeAkComponent::Create(Joy, n"JoyLeftHandHazeAkComp");
		JoyLeftHandHazeAkComp.AttachTo(Joy.Mesh, n"LeftHandBend", EAttachLocation::SnapToTarget);

		JoyRightHandHazeAkComp = UHazeAkComponent::Create(Joy, n"JoyRightHandHazeAkComp");
		JoyRightHandHazeAkComp.AttachTo(Joy.Mesh, n"RightHandBend", EAttachLocation::SnapToTarget);

		JoyHeadHazeAkComp = UHazeAkComponent::Create(Joy, n"JoyHeadHazeAkComp");
		JoyHeadHazeAkComp.AttachTo(Joy.Mesh, n"Head", EAttachLocation::SnapToTarget);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		JoyLeftHandHazeAkComp.HazePostEvent(LeftHandMovementEvent);
		JoyRightHandHazeAkComp.HazePostEvent(RightHandMovementEvent);
		JoyHeadHazeAkComp.HazePostEvent(HeadMovementEvent);
		Game::GetMay().BlockCapabilities(n"SickleEnemyAreaAudio", this);
		//JoyLeftHandHazeAkComp.SetTrackVelocity(true, 1200.f);
		//JoyRightHandHazeAkComp.SetTrackVelocity(true, 1200.f);
		//JoyHeadHazeAkComp.SetTrackVelocity(true, 750.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Game::GetMay().UnblockCapabilities(n"SickleEnemyAreaAudio", this);
	}

	bool GetCurrentMashBlobAkComp(int Phase, UHazeAkComponent& OutHazeAkComp, UAkAudioEvent& OutButtonMashStartEvent, UAkAudioEvent& OutButtonMashStopEvent)
	{
		switch(Phase)
		{
			case(1):
				OutHazeAkComp = UHazeAkComponent::Get(Joy.BlobRightHand);
				OutButtonMashStartEvent = StartRightHandBlobButtonMashEvent;
				OutButtonMashStopEvent = StopRightHandBlobButtonMashEvent;
				return OutHazeAkComp != nullptr;
			case(2):
				OutHazeAkComp = UHazeAkComponent::Get(Joy.BlobBack);
				OutButtonMashStartEvent = StartBackBlobButtonMashEvent;
				OutButtonMashStopEvent = StopBackBlobButtonMashEvent;
				return OutHazeAkComp != nullptr;

			case(3):
				OutHazeAkComp = UHazeAkComponent::Get(Joy.BlobHead);
				OutButtonMashStartEvent = StartHeadBlobButtonMashEvent;
				OutButtonMashStopEvent = StopHeadBlobButtonMashEvent;
				return OutHazeAkComp != nullptr;

			default:
				break;
		}

		return false;	
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector CurrentLeftArmLocation = JoyLeftHandHazeAkComp.GetWorldLocation();
		FVector CurrentRightArmLocation = JoyRightHandHazeAkComp.GetWorldLocation();
		FVector CurrentHeadLocation = JoyHeadHazeAkComp.GetWorldLocation();

		const float NormalizedLeftArmVelo = HazeAudio::NormalizeRTPC01((CurrentLeftArmLocation - LastLeftArmLocation).Size() / DeltaTime, 0.f, 1200.f);
		const float NormalizedRightArmVelo = HazeAudio::NormalizeRTPC01((CurrentRightArmLocation - LastRightArmLocation).Size() / DeltaTime, 0.f, 1200.f);
		const float NormalizedHeadVelo = HazeAudio::NormalizeRTPC01((CurrentHeadLocation - LastHeadLocation).Size() / DeltaTime, 0.f, 750.f);

		JoyLeftHandHazeAkComp.SetRTPCValue("Rtpc_Character_Bosses_Joy_Velocity_LeftArm", NormalizedLeftArmVelo);
		JoyRightHandHazeAkComp.SetRTPCValue("Rtpc_Character_Bosses_Joy_Velocity_RightArm", NormalizedRightArmVelo);
		JoyHeadHazeAkComp.SetRTPCValue("Rtpc_Character_Bosses_Joy_Velocity_Head", NormalizedHeadVelo);

		//Print("NormalizedLeftArmVelo: " + NormalizedLeftArmVelo, 0.f);
		//Print("NormalizedRightArmVelo: " + NormalizedRightArmVelo, 0.f);
		//Print("NormalizedHeadVelo: " + NormalizedHeadVelo, 0.f);

		LastLeftArmLocation = CurrentLeftArmLocation;
		LastRightArmLocation = CurrentRightArmLocation;
		LastHeadLocation = CurrentHeadLocation;
		
		int ButtonMashPhase = 0;
		if(ConsumeAttribute(n"AudioStartedButtonMash", ButtonMashPhase))
		{			
			if(GetCurrentMashBlobAkComp(ButtonMashPhase, CurrentButtonMashBlobAkComp, BlobStartButtonMashEvent, BlobStopButtonMashEvent))
			{				
				CurrentButtonMashBlobAkComp.HazePostEvent(BlobStartButtonMashEvent);
			}				
		}

		if(ConsumeAction(n"AudioStoppedButtonMash") == EActionStateStatus::Active && CurrentButtonMashBlobAkComp != nullptr)
		{
			CurrentButtonMashBlobAkComp.HazePostEvent(BlobStopButtonMashEvent);
			CurrentButtonMashBlobAkComp = nullptr;			
		}

		if(Joy.bButtonMashActive)
		{
			bWasButtonMashing = true;
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Character_Bosses_Joy_Bulb_ButtonMash_Progress", Joy.ButtonMashProgress);

			const float ButtonMashProgressDirection = FMath::Sign(Joy.ButtonMashProgress - LastButtonProgressValue);
			LastButtonProgressValue = Joy.ButtonMashProgress;

			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Character_Bosses_Joy_Bulb_ButtonMash_ProgressDirection", ButtonMashProgressDirection);

			//Print("ButtonMashProgressDirection: " + ButtonMashProgressDirection, 0.f);
		}
		else if(bWasButtonMashing)
		{
			bWasButtonMashing = false;
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Character_Bosses_Joy_Bulb_ButtonMash_Progress", 0.f);
		}
	}
}