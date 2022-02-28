import Peanuts.Audio.AudioStatics;
import Vino.Audio.Capabilities.AudioTags;
import Vino.Audio.Movement.PlayerMovementAudioComponent;

class UPlayerVelocityTraversalOverrideCapability : UHazeCapability
{
	default CapabilityTags.Add(n"AudioTraversalTypeOverride");
	default CapabilityDebugCategory = n"Audio";

	UPROPERTY()
	HazeAudio::EPlayerMovementState OverrideState;

	AHazePlayerCharacter Player;
	UPlayerMovementAudioComponent AudioMoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		AudioMoveComp = UPlayerMovementAudioComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"MovementAudio", this);

		AudioMoveComp.UpdateBodyMovementEvent(AudioMoveComp.BodyMovementEvent);
		AudioMoveComp.SetTraversalTypeSwitch(OverrideState);
		Player.PlayerHazeAkComp.SetRTPCValue(HazeAudio::RTPC::CharacterMovementType, OverrideState);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"MovementAudio", this);
	}
}