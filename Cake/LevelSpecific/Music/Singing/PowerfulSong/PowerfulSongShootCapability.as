import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Music.Singing.SingingComponent;
import Vino.Characters.PlayerCharacter;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongImpactComponent;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongTags;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongInfo;

class UPowerfulSongShootCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"PowerfulSong");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	USingingComponent SingingComp;
	APlayerCharacter ShimmerPlayer;
    UPostProcessingComponent PostProcessingComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SingingComp = USingingComponent::GetOrCreate(Owner);
		ShimmerPlayer = Cast<APlayerCharacter>(Player);
        PostProcessingComp = UPostProcessingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsActioning(PowerfulSongTags::Shoot))
		{
			return EHazeNetworkActivation::ActivateUsingCrumb;
		}

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{

	}

	UFUNCTION(NetFunction)
	void NetApplyHits(FPowerfulSongHitInfo HitInfo)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SingingComp.DeactivatePowerfulSong();
		PostProcessingComp.SpeedShimmer = 0.f;

		Player.ClearFieldOfViewByInstigator(this);
	}
}
