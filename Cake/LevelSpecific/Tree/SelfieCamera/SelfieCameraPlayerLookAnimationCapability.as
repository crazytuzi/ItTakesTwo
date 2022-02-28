import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraPlayerComponent;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraActor;

class USelfieCameraPlayerLookAnimationCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SelfieCameraPlayerLookAnimationCapability");
	default CapabilityTags.Add(n"SelfieCamera");

	default CapabilityDebugCategory = n"LastMovement";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	USelfieCameraPlayerComponent PlayerComp;

	bool bJumpingTo;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = USelfieCameraPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		ASelfieCameraActor SelfieCam = Cast<ASelfieCameraActor>(GetAttributeObject(n"SelfieCam"));
		OutParams.AddObject(n"SelfieCam", SelfieCam);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ASelfieCameraActor SelfieCam = Cast<ASelfieCameraActor>(ActivationParams.GetObject(n"SelfieCam"));

		Player.TriggerMovementTransition(this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.BlockCapabilities(ActionNames::WeaponAim, this);
		// FVector Loc = SelfieCam.InteractionCompControlCam.WorldLocation;
		// FRotator Rot = SelfieCam.InteractionCompControlCam.WorldRotation;

		// FHazeJumpToData JumpData;
		// JumpData.TargetComponent = SelfieCam.InteractionCompControlCam;

		// FHazeDestinationEvents EndJump;
		// EndJump.OnDestinationReached.BindUFunction(this, n"JumpComplete");

		Player.PlaySlotAnimation(Animation = PlayerComp.PlayerCameraLookMH[Player], BlendTime = 0.6f, bLoop = true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.StopAllSlotAnimations(0.3f);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		Player.UnblockCapabilities(ActionNames::WeaponAim, this);
	}

	// UFUNCTION()
	// void JumpComplete(AHazeActor Actor)
	// {
	// 	Player.BlockCapabilities(CapabilityTags::Movement, this);
	// 	Player.BlockCapabilities(CapabilityTags::Interaction, this);
	// 	Player.BlockCapabilities(ActionNames::WeaponAim, this);
	// 	Player.TriggerMovementTransition(this);
	// }
}