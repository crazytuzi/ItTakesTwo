import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Tutorial.TutorialStatics;

class UBoatsledWaitForOtherPlayerCapabilty : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledWaitForOtherPlayer);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 101;

	default CapabilityDebugCategory = n"Boatsled";

	AHazePlayerCharacter PlayerOwner;
	UHazeMovementComponent MovementComponent;

	UBoatsledComponent BoatsledComponent;
	UBoatsledComponent OtherPlayerBoatsledComponent;

	bool bOtherPlayerIsWaiting;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);

		BoatsledComponent = UBoatsledComponent::Get(Owner);
		OtherPlayerBoatsledComponent = UBoatsledComponent::GetOrCreate(PlayerOwner.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BoatsledComponent.IsWaitingForOtherPlayer())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Move camera further away from player
		FHazeCameraSpringArmSettings SpringArmSettings;
		SpringArmSettings.bUseIdealDistance = true;
		SpringArmSettings.IdealDistance = 1500.f;
		SpringArmSettings.bUseMinDistance = true;
		SpringArmSettings.MinDistance = 800.f;
		// PlayerOwner.ApplyCameraSpringArmSettings(SpringArmSettings, 3.f, this);

		// Focus on other player
		FHazePointOfInterest PointOfInterest;
		PointOfInterest.Blend = 3.f;
		PointOfInterest.Duration = -1.f;
		PointOfInterest.FocusTarget.Actor = PlayerOwner.OtherPlayer;
		// PlayerOwner.ApplyPointOfInterest(PointOfInterest, this);

		ShowCancelPrompt(PlayerOwner, this);

		// Attach to totem bone and add boatsled locomotion asset
		PlayerOwner.AttachToComponent(BoatsledComponent.Boatsled.MeshComponent, n"Totem");
		PlayerOwner.AddLocomotionAsset(BoatsledComponent.Boatsled.GetLocomotionStateMachineAsset(PlayerOwner), BoatsledComponent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Check if other player is ready
		bOtherPlayerIsWaiting = OtherPlayerBoatsledComponent.GetBoatsledState() >= EBoatsledState::WaitingForOtherPlayer;

		// Create frame movement
		FHazeFrameMovement MoveData = MovementComponent.MakeFrameMovement(BoatsledTags::BoatsledWaitForOtherPlayer);

		// Request boatsled locomotion if we're done playing root motion animation (state is idle and waiting for other player)
		BoatsledComponent.RequestPlayerBoatsledLocomotion();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// Start race
		if(bOtherPlayerIsWaiting)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(PlayerOwner.IsAnyCapabilityActive(BoatsledTags::BoatsledPlayerExit))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& SyncParams)
	{
		if(bOtherPlayerIsWaiting)
			SyncParams.AddActionState(n"ShouldStartRace");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(DeactivationParams.GetActionState(n"ShouldStartRace"))
		{
			// Locally set state since we deactivated through network
			BoatsledComponent.SetStateLocal(EBoatsledState::WaitingForStartLight);

			// Fire ready event
			BoatsledComponent.BoatsledEventHandler.OnBothPlayersWaitingForStart.Broadcast();
		}

		RemoveCancelPromptByInstigator(PlayerOwner, this);

		// Clear camera stuff
		PlayerOwner.ClearPointOfInterestByInstigator(this);
		PlayerOwner.ClearCameraSettingsByInstigator(this);

		// Cleanup
		bOtherPlayerIsWaiting = false;
	}
}