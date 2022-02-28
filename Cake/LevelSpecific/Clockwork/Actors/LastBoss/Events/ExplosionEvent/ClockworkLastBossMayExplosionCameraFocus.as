import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.ExplosionEvent.ClockworkLastBossCodyExplosionComponent;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.ExplosionEvent.ClockworkLastBossMayExplosionComponent;

class UClockworkLastBossMayExplosionCameraFocus : UHazeCapability
{
	default CapabilityTags.Add(n"ClockworkLastBossMayExplosionCameraFocus");

	default CapabilityDebugCategory = n"ClockworkLastBossMayExplosionCameraFocus";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UClockworkLastBossMayExplosionComponent MayExpComp;
	AHazeActor CurrentFocusActor;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MayExpComp = UClockworkLastBossMayExplosionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (Player != Game::GetMay())
			return EHazeNetworkActivation::DontActivate;

		if (MayExpComp == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (MayExpComp.FocusTargetActor == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		if (MayExpComp.FocusTargetActor == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (MayExpComp != nullptr)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (MayExpComp.FocusTargetActor == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MayExpComp.FocusTargetActor == nullptr)
			return;

		if (MayExpComp.FocusTargetActor != CurrentFocusActor)
		{
			CurrentFocusActor = MayExpComp.FocusTargetActor;

			FHazePointOfInterest Poi;
			Poi.InitializeAsInputAssist();
			Poi.FocusTarget.Actor = MayExpComp.FocusTargetActor;
			Poi.Blend = 1.5f;
			Player.ApplyPointOfInterest(Poi, this, EHazeCameraPriority::Script);
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearPointOfInterestByInstigator(this);
	}
}