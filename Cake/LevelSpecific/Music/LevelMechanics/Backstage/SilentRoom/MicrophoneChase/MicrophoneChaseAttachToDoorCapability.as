import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.CharacterMicrophoneChaseComponent;

class UMicrophoneChaseAttachToDoorCapability : UHazeCapability
{
    AHazePlayerCharacter Player;
    UCharacterMicrophoneChaseComponent Chase;
	AMicrophoneChaseDoor ChaseDoor;
    
    UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
        Player = Cast<AHazePlayerCharacter>(Owner);
		Chase = UCharacterMicrophoneChaseComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Chase.Door == nullptr)
            return EHazeNetworkActivation::DontActivate;

		if(Chase.Door.bReleasePlayer)
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
		ChaseDoor.SetControlSide(Player);
		ChaseDoor.StartOpeningDoor(Player);
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockMovementSyncronization(this);
		Player.AttachToComponent(ChaseDoor.AttachComp, NAME_None, EAttachmentRule::SnapToTarget);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		//Player.DetachFromActor(EDetachmentRule::KeepWorld);
		Player.UnblockMovementSyncronization(this);
		Player.StopAllSlotAnimations();
		Chase.Door = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Chase.Door == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(Chase.Door.bReleasePlayer)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
}
