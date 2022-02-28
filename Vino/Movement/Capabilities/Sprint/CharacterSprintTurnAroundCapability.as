import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.Sprint.CharacterSprintSettings;
import Peanuts.Movement.GroundTraceFunctions;
import Vino.Movement.Helpers.StickFlickTracker;

class UCharacterSprintTurnAroundCapability : UCharacterMovementCapability
{
	default RespondToEvent(n"SprintActive");

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Sprint);
	default CapabilityTags.Add(n"SprintTurnAround");
	
	default CapabilityDebugCategory = n"Movement";

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 147;

	AHazePlayerCharacter Player;
	UPROPERTY()
	USprintSettings SprintSettings;
	FStickFlickTracker FlickTracker;

	FVector InitialVelocity;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		SprintSettings = USprintSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
    void PreTick_EventBased()	
    {
		FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementDirection);
		
		if (MoveInput.Size() > 1.f)
			MoveInput.Normalize();

		FVector ActorLocalInput = MoveComp.OwnerRotation.UnrotateVector(MoveInput);
		FVector2D Flattend(ActorLocalInput.X, ActorLocalInput.Y);		

		FlickTracker.AddStickDelta(FStickDelta(Flattend, Owner.ActorDeltaSeconds), .1f);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (!ShouldBeGrounded())
       		return EHazeNetworkActivation::DontActivate;

		if (!Owner.IsAnyCapabilityActive(n"SprintMovement"))
       		return EHazeNetworkActivation::DontActivate;

		if (!TestFlick(-MoveComp.GetLocalSpace2DVelocity()))
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!ShouldBeGrounded())
       		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (ActiveDuration >= SprintSettings.SlowdownDuration + SprintSettings.SpeedupDuration)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
		MoveComp.SetTargetFacingDirection(Input.GetSafeNormal(), 0.f);

		InitialVelocity = MoveComp.RequestVelocity;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SprintTurnAround");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove, n"SprintTurnAround");
			
			CrumbComp.LeaveMovementCrumb();	
		}
	}		

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{				
			FVector Velocity;
			FVector TargetDirection = GetAttributeVector(AttributeVectorNames::MovementDirection).GetClampedToMaxSize(1.f);

			if (ActiveDuration >= 0.f && ActiveDuration <= SprintSettings.SlowdownDuration)
			{
				float SlowdownAlpha = 1 - (ActiveDuration / SprintSettings.SlowdownDuration);
				Velocity = InitialVelocity * FMath::Pow(SlowdownAlpha, 1.2f);
				//MoveComp.SetTargetFacingDirection(TargetDirection.GetSafeNormal());
			}
			else
			{
				FVector NewDirection = RotateVectorTowardsAroundAxis(Owner.ActorForwardVector, TargetDirection, MoveComp.WorldUp, 180.f * DeltaTime);

				float SpeedupAlpha = (ActiveDuration - SprintSettings.SlowdownDuration) / SprintSettings.SpeedupDuration;
				Velocity = NewDirection.GetSafeNormal() * InitialVelocity.Size() * (0.5f + 0.5f * (FMath::Pow(SpeedupAlpha, 0.25f)));

				MoveComp.SetTargetFacingDirection(NewDirection.GetSafeNormal());
			}

			FrameMove.ApplyTargetRotationDelta();			
			FrameMove.ApplyVelocity(Velocity);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}
	}	

	float InputVelocityAngleDifference() const
	{
		FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementDirection).GetClampedToMaxSize(1.f);
		FVector VelocityDirection = MoveComp.Velocity.GetSafeNormal();

		float InputVelocityDot = MoveInput.DotProduct(VelocityDirection);
		
		return FMath::Acos(InputVelocityDot) * RAD_TO_DEG;
	}

	bool TestFlick(FVector2D Direction) const
	{
		return FlickTracker.TestStickData(Direction);
	}

	FVector RotateVectorTowardsAroundAxis(FVector Source, FVector Target, FVector Axis, float AngleDeg)	
	{
		FVector _Axis = Axis.GetSafeNormal();
		FVector ConstrainedSource = Source.ConstrainToPlane(_Axis).GetSafeNormal();
		FVector ConstrainedTarget = Target.ConstrainToPlane(_Axis).GetSafeNormal();

		float SourceTargetDot = ConstrainedSource.DotProduct(ConstrainedTarget);
		float AngleDifference = FMath::Acos(SourceTargetDot);

		FVector Cross = _Axis.CrossProduct(ConstrainedSource);
		float AxisDirection = FMath::Sign(Cross.DotProduct(Target));

		float ActualAngle = FMath::Min(AngleDifference, AngleDeg * DEG_TO_RAD);
		FQuat RotationQuat = FQuat(_Axis * AxisDirection, ActualAngle);
		
		return RotationQuat * Source;
	}
}
