import Cake.LevelSpecific.Clockwork.HorseDerby.DerbyHorseActor;
import Cake.LevelSpecific.Clockwork.HorseDerby.HorseDerbyManager;

class UDerbyHorseRaceProgressCapability : UHazeCapability
{
	default CapabilityTags.Add(n"DerbyHorse");
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 50;

	AHorseDerbyManager Manager;
	ADerbyHorseActor HorseActor;
	UDerbyHorseComponent HorseComp;

	float CurrentRaceTime;

	float StartDistance = 0.f;
	float RaceDistance = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		HorseActor = Cast<ADerbyHorseActor>(Owner);
		Manager = Cast<AHorseDerbyManager>(GetAttributeObject(n"Manager"));
		HorseComp = HorseActor.HorseComponent;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Manager != nullptr && Manager.Gamestate == EDerbyHorseState::GameActive)
			return EHazeNetworkActivation::ActivateLocal;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Manager == nullptr || Manager.Gamestate != EDerbyHorseState::GameActive)
			return EHazeNetworkDeactivation::DeactivateLocal;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentRaceTime = 0.f;

		StartDistance = HorseActor.SplineTrack.GetSplineDistanceAtGamePosition(EDerbyHorseState::AwaitingStart);
		float GoalDistance = HorseActor.SplineTrack.GetSplineDistanceAtGamePosition(EDerbyHorseState::GameActive);
		RaceDistance = GoalDistance - StartDistance;

		HorseComp.CurrentProgress = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		HorseComp.CurrentProgress = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CurrentRaceTime += DeltaTime;
		CalculateProgress();
	}

	void CalculateProgress()
	{
		float UnitDistance = RaceDistance / 100;

		float CurrentDistance = HorseActor.SplineTrack.SplineComp.GetDistanceAlongSplineAtWorldLocation(HorseActor.ActorLocation);

		CurrentDistance -= StartDistance;
		float CurrentProgress = CurrentDistance / UnitDistance;

		HorseComp.CurrentProgress = CurrentProgress;
	}
}