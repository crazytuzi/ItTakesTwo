
//For all PerceptionClasses Update is needed for the class to work properly.
class UHazeAIPerceptionVision : UHazePerceptionClass
{
	default NoticedPeripheralVisionAngle = 90.f;
	default SensoryType = EHazeSenses::SIGHT;
	default SensoryShape = EHazeSenseShape::CONE;

	float NoticedPeripheralVisionCosine = 0.f;
	float DetectionPeripheralVisionCosine = 0.f;

	AHazeActor ActorOwner = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		NoticedPeripheralVisionCosine = FMath::Cos(FMath::DegreesToRadians(NoticedPeripheralVisionAngle));
		DetectionPeripheralVisionCosine = FMath::Cos(FMath::DegreesToRadians(DetectionPeripheralVisionAngle));
	}

	UFUNCTION(BlueprintOverride)
	void Update()
	{
		ActorOwner = GetAIOwner();

		if (ActorOwner == nullptr)
		{
			return;
		}
	
		AHazeActor CodyActor = Game::GetCody();
		AHazeActor MayActor = Game::GetMay();

		EvaluateData(CodyActor);
		EvaluateData(MayActor);

		if(!bOnlyEvaluatePlayers)
		{
			UHazeGameInstance GameInstance = Game::GetHazeGameInstance();
			if (GameInstance == nullptr)
				return;

			UHazeAIManager AIManager = GameInstance.GetAIManager();
			if (AIManager == nullptr)
				return;

			for(AHazeActor AIActor : AIManager.GetAIActors())
			{
				if(AIActor != nullptr)
				{
					EvaluateData(AIActor);
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void EvaluateData(AHazeActor TargetActor)
	{
		FHazeDetectionData CurrentDetectionData;
		CurrentDetectionData.SensoryShape = SensoryShape;

		if (CanSeeTargetActor(TargetActor, CurrentDetectionData))
		{
			if (LineTraceByVisibility(TargetActor))
			{
				CurrentDetectionData.DetectedActor = TargetActor;
			}
			else
			{
				CurrentDetectionData.Status = EHazeDetectionStatus::UNAWARE;
			}

			CurrentDetectionData.Location = TargetActor.GetActorLocation();
		}	

		DetectionData.Add(CurrentDetectionData);
	}

	bool CanSeeTargetActor(AHazeActor TargetActor, FHazeDetectionData& CurrentData)
	{
		if (TargetActor == nullptr || ActorOwner == nullptr)
		{
			return false;
		}

		const FVector TargetLoc = TargetActor.GetActorLocation();
		const FVector OwnerLoc = ActorOwner.GetActorLocation();
		const FVector OwnerToTarget = TargetLoc - OwnerLoc;

		if (OwnerToTarget.SizeSquared() > FMath::Square(NoticedRadius))
		{
			//Not within Notice Radius, return false
			return false;
		}

		if (OwnerToTarget.GetSafeNormal().DotProduct(ActorOwner.GetActorRotation().Vector()) >= NoticedPeripheralVisionCosine)
		{
			CurrentData.Status = EHazeDetectionStatus::NOTICED;

			if (OwnerToTarget.SizeSquared() < FMath::Square(DetectionRadius))
			{
				if (OwnerToTarget.GetSafeNormal().DotProduct(ActorOwner.GetActorRotation().Vector()) >= DetectionPeripheralVisionCosine)
				{
					CurrentData.Status = EHazeDetectionStatus::DETECTED;
				}
			}

			return true;
		}

		CurrentData.Status = EHazeDetectionStatus::UNAWARE;

		return false;
	}
};