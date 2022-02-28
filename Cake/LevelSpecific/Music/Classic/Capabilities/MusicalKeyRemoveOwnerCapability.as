import Cake.LevelSpecific.Music.Classic.MusicalFollowerKey;
import Cake.LevelSpecific.Music.Classic.MusicKeyComponent;

/*
	Runs on the key and checks if it has a target to follow, if the taret is somehow disabled or dead it will remove itself from that key list.
*/

class UMusicalKeyRemoveOwnerCapability : UHazeCapability
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
		if(Key.KeyOwner == nullptr)
			return EHazeNetworkActivation::DontActivate;

		UMusicKeyComponent KeyComp = UMusicKeyComponent::Get(Key.KeyOwner);

		if(KeyComp == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!KeyComp.IsOwnerDisabled())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UMusicKeyComponent KeyComp = UMusicKeyComponent::Get(Key.KeyOwner);
		KeyComp.RemoveKey(Key);
		Steering.Follow.FollowTarget = nullptr;
		Steering.bEnableAvoidanceBehavior = true;
		Steering.bEnableFollowBehavior = false;
		Key.KeyOwner = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}
}
