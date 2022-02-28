

import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;
import Cake.LevelSpecific.Tree.Swarm.Movement.SwarmTowardsVictimSlerper;

class USwarmSoloShieldDefendMiddleCapability: USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::DefendMiddle;

	/* Arena middle transform + Desired offset */ 
	FTransform DesiredTransform = FTransform::Identity;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if(MoveComp.ArenaMiddleActor == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if(MoveComp.ArenaMiddleActor == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	float RandomOffsetFactor = 0.f;
 
 	UFUNCTION(BlueprintOverride)
 	void OnActivated(FCapabilityActivationParams ActivationParams)
 	{
		SwarmActor.PlaySwarmAnimation(
			Settings.SoloShield.DefendMiddle.AnimSettingsDataAsset,
			this,
			Settings.SoloShield.DefendMiddle.BlendInTime
			// 0.2f
            // Settings.SoloShield.TelegraphDefence.TelegraphTime
		);

		RandomOffsetFactor = FMath::RandRange(0.8f, 1.2f);

		BehaviourComp.NotifyStateChanged();

		TowardsVictimSlerper = USwarmTowardsVictimSlerper::GetOrCreate(SwarmActor);
		TowardsVictimSlerper.InitTowardsVictimSlerper();
		TowardsVictimSlerper.SlerpSpeed = 3000.f;
		TowardsVictimSlerper.DesiredSlerpTime = 10.f;
 	}

	USwarmTowardsVictimSlerper TowardsVictimSlerper;

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
//		CalculateDesiredTransform_RelativeToQueen();
		CalculateDesiredTransform_RelativeToQueenAndVictim(DeltaSeconds);

		// System::DrawDebugSphere(DesiredTransform.GetLocation(), 200.f);

		MoveComp.InterpolateToTarget(
			DesiredTransform,
			Settings.SoloShield.DefendMiddle.LerpSpeed,
			false,
			DeltaSeconds
		);

		// MoveComp.SpringToTargetLocation(
		// 	DesiredTransform.GetLocation(),
		// 	Settings.SoloShield.DefendMiddle.SpringToLocationStiffness,
		// 	Settings.SoloShield.DefendMiddle.SpringToLocationDamping,
		// 	DeltaSeconds
		// );

		// MoveComp.InterpolateToTargetRotation(
		// 	DesiredTransform.GetRotation(),
		// 	3.f,
		// 	false,
		// 	DeltaSeconds	
		// );

 		// System::DrawDebugPoint(DesiredTransform.GetLocation(), 10.f, PointColor = FLinearColor::Blue);
 		// System::DrawDebugPoint(MoveComp.DesiredSwarmActorTransform.GetLocation(), 10.f, PointColor = FLinearColor::Yellow);

		BehaviourComp.FinalizeBehaviour();
	}

	void CalculateDesiredTransform_RelativeToQueen()
	{
		DesiredTransform = MoveComp.ArenaMiddleActor.GetActorTransform();

		// Add the desired offset relative to the ArenaMiddleActors YAW rotation.
		FQuat Swing, Twist;
		DesiredTransform.GetRotation().ToSwingTwist(FVector::UpVector, Swing, Twist);
		FVector RotatedOffset = Twist.RotateVector(GetDefendMiddleOffset());
		DesiredTransform.AddToTranslation(RotatedOffset);
	}

	void CalculateDesiredTransform_RelativeToQueenAndVictim(const float Dt)
	{
		const UPrimitiveComponent QueenRoot = Cast<UPrimitiveComponent>(MoveComp.ArenaMiddleActor.GetRootComponent());
		const FVector Queen_COM = QueenRoot.GetCenterOfMass(); 

// 		System::DrawDebugPoint(Queen_COM, 100.f, PointColor = FLinearColor::Blue);

		TowardsVictimSlerper.UpdateTowardsVictimSlerper(Dt);

		// Calculate root-align bone offset. The offset will be rotated 
		// to be relative to the vector between the queen and the victim.
		const FQuat QueenToVictimQuat = Math::MakeQuatFromX(TowardsVictimSlerper.QueenToVictim);
		const FQuat SwarmToVictimQuat = TowardsVictimSlerper.SwarmToVictim.ToOrientationQuat();

		if (Settings.SoloShield.DefendMiddle.bTangentialToWorldPlane)
		{
			FQuat DummySwing, SwarmToVictimQuat_Twist, QueenToVictimQuat_Twist;
			SwarmToVictimQuat.ToSwingTwist(
				FVector::UpVector,
				DummySwing,
				SwarmToVictimQuat_Twist
			);
			QueenToVictimQuat.ToSwingTwist(
				FVector::UpVector,
				DummySwing,
				QueenToVictimQuat_Twist
			);

			DesiredTransform = FTransform(SwarmToVictimQuat_Twist, Queen_COM);
			const FVector ExtraTelegraphOffset = QueenToVictimQuat_Twist.RotateVector(
				GetDefendMiddleOffset()
			);
			DesiredTransform.AddToTranslation(ExtraTelegraphOffset);
		}
		else
		{
			DesiredTransform = FTransform(SwarmToVictimQuat, Queen_COM);
			const FVector ExtraTelegraphOffset = QueenToVictimQuat.RotateVector(
				GetDefendMiddleOffset()
			);
			DesiredTransform.AddToTranslation(ExtraTelegraphOffset);
		}


	}

	FVector GetDefendMiddleOffset() const
	{
		FVector FinalOffset = Settings.SoloShield.DefendMiddle.Offset;
		FinalOffset *= RandomOffsetFactor;
		return FinalOffset;
	}

}
































