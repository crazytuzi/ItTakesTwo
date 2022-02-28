import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyBeepIndicator;

class UHockeyBeepMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HockeyBeepMovementCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHockeyBeepIndicator BeepIndicator;

	FVector StartLocation;
	FVector EndLocation;

	float ZOffset = -1100.f;
	float MoveSpeed = 520.f;
	float MinDistance = 10.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BeepIndicator = Cast<AHockeyBeepIndicator>(Owner);

		StartLocation = BeepIndicator.ActorLocation;
		EndLocation = StartLocation + FVector(0.f, 0.f, ZOffset);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BeepIndicator.BeepIndicatorState != EBeepIndicatorState::Inactive)
	        return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BeepIndicator.BeepIndicatorState == EBeepIndicatorState::Inactive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (BeepIndicator.BeepIndicatorState == EBeepIndicatorState::MoveDown)
		{
			FVector NextLoc = FMath::VInterpConstantTo(BeepIndicator.ActorLocation, EndLocation, DeltaTime, MoveSpeed);
			BeepIndicator.SetActorLocation(NextLoc);

			float Distance = (EndLocation - BeepIndicator.ActorLocation).Size();

			if (Distance <= MinDistance)
			{
				if (BeepIndicator.bIsTimedWithCountdown)
					BeepIndicator.BeepIndicatorState = EBeepIndicatorState::Inactive;
				else 
					BeepIndicator.BeepIndicatorState = EBeepIndicatorState::BeepTime;
			}
		}
		else if (BeepIndicator.BeepIndicatorState == EBeepIndicatorState::MoveUp)
		{
			FVector NextLoc = FMath::VInterpConstantTo(BeepIndicator.ActorLocation, StartLocation, DeltaTime, MoveSpeed);
			BeepIndicator.SetActorLocation(NextLoc);

			float Distance = (StartLocation - BeepIndicator.ActorLocation).Size();

			if (Distance <= MinDistance)
				BeepIndicator.BeepIndicatorState = EBeepIndicatorState::Inactive;
		}
	}
}