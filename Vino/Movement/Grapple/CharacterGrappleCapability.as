import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Grapple.GrapplePoint;
import Vino.Movement.Grapple.CharacterGrappleSettings;

class UCharacterGrappleCapability : UCharacterMovementCapability
{	
	default CapabilityTags.Add(MovementSystemTags::AirMovement);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(n"MovementGrapple");
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	UGrapplePointComponent GrapplePoint;

	float MoveSpeed = 0.f;
	bool bFirstMoveFrame = false;
	bool bDestinationReached = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		Player.UpdateActivationPointAndWidgets(UGrapplePointComponent::StaticClass());
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		UHazeActivationPoint ActivePoint = Player.GetTargetPoint(UGrapplePointComponent::StaticClass());
		UGrapplePointComponent Grapple = Cast<UGrapplePointComponent>(ActivePoint);
		if (Grapple == nullptr)
       		return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::SwingAttach))
       		return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (bDestinationReached)
       		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (WasActionStarted(ActionNames::Cancel))
       		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (ActiveDuration > GrappleSettings::Speed.FreezeTime + 0.05f && MoveComp.IsGrounded())
       		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		GrapplePoint = Cast<UGrapplePointComponent>(Player.GetTargetPoint(UGrapplePointComponent::StaticClass()));
		Player.ActivatePoint(GrapplePoint, this);

		MoveSpeed = 0.f;
		bFirstMoveFrame = false;
		bDestinationReached = false;

		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		GrapplePoint = nullptr;
		Player.DeactivateCurrentPoint(this);

		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"Grapple");
			CalculateFrameMove(FrameMove, DeltaTime);
			if (Player.IsMay())
				MoveCharacter(FrameMove, n"Grind", n"Grapple");
			else
				MoveCharacter(FrameMove, n"AirDash");
			
			CrumbComp.LeaveMovementCrumb();	
		}
	}	

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{		
			if (ActiveDuration <= GrappleSettings::Speed.FreezeTime)
				MoveSpeed = 0.f;
			else if (!bFirstMoveFrame)
			{
				MoveSpeed = GrappleSettings::Speed.InitialSpeed;
				bFirstMoveFrame = true;
			}
			else
			{
				MoveSpeed -= MoveSpeed * GrappleSettings::Speed.DragExponent * DeltaTime;
				MoveSpeed = FMath::Max(MoveSpeed, GrappleSettings::Speed.MinimumSpeed);
			}

			FVector GrapplePointLocation = GrapplePoint.WorldLocation;
			GrapplePointLocation += GrapplePoint.WorldTransform.TransformVector(GrapplePoint.TargetLocationOffset);

			FVector ToGrapplePoint = GrapplePointLocation - Owner.ActorLocation;
			FVector ToGrapplePointFlattened = ToGrapplePoint.ConstrainToPlane(MoveComp.WorldUp);

			FVector TargetLocation = GrapplePointLocation;
			TargetLocation += MoveComp.WorldUp * ToGrapplePointFlattened.Size();

			FVector ToTargetLocation = TargetLocation - Owner.ActorLocation;
			FVector Velocity = ToTargetLocation.GetSafeNormal() * MoveSpeed;

			FVector DeltaMove = Velocity * DeltaTime;
			if (DeltaMove.Size() > ToGrapplePoint.Size())
			{
				DeltaMove = ToGrapplePoint;
				bDestinationReached = true;
			}

			FrameMove.ApplyDeltaWithCustomVelocity(DeltaMove, Velocity);
			FrameMove.OverrideStepDownHeight(0.f);

			MoveComp.SetTargetFacingDirection(ToGrapplePointFlattened.GetSafeNormal());
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}

		FrameMove.ApplyTargetRotationDelta(); 		
	}
}