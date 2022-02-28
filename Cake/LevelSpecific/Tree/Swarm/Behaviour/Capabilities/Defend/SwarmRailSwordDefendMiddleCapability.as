
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmRailSwordBaseCapability;

class USwarmRailSwordDefendMiddleCapability : USwarmRailSwordBaseCapability
{
	default AssignedState = ESwarmBehaviourState::DefendMiddle;
 
 	UFUNCTION(BlueprintOverride)
 	void OnActivated(FCapabilityActivationParams ActivationParams)
 	{
		SwarmActor.PlaySwarmAnimation(
			Settings.SoloShield.DefendMiddle.AnimSettingsDataAsset,
			this,
            Settings.SoloShield.DefendMiddle.BlendInTime
		);

		BehaviourComp.NotifyStateChanged();

		RandomOffsetFactor = FMath::RandRange(0.8f, 1.2f);
		ManagedSwarmComp = UPhase3RailSwordComponent::GetOrCreate(Owner);
		Manager = UQueenSpecialAttackSwords::Get(SwarmActor.MovementComp.ArenaMiddleActor);

		TowardsVictimSlerper = USwarmTowardsVictimSlerper::GetOrCreate(SwarmActor);
		TowardsVictimSlerper.InitTowardsVictimSlerper();
 	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
		SwarmActor.VictimComp.RemoveClosestPlayerOverride(this);
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
		UpdateDesiredTransform_RelativeToQueenAndVictim(DeltaSeconds, 
		Settings.SoloShield.DefendMiddle.bTangentialToWorldPlane);

		MoveComp.InterpolateToTarget(
			DesiredTransform,
			Settings.SoloShield.DefendMiddle.LerpSpeed,
			false,
			DeltaSeconds
		);

		// The rotation is already lerped above,
		// but we want to lerp the rotation faster
		MoveComp.InterpolateToTargetRotation(
			DesiredTransform.GetRotation(),
			3.f,
			false,
			DeltaSeconds	
		);

// 		System::DrawDebugPoint(DesiredTransform.GetLocation(), 10.f, PointColor = FLinearColor::Blue);
		// System::DrawDebugPoint(MoveComp.DesiredSwarmActorTransform.GetLocation(), 10.f, PointColor = FLinearColor::Yellow);

		BehaviourComp.FinalizeBehaviour();
	}

	FVector GetShieldOffset() const
	{
		FVector FinalOffset = Settings.SoloShield.DefendMiddle.Offset;
		FinalOffset *= RandomOffsetFactor;
		return FinalOffset;
	}

}
































