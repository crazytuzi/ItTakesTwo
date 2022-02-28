import Cake.LevelSpecific.Music.KeyBird.KeyBird;

class UKeyBirdMoveToActionLocationCapability : UHazeCapability
{
	AKeyBird KeyBird;
	USteeringBehaviorComponent Steering;
	UKeyBirdSettings Settings;
	bool bCloseEnough = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		KeyBird = Cast<AKeyBird>(Owner);
		Steering = USteeringBehaviorComponent::Get(Owner);
		Settings = UKeyBirdSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(KeyBird.CurrentState != EKeyBirdState::MoveToActionLocation)
			return EHazeNetworkActivation::DontActivate;

		if(!KeyBird.HasActions())
			return EHazeNetworkActivation::DontActivate;

		if(!Steering.bEnableSeekBehavior)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(KeyBird.ActionLocationSettings != nullptr)
			KeyBird.ApplySettings(KeyBird.ActionLocationSettings, this, EHazeSettingsPriority::Override);

		bCloseEnough = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float DistanceToLocation = Steering.WorldLocation.DistSquared(Steering.Seek.SeekLocation);
		if(DistanceToLocation < FMath::Square(Settings.DistanceSlowdownScale.Y * 1.15f))
		{
			bCloseEnough = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(KeyBird.CurrentState != EKeyBirdState::MoveToActionLocation)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(bCloseEnough)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!Steering.bEnableSeekBehavior)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		KeyBird.ClearSettingsByInstigator(this);
		KeyBird.ConsumeActions();
	}
}
