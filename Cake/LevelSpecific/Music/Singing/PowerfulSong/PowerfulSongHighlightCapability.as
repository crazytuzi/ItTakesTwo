import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongImpactComponent;
import Cake.LevelSpecific.Music.Singing.SingingComponent;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongPlayerUserComponent;

import void PowerfulSong_GatherImpacts(UPowerfulSongAbstractUserComponent, FPowerfulSongHitInfo&) from "Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongStatics";

UCLASS(Deprecated)
class UPowerfulSongHighlightCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	default CapabilityTags.Add(n"PowerfulSong");
	
	AHazePlayerCharacter Player;
	USingingComponent SingingComp;
	UPowerfulSongPlayerUserComponent SongUserComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SingingComp = USingingComponent::Get(Owner);
		SongUserComponent = UPowerfulSongPlayerUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FPowerfulSongHitInfo InHitInfo;
		PowerfulSong_GatherImpacts(SongUserComponent, InHitInfo);

		for(FPowerfulSongImpactLocationInfo ImpactInfo : InHitInfo.Impacts)
		{
			UDEPRECATED_PowerfulSongImpactComponent ImpactComp = Cast<UDEPRECATED_PowerfulSongImpactComponent>(ImpactInfo.ImpactComponent);
			if(ImpactComp == nullptr)
				continue;
			
			ImpactComp.WorldLocationTarget = ImpactInfo.ImpactLocation;
		}

		Player.UpdateActivationPointAndWidgets(UDEPRECATED_PowerfulSongImpactComponent::StaticClass());
	}
}
