
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmHitAndRunTelegraphInitialAttackCapability : USwarmBehaviourCapability
{
 	default AssignedState = ESwarmBehaviourState::TelegraphInitial;

	FQuat StartQuat = FQuat::Identity;
	FQuat SwarmToVictimQuat = FQuat::Identity;
	FVector StartOffsetFromVictim = FVector::ZeroVector;
	FVector VictimLocation = FVector::ZeroVector;

 	UFUNCTION(BlueprintOverride)
 	EHazeNetworkActivation ShouldActivate() const
 	{
 		if (BehaviourComp.HasBehaviourBeenFinalized())
 			return EHazeNetworkActivation::DontActivate;
 
 		if(SwarmActor.VictimComp.PlayerVictim == nullptr)
 			return EHazeNetworkActivation::DontActivate;

		if(VictimComp.IsVictimGrounded() == false)
			return EHazeNetworkActivation::DontActivate;

 		if(MoveComp.GetSplineToFollow() == nullptr)
 			return EHazeNetworkActivation::DontActivate;
 
//  		if(!HasEnoughParticlesForAnimation(Settings.HitAndRun.TelegraphInitial.AnimSettingsDataAsset))
//  			return EHazeNetworkActivation::DontActivate;

		if(Settings.HitAndRun.TelegraphInitial.DesiredStateDuration <= 0.f)
			return EHazeNetworkActivation::DontActivate;
 
 		return EHazeNetworkActivation::ActivateLocal;
 	}
 
 	UFUNCTION(BlueprintOverride)
 	EHazeNetworkDeactivation ShouldDeactivate() const
 	{
 		if (BehaviourComp.HasBehaviourBeenFinalized())
 			return EHazeNetworkDeactivation::DeactivateLocal;
 
 		if(SwarmActor.VictimComp.PlayerVictim == nullptr)
 			return EHazeNetworkDeactivation::DeactivateLocal;

 		if(MoveComp.GetSplineToFollow() == nullptr)
 			return EHazeNetworkDeactivation::DeactivateLocal;
 
//  		if(!HasEnoughParticlesForAnimation(Settings.HitAndRun.TelegraphInitial.AnimSettingsDataAsset))
//  			return EHazeNetworkDeactivation::DeactivateLocal;
 
 		return EHazeNetworkDeactivation::DontDeactivate;
 	}
 
 	UFUNCTION(BlueprintOverride)
 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
 	{
 		SwarmActor.StopSwarmAnimationByInstigator(this);
 		VictimComp.RemoveClosestPlayerOverride(this);
 	}
 
 	UFUNCTION(BlueprintOverride)
 	void OnActivated(FCapabilityActivationParams ActivationParams)
 	{

 		SwarmActor.PlaySwarmAnimation(
 			Settings.HitAndRun.TelegraphInitial.AnimSettingsDataAsset,
 			this,
 			Settings.HitAndRun.TelegraphInitial.AnimBlendInTime
 		);

 		VictimComp.OverrideClosestPlayer(VictimComp.PlayerVictim, this);
 		BehaviourComp.NotifyStateChanged();

		// calculate all initial values. We want the swarm
		// to stand still relative to the moving object
		StartQuat = MoveComp.DesiredSwarmActorTransform.GetRotation();
		VictimLocation = VictimComp.GetLastValidGroundLocation();
		SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsLocation(VictimLocation);
		FQuat SwingDummy, SwarmToVictimQuat_Twist;
		SwarmToVictimQuat.ToSwingTwist(FVector::UpVector, SwingDummy, SwarmToVictimQuat_Twist);
		const FVector DesiredTelegraphOffset = SwarmToVictimQuat_Twist.RotateVector(
			Settings.HitAndRun.TelegraphInitial.TelegraphingOffset
		);

		// System::DrawDebugPoint(SwarmActor.GetActorLocation(), 6.f, FLinearColor::Red, 4.5f); 

		// const FVector SwarmPos = MoveComp.DesiredSwarmActorTransform.GetLocation();
		FVector SwarmPos = SwarmActor.SkelMeshComp.CenterOfParticles;
		SwarmPos += (SwarmActor.SkelMeshComp.CenterOfParticlesVelocity * (1.f / 60.f));
		MoveComp.DesiredSwarmActorTransform.SetLocation(SwarmPos);

		// System::DrawDebugPoint(SwarmActor.GetActorLocation(), 6.f, FLinearColor::Yellow, 4.5f); 

		const FVector DesiredLocation = SwarmPos + DesiredTelegraphOffset;
		StartOffsetFromVictim = DesiredLocation - VictimLocation;

//		MoveComp.InitLerpAlongSpline();
 	}
 
 	UFUNCTION(BlueprintOverride)
 	void TickActive(const float DeltaSeconds)
 	{
 		// Request attack once we've telegraphed long enough.
 		if (BehaviourComp.GetStateDuration() > Settings.HitAndRun.TelegraphInitial.DesiredStateDuration)
 			PrioritizeState(ESwarmBehaviourState::Attack);

 		BehaviourComp.FinalizeBehaviour();

		VictimLocation = VictimComp.GetVictimCenterTransform().GetLocation();
		SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsLocation(VictimLocation);

		const float LerpAlpha = FMath::Clamp(
			BehaviourComp.GetStateDuration() / Settings.HitAndRun.TelegraphInitial.AnimBlendInTime,
			0.f,
			1.f
		);

 		MoveComp.SlerpToTargetRotation(StartQuat, SwarmToVictimQuat, LerpAlpha);

		const FVector DesiredTargetLocation = VictimLocation + StartOffsetFromVictim;

		// System::DrawDebugPoint(SwarmActor.GetActorLocation(), 4.f, FLinearColor::Yellow, 1.5f); 
		// System::DrawDebugPoint(DesiredTargetLocation, 4.f, FLinearColor::Green, 1.5f); 

		TArray<FHitResult> Hits;
		const FVector DeltaTrace = FVector::UpVector * 1000.f;
		MoveComp.RayTraceMulti(
			DesiredTargetLocation + (FVector::UpVector * 1000),
			DesiredTargetLocation - (FVector::UpVector * 5000),
			Hits,
			ETraceTypeQuery::WaterTrace
		);

		if(Hits.Num() != 0)
		{
			const FVector TraceTargetLocation = Hits.Last().ImpactPoint;
			// MoveComp.SpringToTargetLocation(TraceTargetLocation, 15.f, 0.6f, DeltaSeconds);
			MoveComp.SpringToTargetWithTime(
				TraceTargetLocation,
				Settings.HitAndRun.TelegraphInitial.AnimBlendInTime,
				DeltaSeconds
			);
			// System::DrawDebugPoint(TraceTargetLocation, 4.f, FLinearColor::Yellow, 1.5f); 
			// Print("" + Hits.Last().GetActor());
		}
		else
		{
 			MoveComp.LerpToTargetLocation(VictimLocation + StartOffsetFromVictim, LerpAlpha);
		}

 	}
}











