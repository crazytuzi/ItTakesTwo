import Cake.LevelSpecific.Tree.Swarm.Effects.SwarmEventHandler;

UCLASS()
class USwarmAudioEventHandler : USwarmEventHandler 
{
	UPROPERTY()
	float ShapeChangeTimeStamp = -1;

	float ShapeChangeDuration = 0;

	//UPROPERTY(Category = "Audio Events")
	//UAkAudioEvent StartFlyingEvent;

	//UPROPERTY(Category = "Audio Events")
	//UAkAudioEvent StopFlyingEvent;

	//UPROPERTY(Category = "Audio Events")
	//UAkAudioEvent DeathExploEvent;
	float LastSwarmSpeed;
	float LastSwarmDeltaDirection;
	float LastSwarmAngularVelo;
	float LastSwarmRadius;
	float LastSwarmShapeChange;

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{
		float SwarmSpeed = GetSwarmSpeedNormalizedToRange();
		//Print("SwarmSpeed: " + SwarmSpeed);
		if (SwarmSpeed != LastSwarmSpeed)
		{
			LastSwarmSpeed = SwarmSpeed;
			Swarm.HazeAkComp.SetRTPCValue("Rtpc_Characters_Enemies_Swarm_Velocity", SwarmSpeed, 200.f);
		}

		float SwarmDeltaDirection = GetSwarmVelocityDeltaDirection();
		//Print("SwarmDeltaDir: " + SwarmDeltaDirection);
		if (SwarmDeltaDirection != LastSwarmDeltaDirection)
		{
			LastSwarmDeltaDirection = SwarmDeltaDirection;
			Swarm.HazeAkComp.SetRTPCValue("Rtpc_Characters_Enemies_Swarm_VelocityDelta", SwarmDeltaDirection, 200.f);
		}

		const float SwarmAngularVelo = GetSwarmAngularSpeedNormalizedToRange();
		if (SwarmAngularVelo != LastSwarmAngularVelo)
		{
			LastSwarmAngularVelo = SwarmAngularVelo;
			//Print("SwarmAngVelo: " + SwarmAngularVelo);
			if (FMath::IsFinite(SwarmAngularVelo))
				Swarm.HazeAkComp.SetRTPCValue("Rtpc_Characters_Enemies_Swarm_AngularVelocity", SwarmAngularVelo, 200.f);
		}

		float SwarmRadius = GetSwarmRadiusNormalizedToRange();
		//Print("SwarmRadius: " + SwarmRadius);
		if (SwarmRadius != LastSwarmRadius)
		{
			LastSwarmRadius = SwarmRadius;
			Swarm.HazeAkComp.SetRTPCValue("Rtpc_Characters_Enemies_Swarm_RadiusSize", SwarmRadius, 200.f);
		}

		float SwarmShapeChange = GetShapeChangeValue(ShapeChangeTimeStamp, ShapeChangeDuration);
		//Print("SwarmShapeChange: " + SwarmShapeChange);
		if (SwarmShapeChange != LastSwarmShapeChange)
		{
			LastSwarmShapeChange = SwarmShapeChange;
			Swarm.HazeAkComp.SetRTPCValue("Rtpc_Characters_Enemies_Swarm_ChangeShape", SwarmShapeChange, 200.f);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		Swarm.HazeAkComp.HazePostEvent(Swarm.StartFlyingEvent);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);
		Swarm.HazeAkComp.HazePostEvent(Swarm.StopFlyingEvent);
		// Disable active systems incase something blocks the Swarm, such as Cutscenes for example.
	}

	UFUNCTION(BlueprintOverride)
	void HandleShapeChanged(float InShapeChangeDuration) 
	{
		ShapeChangeDuration = InShapeChangeDuration;
		ShapeChangeTimeStamp = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	void HandleHitByMatch(FVector WorldLocation) 
	{
		//Print("Match Hit Swarm!");
		//Swarm.HazeAkComp.HazePostEvent(Swarm.DeathExploEvent);
		// System::DrawDebugPoint(WorldLocation, 10.f, FLinearColor::Red, 5.f);
	}

	UFUNCTION(BlueprintOverride)
	void HandleSapExplosion(FVector WorldLocation) 
	{
		//Swarm.HazeAkComp.HazePostEvent(Swarm.DeathExploEvent);
		
		UHazeAkComponent::HazePostEventFireForget(Swarm.SwarmWallDestroyedEvent, Swarm.GetActorTransform());
		
	}

	UFUNCTION(BlueprintOverride)
	void HandleDeath(ASwarmActor Swarm) {}

	UFUNCTION(BlueprintOverride)
	void HandleAboutToDie(ASwarmActor Swarm) {}

	UFUNCTION(BlueprintOverride)
	void HandleUltimate(ASwarmActor Swarm) {}

//	UFUNCTION(BlueprintOverride)
//	void HandleParticleDeath(int ParticleBoneIdx) {}

	UFUNCTION(BlueprintOverride)
	void HandlePlayerHitBySwarm(AHazePlayerCharacter PlayerVicitim) {}

}
