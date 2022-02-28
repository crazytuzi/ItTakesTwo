import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyUnderGround.SickleEnemyUnderGroundComponent;


class USickleEnemyUndergroundRageModeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SickleEnemyAlive");
	default CapabilityTags.Add(n"SickleEnemyUnderGround");

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 90;
	
	ASickleEnemy AiOwner;
	USickleEnemyUnderGroundComponent AiComponent;
	UHazeSplineFollowComponent SplineFollowComponent;

	//FVector TargetLocation;
	//float ChangeTargetAtDistance = 0;
	AHazePlayerCharacter PlayerToRush = nullptr;
	float RushCooldown = 0;
	int ActiveSplineIndex = -1;
	float TimeLeftToSwitchSpline = -1;

	TArray<AHazeSplineActor> MovementSplines;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyUnderGroundComponent::Get(Owner);
		SplineFollowComponent = UHazeSplineFollowComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(PlayerToRush == nullptr && RushCooldown <= 0)
		{
			if(AiComponent.bMayWantsMeToHide)
			{
				PlayerToRush = Game::GetMay();
			}
			else if(AiComponent.bCodyWantsMeToHide)
			{
				PlayerToRush = Game::GetCody();
			}
		}
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!AiComponent.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(AiOwner.AreaToMoveIn == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(AiOwner.RestrictedAreaToMoveIn == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(AiOwner.RestrictedAreaToMoveIn.MovementSplines.Num() == 0)
			return EHazeNetworkActivation::DontActivate;

		if(AiOwner.AreaToMoveIn.PlayersInArea.Num() > 0)
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!AiComponent.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(AiOwner.AreaToMoveIn == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(AiOwner.RestrictedAreaToMoveIn == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(AiOwner.RestrictedAreaToMoveIn.MovementSplines.Num() == 0)
			return EHazeNetworkDeactivation::DeactivateLocal;;

		if(AiOwner.AreaToMoveIn.PlayersInArea.Num() > 0)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ChangeMovementSpline();
		AiOwner.CapsuleComponent.SetCollisionProfileName(Trace::GetCollisionProfileName(AiComponent.UnderGroundMovementProfile));
		AiOwner.BlockMovement(0.2f);
		AiComponent.IgnorePlayersWhenMoving();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AiComponent.IncludePlayersWhenMoving();
		SplineFollowComponent.DeactivateSplineMovement();
		ActiveSplineIndex = -1; 
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement FinalMovement = AiComponent.MakeFrameMovement(n"SickleEnemyUnderGroundRageMovement");
		FinalMovement.OverrideStepUpHeight(200.f);
		FinalMovement.OverrideStepDownHeight(400.f);

		if(HasControl())
		{		
			if(AiOwner.CanMove())
			{
				const float MovementSpeed = AiComponent.MovementSpeed * AiComponent.RageMoveSpeedMultiplier;
				float SplineUpdateSpeed = 0;

				if(ActiveSplineIndex >= 0)
				{
					UHazeSplineComponentBase Spline = SplineFollowComponent.GetActiveSpline();
					
					FVector ClosestSplineWorldPos;
					float DistanceAlongSpline;
					Spline.FindDistanceAlongSplineAtWorldLocation(AiOwner.GetActorLocation(), ClosestSplineWorldPos, DistanceAlongSpline);
					if(ClosestSplineWorldPos.DistSquared2D(AiOwner.GetActorLocation()) < FMath::Square(100.f))
						SplineUpdateSpeed = MovementSpeed * 1.25f;
		
					FHazeSplineSystemPosition SplinePosition;
					SplineFollowComponent.UpdateSplineMovement(SplineUpdateSpeed * DeltaTime, SplinePosition);
					const FVector WantedLocation = SplinePosition.GetWorldLocation();
					const FVector CurrentLocation = AiOwner.GetActorLocation();
					FVector DeltaMove = (WantedLocation - CurrentLocation).ConstrainToPlane(FVector::UpVector);
					DeltaMove = DeltaMove.GetClampedToMaxSize(MovementSpeed * DeltaTime);
					FinalMovement.ApplyDeltaWithCustomVelocity(DeltaMove, DeltaMove.GetSafeNormal() * MovementSpeed);

					FVector FaceDir = (WantedLocation - CurrentLocation).GetSafeNormal();
					if(!FaceDir.IsNearlyZero())
						AiComponent.SetTargetFacingDirection(FaceDir, 5.f);

					TimeLeftToSwitchSpline -= DeltaTime;
					if(TimeLeftToSwitchSpline <= 0)
						ChangeMovementSpline();
				}

				FinalMovement.ApplyTargetRotationDelta();
			}

			AiComponent.Move(FinalMovement);
			AiOwner.CrumbComponent.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ReplicationData;
			AiOwner.CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, ReplicationData);
			FinalMovement.ApplyConsumedCrumbData(ReplicationData);
			AiComponent.Move(FinalMovement);
		}
	}

	void ChangeMovementSpline()
	{
		const int OldSplineIndex = ActiveSplineIndex;
		do
		{
			ActiveSplineIndex = FMath::RandRange(0, AiOwner.RestrictedAreaToMoveIn.MovementSplines.Num() - 1);
		} while(OldSplineIndex == ActiveSplineIndex);

		auto Spline = UHazeSplineComponentBase::Get(AiOwner.RestrictedAreaToMoveIn.MovementSplines[ActiveSplineIndex]);
		FHazeSplineSystemPosition InitializePosition = Spline.GetPositionClosestToWorldLocation(AiOwner.GetActorLocation(), FMath::RandBool());
		const float SplineLength = Spline.GetSplineLength();
		InitializePosition.Move(FMath::RandRange(-SplineLength, SplineLength));
		SplineFollowComponent.ActivateSplineMovement(InitializePosition);

		const float MovementSpeed = AiComponent.MovementSpeed * AiComponent.RageMoveSpeedMultiplier;
		if(MovementSpeed > 0)
		{
			const float MoveTime = SplineLength / MovementSpeed;
			TimeLeftToSwitchSpline = FMath::RandRange(MoveTime * 0.5f, MoveTime * 2.f);
		}
		else
		{
			const float MoveTime = SplineLength / 1000.f;
			TimeLeftToSwitchSpline = FMath::RandRange(MoveTime * 0.5f, MoveTime * 2.f);
		}
	}

	// void ChangeTargetLocation()
	// {
	// 	const FVector MayLocation = GetBestLocationAwayFromPlayer(EHazePlayer::May);
	// 	const FVector CodyLocation = GetBestLocationAwayFromPlayer(EHazePlayer::Cody);
	// 	TargetLocation = MayLocation.DistSquared(AiOwner.GetActorLocation()) > CodyLocation.DistSquared(AiOwner.GetActorLocation()) ? MayLocation : CodyLocation;
	// //	System::DrawDebugSphere(TargetLocation, Duration = 5.f);
	// 	ChangeTargetAtDistance = AiComponent.RagePickNewMovetoLocationDistance.GetRandomValue();
	// }

	// FVector GetBestLocationAwayFromPlayer(EHazePlayer Player) const
	// {	
	// 	const FVector PlayerLocation = Game::GetMay().GetActorLocation();
	// 	const FVector AiLocation = AiOwner.GetActorLocation();

	// 	const float ActorRadius = AiOwner.GetCollisionSize().X;
	// 	const FVector WorldUp = AiOwner.GetMovementWorldUp();

	// 	// Use the entire shape
	// 	const float MaxDistanceToTrace = Player == EHazePlayer::May ? AiComponent.DetectMayDistance : AiComponent.DetectCodyDistance;

	// 	const int PointsCount = 16;
	// 	TArray<FVector> ValidPoints;
	// 	ValidPoints.Reserve(PointsCount);
	// 	FVector BestLocation = AiLocation;

	// 	FRotator TestRotation;
	// 	float BiggestDistance = 0;
	
	// 	for(int i = 0; i < PointsCount; ++i)
	// 	{
	// 		TestRotation.Yaw += 360 / PointsCount;
	// 		FVector TestLocation = TestRotation.RotateVector(FVector(MaxDistanceToTrace, 0.f, 0.f));
	// 		TestLocation += AiLocation;
	// 		AiOwner.GetBestMoveToPoint(TestLocation, TestLocation);
	// 		//Collision.GetClosestPointOnCollision(TestLocation, TestLocation);

	// 	#if EDITOR
	// 		if(AiOwner.bHazeEditorOnlyDebugBool)
	// 			System::DrawDebugSphere(TestLocation, Duration = 1, LineColor = FLinearColor::White);
	// 	#endif

	// 		const float Distance = TestLocation.DistSquared2D(PlayerLocation, WorldUp);
	// 		if(Distance > FMath::Square(AiComponent.DetectMayDistance))
	// 		{
	// 			ValidPoints.Add(TestLocation);
	// 		}

	// 		if(Distance > BiggestDistance)
	// 		{
	// 			BiggestDistance = Distance;
	// 			BestLocation = TestLocation;
	// 		}
	// 	}

	// 	if(ValidPoints.Num() > 0)
	// 	{
	// 		const int RandomIndex = FMath::RandRange(0, ValidPoints.Num() - 1);

	// 		#if EDITOR
	// 		if(AiOwner.bHazeEditorOnlyDebugBool)
	// 			System::DrawDebugSphere(ValidPoints[RandomIndex], Thickness = 4, Duration = 1, LineColor = FLinearColor::Red);
	// 		#endif

	// 		return ValidPoints[RandomIndex];
	// 	}

	// 	return BestLocation;
	// }
}