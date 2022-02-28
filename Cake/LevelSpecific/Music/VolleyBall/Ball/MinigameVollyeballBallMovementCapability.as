import Cake.LevelSpecific.Music.VolleyBall.Ball.MinigameVollyeballBall;


class UMinigameVolleyballBallMovementCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 100;

	UHazeMovementComponent Movement;
	UHazeCrumbComponent Crumb;
	AMinigameVolleyballBall BallOwner;

	bool bHasActiveVelocityPrediction = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{  
		BallOwner = Cast<AMinigameVolleyballBall>(Owner);
		Movement = UHazeMovementComponent::Get(Owner);
		Crumb = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement MovementData = Movement.MakeFrameMovement(n"BallMovement");
		bool bAddedForce = false;
		if(HasControl() || Owner.MovementSyncronizationIsBlocked())
		{
			FVector TotalImpulse;
			for(auto Force : BallOwner.PendingControlSideImpulses)
			{
				TotalImpulse += Force;
			}

			bAddedForce = TotalImpulse.SizeSquared() > 0;

			BallOwner.PendingControlSideImpulses.Empty();
			MovementData.ApplyVelocity(TotalImpulse);
			MovementData.ApplyActorVerticalVelocity();

			if(!Movement.IsGrounded())
			{
				MovementData.ApplyGravityAcceleration();
				if(BallOwner.ActorVelocity.Z < -20)
				{
					FVector HorizontalVelocity = BallOwner.GetActorVelocity().ConstrainToPlane(FVector::UpVector);
					HorizontalVelocity = FMath::VInterpTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, 0.5f);
					MovementData.ApplyVelocity(HorizontalVelocity);
				}
				else
				{
					MovementData.ApplyActorHorizontalVelocity();
				}
			}
				
			MovementData.ApplyTargetRotationDelta();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			Crumb.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			MovementData.ApplyConsumedCrumbData(ConsumedParams);

			if(Movement.Velocity.IsNearlyZero() && !BallOwner.VelocityPrediction.IsNearlyZero())
			{
				bHasActiveVelocityPrediction = true;
				FVector WantedWorldLocation = BallOwner.MeshOffset.GetWorldLocation();
				WantedWorldLocation += BallOwner.VelocityPrediction * Network::GetPingRoundtripSeconds();
				BallOwner.MeshOffset.OffsetLocationWithSpeed(WantedWorldLocation, BallOwner.VelocityPrediction.Size() * 0.5f);
				BallOwner.VelocityPrediction = FVector::ZeroVector;
				
			}
			else if(bHasActiveVelocityPrediction && Crumb.GetCrumbTrailLength() > 0)
			{
				bHasActiveVelocityPrediction = false;
				BallOwner.MeshOffset.ResetLocationWithTime(0.1f);
			}
		}

		Movement.Move(MovementData);
		Crumb.LeaveMovementCrumb();

		if(BallOwner.MovingType != EMinigameVolleyballMoveType::Decending
			&& !bAddedForce 
			&& Movement.GetVelocity().DotProduct(FVector::UpVector) <= 0 )
		{
			BallOwner.SetDecending();
		}
	}	
}