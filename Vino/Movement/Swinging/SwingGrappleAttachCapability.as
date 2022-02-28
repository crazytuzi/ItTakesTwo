import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Swinging.SwingComponent;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Movement.Jump.AirJumpsComponent;
import Rice.Math.MathStatics;
import Vino.Movement.Swinging.SwingRope;

// Used for when attaching or detaching a rope
class USwingGrappleAttachCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Swinging);
	default CapabilityTags.Add(n"SwingingAttach");
	default CapabilityTags.Add(n"SwingingGrappleAttach");

	default CapabilityDebugCategory = n"Movement Swinging";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 175;

	AHazePlayerCharacter OwningPlayer;
	USwingingComponent SwingingComponent;
	UCharacterAirJumpsComponent AirJumpsComp;
	UHazeAkComponent HazeAKComp;

	const float Duration = 0.5f;
	FVector InitialVelocity;
	const float InitialSpeed = 1450.f;
	const float TargetSpeed = 2200.f;

	FVector InitialDirection;
	FVector TargetDirection;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
		SwingingComponent = USwingingComponent::GetOrCreate(Owner);
		AirJumpsComp = UCharacterAirJumpsComponent::GetOrCreate(Owner);
		HazeAKComp = UHazeAkComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStartedDuringTime(n"SwingAttach", 0.1f))
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if (SwingingComponent.GetTargetSwingPoint() == nullptr)
			return EHazeNetworkActivation::DontActivate;
        
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (ActiveDuration >= Duration)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;

	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"SwingPoint", SwingingComponent.GetTargetSwingPoint());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		InitialVelocity = MoveComp.Velocity;
		InitialVelocity.Z = 0.f;

		ConsumeAction(n"SwingAttach");

		Owner.BlockCapabilities(MovementSystemTags::Grinding, this);

		// Update the active swing point
		USwingPointComponent ActiveSwingPoint = Cast<USwingPointComponent>(ActivationParams.GetObject(n"SwingPoint"));
		SwingingComponent.StartSwinging(ActiveSwingPoint);

		if (SwingingComponent.SwingRope != nullptr)
			SwingingComponent.SwingRope.AttachToSwingPoint(ActiveSwingPoint);

		AirJumpsComp.ResetJumpAndDash();

		ActiveSwingPoint.OnSwingPointAttached.Broadcast(OwningPlayer);
		SwingingComponent.OnAttachedToSwingPoint.Broadcast(ActiveSwingPoint);


		if (HasControl())
		{
			
			FVector ToSwingPoint = SwingingComponent.PlayerToSwingPoint.GetSafeNormal();
			InitialDirection = ToSwingPoint.ConstrainToPlane(MoveComp.WorldUp);
			InitialDirection.Normalize();
			TargetDirection = InitialDirection;

			FVector SphereRight = ToSwingPoint.CrossProduct(ToSwingPoint.ConstrainToPlane(MoveComp.WorldUp)).GetSafeNormal();
			FQuat RotationQuat(SphereRight, -35.f * DEG_TO_RAD);
			InitialDirection = RotationQuat * InitialDirection;
		}

		// Play Sounds
		if (SwingingComponent.EffectsData.PlayerAttach != nullptr)
			HazeAKComp.HazePostEvent(SwingingComponent.EffectsData.PlayerAttach);

		if (SwingingComponent.EffectsData.SwingPointAttach != nullptr)
			UHazeAkComponent::HazePostEventFireForget(SwingingComponent.EffectsData.SwingPointAttach, SwingingComponent.ActiveSwingPoint.WorldTransform);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(MovementSystemTags::Grinding, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"Swinging");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove, n"Swinging", n"Grapple");
			
			CrumbComp.LeaveMovementCrumb();	
		}
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{
			const float MovePercentage = FMath::Clamp(ActiveDuration / Duration, 0.f, 1.f);

			float Speed = FMath::Lerp(InitialSpeed, TargetSpeed, MovePercentage);
			FVector MoveDirection = FMath::Lerp(InitialDirection, TargetDirection, MovePercentage);
			FVector InheritedVelocity = FMath::Lerp(InitialVelocity, FVector(), MovePercentage);

			FVector Velocity = (MoveDirection * Speed) + InheritedVelocity;

			FrameMove.ApplyVelocity(Velocity);
			FrameMove.OverrideStepDownHeight(0.f);

			FVector FacingDirection = Owner.ActorForwardVector;
			if (!MoveComp.Velocity.IsNearlyZero())
				FacingDirection = MoveComp.Velocity.GetSafeNormal();
			MoveComp.SetTargetFacingDirection(FacingDirection, 10.f);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}

		FrameMove.ApplyTargetRotationDelta(); 		
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		if(IsActive())
		{
			FString DebugText = "";

			DebugText += "Active Swing Point = ";
			DebugText += "" + SwingingComponent.ActiveSwingPoint.Name;

			return DebugText;
		}

		return "Not Active";
	}
}