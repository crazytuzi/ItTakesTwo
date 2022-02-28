import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;

class UCharacterChangeSizeSidescrollerAudioCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	UCharacterChangeSizeComponent SizeComp;
	float LastSizeRtpcValue;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SizeComp = UCharacterChangeSizeComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		LastSizeRtpcValue = 1;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(SizeComp.CurrentSize == ECharacterSize::Small && LastSizeRtpcValue != 0)
		{
			LastSizeRtpcValue = 0.f;
			Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_Cody_SpaceStation_Sidescrolling_Size", LastSizeRtpcValue);
		}
		else if(SizeComp.CurrentSize != ECharacterSize::Small && LastSizeRtpcValue == 0)
		{
			LastSizeRtpcValue = 1.f;
			Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_Cody_SpaceStation_Sidescrolling_Size", LastSizeRtpcValue);
		}		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_Cody_SpaceStation_Sidescrolling_Size", 1);
	}

}