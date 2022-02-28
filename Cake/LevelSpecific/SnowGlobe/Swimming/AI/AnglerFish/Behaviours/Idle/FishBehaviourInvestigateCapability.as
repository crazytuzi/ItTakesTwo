import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourCapability;
import Vino.AI.ScenePoints.ScenePointComponent;

class UFishBehaviourInvestigateCapability : UFishBehaviourCapability
{
    default State = EFishState::Idle;
	default SetPriority(EFishBehaviourPriority::High);

	UScenepointComponent InvestigatePoint = nullptr;
	FVector StartLoc = FVector::ZeroVector;
	float InvestigateEndTime = BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Super::ShouldActivate() == EHazeNetworkActivation::DontActivate)
			return EHazeNetworkActivation::DontActivate;	
		if (BehaviourComponent.InvestigateScenepoint == nullptr)
    		return EHazeNetworkActivation::DontActivate;
       	return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() != EHazeNetworkDeactivation::DontDeactivate)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;	

		if (InvestigatePoint == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb; 

		if (Time::GetGameTimeSeconds() > InvestigateEndTime)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb; 

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"Scenepoint", BehaviourComponent.InvestigateScenepoint);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		InvestigatePoint = Cast<UScenepointComponent>(ActivationParams.GetObject(n"Scenepoint"));
		BehaviourComponent.InvestigateScenepoint = nullptr; // Consume
		StartLoc = Owner.ActorLocation;
		InvestigateEndTime = Time::GetGameTimeSeconds() + 40.f; 

		EffectsComp.SetEffectsMode(EFishEffectsMode::Searching);
		AnimComp.SetAgitated(false);
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaSeconds)
    {
        if (BehaviourComponent.HasValidTarget())
		{
			// We've found a target, engage!
            BehaviourComponent.State = EFishState::Combat; 
            return;
        }

		FVector InvestigateLoc = InvestigatePoint.WorldLocation + Settings.InvestigationOffset;

		// Slow down when nearing point
		FVector ToPoint = InvestigateLoc - Owner.ActorLocation;
		float DistToPoint = ToPoint.Size();
		float Acceleration = FMath::GetMappedRangeValueClamped(FVector2D(6000.f, 20000.f), FVector2D(100.f, Settings.InvestigationAcceleration * 1.5f), DistToPoint);

		// Try not to swim through hiding places containing players
		FVector Dest = InvestigatePoint.WorldLocation;
		FVector AvoidCody = MoveComp.GetHidingPlayerAvoidanceDestination(Dest, Game::GetCody());
		FVector AvoidMay = MoveComp.GetHidingPlayerAvoidanceDestination(Dest, Game::GetMay());
		Dest = (AvoidCody.Z > AvoidMay.Z) ? AvoidCody : AvoidMay;
        BehaviourComponent.MoveTo(Dest, Acceleration, Settings.InvestigationTurnDuration * 0.5f);

		// Abort investigation when we've been looking at point for a while
		if ((DistToPoint < 10000.f) && (BehaviourComponent.MawForwardVector.DotProduct(ToPoint.GetSafeNormal()) > 0.87f))
			InvestigateEndTime = FMath::Min(InvestigateEndTime, Time::GetGameTimeSeconds() + Settings.InvestigationDuration);

		FVector StartToSp = InvestigatePoint.WorldLocation - StartLoc;
		FVector ToSp = InvestigatePoint.WorldLocation - Owner.ActorLocation;
		if (StartToSp.DotProduct(ToSp) < 0.f)
			InvestigatePoint = nullptr; // Passed point we want to investigate, abort
    }
}
