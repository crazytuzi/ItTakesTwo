import Cake.LevelSpecific.PlayRoom.SpaceStation.SpacePinball.SpacePinball;
import Vino.PlayerHealth.PlayerHealthStatics;

class ASpacePinballControlCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	ASpacePinball TargetPinball;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"ControlPinball"))
        	return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsPlayerDead(Player))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.TriggerMovementTransition(this);

		TargetPinball = Cast<ASpacePinball>(GetAttributeObject(n"Pinball"));
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.AttachToActor(TargetPinball, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, true);
		Player.SmoothSetLocationAndRotation(TargetPinball.ActorLocation, TargetPinball.ActorRotation);
		Player.ApplyCameraSettings(TargetPinball.CamSettings, FHazeCameraBlendSettings(), this, EHazeCameraPriority::Maximum);

		TargetPinball.OnSpacePinballCrashed.AddUFunction(this, n"PinballCrashed");

		Player.OtherPlayer.DisableOutlineByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);

		Player.ClearCameraSettingsByInstigator(this);

		Player.SetCapabilityActionState(n"ControlPinball", EHazeActionState::Inactive);

		TargetPinball.bControlled = false;

		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		TargetPinball.OnSpacePinballCrashed.Unbind(this, n"PinballCrashed");

		Player.OtherPlayer.EnableOutlineByInstigator(this);
	}

	UFUNCTION()
	void PinballCrashed()
	{
		KillPlayer(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

		TargetPinball.UpdateControlledInput(Input.Y);

		if (TargetPinball.bMoving)
		{
			float LargeMotorRumbleIntensity = FMath::Lerp(0.f, 0.25f, Input.Size());
			Player.SetFrameForceFeedback(LargeMotorRumbleIntensity, 0.1f);
		}
	}
}