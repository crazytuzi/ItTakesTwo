import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;
import Vino.Movement.Components.MovementComponent;

class UMusicFlyingActiveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"MusicFlying");
	
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 19;

	UMusicalFlyingComponent FlyingComp;
	UHazeMovementComponent MoveComp;
	UHazeJumpToComponent JumpToComp;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		JumpToComp = UHazeJumpToComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.bForceActivateFlying)
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if(!FlyingComp.CanFly())
			return EHazeNetworkActivation::DontActivate;

		if(!FlyingComp.bWantsToFly)
			return EHazeNetworkActivation::DontActivate;

		if(!MoveComp.IsAirborne())
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.IsFlyingDisabled())
			return EHazeNetworkActivation::DontActivate;

		if(JumpToComp.ActiveJumpTos.Num() != 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FlyingComp.FlyingVelocity = 0.0f;
		FlyingComp.bForceActivateFlying = false;
		UHazeLocomotionStateMachineAsset LocomotionStateMachine = Player.IsCody() ? FlyingComp.CodyFlyingStateMachine : FlyingComp.MayFlyingStateMachine;
		Player.AddLocomotionAsset(LocomotionStateMachine, this);
		FlyingComp.OnEnterFlying();
		FlyingComp.bIsFlying = true;

		Owner.ApplySettings(FlyingComp.MusicalFlyingSettings, this);
		Owner.ApplySettings(FlyingComp.ReturnToVolumeSettings, this);

		Owner.BlockCapabilities(ActionNames::WeaponAim, this);
		Owner.BlockCapabilities(n"CymbalShield", this);
		Owner.BlockCapabilities(n"SongOfLife", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		RequestAnimation();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		if(FlyingComp.bIsReturningToVolume)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(FlyingComp.bForceDeactivateFlying)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(FlyingComp.bWantsToStopFlying && !FlyingComp.bMoveUpDownWithButtons)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(FlyingComp.bDeactivateFlyingWhenGrounded && MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(FlyingComp.IsFlyingDisabled())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(JumpToComp.ActiveJumpTos.Num() != 0)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FlyingComp.bForceDeactivateFlying = false;
		FlyingComp.OnExitFlying();
		ConsumeAction(ActionNames::MovementGroundPound);
		ConsumeAction(ActionNames::MovementSlide);
		ConsumeAction(ActionNames::MovementCrouch);
		Player.MeshOffsetComponent.ResetRelativeRotationWithTime(0.15f);
		Player.ClearCameraSettingsByInstigator(this);
		Player.ClearLocomotionAssetByInstigator(this);
		FlyingComp.bIsFlying = false;

		Player.ClearSettingsByInstigator(this);

		Owner.UnblockCapabilities(ActionNames::WeaponAim, this);
		Owner.UnblockCapabilities(n"CymbalShield", this);
		Owner.UnblockCapabilities(n"SongOfLife", this);
	}

	private void RequestAnimation()
	{
		if(!Player.Mesh.CanRequestLocomotion())
			return;

		FHazeRequestLocomotionData AnimationRequest;
		
		if(!MoveComp.GetAnimationRequest(AnimationRequest.AnimationTag))
		{
			AnimationRequest.AnimationTag = n"JetPack";
		}

		Player.RequestLocomotion(AnimationRequest);
	}
}
