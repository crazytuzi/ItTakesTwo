import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCrane;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCraneRidingComponent;

class UDinoCraneMovementCapability : UHazeCapability
{
    default CapabilityTags.Add(n"Movement");
    default CapabilityTags.Add(n"DinoCrane");
    default CapabilityTags.Add(n"DinoCraneMovement");

    default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 101;

    UHazeBaseMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	ADinoCrane DinoCrane;

	float HeadVelocity = 0.f;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        MoveComp = UHazeBaseMovementComponent::Get(Owner);
        CrumbComp = UHazeCrumbComponent::Get(Owner);
		DinoCrane = Cast<ADinoCrane>(Owner);

		Owner.BlockCapabilities(n"GroundMovement", this);
    }

    UFUNCTION(BlueprintOverride)
    void OnRemoved()
    {
		Owner.UnblockCapabilities(n"GroundMovement", this);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if (DinoCrane.GrabbedPlatform != nullptr)
			return EHazeNetworkActivation::DontActivate; 
        return EHazeNetworkActivation::ActivateLocal; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if (DinoCrane.GrabbedPlatform != nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal; 
        return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"DinoCraneMovement");

			if (HasControl())
			{
				if (DinoCrane.RidingPlayer != nullptr)
				{
					auto RideComp = GetDinoRidingComponent(DinoCrane);
					// Use input to move
					FVector Input = RideComp.SteeringInput;
					float VerticalInput = RideComp.VerticalInput;
					FRotator Facing = RideComp.ControlRotation;

					if (!Facing.IsNearlyZero())
						MoveComp.SetTargetFacingRotation(Facing, DinoCrane.DinoRotationSpeed);

					Movement.ApplyVelocity(Input * DinoCrane.DinoMovementSpeed);

					HeadVelocity = FMath::FInterpConstantTo(HeadVelocity, VerticalInput, DeltaTime, 4.f);

					FVector MoveAmount;
					MoveAmount.Z = DeltaTime * HeadVelocity * DinoCrane.HeadMoveSpeed;

					DinoCrane.MoveHead(MoveAmount, bSetStandardDistance = true);

					Movement.ApplyTargetRotationDelta();
				}
			}
			else
			{
				// Sync to crumb
				FHazeActorReplicationFinalized ConsumedParams;
				CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
				Movement.ApplyConsumedCrumbData(ConsumedParams);			
			}

			if (MoveComp.CanCalculateMovement())
			{
				MoveComp.Move(Movement);

				if (DinoCrane.RidingPlayer != nullptr)
					CrumbComp.LeaveMovementCrumb();
			}
		}
    }
};