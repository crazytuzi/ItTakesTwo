import Peanuts.AutoMove.CharacterAutoMoveComponent;
import Vino.Movement.Components.MovementComponent;

class UCharacterAutoMoveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(AttributeVectorNames::MovementDirection);
	default CapabilityTags.Add(n"AutoMove");

	default CapabilityDebugCategory = CapabilityTags::Movement;
	
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 101;

	AHazePlayerCharacter Player;
	UCharacterAutoMoveComponent AutoMoveComp;
	UHazeMovementComponent MoveComp;

	FVector MoveDirection;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		AutoMoveComp = UCharacterAutoMoveComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (AutoMoveComp.AutoMoveMode == EAutoMoveMode::None)
			return EHazeNetworkActivation::DontActivate;		

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ActiveDuration > AutoMoveComp.Duration)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (AutoMoveComp.AutoMoveMode == EAutoMoveMode::None)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!GetAttributeVector(AttributeVectorNames::MovementDirection).IsNearlyZero() && AutoMoveComp.bInterruptOnPlayerInput)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AutoMoveComp.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		UpdateMoveDirection();
		Player.SetCapabilityAttributeVector(AttributeVectorNames::MovementDirection, MoveDirection);
	}

	void UpdateMoveDirection()
	{
		switch (AutoMoveComp.AutoMoveMode)
		{
			case EAutoMoveMode::WorldDirection:
				MoveDirection = AutoMoveComp.MoveDirection;
			break;
			case EAutoMoveMode::FollowActor:
			{
				FVector ToActor = AutoMoveComp.ActorToFollow.ActorLocation - Owner.ActorLocation;
				ToActor = ToActor.ConstrainToPlane(MoveComp.WorldUp);
				ToActor.Normalize();

				MoveDirection = ToActor;
			}
			break;
			case EAutoMoveMode::FollowSpline:
			{
				float DistanceAlongSpline = AutoMoveComp.SplineToFollow.GetDistanceAlongSplineAtWorldLocation(Player.ActorLocation);
				float TargetDistanceAlongSpline = DistanceAlongSpline + AutoMoveComp.ChaseDistance;

				FVector SplineFollowLocation = AutoMoveComp.SplineToFollow.GetLocationAtDistanceAlongSpline(TargetDistanceAlongSpline, ESplineCoordinateSpace::World);
				FVector SplineRightVector = AutoMoveComp.SplineToFollow.GetRightVectorAtDistanceAlongSpline(TargetDistanceAlongSpline, ESplineCoordinateSpace::World);
				SplineRightVector = SplineRightVector.ConstrainToPlane(MoveComp.WorldUp);
				SplineRightVector.Normalize();

				SplineFollowLocation += SplineRightVector * AutoMoveComp.LateralFollowOffset;
			
				if (TargetDistanceAlongSpline > AutoMoveComp.SplineToFollow.SplineLength)
				{
					float Overhang = TargetDistanceAlongSpline - AutoMoveComp.SplineToFollow.SplineLength;

					FVector Tangent = AutoMoveComp.SplineToFollow.GetTangentAtSplinePoint(AutoMoveComp.SplineToFollow.LastSplinePointIndex, ESplineCoordinateSpace::World);					
					Tangent.Normalize();

					SplineFollowLocation += Tangent * Overhang;
				}

				FVector ToSplineFollowLocation = SplineFollowLocation - Owner.ActorLocation;
				ToSplineFollowLocation = ToSplineFollowLocation.ConstrainToPlane(MoveComp.WorldUp);
				ToSplineFollowLocation.Normalize();

				MoveDirection = ToSplineFollowLocation;
			}
			break;
		}
		
	}
}