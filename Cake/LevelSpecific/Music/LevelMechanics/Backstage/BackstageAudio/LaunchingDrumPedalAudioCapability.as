import Cake.LevelSpecific.Music.LevelMechanics.Backstage.LaunchingDrumPedal;
import Cake.LevelSpecific.Music.Singing.SongOfLife.SongOfLifeComponent;

class ULaunchingDrumPedalAudioCapability : UHazeCapability
{
	ADrumPedal DrumPedal;
	USongOfLifeComponent SongComp;

	int32 HitCounts = 0;
	float LastPhysValue = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		DrumPedal = Cast<ADrumPedal>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(DrumPedal.PlayerOnPedal.Num() <= 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		LastPhysValue = DrumPedal.PhysValue.UpperBound;
		DrumPedal.HazeAkComp.HazePostEvent(DrumPedal.OnPedalActivatedEvent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PrintToScreen(""+DrumPedal.PhysValue.Value);

		if(DidHitDrum(DrumPedal.PhysValue.Value) && HitCounts < 2)
		{
			HitCounts ++;

			UAkAudioEvent WantedHitEvent = HitCounts == 1 ? DrumPedal.OnKickPrimaryHitEvent : DrumPedal.OnKickSecondaryHitEvent;
			if(WantedHitEvent != nullptr)
			{
				UHazeAkComponent::HazePostEventFireForget(WantedHitEvent, DrumPedal.ConnectedBaseDrum.GetActorTransform());
			}
		}
		
		LastPhysValue = DrumPedal.PhysValue.Value;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(DrumPedal.PlayerOnPedal.Num() > 0)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		DrumPedal.HazeAkComp.HazePostEvent(DrumPedal.OnPedalDeactivatedEvent);
		HitCounts = 0.f;
		LastPhysValue = 0.f;
	}

	bool DidHitDrum(const float& CurrentPhysValue)
	{
		return DrumPedal.ConnectedBaseDrum != nullptr && CurrentPhysValue == 0;
	}


}