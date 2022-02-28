import Cake.LevelSpecific.Tree.Swarm.SwarmActor;

UCLASS(abstract)
class USwarmEventHandler : UHazeCapability
{
	default CapabilityTags.Add(n"Swarm");
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	UPROPERTY(NotEditable)
	ASwarmActor Swarm = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Swarm = Cast<ASwarmActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Swarm.OnDie.AddUFunction(this, n"HandleDeath");
		Swarm.OnAboutToDie.AddUFunction(this, n"HandleAboutToDie");
		Swarm.OnUltimatePerformed.AddUFunction(this, n"HandleUltimate");

//		for(USwarmSkeletalMeshComponent SwarmSkelMeshIter : Swarm.SwarmSkelMeshes)
//			SwarmSkelMeshIter.OnSwarmParticleKilled.AddUFunction(this, n"HandleParticleDeath");

		Swarm.ShapeChanged.AddUFunction(this, n"HandleShapeChanged");
		Swarm.OnHitByMatch.AddUFunction(this, n"HandleHitByMatch");
		Swarm.OnSapExplosion.AddUFunction(this, n"HandleSapExplosion");
		Swarm.VictimComp.OnVictimHitBySwarm.AddUFunction(this, n"HandlePlayerHitBySwarm");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Swarm.OnDie.Unbind(this, n"HandleDeath");
		Swarm.OnAboutToDie.Unbind(this, n"HandleAboutToDie");
		Swarm.OnUltimatePerformed.Unbind(this, n"HandleUltimate");

//		for(USwarmSkeletalMeshComponent SwarmSkelMeshIter : Swarm.SwarmSkelMeshes)
//			SwarmSkelMeshIter.OnSwarmParticleKilled.Unbind(this, n"HandleParticleDeath");

		Swarm.ShapeChanged.Unbind(this, n"HandleShapeChanged");
		Swarm.OnHitByMatch.Unbind(this, n"HandleHitByMatch");
		Swarm.OnSapExplosion.Unbind(this, n"HandleSapExplosion");
		Swarm.VictimComp.OnVictimHitBySwarm.Unbind(this, n"HandlePlayerHitBySwarm");
	}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleDeath(ASwarmActor Swarm) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleAboutToDie(ASwarmActor Swarm) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleUltimate(ASwarmActor Swarm) {}

//	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
//	void HandleParticleDeath(int ParticleBoneIdx) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleShapeChanged(float InShapeChangeDuration) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleSapExplosion(FVector WorldLocation) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleHitByMatch(FVector WorldLocation) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandlePlayerHitBySwarm(AHazePlayerCharacter PlayerVicitim) {}

	UFUNCTION(BlueprintPure)
	FVector GetCenterOfSwarmLocation() const
	{
		return Swarm.SkelMeshComp.CenterOfParticles;
	}

	UFUNCTION(BlueprintPure)
	float GetSwarmAngularSpeedNormalizedToRange(const float MaxSpeed = 1000000.f) const
	{
		return Math::NormalizeToRange(Swarm.SkelMeshComp.CenterOfParticlesAngularVelocity.Size(), 0.f, MaxSpeed);
	}

	UFUNCTION(BlueprintPure)
	float GetSwarmSpeedNormalizedToRange(const float MaxSpeed = 2000.f) const
	{
		return FMath::Clamp(Math::NormalizeToRange(Swarm.SkelMeshComp.CenterOfParticlesVelocity.Size(), 0.f, MaxSpeed), 0.f, 1.f);
	}

	// -1, 0, or 1. 
	UFUNCTION(BlueprintPure)
	float GetSwarmVelocityDeltaDirection(const float ThresholdSQ = 1.f) const
	{
		return Swarm.MovementComp.GetSwarmMovingDirection(ThresholdSQ);
		
	}

	UFUNCTION(BlueprintPure)
	float GetSwarmRadiusNormalizedToRange(const float MaxRadius = 1500.f) const
	{
		return Math::NormalizeToRange(Swarm.GetSwarmRadius(), 0.f, MaxRadius);
	}

	// 0 == complete, 1 == started shapeshifting
	UFUNCTION(BlueprintPure)
	float GetShapeChangeValue(const float InTimeStampShapeChangeTriggered, const float InShapeChangeDuration) const
	{
		if(InShapeChangeDuration == 0.f)
			return 0.f;
		else
			return FMath::Clamp(Time::GetGameTimeSince(InTimeStampShapeChangeTriggered) / InShapeChangeDuration, 0.f, 1.f);
	}

}
