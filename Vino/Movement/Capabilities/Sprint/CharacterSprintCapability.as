import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.Sprint.CharacterSprintSettings;
import Peanuts.Movement.GroundTraceFunctions;
import Vino.Movement.Capabilities.Sprint.CharacterSprintComponent;
import Peanuts.AutoMove.CharacterAutoMoveComponent;
import Rice.Math.MathStatics;

class UCharacterSprintCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Sprint);
	default CapabilityTags.Add(n"SprintMovement");
	default CapabilityTags.Add(MovementSystemTags::AudioMovementEfforts);
	
	default CapabilityDebugCategory = n"Movement";

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 125;

	AHazePlayerCharacter Player;
	UCharacterSprintComponent SprintComp;
	USprintSettings SprintSettings;

	float NoInputTimer = 0.f;
	bool bDashBlocked = false;
	bool bEnteredFromDash = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);	
		SprintComp = UCharacterSprintComponent::GetOrCreate(Owner);
		SprintSettings = USprintSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
    void PreTick(float DeltaTime)	
    {
		if (GetAttributeVector(AttributeVectorNames::MovementDirection).IsNearlyZero())
			NoInputTimer += DeltaTime;
		else
			NoInputTimer = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.IsGrounded())
       		return EHazeNetworkActivation::DontActivate;

		if (GetAttributeVector(AttributeVectorNames::MovementDirection).IsNearlyZero())
			return EHazeNetworkActivation::DontActivate;

		if (!SprintComp.bShouldSprint)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (!MoveComp.IsGrounded())
       		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!SprintComp.bShouldSprint)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		if (NoInputTimer >= 0.06f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SprintComp.bSprintActive = true;
		SprintComp.SprintDuration = 0.f;
		
		if (IsActioning(n"SprintingOutOfCutscene"))
		{
			Player.SetCapabilityActionState(n"SprintingOutOfCutscene", EHazeActionState::Inactive);
			MoveComp.Velocity = Owner.ActorForwardVector * SprintSettings.MoveSpeed;
		}
		else
		{
			if (!IsActioning(n"DashFinished"))
				Player.PlayForceFeedback(SprintComp.SprintActivationForceFeedback, false, true, n"SprintActivation");
		}

		Player.SetCapabilityActionState(n"SprintActive", EHazeActionState::Active);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	
		SprintComp.bSprintActive = false;

		if (NoInputTimer >= 0.06f)
			SprintComp.bSprintToggled = false;

		SetDashBlockState(false);

		if (MoveComp.Velocity.Size() > MoveComp.MoveSpeed)
			Owner.SetCapabilityActionState(n"SprintSlowdown", EHazeActionState::ActiveForOneFrame);

		if (GetAttributeVector(AttributeVectorNames::MovementDirection).IsNearlyZero())
			ConsumeAction(ActionNames::MovementSprint);		

		bEnteredFromDash = false;		
		ConsumeAction(n"SprintActive");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (IsActioning(ActionNames::MovementSprint))
			SetDashBlockState(true);
		else
			SetDashBlockState(false);			

		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(MovementSystemTags::Sprint);
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove, MovementSystemTags::Sprint);
			
			CrumbComp.LeaveMovementCrumb();	
		}

		SprintComp.SprintDuration += DeltaTime;
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{		
			FVector GroundNormal = MoveComp.WorldUp;
			if (MoveComp.DownHit.bBlockingHit)
				GroundNormal = MoveComp.DownHit.Normal;

			FVector Velocity = Math::ConstrainVectorToSlope(MoveComp.Velocity, GroundNormal, MoveComp.WorldUp);
			float MoveSpeed = Velocity.Size();
	
			// Adjust Speed
			float TargetMoveSpeed = SprintSettings.MoveSpeed;
			float SpeedDifference = TargetMoveSpeed - MoveSpeed;
			float Acceleration = SprintSettings.Acceleration * FMath::Sign(SpeedDifference) * DeltaTime;

			if (FMath::Abs(Acceleration) > FMath::Abs(SpeedDifference))
				MoveSpeed = TargetMoveSpeed;
			else
				MoveSpeed += Acceleration;

			// Rotate velocity to target Velocity
			FVector TargetDirection = Velocity;
			if (!GetAttributeVector(AttributeVectorNames::MovementDirection).IsNearlyZero())
				TargetDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
			TargetDirection.Normalize();

			float TurnRate = SprintSettings.TurnRate * DeltaTime;
			FVector NewDirection = RotateVectorTowardsAroundAxis(Owner.ActorForwardVector, TargetDirection, MoveComp.WorldUp, TurnRate);
			NewDirection = Math::ConstrainVectorToSlope(NewDirection, GroundNormal, MoveComp.WorldUp);
			NewDirection.Normalize();

			//	Create new velocity
			Velocity = NewDirection * MoveSpeed;
			FrameMove.ApplyVelocity(Velocity);
			FrameMove.ApplyAndConsumeImpulses();
			FrameMove.FlagToMoveWithDownImpact();

			FVector FacingDirection = Owner.ActorForwardVector;
			if (!Velocity.IsNearlyZero())
				FacingDirection = Velocity.GetSafeNormal();
			MoveComp.SetTargetFacingDirection(FacingDirection);			
			FrameMove.ApplyTargetRotationDelta();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}
	}	

	void SetDashBlockState(bool bBlock = true)
	{
		if (!bDashBlocked && bBlock)
		{
			Owner.BlockCapabilities(n"DashMovement", this);
			bDashBlocked = true;
		}
		else if (bDashBlocked && !bBlock)		
		{
			Owner.UnblockCapabilities(n"DashMovement", this);
			bDashBlocked = false;
		}

	}
}
