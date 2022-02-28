import Cake.LevelSpecific.Music.VolleyBall.Player.MinigameVolleyballPlayer;
import Cake.LevelSpecific.Music.VolleyBall.Ball.MinigameVollyeballBall;
import Vino.Movement.Dash.CharacterAirDashCapability;


class UMinigameVolleyballVolleyballAirDashCapability : UCharacterAirDashCapability
{
	UMinigameVolleyballPlayerComponent VolleyballComponent;
	AMinigameVolleyballBall BallTarget;
	FVector InitialLocation;

	const float ValidTargetDistance = 1000.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams) override
	{
		Super::Setup(SetupParams);
		VolleyballComponent = UMinigameVolleyballPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride) 
	void OnActivated(FCapabilityActivationParams ActivationParams) override
	{
		Super::OnActivated(ActivationParams);

		InitialLocation = Player.GetActorLocation();

		const FVector PlayerLocation = InitialLocation;
		const FVector NetLocation = VolleyballComponent.Field.ClosestPositionOnNet(PlayerLocation);
		const FVector DirToField = (NetLocation - PlayerLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		const FVector InputDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);

		int BestBallIndex = -1;
		float BestScore = -1;
		for(int i = 0; i < VolleyballComponent.Balls.Num(); ++i)
		{	
			const FVector BallLocation = VolleyballComponent.Balls[i].GetActorLocation();
			const FVector DirToBall = (BallLocation - PlayerLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			const float BallAngle = DirToBall.DotProduct(Player.GetActorForwardVector());
			const float MinAngleValue = -0.1f;

			// to far
			const float DistSq = BallLocation.DistSquared(PlayerLocation);
			if(DistSq > FMath::Square(ValidTargetDistance))
				continue;

			// facing away
			if(InputDirection.IsNearlyZero(0.2f) && BallAngle < -0.1f)
				continue;

			// steering away
			if(InputDirection.DotProduct(DirToBall) < 0.5f)
				continue;

			float AngleScore = FMath::GetMappedRangeValueClamped(FVector2D(1.f, MinAngleValue), FVector2D(1.f, 0.f), BallAngle) * 10;
			float DistanceScore = 1.f - (DistSq / FMath::Square(ValidTargetDistance)) * 8.f;
			float TotalScore = AngleScore + DistanceScore;
			if(TotalScore < BestScore)
				continue;

			BestScore = TotalScore;
			BestBallIndex = i;
		}

		if(BestBallIndex >= 0)
			BallTarget = VolleyballComponent.Balls[BestBallIndex];
	}

	UFUNCTION(BlueprintOverride) 
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams) override
	{
		BallTarget = nullptr;
		Super::OnDeactivated(DeactivationParams);
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime) override
	{	
		if(BallTarget == nullptr 
			|| !HasControl() 
			|| DurationAlpha >= 1.f 
			|| BallTarget.ControllingPlayer != Player.Player
			|| BallTarget.MovingType == EMinigameVolleyballMoveType::DecendingToFail)
		{
			Super::CalculateFrameMove(FrameMove, DeltaTime);
		}
		else
		{	
			DurationAlpha = Math::Saturate(ActiveDuration / AirDashSettings.Duration);

			FVector TargetLocation = FMath::Lerp(InitialLocation, BallTarget.GetActorLocation(), DurationAlpha);
			FVector Delta = TargetLocation - Owner.GetActorLocation();
			FrameMove.ApplyDeltaWithCustomVelocity(Delta, FVector::ZeroVector);
	
			FRotator TargetFaceRotation = Owner.GetActorRotation();
			if (InitialLocation.DistSquared(BallTarget.GetActorLocation()) > 0)
				TargetFaceRotation = (InitialLocation - BallTarget.GetActorLocation()).ToOrientationRotator();
			else if(!Delta.IsNearlyZero())
				TargetFaceRotation = Delta.ToOrientationRotator();

			if (ActiveDuration <= 0.08f)
				MoveComp.SetTargetFacingRotation(TargetFaceRotation);
			else
				MoveComp.SetTargetFacingRotation(TargetFaceRotation, 2.f);

			FrameMove.OverrideStepDownHeight(5.f);	
			FrameMove.ApplyTargetRotationDelta(); 
		}		
	}
}