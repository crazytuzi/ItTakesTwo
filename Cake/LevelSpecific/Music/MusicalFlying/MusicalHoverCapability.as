import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Cake.LevelSpecific.Music.Singing.SingingComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

UCLASS(Deprecated)
class UMusicalHoverCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"MusicalHover");
	default CapabilityTags.Add(n"MusicalAirborne");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 1;

	AHazePlayerCharacter Player;
	UMusicalFlyingComponent FlyingComp;
	UMusicalFlyingSettings Settings;

	float FlightVelocity = 0.0f;

	float CurrentRoll = 0.0f;
	float CurrentPitch = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
		Settings = UMusicalFlyingSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!FlyingComp.bFlyingValid)
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.ExitVolumeBehavior == EMusicalFlyingExitVolumeBehavior::HalfLoop)
			return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.CurrentState == EMusicalFlyingState::Inactive)
			return EHazeNetworkActivation::DontActivate;

		if (FlyingComp.bFly)
			return EHazeNetworkActivation::DontActivate;

		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (FlyingComp.CurrentState != EMusicalFlyingState::Hovering)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (FlyingComp.bFly)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!FlyingComp.bFlyingValid)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FlyingComp.SetFlyingState(EMusicalFlyingState::Hovering);
		FVector TeleportLoc;
		if (MoveComp.IsGrounded())
			TeleportLoc = Player.ActorLocation + (Player.ActorUpVector * 350.f);
		else
			TeleportLoc = Player.ActorLocation;

		Player.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.BlockCapabilities(MovementSystemTags::GroundPound, this);
		Player.BlockCapabilities(MovementSystemTags::GroundMovement, this);
		Player.BlockCapabilities(MovementSystemTags::Jump, this);
		Player.BlockCapabilities(MovementSystemTags::Dash, this);
		Player.BlockCapabilities(n"CymbalShield", this);
		Player.BlockCapabilities(n"AirMovement", this);
		Player.SmoothSetLocationAndRotation(TeleportLoc, Player.ViewRotation, 1000.f);
		ConsumeAction(ActionNames::InteractionTrigger);
		Player.ApplyCameraSettings(FlyingComp.HoverCamSettings, FHazeCameraBlendSettings(1.0f), this, EHazeCameraPriority::Medium);

		UCymbalComponent CymbalComp = UCymbalComponent::Get(Owner);

		if(CymbalComp != nullptr)
		{
			CymbalComp.ApplyHoverSettings(this);
			CymbalComp.SetEnableSlowMotionWhenAiming(false);
		}

		USingingComponent SingingComp = USingingComponent::Get(Owner);

		if(SingingComp != nullptr)
		{
			SingingComp.ApplyHoverSettings(this);
		}

		FlyingComp.OnEnterHover();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.UnblockCapabilities(MovementSystemTags::GroundPound, this);
		Player.UnblockCapabilities(MovementSystemTags::GroundMovement, this);
		Player.UnblockCapabilities(MovementSystemTags::Jump, this);
		Player.UnblockCapabilities(MovementSystemTags::Dash, this);
		Player.UnblockCapabilities(n"CymbalShield", this);
		Player.UnblockCapabilities(n"AirMovement", this);

		Player.Mesh.SetRelativeRotation(FRotator::ZeroRotator);

		UCymbalComponent CymbalComp = UCymbalComponent::Get(Owner);

		if(CymbalComp != nullptr)
		{
			CymbalComp.ClearHoverSettings(this);
			CymbalComp.SetEnableSlowMotionWhenAiming(true);
		}

		USingingComponent SingingComp = USingingComponent::Get(Owner);

		if(SingingComp != nullptr)
		{
			SingingComp.ClearHoverSettings(this);
		}

		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!MoveComp.CanCalculateMovement())
		{
			return;
		}

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"MusicalHover");
		CalculateFrameMove(FrameMove, DeltaTime);
		MoveComp.Move(FrameMove);
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{
		if(HasControl())
		{
			FrameMove.OverrideStepDownHeight(0.f);
			FrameMove.OverrideStepUpHeight(0.f);
			FrameMove.OverrideGroundedState(EHazeGroundedState::Airborne);
			

			FVector MovementDirection = FlyingComp.HoverMovementDirection;

			MoveComp.SetTargetFacingDirection(Player.ViewRotation.ForwardVector);
			FrameMove.SetRotation(Player.ViewRotation.ForwardVector.ToOrientationQuat());

			FVector Acceleration = MovementDirection * Settings.HoverAcceleration;

			FVector Velocity = MoveComp.Velocity;
			Velocity -= Velocity * Settings.HoverDrag * DeltaTime;
			Velocity += (Acceleration + FlyingComp.HoverBoost) * DeltaTime;

			FrameMove.ApplyVelocity(Velocity);
			FrameMove.ApplyAndConsumeImpulses();

			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}
	}
}
