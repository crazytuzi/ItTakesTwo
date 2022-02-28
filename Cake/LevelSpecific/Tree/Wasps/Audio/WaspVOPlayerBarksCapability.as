import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Cake.LevelSpecific.Tree.Wasps.Health.WaspHealthComponent;
import Cake.LevelSpecific.Tree.Wasps.Settings.WaspComposableSettings;
import Cake.Weapons.Sap.SapResponseComponent;
import Cake.LevelSpecific.Tree.Wasps.Animation.WaspAnimationComponent;

class UWaspVOPlayerBarksCapability : UHazeCapability
{
	UWaspBehaviourComponent BehaviourComp;
	UWaspHealthComponent HealthComp;
	UWaspComposableSettings Settings;
	float SapHitCooldown = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComp = UWaspBehaviourComponent::Get(Owner);
		HealthComp = UWaspHealthComponent::Get(Owner);
		Settings = UWaspComposableSettings::GetSettings(Owner);

		HealthComp.OnDie.AddUFunction(this, n"OnDie");
		HealthComp.OnHitBySap.AddUFunction(this , n"OnHitBySap");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::DontActivate;
	}	

	UFUNCTION(NotBlueprintCallable)
	void OnHitBySap()
	{
		if ((HealthComp.SapMass >= Settings.SapAmountToStun) && 
			(Time::GameTimeSeconds > SapHitCooldown))
		{
			SapHitCooldown = Time::GameTimeSeconds + 5.f;
			PlayFoghornVOBankEvent(BehaviourComp.VOBankDataAsset, n"FoghornDBTreeSquirrelHomeSappedCombat", Game::Cody);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnDie(AHazeActor Wasp)
	{
		PlayFoghornVOBankEvent(BehaviourComp.VOBankDataAsset, n"FoghornDBTreeSquirrelHomeSappedCombatBoom", Game::May);	
		PlayFoghornVOBankEvent(BehaviourComp.VOBankDataAsset, n"FoghornDBTreeSquirrelHomeWaspKill", Game::May);
	}
}

class UWaspVOPlayerShieldWaspBarksCapability : UHazeCapability
{
	UWaspBehaviourComponent BehaviourComp;
	UWaspAnimationComponent AnimComp;
	UWaspHealthComponent HealthComp;

	float HintCooldown = 0.f;
	bool bHasBeenSuccessfullySapped = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComp = UWaspBehaviourComponent::Get(Owner);
		HealthComp = UWaspHealthComponent::Get(Owner);
		AnimComp = UWaspAnimationComponent::Get(Owner);
		USapResponseComponent SapReponseComp = USapResponseComponent::Get(Owner);
		SapReponseComp.OnHitNonStick.AddUFunction(this, n"OnHitNonStick");
		HealthComp.OnHitBySap.AddUFunction(this , n"OnHitBySap");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::DontActivate;
	}	

	UFUNCTION(NotBlueprintCallable)
	void OnHitBySap()
	{
		// If players have managed to sap wasp enough we don't need to give any more hints
		if (HealthComp.SapMass >= 2.f)
			bHasBeenSuccessfullySapped = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnHitNonStick(FSapAttachTarget Where, float Mass)
	{
		// Ignore further non-stick if players have already figured out how to sap us
		if (bHasBeenSuccessfullySapped)
			return;

		if (Time::GameTimeSeconds < HintCooldown)
			return;

		if (Where.Component == AnimComp.ShieldComp)
		{
			PlayFoghornVOBankEvent(BehaviourComp.VOBankDataAsset, n"FoghornDBTreeSquirrelHomeShieldWaspHint");	
			HintCooldown = Time::GameTimeSeconds + 10.f;
		}
	}
}
