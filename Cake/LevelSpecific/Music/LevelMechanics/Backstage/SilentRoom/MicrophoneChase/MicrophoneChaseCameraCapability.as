import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.CharacterMicrophoneChaseComponent;

class UMicrophoneChaseCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MicrophoneChaseCameraCapability");

	default CapabilityDebugCategory = n"MicrophoneChaseCameraCapability";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UCharacterMicrophoneChaseComponent MicChaseComp;
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MicChaseComp = UCharacterMicrophoneChaseComponent::Get(Player); 
		CamSettings = MicChaseComp.ChaseCamSettings;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (IsActioning(n"MicrophoneChase"))
			return EHazeNetworkActivation::ActivateFromControl;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"MicrophoneChase"))
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FHazeCameraBlendSettings Blend;
		Player.ApplyCameraSettings(CamSettings, Blend, this, EHazeCameraPriority::Script);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (IsDebugActive())
		{
			System::DrawDebugLine(Owner.ActorLocation, (Owner.ActorLocation + Owner.ActorForwardVector * 2500.f));
		}
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		if(IsActive())
		{
			FString DebugText = "";
			if(HasControl())
			{
				DebugText += "Control Side\n";
			}
			else
			{
				DebugText += "Slave Side\n";
			}
			return DebugText;
		}

		return "Not Active";
	}
}