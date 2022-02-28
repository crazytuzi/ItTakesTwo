import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.DarkRoom.FireflySwarm;

class UFireflyFlightCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 90;

	AHazePlayerCharacter Player;
	UFireflyFlightComponent FlightComp;

	float HorizontalDrag = 2.f;
	float HorizontalAcceleration = 4000.f;
	float VerticalDrag = 1.15f;
	float Gravity = -2500.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlightComp = UFireflyFlightComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
	        return EHazeNetworkActivation::DontActivate;

		if (FlightComp.Velocity.Z > 20.f)
        	return EHazeNetworkActivation::ActivateUsingCrumb;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (MoveComp.IsGrounded() && FlightComp.Velocity.Z < 0.f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(ActionNames::WeaponAim, this);
		SetMutuallyExclusive(CapabilityTags::Movement, true);
		Player.TriggerMovementTransition(this);
		Player.BlockCapabilities(CapabilityTags::MovementAction, this);
		FlightComp.Velocity += MoveComp.Velocity;
		Player == Game::GetCody() ? Player.AddLocomotionFeature(FlightComp.CodyZeroGFeature) : Player.AddLocomotionFeature(FlightComp.MayZeroGFeature);
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 2.f;
		Player.ApplyCameraSettings(FlightComp.CameraFlightSettings, Blend, this, EHazeCameraPriority::Low);
	}


	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(ActionNames::WeaponAim, this);
		FlightComp.Velocity = FVector::ZeroVector;
		SetMutuallyExclusive(CapabilityTags::Movement, false);
		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"FireflyLaunch");
		if (HasControl())
		{
			FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);

			//Horizontal brah!

			FVector HorizontalForce = Input * HorizontalAcceleration;
			FlightComp.Velocity += HorizontalForce * DeltaTime;
			FVector HorizontalVelocity = FlightComp.Velocity.ConstrainToPlane(FVector::UpVector);
			FlightComp.Velocity -= HorizontalVelocity * HorizontalDrag * DeltaTime;

			//Vertical brah!

			FlightComp.Velocity.Z -= FlightComp.Velocity.Z * VerticalDrag * DeltaTime;

			//Gravity brah
			float GravityFactor = 1.f - FlightComp.AttachedFireflies / 10.f;
			FlightComp.Velocity += FVector::UpVector * Gravity * GravityFactor * DeltaTime;

			FrameMove.ApplyVelocity(FlightComp.Velocity);

			if (!MoveComp.Velocity.IsNearlyZero(50.f))
				MoveComp.SetTargetFacingDirection(MoveComp.Velocity.GetSafeNormal(), 4.f);
		}
		else
		{
			// Remote, follow them crumbsies
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}

		FrameMove.ApplyTargetRotationDelta();
		FrameMove.OverrideStepUpHeight(0.f);
		FrameMove.OverrideStepDownHeight(0.f);
		MoveCharacter(FrameMove, n"FireFlies");

		CrumbComp.LeaveMovementCrumb();
	}
}
