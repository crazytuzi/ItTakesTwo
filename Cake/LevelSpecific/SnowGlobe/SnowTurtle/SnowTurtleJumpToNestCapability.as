import Cake.LevelSpecific.SnowGlobe.SnowTurtle.SnowTurtleBaby;

class USnowTurtleJumpToNestCapability : UHazeCapability
{
		default CapabilityTags.Add(n"Example");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ASnowTurtleBaby SnowTurtle;

	float MinDistance = 5.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SnowTurtle = Cast<ASnowTurtleBaby>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SnowTurtle.bIsInNest && !SnowTurtle.bIsSettledInNest)
        	return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SnowTurtle.DistanceFromNest <= MinDistance)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector CurrentLoc = FMath::VInterpConstantTo(SnowTurtle.ActorLocation, SnowTurtle.TargetNestPosition, DeltaTime, 526.2f);
		SnowTurtle.SetActorLocation(CurrentLoc);
		// FRotator TargetRot = FRotator::MakeFromX(SnowTurtle.NestForwardVector);
		// FRotator CurrentRot = FMath::RInterpTo(SnowTurtle.ActorRotation, TargetRot, DeltaTime, 0.1f);
		// SnowTurtle.SetActorRotation(CurrentRot);

		if (SnowTurtle.DistanceFromNest <= MinDistance)
			SnowTurtle.bIsSettledInNest = true;
	}

}