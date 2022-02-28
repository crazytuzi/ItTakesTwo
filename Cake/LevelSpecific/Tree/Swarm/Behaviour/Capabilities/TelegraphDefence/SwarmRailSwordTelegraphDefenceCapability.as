
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmRailSwordBaseCapability;

class USwarmRailSwordTelegraphDefenceCapability: USwarmRailSwordBaseCapability
{
	default AssignedState = ESwarmBehaviourState::TelegraphDefence;

	FTransform StartTransform = FTransform::Identity;
 
 	UFUNCTION(BlueprintOverride)
 	void OnActivated(FCapabilityActivationParams ActivationParams)
 	{
		SwarmActor.PlaySwarmAnimation(
			Settings.SoloShield.TelegraphDefence.AnimSettingsDataAsset,
			this,
			Settings.SoloShield.TelegraphDefence.TelegraphTime
		);

		BehaviourComp.NotifyStateChanged();

		RandomOffsetFactor = FMath::RandRange(0.8f, 1.2f);
		ManagedSwarmComp = UPhase3RailSwordComponent::GetOrCreate(Owner);
		Manager = UQueenSpecialAttackSwords::Get(SwarmActor.MovementComp.ArenaMiddleActor);

		StartTransform = MoveComp.DesiredSwarmActorTransform;

		TowardsVictimSlerper = USwarmTowardsVictimSlerper::GetOrCreate(SwarmActor);
		TowardsVictimSlerper.InitTowardsVictimSlerper();
 	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if(TowardsVictimSlerper != nullptr)
			TowardsVictimSlerper.ResetData();
	}

 	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (BehaviourComp.GetStateDuration() > Settings.SoloShield.TelegraphDefence.TelegraphTime)
			PrioritizeState(ESwarmBehaviourState::DefendMiddle);

		UpdateDesiredTransform_RelativeToQueenAndVictim(DeltaSeconds, 
		Settings.SoloShield.TelegraphDefence.bTangentialToWorldPlane);

		float SpringToTargetTime = Settings.SoloShield.TelegraphDefence.TelegraphTime;
		SpringToTargetTime -= BehaviourComp.GetStateDuration();
		if(SpringToTargetTime < 0.f)
			SpringToTargetTime = 0.f;

		MoveComp.SpringToTargetWithTime(
			DesiredTransform.GetLocation(),
			// Settings.SoloShield.TelegraphDefence.TelegraphTime,
			SpringToTargetTime,
			DeltaSeconds
		);

		MoveComp.InterpolateToRotationOverTime
		(	
			StartTransform.GetRotation(),
			DesiredTransform.GetRotation(),
			BehaviourComp.GetStateDuration(),
			// Settings.SoloShield.TelegraphDefence.TelegraphTime
			SpringToTargetTime
		);

		// System::DrawDebugPoint(MoveComp.DesiredSwarmActorTransform.GetLocation(), 10.f, PointColor = FLinearColor::Red);

		BehaviourComp.FinalizeBehaviour();
	}

	FVector GetShieldOffset() const
	{
		FVector FinalOffset = Settings.SoloShield.TelegraphDefence.Offset;
		FinalOffset *= RandomOffsetFactor;
		return FinalOffset;
	}

}





