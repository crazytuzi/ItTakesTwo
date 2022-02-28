import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdKeepAboveVolume;

class UClockworkBirdLaunchCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"ClockworkBirdLaunch");
	default CapabilityTags.Add(n"ClockworkBirdFlying");

	default CapabilityDebugCategory = n"ClockworkBirdFlying";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	AClockworkBird Bird;

	UHazeMovementComponent MoveComp;
	float Timer = 0.f;
	float Cooldown = 0.f;
	UClockworkBirdFlyingSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Bird = Cast<AClockworkBird>(Owner);
		
		MoveComp = UHazeMovementComponent::Get(Bird);
		Settings = UClockworkBirdFlyingSettings::GetSettings(Bird);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Bird.bIsFlying || Bird.bIsLanding)
			return EHazeNetworkActivation::DontActivate;
		if (Cooldown > 0.f)
			return EHazeNetworkActivation::DontActivate;
		if (Bird.ActivePlayer == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if ((!WasActionStarted(ClockworkBirdTags::ClockworkBirdJumping) && !IsActioning(n"LaunchBirdFromPerch"))
			&& !ShouldAutoLaunch()
			&& !(IsActioning(n"LaunchBirdAfterLand") && Bird.bPlayerStartedAnimating))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Timer >= Settings.LaunchDuration)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (!Bird.bIsFlying || Bird.bIsLanding)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Timer = 0.f;
		Cooldown = Settings.LaunchDuration;

		Bird.SetIsFlying(true);
		Bird.DidSecondJump(true);
		Bird.SetCapabilityActionState(ClockworkBirdTags::ClockworkBirdLaunch, EHazeActionState::Active);
		Bird.bIsLaunching = true;

		ConsumeAction(n"LaunchBirdAfterLand");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Bird.DidSecondJump(false);
		Bird.SetCapabilityActionState(ClockworkBirdTags::ClockworkBirdLaunch, EHazeActionState::Inactive);
		Bird.bIsLaunching = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		Timer += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		Cooldown -= DeltaTime;
	}

	bool ShouldAutoLaunch() const
	{
		TArray<AActor> InsideActors;
		Bird.GetOverlappingActors(InsideActors);

		for (auto Actor : InsideActors)
		{
			if (Cast<AClockworkBirdKeepAboveVolume>(Actor) != nullptr)
				return true;
		}

		return false;
	}
}