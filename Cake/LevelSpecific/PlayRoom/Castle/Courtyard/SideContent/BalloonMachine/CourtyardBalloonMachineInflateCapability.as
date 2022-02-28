import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.BalloonMachine.CourtyardBalloonMachine;

class UCourtyardBalloonMachineInflateCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Balloon");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	ACourtyardBalloonMachine BalloonMachine;

	float InflateTime = 4.f;
	float Cooldown = 12.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BalloonMachine = Cast<ACourtyardBalloonMachine>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!BalloonMachine.bActive)
        	return EHazeNetworkActivation::DontActivate;

		if (BalloonMachine.Balloon == nullptr)
        	return EHazeNetworkActivation::DontActivate;

		if (BalloonMachine.Balloon.bInflated)
        	return EHazeNetworkActivation::DontActivate;

		if (DeactiveDuration < Cooldown)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!BalloonMachine.bActive)
        	return EHazeNetworkDeactivation::DeactivateFromControl;

		if (BalloonMachine.Balloon.bInflated)
        	return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BalloonMachine.Balloon.MeshRoot.SetRelativeScale3D(0.f);
		BalloonMachine.Balloon.SetActorLocation(BalloonMachine.BalloonSpawnPoint.WorldLocation);
		BalloonMachine.Balloon.SetActorEnableCollision(true);
		BalloonMachine.Balloon.SetActorHiddenInGame(false);

		BalloonMachine.Balloon.TriggerMovementTransition(this);
		
		BalloonMachine.Balloon.RandomizeBalloonColour();
		BalloonMachine.Balloon.StartLocation = BalloonMachine.BalloonSpawnPoint.WorldLocation;
		BalloonMachine.HazeAkComp.HazePostEvent(BalloonMachine.InflateAudioEvent);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		float Scale = FMath::Clamp(ActiveDuration / InflateTime, 0.f, 1.f);
		BalloonMachine.Balloon.MeshRoot.SetRelativeScale3D(Scale);

		if (Scale >= 1.f)
			BalloonMachine.Balloon.bInflated = true;
	}
}