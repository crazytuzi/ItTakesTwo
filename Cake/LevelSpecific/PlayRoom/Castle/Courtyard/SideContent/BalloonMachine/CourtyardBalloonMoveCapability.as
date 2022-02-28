import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.BalloonMachine.CourtyardBalloon;

class UCourtyardBalloonMoveCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Balloon");
	default CapabilityTags.Add(CapabilityTags::Movement);
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	ACourtyardBalloon Balloon;
	UHazeCrumbComponent CrumbComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Balloon = Cast<ACourtyardBalloon>(Owner);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Balloon.bInflated)
			return EHazeNetworkActivation::DontActivate;

		if (!Balloon.bFloatUpwards)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Balloon.bInflated)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Balloon.bInflated = true;
		Balloon.Velocity = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			
		if (HasControl())
		{
			//SwayDirection = FVector::ForwardVectorRotateAngleAxis(FMath::RandRange(-50, 50) * DeltaTime, FVector::UpVector);
			
			Balloon.Velocity -= Balloon.Velocity * Balloon.Drag * DeltaTime;
			Balloon.Velocity += FVector::UpVector * Balloon.LiftAcceleration * DeltaTime;
			//Velocity += SwayDirection * SwayAcceleration * DeltaTime;
			//Velocity = Velocity.RotateAngleAxis(FMath::RandRange(-50, 50) * DeltaTime, FVector::UpVector);

			FVector DeltaMove = Balloon.Velocity * DeltaTime;
			Balloon.AddActorWorldOffset(DeltaMove);

			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

			Balloon.AddActorWorldOffset(ConsumedParams.DeltaTranslation);
		}
	}
}