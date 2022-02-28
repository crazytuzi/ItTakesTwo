import Cake.LevelSpecific.SnowGlobe.WindWalk.DoublePull.WindWalkDoublePullActor;

// Runs before WindWalkDoublePullTumbleCapability
class UWindWalkDoublePullTumbleRecoveryCapability : UHazeCapability
{
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePull);
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePullTumbleRecovery);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 49;

	default CapabilityDebugCategory = WindWalkTags::WindWalk;

	UPROPERTY()
	UCurveFloat DecelerationCurve;

	AWindWalkDoublePullActor DoublePullOwner;
	UHazeMovementComponent MovementComponent;
	UHazeCrumbComponent CrumbComponent;

	const float RecoveryTime = 1.0f;
	float ElapsedTime;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		DoublePullOwner = Cast<AWindWalkDoublePullActor>(Owner);
		MovementComponent = DoublePullOwner.MovementComponent;
		CrumbComponent = DoublePullOwner.CrumbComponent;
	}

	// Activate if tumble capability is active and players have stopped activating magnet
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(DoublePullOwner.bIsInStartZone)
			return EHazeNetworkActivation::DontActivate;

		if(!DoublePullOwner.IsAnyCapabilityActive(WindWalkTags::WindWalkDoublePullTumble))
			return EHazeNetworkActivation::DontActivate;

		if(!DoublePullOwner.BothPlayersAreActivatingMagnet())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Don't let players advance whilst they break
		DoublePullOwner.BlockCapabilities(n"DoublePullEffort", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ElapsedTime += DeltaTime;	

		FHazeFrameMovement MoveData = MovementComponent.MakeFrameMovement(WindWalkTags::WindWalkDoublePullTumbleRecovery);
		MoveData.OverrideCollisionProfile(n"NoCollision");

		if(HasControl())
		{
			float CurveAlpha = ElapsedTime / RecoveryTime;
			float VelocityMultiplier = DecelerationCurve.GetFloatValue(CurveAlpha);

			FVector Velocity = MovementComponent.GetVelocity() * VelocityMultiplier * 1.07f;

			MovementComponent.SetTargetFacingRotation(Math::MakeQuatFromX(-Velocity), DeltaTime * 20.f);
			MoveData.ApplyTargetRotationDelta();

			MoveData.ApplyVelocity(Velocity);
			CrumbComponent.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			MoveData.ApplyConsumedCrumbData(CrumbData);
		}

		MovementComponent.Move(MoveData);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ElapsedTime >= RecoveryTime)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(IsActioning(WindWalkTags::ControlHitByHazard))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		DoublePullOwner.UnblockCapabilities(n"DoublePullEffort", this);
		ElapsedTime = 0.f;
	}
}