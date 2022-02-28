import Cake.LevelSpecific.Music.Singing.SingingComponent;
import Cake.LevelSpecific.Music.Singing.SongOfLife.SongOfLifeComponent;

/*
	Enables points that can be triggered by song of life despite being behind the camera.
*/

class USingingTargetingCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 40;
	
	USingingComponent SingingComp;
	USingingSettings Settings;
	USongOfLifeContainerComponent SongContainer;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SingingComp = USingingComponent::Get(Owner);
		SongContainer = USongOfLifeContainerComponent::GetOrCreate(Owner);
		Settings = USingingSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float SingingRangeSq = FMath::Square(Settings.SongOfLifeRange);
		for(USongOfLifeComponent SongComp : SongContainer.SongOfLifeCollection)
		{
			if(SongComp == nullptr)
				continue;
			if(SongComp.IsBeingDestroyed())
				continue;

			const bool bWasValid = SongComp.bSongOfLifeInRange;
			const float DistanceToReactionSq = Owner.ActorCenterLocation.DistSquared(SongComp.WorldLocation);
			const bool bValid = DistanceToReactionSq < SingingRangeSq;
			SongComp.bSongOfLifeInRange = bValid;

			// Add vfx to this point if we detect something new.
			if(!bWasValid && bValid)
			{
				SingingComp.AddOrGetVFX(SongComp);
			}
		}

		Player.UpdateActivationPointAndWidgets(USongOfLifeComponent::StaticClass());
	}
}
