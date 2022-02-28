
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;
import Cake.LevelSpecific.Tree.Queen.SpecialAttacks.Phase3RailSwordComponent;
import Cake.LevelSpecific.Tree.Queen.SpecialAttacks.QueenSpecialAttackSwords;

class USwarmRailSwordTelegraphInitialAttackCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::TelegraphInitial;

	FQuat SplineRot = FQuat::Identity;
	FVector SplineLoc = FVector::ZeroVector;

	UPhase3RailSwordComponent ManagedSwarmComp;
	UQueenSpecialAttackSwords Manager;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		if(SwarmActor.VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(SwarmActor.MovementComp.ArenaMiddleActor == nullptr)
			return EHazeNetworkActivation::DontActivate;

		// this happens when the vicim falls of the spline
		// perhaps we should switch target when this happens. 
		// or maybe the railsword should cancel into shield?
		// or have it's own spline reference?
		if(!VictimComp.IsVictimFollowingSpline())
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

		if(SwarmActor.MovementComp.ArenaMiddleActor == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwarmActor.PlaySwarmAnimation(
			Settings.RailSword.TelegraphInitial.AnimSettingsDataAsset,
			this,
			Settings.RailSword.TelegraphInitial.TelegraphingTime
		);

		UHazeSplineFollowComponent SplineFollowComp  = VictimComp.GetSplineFollowComp();
		ensure(SplineFollowComp.HasActiveSpline());

		FHazeSplineSystemPosition SplinePosData = SplineFollowComp.GetPosition(); 
		auto Spline = SplineFollowComp.GetActiveSpline();
		MoveComp.FollowSplineComp = Cast<UHazeSplineComponent>(Spline);

		VictimComp.bWasHeadingForwardsOnSpline = SplinePosData.IsForwardOnSpline();

		VictimComp.OverrideClosestPlayer(VictimComp.PlayerVictim, this);
		BehaviourComp.NotifyStateChanged();

		ManagedSwarmComp = UPhase3RailSwordComponent::Get(Owner);
		Manager = UQueenSpecialAttackSwords::Get(MoveComp.ArenaMiddleActor);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
		VictimComp.RemoveClosestPlayerOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaSeconds)
	{
		if (BehaviourComp.GetStateDuration() > Settings.RailSword.TelegraphInitial.TimeUntilWeSwitchState)
			PrioritizeState(ESwarmBehaviourState::Attack);

		UpdateMovement(DeltaSeconds);

		BehaviourComp.FinalizeBehaviour();
	}

	void UpdateMovement(const float Dt)
	{
		// TRANSLATION
		const FVector DesiredPosition = ManagedSwarmComp.CalculateSwordTelegraphPos(
			MoveComp.ArenaMiddleActor.GetActorLocation()
		);

		// Make sure that the sword start attaining their correct location after they've risen.
		float TimeToSpringToLocation = Settings.RailSword.TelegraphInitial.TelegraphingTime;
		const float InitTime = Settings.RailSword.TelegraphInitial.TelegraphingTime;
		const float StateDuration = BehaviourComp.GetStateDuration();
		if(StateDuration >= InitTime)
		{
			float FadeOutTime = Settings.RailSword.TelegraphInitial.TimeUntilWeSwitchState;
			FadeOutTime = FMath::Max(FadeOutTime - InitTime, 0.f);

			const float FadeOutTimeElapsed = StateDuration - InitTime;
			float Alpha = FMath::Clamp(StateDuration / FadeOutTime, 0.f, 1.f);
			Alpha = FMath::Pow(Alpha, 2.f);
			Alpha = 1.f - Alpha;
			TimeToSpringToLocation *= Alpha;
			// Print("Alpha:" + Alpha, 0.001);
			// Print("TimeToSpringToLocation:" + TimeToSpringToLocation, 0.001);
			// Print("stateDuration :" + StateDuration, 0.001);
		}

		// you'll have to make the springs stronger in SwarmAnimSettings as well 
		// if you've increased the RotationSpeed of the desired locations
		MoveComp.SpringToTargetWithTime(
			DesiredPosition,
			TimeToSpringToLocation,
			// Settings.RailSword.TelegraphInitial.TelegraphingTime,	
			Dt	
		);

		// ROTATION
		const FVector ArenaMidPos = MoveComp.ArenaMiddleActor.GetActorLocation();
		FVector LookDirection = DesiredPosition - ArenaMidPos;
		LookDirection.Z = 0;
  		const FQuat LookRotation = Math::MakeQuatFromX(LookDirection);
		MoveComp.InterpolateToTargetRotation(
			LookRotation,
			30.f,
			false,
			Dt	
		);

		// System::DrawDebugSphere(DesiredPosition);
		// System::DrawDebugSphere(SwarmActor.GetActorLocation(), LineColor = FLinearColor::Yellow);
		// System::DrawDebugSphere(MoveComp.DesiredSwarmActorTransform.GetLocation(), LineColor = FLinearColor::Red);
	}

	bool IsPlayerCloseToFinishingGrind() const
	{
		const UHazeSplineFollowComponent SplineFollowComp  = VictimComp.GetSplineFollowComp();
		const FHazeSplineSystemPosition SplinePosData = SplineFollowComp.GetPosition(); 
		UHazeSplineComponentBase GrindSpline = SplinePosData.GetSpline();

		const float PredictedDist = GrindSpline.GetDistanceAlongSplineAtWorldLocation(
			VictimComp.GetPredictedVictimLocation(Settings.RailSword.TelegraphInitial.TelegraphingTime)
			// VictimComp.PlayerVictim.GetActorLocation()
		);

		const float SplineLength = SplinePosData.GetSpline().GetSplineLength(); 
		const float EndDist = SplinePosData.IsForwardOnSpline() ? SplineLength: 0.f;

		const float Threshold = Settings.RailSword.TelegraphInitial.MinDistancePlayerHasToTraveledOnSpline;

		// players seems to switch sides when he is on the very end of the spline
		if(PredictedDist < Threshold || PredictedDist > (SplineLength - Threshold))
			return true;

		if(SplinePosData.IsForwardOnSpline())
			return PredictedDist >= EndDist;
		else
			return PredictedDist <= EndDist;
	}

	bool IsPlayerActuallyGoingToGrind() const
	{
		const UHazeSplineFollowComponent SplineFollowComp  = VictimComp.GetSplineFollowComp();
		const FHazeSplineSystemPosition SplinePosData = SplineFollowComp.GetPosition(); 
		UHazeSplineComponentBase GrindSpline = SplinePosData.GetSpline();

		const float CurrentDist = GrindSpline.GetDistanceAlongSplineAtWorldLocation(
			VictimComp.PlayerVictim.GetActorLocation()
		);
		const float StartDist = !SplinePosData.IsForwardOnSpline() ? SplinePosData.GetSpline().GetSplineLength() : 0.f;
		const float Threshold = Settings.RailSword.TelegraphInitial.MinDistancePlayerHasToTraveledOnSpline;

		return FMath::Abs(CurrentDist - StartDist) > Threshold;
	}

}











