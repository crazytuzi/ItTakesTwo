import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Settings.FishComposableSettings;
import Vino.Checkpoints.Statics.DeathStatics;
import Peanuts.Fades.FadeStatics;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Effects.FishEffectsComponent;

class UFishSwallowPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Swallow");

	default TickGroup = ECapabilityTickGroups::LastMovement;

	UFishBehaviourComponent BehaviourComp;
	UFishEffectsComponent EffectsComp;	
	UFishComposableSettings Settings;
	float SwallowTime;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComp = UFishBehaviourComponent::Get(Owner);
		Settings = UFishComposableSettings::GetSettings(Owner);
		EffectsComp = UFishEffectsComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.Food.Num() == 0)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Time::GetGameTimeSeconds() > SwallowTime)
            return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		// Digest first one or two food
		if (ensure(BehaviourComp.Food.Num() > 0) && BehaviourComp.IsValidTarget(BehaviourComp.Food[0]))
			ActivationParams.AddObject(n"Dinner", BehaviourComp.Food[0]);
		if ((BehaviourComp.Food.Num() > 1) && BehaviourComp.IsValidTarget(BehaviourComp.Food[1]))
			ActivationParams.AddObject(n"Dessert", BehaviourComp.Food[1]);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwallowTime = Time::GetGameTimeSeconds() + 0.5f;

		// Clear POI from us on both players (we might have switched target)
		Game::GetMay().ClearPointOfInterestByInstigator(BehaviourComp);	
		Game::GetCody().ClearPointOfInterestByInstigator(BehaviourComp);	

		AHazePlayerCharacter Dinner = Cast<AHazePlayerCharacter>(ActivationParams.GetObject(n"Dinner"));
		if (Dinner != nullptr)
			KillPlayer(Dinner, BehaviourComp.PlayerDeathEffect);	

		AHazePlayerCharacter Dessert = Cast<AHazePlayerCharacter>(ActivationParams.GetObject(n"Dessert"));
		if (Dessert != nullptr)
			KillPlayer(Dessert, BehaviourComp.PlayerDeathEffect);	

		BehaviourComp.Food.Empty();
  	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Deactivate mouth cam for both players (we might have switched target)
		Game::GetMay().DeactivateCameraByInstigator(BehaviourComp);	
		Game::GetCody().DeactivateCameraByInstigator(BehaviourComp);	
		if ((BehaviourComp.State != EFishState::Attack) || (BehaviourComp.State != EFishState::Combat))
			EffectsComp.SetEffectsMode(EFishEffectsMode::Idle);
	}
}