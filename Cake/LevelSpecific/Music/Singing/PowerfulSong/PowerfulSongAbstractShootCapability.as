import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongTags;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongImpactComponent;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongProjectile;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongAbstractUserComponent;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongSpeakerBlast;

import void PowerfulSong_GatherImpacts(UPowerfulSongAbstractUserComponent, FPowerfulSongHitInfo&) from "Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongStatics";
import Cake.LevelSpecific.Music.Singing.SongReactionComponent;

// Capability that can be used by anything to utilize PowerfulSong

class UPowerfulSongAbstractShootCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";

	default CapabilityDebugCategory = n"LevelSpecific";
	default CapabilityTags.Add(n"PowerfulSong");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	UPowerfulSongAbstractUserComponent SongUserComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SongUserComponent = UPowerfulSongAbstractUserComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!SongUserComponent.bWantsToShoot)
		{
			return EHazeNetworkActivation::DontActivate;
		}

		if(!SongUserComponent.ProjectileClass.IsValid())
		{
			return EHazeNetworkActivation::DontActivate;
		}

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		FPowerfulSongHitInfo InHitInfo;
		PowerfulSong_GatherImpacts(SongUserComponent, InHitInfo);

		FPowerfulSongInfo Info;
		Info.Direction = SongUserComponent.GetPowerfulSongForward();
		Info.Instigator = Owner;

		ActivationParams.AddVector(n"FacingDirection", Info.Direction);
		
		for(FPowerfulSongImpactLocationInfo ImpactInfo : InHitInfo.Impacts)
		{
			Info.ImpactLocation = ImpactInfo.ImpactLocation;
			USongReactionComponent ImpactComp = Cast<USongReactionComponent>(ImpactInfo.ImpactComponent);
			if(ImpactComp == nullptr)
				continue;
			
			ImpactComp.NetPowerfulSongImpact(Info);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// No need to keep track of this Actor as it will destroy itself soon. Visual stuff only.
		APowerfulSongSpeakerBlast SpeakerProjectile = Cast<APowerfulSongSpeakerBlast>(SpawnActor(SongUserComponent.ProjectileClass, SongUserComponent.WorldLocation, ActivationParams.GetVector(n"FacingDirection").Rotation()));
		SongUserComponent.bWantsToShoot = false;
	}
}
