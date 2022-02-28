import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPlayerComp;

class UHockeyPlayerDashCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HockeyPlayerDashCapability");

	default CapabilityDebugCategory = n"GamePlay";
	default CapabilityDebugCategory = n"AirHockey";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UHockeyPlayerComp PlayerComp;

	UHazeCameraUserComponent UserComp;

	bool bResetDash;

	float StartingSpeed;

	FHazeAcceleratedFloat AcceleratedDashFloat;

	float Timer;
	float DashTime = 0.25f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UHockeyPlayerComp::Get(Player);
		UserComp = UHazeCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// if (WasActionStarted(ActionNames::PrimaryLevelAbility) /*&& !bResetDash*/)
	    //     return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// if (bResetDash)
		// 	return EHazeNetworkDeactivation::DeactivateLocal;

		// if (WasActionStopped(ActionNames::PrimaryLevelAbility))
		// 	return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AcceleratedDashFloat.SnapTo(1.f);
		StartingSpeed = PlayerComp.HockeyPaddle.MovementSpeed;
		Print("StartingSpeed: " + StartingSpeed);
		// Timer = DashTime;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// bResetDash = false;
		
		//Only set if startingspeed was initiated
		if (StartingSpeed > 0.f)
			PlayerComp.HockeyPaddle.MovementSpeed = StartingSpeed;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		// bResetDash = false;
		
		//Only set if startingspeed was initiated
		if (StartingSpeed > 0.f)
			PlayerComp.HockeyPaddle.MovementSpeed = StartingSpeed;
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Timer -= DeltaTime;

		AcceleratedDashFloat.AccelerateTo(2.2f, DashTime, DeltaTime);
		PlayerComp.HockeyPaddle.MovementSpeed = StartingSpeed * AcceleratedDashFloat.Value;

		// if (Timer <= 0.f)
		// 	bResetDash = true;
	}
}