import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Settings.FishComposableSettings;
import Vino.Checkpoints.Statics.DeathStatics;
import Peanuts.Fades.FadeStatics;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Effects.FishEffectsComponent;

class UFishTryToEatPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Swallow");

	default TickGroup = ECapabilityTickGroups::LastMovement;

	UFishBehaviourComponent BehaviourComp;
	UFishEffectsComponent EffectsComp;	
	UHazeCrumbComponent CrumbComp;
	UFishComposableSettings Settings;
	float SwallowTime;
	TSet<AHazeActor> DigestingFood;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComp = UFishBehaviourComponent::Get(Owner);
		Settings = UFishComposableSettings::GetSettings(Owner);
		EffectsComp = UFishEffectsComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);		
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
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwallowTime = Time::GetGameTimeSeconds() + 1.2f;
		DigestingFood.Empty();
  	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if ((BehaviourComp.State != EFishState::Attack) || (BehaviourComp.State != EFishState::Combat))
			EffectsComp.SetEffectsMode(EFishEffectsMode::Idle);
		BehaviourComp.Food.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Check if there is food to digest
		TArray<AHazePlayerCharacter> Targets = Game::GetPlayers();
		for (AHazePlayerCharacter Target : Targets)
		{
			if (DigestingFood.Contains(Target))
				continue;
			if (BehaviourComp.CanHitTarget(Target, Settings.AttackRunHitRadius, 0.f))
			{
				UHazeCrumbComponent HitCrumbComp = HasControl() ? CrumbComp : UHazeCrumbComponent::Get(Target);
				FHazeDelegateCrumbParams CrumbParams;
				CrumbParams.AddObject(n"Food", Target);
				HitCrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbSwallow"), CrumbParams);
				DigestingFood.Add(Target);				
			}
		}
	}

	UFUNCTION()
	void CrumbSwallow(const FHazeDelegateCrumbData& CrumbParams)
	{
		AHazePlayerCharacter Food = Cast<AHazePlayerCharacter>(CrumbParams.GetObject(n"Food"));
		if (ensure(Food != nullptr))
			KillPlayer(Food, BehaviourComp.PlayerDeathEffect);	
	}
}