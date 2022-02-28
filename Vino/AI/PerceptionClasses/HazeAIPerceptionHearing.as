//For all PerceptionClasses Update is needed for the class to work properly.
class UHazeAIPerceptionHearing : UHazePerceptionClass
{
	default NoticedRadius = 1000.f;
	default NoticedPeripheralVisionAngle = 85.f;

	default SensoryType = EHazeSenses::HEARING;
	default SensoryShape = EHazeSenseShape::SPHERE;

	bool bAlreadyUpdated = false;
	float NoticedPeripheralCosine = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		NoticedPeripheralCosine = FMath::Cos(FMath::DegreesToRadians(NoticedPeripheralVisionAngle));
	}

	UFUNCTION(BlueprintOverride)
	void Update()
	{
		if(GetAIOwner() == nullptr)
		{
			return;
		}

		if(DetectedActor != nullptr && bAlreadyUpdated)
		{
			bAlreadyUpdated = false;
			return;
		}

		if(DetectedActor != nullptr && bAlreadyUpdated)
		{
			bAlreadyUpdated = true;
		}

		if(bOnlyEvaluatePlayers)
		{
			EvaluateData(DetectedActor);
		}
		else
		{
			UHazeGameInstance GameInstance = Game::GetHazeGameInstance();
			if(GameInstance == nullptr)
			{
				return;
			}

			UHazeAIManager AIManager = GameInstance.GetAIManager();
			if(AIManager == nullptr)
			{
				return;
			}

			for(AHazeActor AIActor : AIManager.GetAIActors())
			{
				if(AIActor != nullptr)
				{
					EvaluateData(AIActor);
				}
			}
		}

		DetectedActor = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void EvaluateData(AHazeActor TargetActor)
	{
		FHazeDetectionData CurrentDetectionData;
		CurrentDetectionData.Status = EHazeDetectionStatus::UNAWARE;
		CurrentDetectionData.SensoryShape = SensoryShape;

		if (CanHearTargetActor(TargetActor, CurrentDetectionData))
		{
			if (LineTraceByVisibility(TargetActor) == false)
			{
				CurrentDetectionData.Status = EHazeDetectionStatus::NOTICED;
			}

			CurrentDetectionData.DetectedActor = TargetActor;
			CurrentDetectionData.Location = TargetActor.GetActorLocation();
		}

		DetectionData.Add(CurrentDetectionData);
	}

	bool CanHearTargetActor(AHazeActor TargetActor, FHazeDetectionData& CurrentData)
	{
		AHazeActor AIActor = GetAIOwner();

		if (TargetActor == nullptr || AIActor == nullptr)
		{
			return false;
		}

		const FVector TargetLoc = TargetActor.GetActorLocation();
		const FVector OwnerLoc = AIActor.GetActorLocation();
		const FVector OwnerToTarget = TargetLoc - OwnerLoc;

		if (OwnerToTarget.SizeSquared() > FMath::Square(NoticedRadius))
		{
			//Not within Notice Radius, return false
			return false;
		}

		float Test1 = OwnerToTarget.GetSafeNormal().DotProduct(AIActor.GetActorRotation().Vector());

		if(OwnerToTarget.GetSafeNormal().DotProduct(AIActor.GetActorRotation().Vector()) >= NoticedPeripheralCosine)
		{
			CurrentData.Status = EHazeDetectionStatus::DETECTED;
		}
		else
		{
			CurrentData.Status = EHazeDetectionStatus::NOTICED;
		}
	
		return true;
	}

	const FVector GetSoundLocation() const
	{
		return FVector();
	}
};