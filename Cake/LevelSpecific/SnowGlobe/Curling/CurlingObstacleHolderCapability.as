import Cake.LevelSpecific.SnowGlobe.Curling.CurlingObstacleHolder;

class UCurlingObstacleHolderCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingObstacleHolderCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ACurlingObstacleHolder ObstacleHolder;

	float ZRaiseAmount = 75.f;
	float ZRaiseTarget;
	float ZStartPosition;

	float CurrentZ;

	//Initially supposed to move obstacles

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		ObstacleHolder = Cast<ACurlingObstacleHolder>(Owner);

		ZStartPosition = ObstacleHolder.ActorLocation.Z;
		ZRaiseTarget = ZStartPosition + ZRaiseAmount;
		CurrentZ = ZStartPosition;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (ObstacleHolder.ObstacleState != EObstacleState::Default)
	        return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ObstacleHolder.ObstacleState == EObstacleState::Default)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentZ = ObstacleHolder.ActorLocation.Z;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		float AllDistances = 0.f;

		if (ObstacleHolder.ObstacleState == EObstacleState::Raised)
		{
			CurrentZ = FMath::FInterpConstantTo(CurrentZ, ZRaiseTarget + 15.f, DeltaTime, 150.f);
		}
		else if (ObstacleHolder.ObstacleState == EObstacleState::Lowering)
		{
			CurrentZ = FMath::FInterpConstantTo(CurrentZ, ZStartPosition, DeltaTime, 150.f);
		}

		ObstacleHolder.SetActorLocation(FVector(ObstacleHolder.ActorLocation.X, ObstacleHolder.ActorLocation.Y, CurrentZ));
		
		for (ACurlingObstacle Obstacle : ObstacleHolder.CurlingObstacleArray)
		{
			Obstacle.SetActorLocation(FVector(Obstacle.ActorLocation.X, Obstacle.ActorLocation.Y, CurrentZ));

			float Difference = 0.f;
			
			if (ObstacleHolder.ObstacleState == EObstacleState::Raised)
			{
				Difference = ZRaiseTarget - CurrentZ;
				Difference = FMath::Abs(Difference);
				AllDistances += Difference;
			}
			else if (ObstacleHolder.ObstacleState == EObstacleState::Lowering)
			{
				Difference = ZStartPosition - CurrentZ;
				Difference = FMath::Abs(Difference);
				AllDistances += Difference;				
			}
		}

		if (ObstacleHolder.ObstacleState == EObstacleState::Lowering && CurrentZ <= ZStartPosition)
			ObstacleHolder.ObstacleState = EObstacleState::Default;
	}
}