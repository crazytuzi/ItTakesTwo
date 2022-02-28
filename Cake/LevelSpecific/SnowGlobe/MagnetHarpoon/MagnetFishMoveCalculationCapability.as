import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetFishActor;

class UMagnetFishMoveCalculationCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetFishMoveCalculationCapability");
	default CapabilityTags.Add(n"MagnetFish");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 150;

	AMagnetFishActor MagnetFish;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MagnetFish = Cast<AMagnetFishActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (MagnetFish.MagnetFishState != EMagnetFishState::GoingToSpline && MagnetFish.MagnetFishState != EMagnetFishState::OnSpline)
        	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (MagnetFish.MagnetFishState != EMagnetFishState::GoingToSpline && MagnetFish.MagnetFishState != EMagnetFishState::OnSpline)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (HasControl())
			ControlMovement(DeltaTime);
		else
			ReplicateCrumbMovement(DeltaTime);
	}

	void ControlMovement(float DeltaTime)
	{
		FVector NextLoc;

		if (MagnetFish.MagnetFishState == EMagnetFishState::OnSpline)
			NextLoc = FMath::VInterpTo(MagnetFish.ActorLocation, MagnetFish.TargetLoc, DeltaTime, MagnetFish.Speed);
		else
			NextLoc = FMath::VInterpConstantTo(MagnetFish.ActorLocation, MagnetFish.TargetLoc, DeltaTime, MagnetFish.Speed);

		MagnetFish.AccelRotMove.AccelerateTo(MagnetFish.TargetRot, 0.4f, DeltaTime);
		MagnetFish.SetActorLocationAndRotation(NextLoc, MagnetFish.AccelRotMove.Value);
		MagnetFish.CrumbComp.LeaveMovementCrumb();
	}

	void ReplicateCrumbMovement(float DeltaTime)
	{
		FHazeActorReplicationFinalized Replication;
		MagnetFish.CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, Replication);
		MagnetFish.AccelRotMove.AccelerateTo(Replication.GetRotation(), 0.4f, DeltaTime);
		MagnetFish.SetActorLocationAndRotation(Replication.GetLocation(), MagnetFish.AccelRotMove.Value);
	}
}