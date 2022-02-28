import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourCapability;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Scenepoints.FishRoamScenepoint;

class UFishBehaviourRoamCapability : UFishBehaviourCapability
{
    default State = EFishState::Idle;

	UFishRoamScenepointsTeam ScenePointsTeam = nullptr;
	UFishRoamScenepointComponent Roampoint = nullptr;
	FVector StartLoc;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		ScenePointsTeam = Cast<UFishRoamScenepointsTeam>(Owner.JoinTeam(n"FishRoamScenepointsTeam", UFishRoamScenepointsTeam::StaticClass()));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Super::ShouldActivate() == EHazeNetworkActivation::DontActivate)
			return EHazeNetworkActivation::DontActivate;	
		if (ScenePointsTeam.RoamScenepoints.Num() == 0)
    		return EHazeNetworkActivation::DontActivate;
       	return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() != EHazeNetworkDeactivation::DontDeactivate)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;	
		if (Roampoint == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		// Find points which are somewhat distant within our front hemisphere
		FVector OwnLoc = Owner.ActorLocation;
		FVector Forward = BehaviourComponent.MawForwardVector;
		TArray<UFishRoamScenepointComponent> GoodPoints;
		for (UFishRoamScenepointComponent RoamSP : ScenePointsTeam.RoamScenepoints)
		{
			if (RoamSP == nullptr)
				return;
			FVector ToPoint = RoamSP.WorldLocation - OwnLoc;
			if (ToPoint.SizeSquared() < FMath::Square(2000.f))
				continue;
			if (ToPoint.DotProduct(Forward) < 0.f)
				continue;
			GoodPoints.Add(RoamSP);
		}
		if (GoodPoints.Num() == 0)
			GoodPoints = ScenePointsTeam.RoamScenepoints;
		
		ensure(GoodPoints.Num() > 0); 
		ActivationParams.AddObject(n"Scenepoint", GoodPoints[FMath::RandRange(0, GoodPoints.Num() - 1)]);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		Roampoint = Cast<UFishRoamScenepointComponent>(ActivationParams.GetObject(n"Scenepoint"));
		StartLoc = Owner.ActorLocation;

		EffectsComp.SetEffectsMode(EFishEffectsMode::Idle);
		AnimComp.SetAgitated(false);
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaSeconds)
    {
		if (Roampoint == nullptr)
			return;

		//System::DrawDebugLine(Owner.ActorLocation, Roampoint.WorldLocation, FLinearColor::Yellow, 0.f, 20.f);

        if (BehaviourComponent.HasValidTarget() && (BehaviourComponent.StateDuration > 1.f))
		{
			// We've found a target, engage!
            BehaviourComponent.State = EFishState::Combat; 
            return;
        }

		// Try not to swim through hiding places containing players
		FVector Dest = Roampoint.WorldLocation;
		FVector AvoidCody = MoveComp.GetHidingPlayerAvoidanceDestination(Dest, Game::GetCody());
		FVector AvoidMay = MoveComp.GetHidingPlayerAvoidanceDestination(Dest, Game::GetMay());
		Dest = (AvoidCody.Z > AvoidMay.Z) ? AvoidCody : AvoidMay;
        BehaviourComponent.MoveTo(Dest, Settings.IdleAcceleration, Settings.IdleTurnDuration);

		FVector StartToSp = Roampoint.WorldLocation - StartLoc;
		FVector ToSp = Roampoint.WorldLocation - Owner.ActorLocation;
		if (StartToSp.DotProduct(ToSp) < 0.f)
			Roampoint = nullptr; // Time to choose another scene point

		EffectsComp.SetEffectsMode(EFishEffectsMode::Idle);
    }
}
