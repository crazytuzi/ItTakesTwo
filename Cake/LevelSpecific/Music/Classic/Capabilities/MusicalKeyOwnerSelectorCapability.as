import Cake.LevelSpecific.Music.Classic.MusicalFollowerKey;
import Cake.SteeringBehaviors.SteeringBehaviorComponent;
import Cake.LevelSpecific.Music.Classic.MusicKeyComponent;


class UMusicalKeyOwnerSelectorCapability : UHazeCapability
{
	AMusicalFollowerKey Key;
	USteeringBehaviorComponent Steering;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Key = Cast<AMusicalFollowerKey>(Owner);
		Steering = USteeringBehaviorComponent::Get(Owner);
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(Key.KeyOwner != nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(Key.WantedOwnerList.Num() == 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"WantedOwner", Key.WantedOwnerList[0]);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AHazeActor WantedOwner = Cast<AHazeActor>(ActivationParams.GetObject(n"WantedOwner"));
		Key.KeyOwner = WantedOwner;
		Key.WantedOwnerList.Empty();
		Steering.Follow.FollowTarget = WantedOwner;
		Steering.bEnableFollowBehavior = true;
		Steering.bEnableAvoidanceBehavior = false;
		UMusicKeyComponent KeyComp = UMusicKeyComponent::Get(WantedOwner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}
}
