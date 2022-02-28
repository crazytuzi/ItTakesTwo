

import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;
import Cake.LevelSpecific.Tree.Swarm.Movement.SwarmTowardsVictimSlerper;

class USwarmSoloShieldTelegraphDefenceCapability: USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::TelegraphDefence;

	/* Arena middle transform + Desired offset */ 
	FTransform DesiredTransform = FTransform::Identity;
	FTransform StartTransform = FTransform::Identity;

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
 
 	UFUNCTION(BlueprintOverride)
 	void OnActivated(FCapabilityActivationParams ActivationParams)
 	{
		SwarmActor.PlaySwarmAnimation(
			Settings.SoloShield.TelegraphDefence.AnimSettingsDataAsset,
			this,
			Settings.SoloShield.TelegraphDefence.TelegraphTime
		);

		StartTransform = MoveComp.DesiredSwarmActorTransform;

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
		if (BehaviourComp.GetStateDuration() > Settings.SoloShield.TelegraphDefence.TelegraphTime)
			PrioritizeState(ESwarmBehaviourState::DefendMiddle);

//		CalculateDesiredTransform_RelativeToQueen();
		CalculateDesiredTransform_RelativeToQueenAndVictim(DeltaSeconds);

		// System::DrawDebugSphere(DesiredTransform.GetLocation(), 200.f);

		float SpringToTargetTime = Settings.SoloShield.TelegraphDefence.TelegraphTime;
		SpringToTargetTime -= BehaviourComp.GetStateDuration();
		if(SpringToTargetTime < 0.f)
			SpringToTargetTime = 0.f;

		// PrintToScreenScaled("SpringToTargetTime: " + SpringToTargetTime);

		MoveComp.InterpolateToRotationOverTime
		(	
			StartTransform.GetRotation(),
			DesiredTransform.GetRotation(),
			BehaviourComp.GetStateDuration(),
			SpringToTargetTime
		);

		MoveComp.SpringToTargetWithTime(
			DesiredTransform.GetLocation(),
			SpringToTargetTime,
			DeltaSeconds
		);

		BehaviourComp.FinalizeBehaviour();
	}

	void CalculateDesiredTransform_RelativeToQueen()
	{
		DesiredTransform = MoveComp.ArenaMiddleActor.GetActorTransform();

		// Add the desired offset relative to the ArenaMiddleActors YAW rotation.
		FQuat Swing, Twist;
		DesiredTransform.GetRotation().ToSwingTwist(FVector::UpVector, Swing, Twist);
		FVector RotatedOffset = Twist.RotateVector(Settings.SoloShield.TelegraphDefence.Offset);
		DesiredTransform.AddToTranslation(RotatedOffset);
	}

	void CalculateDesiredTransform_RelativeToQueenAndVictim(const float Dt)
	{
		const UPrimitiveComponent QueenRoot = Cast<UPrimitiveComponent>(MoveComp.ArenaMiddleActor.GetRootComponent());
		const FVector Queen_COM = QueenRoot.GetCenterOfMass(); 

 		// System::DrawDebugPoint(Queen_COM, 100.f, PointColor = FLinearColor::Blue);

		TowardsVictimSlerper.UpdateTowardsVictimSlerper(Dt);

		// Calculate root-align bone offset. The offset will be rotated 
		// to be relative to the vector between the queen and the victim.
		const FQuat QueenToVictimQuat = Math::MakeQuatFromX(TowardsVictimSlerper.QueenToVictim);
		const FQuat SwarmToVictimQuat = TowardsVictimSlerper.SwarmToVictim.ToOrientationQuat();

		if (Settings.SoloShield.TelegraphDefence.bTangentialToWorldPlane)
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
				Settings.SoloShield.TelegraphDefence.Offset
			);
			DesiredTransform.AddToTranslation(ExtraTelegraphOffset);
		}
		else
		{
			DesiredTransform = FTransform(SwarmToVictimQuat, Queen_COM);
			const FVector ExtraTelegraphOffset = QueenToVictimQuat.RotateVector(
				Settings.SoloShield.TelegraphDefence.Offset
			);
			DesiredTransform.AddToTranslation(ExtraTelegraphOffset);
		}
	}

}





