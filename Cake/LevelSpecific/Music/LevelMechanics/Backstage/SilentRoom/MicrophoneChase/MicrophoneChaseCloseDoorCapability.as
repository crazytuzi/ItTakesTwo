import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.CharacterMicrophoneChaseComponent;

class UMicrophoneChaseCloseDoorCapability : UHazeCapability
{
	
    default CapabilityTags.Add(n"MicrophoneChaseDoor");

	default CapabilityDebugCategory = n"MicrophoneChaseDoor";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
    UCharacterMicrophoneChaseComponent Chase;
	AMicrophoneChaseDoor ChaseDoor;

    UButtonMashProgressHandle ButtonMashHandle;

	float ButtonMashSpeed = 0.2f;
	float CurrentMash = 0.0f;

	//float PushAmount = 0.f;
	//float PushingTimer = 0.f;

	bool bHasClosedDoor = false;
	bool bFirstMash = false;

	UHazeLocomotionFeatureBase FeatureToUse;
    
    UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
        Player = Cast<AHazePlayerCharacter>(Owner);
		Chase = UCharacterMicrophoneChaseComponent::Get(Owner);

		FeatureToUse = Player == Game::GetCody() ? Chase.CodyDoorFeature : Chase.MayDoorFeature;
		Player.AddLocomotionFeature(FeatureToUse);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.RemoveLocomotionFeature(FeatureToUse);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(Chase.Door == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(Chase.Door.IsDoorClosed())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"Door", Chase.Door);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ChaseDoor = Cast<AMicrophoneChaseDoor>(ActivationParams.GetObject(n"Door"));
        ButtonMashHandle = StartButtonMashProgressAttachToComponent(Player, ChaseDoor.AttachComp, n"", FVector(0.f, 0.f, 100.f));
		bFirstMash = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ButtonMashHandle.StopButtonMash();
		ButtonMashHandle = nullptr;

		// Tell the door that it is closed - DOING THIS ON TICK INSTEAD!
		//Chase.Door.OnDoorClosed();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Chase.Door == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		// if(Chase.Door.IsDoorClosed())
		// 	return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeRequestLocomotionData Data;
		Data.AnimationTag = n"MicrophoneChaseDoor";
		Player.RequestLocomotion(Data);
		
		if(!HasControl())
			return;



		CurrentMash = FMath::Min(CurrentMash + ButtonMashHandle.MashRateControlSide * ButtonMashSpeed * DeltaTime, 1.0f);

		if(CurrentMash >= 1.0f && !ChaseDoor.IsDoorClosed())
		{
			//PushingTimer = 0.25f;
			ChaseDoor.AddProgress(CurrentMash * 0.26f);
			ButtonMashSpeed *= 0.9f;
			CurrentMash = 0.0f;
			NetPushDoorAnim();
		}

		if (ChaseDoor.IsDoorClosed() && !bHasClosedDoor)
		{
			bHasClosedDoor = true;
			ChaseDoor.OnDoorClosed();
		}

		if (CurrentMash != 0.f && !bFirstMash)
		{
			NetStartedButtonMashAnim();
			bFirstMash = true;
		}
			
	}

	UFUNCTION(NetFunction)
	private void NetStartedButtonMashAnim()
	{
		Player.SetAnimBoolParam(n"IsButtonMashing", true);
	}

	UFUNCTION(NetFunction)
	private void NetPushDoorAnim()
	{
		Player.SetAnimBoolParam(n"PushDoor", true);
	}
}
