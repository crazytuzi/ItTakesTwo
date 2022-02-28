import Cake.LevelSpecific.Music.LevelMechanics.Classic.FollowCloud.FollowCloudSettings;
import Cake.LevelSpecific.Music.Singing.SongReactionComponent;

class UFollowCloudSongReactionCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	
	default TickGroup = ECapabilityTickGroups::GamePlay;

	USongReactionComponent SongReactionComp;
	UFollowCloudSettings Settings;
	bool bAffectedBySong = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Settings = UFollowCloudSettings::GetSettings(Owner);
		SongReactionComp = USongReactionComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(bAffectedBySong == false)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bAffectedBySong == false)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(n"FollowCloudOutOfBounds", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(n"FollowCloudOutOfBounds", this);
	}

	UFUNCTION()
	void StartAffectedBySongOfLife(FSongOfLifeInfo Info)
	{
		bAffectedBySong = true;
	}
	UFUNCTION()
	void StopAffectedBySongOfLife(FSongOfLifeInfo Info)
	{
		bAffectedBySong = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		/*
		FVector MayLocation = Game::GetMay().GetActorLocation();	
		FVector CloudLocation = Owner.GetActorLocation();
		if (!MayLocation.IsNear(CloudLocation, 1750.f))
		{
			FVector ToMayDirection = (MayLocation - CloudLocation).GetSafeNormal();
			Owner.AddImpulse(ToMayDirection * Settings.SongOfLifeForce);
		}
		*/
	}
}
