import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Music.MusicJumpTo.MusicJumpToComponent;

/*
Copy paste of JumpTo but for Music to allow GameplayActions while jumping since this is required in certain parts of backstage.
*/

class UMusicJumpToCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 9;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	UMusicJumpToComponent JumpToComp;

	float Time = 0.f;
	float Duration = 0.f;

	private FVector StartLocation;
	private FQuat StartRotation;

	private USceneComponent TargetComponent;
	private FVector Internal_TargetLocation;
	private FQuat Internal_TargetRotation;

	// We want to keep out vertical velocity as a float, so we can handle changes in world up
	float VerticalVelocity;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		JumpToComp = UMusicJumpToComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!JumpToComp.bJump)
			return EHazeNetworkActivation::DontActivate;

		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		if(JumpToComp.TargetComponent != nullptr)
		{
			ActivationParams.AddObject(n"TargetComponent", JumpToComp.TargetComponent);
		}
		else
		{
			ActivationParams.AddVector(n"TargetLocation", JumpToComp.TargetTransform.Location);
			ActivationParams.AddVector(n"TargetRotation", JumpToComp.TargetTransform.Rotation.Vector());
		}

		ActivationParams.AddValue(n"AdditionalHeight", JumpToComp.AdditionalHeight);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TargetComponent = Cast<USceneComponent>(ActivationParams.GetObject(n"TargetComponent"));
		Internal_TargetLocation = ActivationParams.GetVector(n"TargetLocation");
		Internal_TargetRotation = ActivationParams.GetVector(n"TargetRotation").ToOrientationQuat();
		const float AdditionalHeight = ActivationParams.GetValue(n"AdditionalHeight");

		const FVector WorldUp = MoveComp.WorldUp;

		// Setup velocity
		StartLocation = Owner.ActorLocation;

		const float Gravity = MoveComp.GravityMagnitude;
		const float VerticalDistance = (TargetLocation - StartLocation).DotProduct(WorldUp);

		/*
		Calculate how long it will take to reach the target height, with given impulse

		Parabola:
		-G/2 * (X - V/G)^2 + V^2/2G = A

		(-2A / G) + (V / G)^2
		*/
		float TargetHeight = VerticalDistance + AdditionalHeight;

		// Make sure we jump high enough to at _least_ reach additional height
		if (TargetHeight < AdditionalHeight)
			TargetHeight = AdditionalHeight;

		float Impulse = FMath::Sqrt(2.f * TargetHeight * Gravity);

		float ValueToSqrt = (-2.f * VerticalDistance) / Gravity +
			((Impulse / Gravity) * (Impulse / Gravity));

		// This shouldn't be possible, but just to safe up, make sure we dont error
		if (!ensure(ValueToSqrt >= 0.f))
			ValueToSqrt = 0.001f;

		// X = V / G + sqrt((-2A / G) + (V / G)^2)
		float FlyTime = Impulse / Gravity +
			FMath::Sqrt(ValueToSqrt);

		Time = 0.f;
		Duration = FlyTime;
		VerticalVelocity = Impulse;

		// Rotations
		StartLocation = Owner.ActorLocation;
		StartRotation = Owner.ActorRotation.Quaternion();

		Owner.BlockCapabilities(CapabilityTags::Collision, this);
		Owner.BlockCapabilities(CapabilityTags::Interaction, this);
		Owner.BlockCapabilities(CapabilityTags::MovementAction, this);
		Owner.BlockCapabilities(CapabilityTags::MovementInput, this);
		Owner.TriggerMovementTransition(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement Move = MoveComp.MakeFrameMovement(n"JumpTo");
		if(HasControl())
		{
			Move.OverrideStepUpHeight(0.f);
			Move.OverrideStepDownHeight(0.f);

			// For horizontal translation, we lerp from the jumps start location to the target, then snap (horizontally) to that lerped location
			FVector TargetLerpLocation = FMath::Lerp(StartLocation, TargetLocation, Time / Duration);
			FVector CurrentLocation = Owner.ActorLocation;
			FVector Difference = TargetLerpLocation - CurrentLocation;
			Difference = Difference.ConstrainToPlane(MoveComp.WorldUp);

			Move.ApplyDelta(Difference);

			// Integrate gravity
			float GravityMag = MoveComp.GravityMagnitude;
			float DeltaMove = VerticalVelocity * DeltaTime - GravityMag * DeltaTime * DeltaTime * 0.5f;

			VerticalVelocity -= GravityMag * DeltaTime;
			Move.ApplyDelta(MoveComp.WorldUp * DeltaMove);

			// Rotation (just lerp to target)
			FQuat Rotation = FQuat::Slerp(StartRotation, TargetRotation, Time / Duration);
			Move.SetRotation(Rotation);

			MoveCharacter(Move, n"JumpTo");

			Time += DeltaTime;
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ReplicatedMovement;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ReplicatedMovement);

			Move.ApplyConsumedCrumbData(ReplicatedMovement);
			MoveCharacter(Move, n"JumpTo");
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (Time >= Duration)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Smooth teleport to final location, since we could've gotten blocked or something
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		if (Player != nullptr && !DeactivationParams.GetActionState(n"SwitchToNewJump"))
		{
			Player.RootOffsetComponent.FreezeAndResetWithTime(0.2f);

			MoveComp.SetControlledComponentTransform(TargetLocation, TargetRotation.Rotator());
		}

		Owner.UnblockCapabilities(CapabilityTags::Collision, this);
		Owner.UnblockCapabilities(CapabilityTags::Interaction, this);
		Owner.UnblockCapabilities(CapabilityTags::MovementAction, this);
		Owner.UnblockCapabilities(CapabilityTags::MovementInput, this);

		JumpToComp.bJump = false;
	}


	FQuat GetTargetRotation() const property
	{
		if(TargetComponent != nullptr)
			return TargetComponent.WorldRotation.Quaternion();

		return Internal_TargetRotation;
	}

	FVector GetTargetLocation() const property
	{
		if(TargetComponent != nullptr)
			return TargetComponent.WorldLocation;

		return Internal_TargetLocation;
	}
}
