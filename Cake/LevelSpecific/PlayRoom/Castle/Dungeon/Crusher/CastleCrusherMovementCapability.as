import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.PlayRoom.Castle.Dungeon.Crusher.CastleCrusher;

class UCastleCrusherMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Castle");
	default CapabilityTags.Add(n"Crusher");
	default CapabilityTags.Add(n"Movement");

	default CapabilityDebugCategory = n"Castle";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	ACastleCrusher Crusher;
	UHazeCrumbComponent CrumbComp;

	bool bCompletedMove = false;

	const float MinimumSpeed = 120.f;
	const float MaximumSpeed = 220.f;
	const float MinimumDistance = 600.f;
	const float MaximumDistance = 1400.f;

	// The preferred maximum distance of the crusher to keep it on screen
	const float LoiterDistance = 1750.f;
	// The speed it will reach to get there
	const float SpeedToLoiter = 400.f;

	// The speed the crusher will reach to get to the level end position on success
	const float DeathSpeed = 500.f;

	const float SpeedInterpSpeed = 5.f;

	UCameraShakeBase CameraShake;
	const float CameraShakeMinDistance = 1000.f;
	const float CameraShakeMaxDistance = 2000.f;
	const float CameraShakeMinimumScale = 0.6f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Crusher = Cast<ACastleCrusher>(Owner);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Crusher.bEnabled)
        	return EHazeNetworkActivation::DontActivate;

		if (Crusher.bReachedBridge)
        	return EHazeNetworkActivation::DontActivate;

		if (Crusher.MoveToBridgeActor == nullptr)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Crusher.bEnabled)
        	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (Crusher.bReachedBridge)
        	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CameraShake = Game::GetMay().PlayCameraShake(Crusher.CameraShakeClass);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Game::GetMay().StopAllCameraShakes();
		if (CameraShake != nullptr)
			Game::May.StopCameraShake(CameraShake, false);

		if (Crusher.bReachedBridge)
			Crusher.OnReachedBridge.Broadcast();		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (HasControl())
		{		
			const float AverageDistance = GetAverageDistanceToPlayers();

			float DesiredSpeed = 0.f;
			if (Crusher.CrusherBridge.bBridgeWeakened)
			{
				DesiredSpeed = DeathSpeed;
			}
			else if (AverageDistance > MaximumDistance)
			{
				float Alpha = FMath::Clamp((AverageDistance - MaximumDistance) / (LoiterDistance - MaximumDistance), 0.f, 1.f);
				DesiredSpeed = FMath::Lerp(MaximumSpeed, SpeedToLoiter, Alpha);
			}
			else
			{
				float DistanceAlpha = FMath::Clamp(AverageDistance / MaximumDistance, 0.f, 1.f);
				DistanceAlpha = FMath::Pow(DistanceAlpha, 1.5f);
				DesiredSpeed = FMath::Lerp(MinimumSpeed, MaximumSpeed, DistanceAlpha);
			}

			Crusher.Speed = FMath::FInterpTo(Crusher.Speed, DesiredSpeed, DeltaTime, SpeedInterpSpeed);

			float Delta = Crusher.Speed * DeltaTime;

			if (DistanceToTarget < Delta)
			{	
				// We might not need to update the delta here, due to the cutscene doing a blend anyway
				Delta = DistanceToTarget;
				Crusher.bReachedBridge = true;
			}
			
			if (IsDebugActive())
			{
				PrintToScreenScaled("Actual Speed: " + Crusher.Speed, Scale = 2.f);
				PrintToScreenScaled("Desired Speed: " + DesiredSpeed, Scale = 2.f);
				PrintToScreenScaled("AverageDistance: " + AverageDistance, Scale = 2.f);
			}

			FVector DeltaMove = Owner.ActorForwardVector * Delta;			
			Owner.AddActorWorldOffset(DeltaMove);

			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

			Owner.SetActorLocation(ConsumedParams.Location);

			Crusher.Speed = ConsumedParams.DeltaTranslation.Size() / DeltaTime;
		}

		if (Crusher.Mesh.CanRequestLocomotion())
		{
			FHazeRequestLocomotionData Request;
			Request.AnimationTag = n"CastleEnemyCrusher";
			Crusher.Mesh.RequestLocomotion(Request);
		}

		float ShakeScale = FMath::Clamp((GetAverageDistanceToPlayers() - CameraShakeMinDistance) / (CameraShakeMaxDistance - CameraShakeMinimumScale), 0.f, 1.f);
		ShakeScale = FMath::Lerp(1.0f, CameraShakeMinimumScale, ShakeScale);
		ShakeScale = ShakeScale * FMath::Clamp(ActiveDuration / 2.f, 0.f, 1.f);
		CameraShake.ShakeScale = ShakeScale;
	}

	float GetDistanceToTarget() const property
	{
		FVector ToMoveTo = Crusher.MoveToBridgeActor.ActorLocation - Owner.ActorLocation;
		return ToMoveTo.DotProduct(Owner.ActorForwardVector);
	}

	float GetAverageDistanceToPlayers() property
	{
		TPerPlayer<float> PlayerDistances;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			FVector ToPlayer = Player.ActorLocation - Crusher.ActorLocation;
			PlayerDistances[Player] = Crusher.ActorForwardVector.DotProduct(ToPlayer);
		}

		return (PlayerDistances[0] + PlayerDistances[1]) / 2.f;
	}

	float GetSpeedFromDistance(float Distance)
	{
		return FMath::GetMappedRangeValueClamped(FVector2D(MinimumDistance, MaximumDistance), FVector2D(MinimumSpeed, MaximumSpeed), Distance);
	}
}