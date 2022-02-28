import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdLandingPerch;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdTags;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;

class UClockworkPlayerLandBirdOnPerchCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

    AHazePlayerCharacter Player;

	AClockworkBirdLandingPerch TriggeredPoint;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams SetupParams)
    {
        Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
    void PreTick(float DeltaTime)
    {
		auto MountedBird = Cast<AClockworkBird>(GetAttributeObject(ClockworkBirdTags::ClockworkBird));
		if (!IsActive() && !IsBlocked() && MountedBird != nullptr && MountedBird.bIsFlying)
		{
			Player.UpdateActivationPointAndWidgets(UClockworkBirdPerchActivationPoint::StaticClass());
		}

        if (!IsActive() && WasActionStarted(ActionNames::InteractionTrigger))
        {
			auto ActivePoint = Cast<UClockworkBirdPerchActivationPoint>(Player.GetTargetPoint(UClockworkBirdPerchActivationPoint::StaticClass()));
			if (ActivePoint != nullptr)
				TriggeredPoint = Cast<AClockworkBirdLandingPerch>(ActivePoint.Owner);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (TriggeredPoint != nullptr)
			return EHazeNetworkActivation::ActivateUsingCrumb;
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		auto MountedBird = Cast<AClockworkBird>(GetAttributeObject(ClockworkBirdTags::ClockworkBird));
		if (MountedBird == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (TriggeredPoint == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (MountedBird.CurrentPerch == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"Perch", TriggeredPoint);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		auto MountedBird = Cast<AClockworkBird>(GetAttributeObject(ClockworkBirdTags::ClockworkBird));
		if (MountedBird != nullptr)
		{
			auto Perch = ActivationParams.GetObject(n"Perch");
			MountedBird.SetCapabilityAttributeObject(ClockworkBirdTags::LandOnPerch, Perch);
			MountedBird.CurrentPerch = Perch;
		}
		TriggeredPoint = nullptr;
	}
};