import Peanuts.Audio.AudioStatics;
import Vino.Audio.Capabilities.AudioTags;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleComponent;

class UCastleDungeonPlayerAudioCapabilityBase : UHazeCapability
{
	UPROPERTY()
	UAkAudioEvent OnPlayerTakeDamage;

	AHazePlayerCharacter Player;
	UCastleComponent CastleComponent;
	default CapabilityTags.Add(AudioTags::FallingAudioBlocker);

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CastleComponent = UCastleComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CastleComponent.OnDamageTaken.AddUFunction(this, n"OnCastlePlayerTakeDamage");
	}

	UFUNCTION()
	void OnCastlePlayerTakeDamage(AHazePlayerCharacter Player, FCastlePlayerDamageEvent DamageEvent)
	{
		Player.PlayerHazeAkComp.HazePostEvent(OnPlayerTakeDamage);
	}
}