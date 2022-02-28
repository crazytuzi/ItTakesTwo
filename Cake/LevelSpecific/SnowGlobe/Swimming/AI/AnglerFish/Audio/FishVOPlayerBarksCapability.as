import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Settings.FishComposableSettings;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Audio.FishAudioComponent;

class UFishVOPlayerBarksCapability : UHazeCapability
{
	UFishBehaviourComponent BehaviourComp;
	UFishAudioComponent AudioComp;
	UFishComposableSettings Settings;
	AHazePlayerCharacter LastTarget = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComp = UFishBehaviourComponent::Get(Owner);
		AudioComp = UFishAudioComponent::Get(Owner);
		Settings = UFishComposableSettings::GetSettings(Owner);

		BehaviourComp.OnSpotTarget.AddUFunction(this, n"OnSpotTarget");
	}

	UFUNCTION(NotBlueprintCallable)
	void OnSpotTarget(AHazeActor Target)
	{
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(Target);
		if (PlayerTarget != nullptr)
			LastTarget = PlayerTarget; 
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (LastTarget == nullptr)
			return EHazeNetworkActivation::DontActivate;

		// We have a new target
		return EHazeNetworkActivation::ActivateLocal;
	}	

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// Deactivate if attack was successful
		if (IsPlayerDead(Game::Cody) || IsPlayerDead(Game::May))
			return EHazeNetworkDeactivation::DeactivateLocal;

		// Deactivate when attack is over
		if (BehaviourComp.State == EFishState::Recover)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// We have spotted food. Food may now panic.
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(BehaviourComp.Target);
		if (Player == nullptr)
			return;

		LastTarget = Player;
		if (Player.IsMay())
			PlayFoghornVOBankEvent(AudioComp.VOBankDataAsset, n"FoghornDBSnowGlobeLakeAnglerFishAggroMay", Player);	
		else
			PlayFoghornVOBankEvent(AudioComp.VOBankDataAsset, n"FoghornDBSnowGlobeLakeAnglerFishAggroCody", Player);	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AHazePlayerCharacter Target = LastTarget;
		LastTarget = nullptr;
		if (IsPlayerDead(Game::Cody) || IsPlayerDead(Game::May))
			return;

		// We've completed an attack without eating any players
		if (Target.IsMay())
			PlayFoghornVOBankEvent(AudioComp.VOBankDataAsset, n"FoghornDBSnowGlobeLakeAnglerFishPostAggroMay", Target);	
		else
			PlayFoghornVOBankEvent(AudioComp.VOBankDataAsset, n"FoghornDBSnowGlobeLakeAnglerFishPostAggroCody", Target);	
	}
}
