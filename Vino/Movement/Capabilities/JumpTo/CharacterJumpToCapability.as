import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.PlayerHealth.PlayerHealthStatics;
import Peanuts.Movement.GroundTraceFunctions;

const float DASH_TO_SPEED = 2250.f;
const float DASH_TO_MIN_TRAVEL_TIME = 0.00f;
const float DASH_TO_LAND_TIME = 0.01f;

class UCharacterJumpToCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(n"CharacterJumpToCapability");

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 1;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	FHazeJumpToInstance ActiveInstance;

	UHazeJumpToComponent JumpToComp;

	float Time = 0.f;
	float Duration = 0.f;

	FTransform StartTransform;
	bool bStartedGrounded = false;
	FVector RelativeOffset;

	AHazePlayerCharacter PlayerOwner;
	int ResetCounterAtStart = -1;

	// We want to keep out vertical velocity as a float, so we can handle changes in world up
	float VerticalVelocity;

	FQuat DirectionToTarget;
	float TravelTime = 0.f;
	float TravelDestinationAngleDifference = 0.f;

	bool bSkipDeactivationMove = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		JumpToComp = UHazeJumpToComponent::GetOrCreate(Owner);
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (JumpToComp.ActiveJumpTos.Num() == 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (JumpToComp.ActiveJumpTos.Num() != 0)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (Time >= Duration)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (ResetCounterAtStart < Reset::GetPlayerResetCounter(PlayerOwner))
		{
			if (HasControl())
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			else
				return EHazeNetworkDeactivation::DeactivateLocal;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (HasControl() && IsBlocked())
		{
			while (JumpToComp.ActiveJumpTos.Num() != 0
				&& JumpToComp.ActiveJumpTos[0].JumpToData.bCancelWhenBlocked)
			{
				// The jumpto capability is blocked but we want to do a jumpto,
				// this jumpto isn't important, so we just cancel it
				JumpToComp.ActiveJumpTos.RemoveAt(0);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		FHazeJumpToInstance Instance = JumpToComp.ActiveJumpTos[0];
		JumpToComp.ActiveJumpTos.RemoveAt(0);
		ActivationParams.AddStruct(n"ActiveInstance", Instance);
		ActivationParams.AddNumber(n"ResetCounter", Reset::GetPlayerResetCounter(PlayerOwner));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		ActivationParams.GetStruct(n"ActiveInstance", ActiveInstance);
		ResetCounterAtStart = ActivationParams.GetNumber(n"ResetCounter");

		Time = 0.f;
		if (ActiveInstance.JumpToData.Trajectory == EHazeJumpToTrajectory::Jump)
		{
			CalculateJumpTrajectory();
		}
		else if (ActiveInstance.JumpToData.Trajectory == EHazeJumpToTrajectory::Dash)
		{
			CalculateDashTrajectory();
			UpdateDashAnimParams();
		}

		// Rotations
		bStartedGrounded = MoveComp.IsGrounded();
		StartTransform = Owner.GetActorTransform();

		Owner.BlockCapabilities(CapabilityTags::Collision, this);
		Owner.BlockCapabilities(CapabilityTags::Interaction, this);
		Owner.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Owner.BlockCapabilities(CapabilityTags::MovementAction, this);
		Owner.BlockCapabilities(CapabilityTags::MovementInput, this);
		Owner.TriggerMovementTransition(this);

		bSkipDeactivationMove = ActiveInstance.JumpToData.bKeepVelocity;
	}

	void CalculateJumpTrajectory()
	{
		FTransform Target = GetWorldTargetTransform();
		FVector WorldUp = MoveComp.WorldUp;

		// Setup velocity
		FVector TargetLoc = Target.Translation;
		FVector Loc = Owner.GetActorLocation();

		if (TargetLoc.Distance(Loc) < ActiveInstance.JumpToData.SmoothTeleportRange)
		{
			Duration = 0.f;
			VerticalVelocity = 0.f;
			return;
		}

		float Gravity = MoveComp.GravityMagnitude;
		float VerticalDistance = (TargetLoc - Loc).DotProduct(WorldUp);

		/*
		Calculate how long it will take to reach the target height, with given impulse

		Parabola:
		-G/2 * (X - V/G)^2 + V^2/2G = A

		(-2A / G) + (V / G)^2
		*/
		float TargetHeight = VerticalDistance + ActiveInstance.JumpToData.AdditionalHeight;

		// Make sure we jump high enough to at _least_ reach additional height
		if (TargetHeight < ActiveInstance.JumpToData.AdditionalHeight)
			TargetHeight = ActiveInstance.JumpToData.AdditionalHeight;

		TargetHeight = FMath::Max(TargetHeight, 0.f);

		float Impulse = FMath::Sqrt(2.f * TargetHeight * Gravity);

		float ValueToSqrt = (-2.f * VerticalDistance) / Gravity +
			((Impulse / Gravity) * (Impulse / Gravity));

		// This shouldn't be possible, but just to safe up, make sure we dont error
		if (!ensure(ValueToSqrt >= 0.f))
			ValueToSqrt = 0.001f;

		// X = V / G + sqrt((-2A / G) + (V / G)^2)
		float FlyTime = Impulse / Gravity +
			FMath::Sqrt(ValueToSqrt);

		Duration = FlyTime;
		VerticalVelocity = Impulse;
	}

	void CalculateDashTrajectory()
	{
		FTransform Target = GetWorldTargetTransform();
		FVector TargetLocation = Target.Location;
		FVector OwnerLocation = Owner.ActorLocation;

		FVector Delta = TargetLocation - OwnerLocation;
		FVector HorizDelta = Delta.ConstrainToPlane(MoveComp.WorldUp);

		float Distance = Delta.Size();
		if (HorizDelta.Size() < ActiveInstance.JumpToData.SmoothTeleportRange)
		{
			Duration = 0.f;
			TravelTime = 0.f;
		}
		else
		{
			TravelTime = FMath::Max(Distance / DASH_TO_SPEED, DASH_TO_MIN_TRAVEL_TIME);
			Duration = TravelTime + DASH_TO_LAND_TIME;
		}

		if (HorizDelta.IsNearlyZero())
			DirectionToTarget = Target.Rotation;
		else
			DirectionToTarget = FRotator::MakeFromX(HorizDelta).Quaternion();

		VerticalVelocity = 0.f;

		FVector TravelForward = DirectionToTarget.ForwardVector;
		FVector TargetForward = Target.Rotation.ForwardVector.ConstrainToPlane(MoveComp.WorldUp);

		TravelDestinationAngleDifference = FMath::RadiansToDegrees(
			FMath::Atan2(TargetForward.CrossProduct(TravelForward).DotProduct(MoveComp.WorldUp), TravelForward.DotProduct(TargetForward))
		);

		RelativeOffset = OwnerLocation - TargetLocation;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
		bool bSwitchToNewJump = JumpToComp.ActiveJumpTos.Num() != 0;
		if (bSwitchToNewJump)
			DeactivationParams.AddActionState(n"SwitchToNewJump");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FHazeDestinationReachedDelegate Delegate;
		if (ActiveInstance.CallbackObject != nullptr)
			Delegate.BindUFunction(ActiveInstance.CallbackObject, ActiveInstance.CallbackFunction);

		// Smooth teleport to final location, since we could've gotten blocked or something
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		if (Player != nullptr && !DeactivationParams.GetActionState(n"SwitchToNewJump") && !Player.IsPlayerDead()
			&& !ActiveInstance.JumpToData.bKeepVelocity && !Player.bIsControlledByCutscene
			&& ResetCounterAtStart == Reset::GetPlayerResetCounter(Player))
		{
			Player.RootOffsetComponent.FreezeAndResetWithTime(0.2f);

			FTransform Target = GetWorldTargetTransform();
			MoveComp.SetTargetFacingRotation(Target.Rotation, 0.f);
			Owner.SetCapabilityAttributeVector(AttributeVectorNames::MovementDirection, FVector::ZeroVector);

			if (MoveComp.CanCalculateMovement())
			{
				FHazeFrameMovement Move = MoveComp.MakeFrameMovement(n"JumpToFinish");
				Move.ApplyDeltaWithCustomVelocity(Target.Location - Player.ActorLocation, FVector::ZeroVector);
				if (IsPlayerGroundedAtLocation(Player, Target.Location))
					Move.OverrideGroundedState(EHazeGroundedState::Grounded);
				else
					Move.OverrideGroundedState(EHazeGroundedState::Airborne);

				Move.SetRotation(Target.Rotation);
				MoveCharacter(Move, Duration > 0.f ? GetAnimationFeature() : n"Movement");
			}
		}

		ActiveInstance = FHazeJumpToInstance();

		Owner.UnblockCapabilities(CapabilityTags::Collision, this);
		Owner.UnblockCapabilities(CapabilityTags::Interaction, this);
		Owner.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Owner.UnblockCapabilities(CapabilityTags::MovementAction, this);
		Owner.UnblockCapabilities(CapabilityTags::MovementInput, this);

		Delegate.ExecuteIfBound(Owner);
	}

	void PerformJumpMove(FHazeFrameMovement& Move, float DeltaTime)
	{
		FTransform Target = GetWorldTargetTransform();

		// For horizontal translation, we lerp from the jumps start location to the target, then snap (horizontally) to that lerped location
		FVector TargetLerpLocation = FMath::Lerp(StartTransform.Location, Target.Location, Time / Duration);
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
		FQuat Rotation = FQuat::Slerp(StartTransform.Rotation, Target.Rotation, Time / Duration);
		Move.SetRotation(Rotation);
	}

	void PerformDashMove(FHazeFrameMovement& Move, float DeltaTime)
	{
		FTransform Target = GetWorldTargetTransform();

		RelativeOffset = FMath::VInterpConstantTo(RelativeOffset, FVector::ZeroVector, DeltaTime, DASH_TO_SPEED);
		Move.ApplyDelta((RelativeOffset + Target.Location) - Owner.ActorLocation);

		if (Time >= TravelTime)
		{
			MoveComp.SetTargetFacingRotation(Target.Rotation, PI * 3.f);
			Move.ApplyTargetRotationDelta();
		}
		else
		{
			Move.SetRotation(DirectionToTarget);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Duration <= 0.f)
			return;
		
		FHazeFrameMovement Move = MoveComp.MakeFrameMovement(n"JumpTo");
		if (HasControl())
		{
			Move.OverrideStepUpHeight(0.f);
			Move.OverrideStepDownHeight(0.f);

			if (ActiveInstance.JumpToData.Trajectory == EHazeJumpToTrajectory::Jump)
			{
				PerformJumpMove(Move, DeltaTime);
			}
			else if (ActiveInstance.JumpToData.Trajectory == EHazeJumpToTrajectory::Dash)
			{
				PerformDashMove(Move, DeltaTime);
				UpdateDashAnimParams();
			}

			Time += DeltaTime;

			if (MoveComp.CanCalculateMovement())
			{
				MoveCharacter(Move, GetAnimationFeature());
				CrumbComp.LeaveMovementCrumb();
			}
		}
		else
		{
			FHazeActorReplicationFinalized ReplicatedMovement;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ReplicatedMovement);

			Move.ApplyConsumedCrumbData(ReplicatedMovement);

			if (MoveComp.CanCalculateMovement())
			{
				MoveCharacter(Move, GetAnimationFeature());
			}
		}
	}

	void UpdateDashAnimParams()
	{
		Owner.SetAnimFloatParam(n"DashToPredictedTravelTime", TravelTime);
		Owner.SetAnimFloatParam(n"DashToRemainingDistance", GetWorldTargetTransform().Location.Distance(Owner.ActorLocation));
		Owner.SetAnimFloatParam(n"DashToAngleDelta", TravelDestinationAngleDifference);
		Owner.SetAnimBoolParam(n"DashToLanded", Time >= TravelTime);
	}

	FName GetAnimationFeature()
	{
		if (ActiveInstance.JumpToData.Trajectory == EHazeJumpToTrajectory::Jump)
		{
			return n"JumpTo";
		}
		else if (ActiveInstance.JumpToData.Trajectory == EHazeJumpToTrajectory::Dash)
		{
			return n"DashTo";
		}
		else
		{
			return NAME_None;
		}
	}

	FTransform GetWorldTargetTransform()
	{
		// If no target, its world space
		if (ActiveInstance.JumpToData.TargetComponent == nullptr)
			return ActiveInstance.JumpToData.Transform;

		// Otherwise, transform from local-space to world space
		return ActiveInstance.JumpToData.Transform * ActiveInstance.JumpToData.TargetComponent.WorldTransform;
	}
};
