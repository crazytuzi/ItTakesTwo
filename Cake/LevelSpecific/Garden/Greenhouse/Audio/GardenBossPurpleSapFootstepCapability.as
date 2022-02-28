import Vino.Audio.Movement.PlayerMovementAudioComponent;

class UGardenBossPurpleSapFootstepCapability : UHazeCapability
{	
	UPROPERTY()
	UPhysicalMaterialAudio SapPhysMat;

	AHazePlayerCharacter PlayerOwner;
	UPlayerMovementAudioComponent AudioMoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		AudioMoveComp = UPlayerMovementAudioComponent::Get(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{	
		return EHazeNetworkActivation::ActivateLocal;
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(ConsumeAction(n"AudioEnteredGoo") == EActionStateStatus::Active)
		{
			AudioMoveComp.OverrideFootstepEvent = PlayerOwner.IsMay() ? 
			SapPhysMat.MayMaterialEvents.MayMaterialFootstepEvent : SapPhysMat.CodyMaterialEvents.CodyMaterialFootstepEvent;
		}

		if(ConsumeAction(n"AudioExitedGoo") == EActionStateStatus::Active)
		{
			AudioMoveComp.OverrideFootstepEvent = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AudioMoveComp.OverrideFootstepEvent = nullptr;
	}

}