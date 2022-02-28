import Cake.LevelSpecific.SnowGlobe.WindWalk.DoublePull.WindWalkDoublePullActor;

// Active when double pull actor lies within start trigger (mountain base) and players are not activating magnets
class UWindWalkDoublePullStartCapability : UHazeCapability
{
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePull);
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePullStart);

	default CapabilityDebugCategory = WindWalkTags::WindWalk;

	AWindWalkDoublePullActor WindWalkDoublePullActor;

	const FVector LocalCameraOffset = FVector(100.f, 0.f, 50.f);

	const float BlendTime = 3.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		WindWalkDoublePullActor = Cast<AWindWalkDoublePullActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!WindWalkDoublePullActor.bIsInStartZone)
			return EHazeNetworkActivation::DontActivate;

		if(WindWalkDoublePullActor.BothPlayersAreActivatingMagnet())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FHazePointOfInterest PointOfInterest;
		PointOfInterest.Duration = -1.f;
		PointOfInterest.Blend = BlendTime;
		PointOfInterest.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		PointOfInterest.FocusTarget.WorldOffset = WindWalkDoublePullActor.ActorLocation - WindWalkDoublePullActor.Spline.Spline.GetDirectionAtSplinePoint(0, ESplineCoordinateSpace::World) * 1000;

		for(AHazePlayerCharacter PlayerCharacter : Game::GetPlayers())
		{
			PlayerCharacter.ApplyIdealDistance(300.f, BlendTime);
			PlayerCharacter.ApplyCameraOffsetOwnerSpace(LocalCameraOffset, BlendTime, this);
			PlayerCharacter.ApplyPointOfInterest(PointOfInterest, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!WindWalkDoublePullActor.bIsInStartZone)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(WindWalkDoublePullActor.BothPlayersAreActivatingMagnet())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		for(AHazePlayerCharacter PlayerCharacter : Game::GetPlayers())
		{
			PlayerCharacter.ClearIdealDistanceByInstigator(this);
			PlayerCharacter.ClearCameraOffsetOwnerSpaceByInstigator(this);
			PlayerCharacter.ClearPointOfInterestByInstigator(this);
		}
	}
}