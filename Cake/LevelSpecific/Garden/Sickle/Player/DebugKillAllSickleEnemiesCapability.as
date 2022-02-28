import Vino.Control.DebugShortcutsEnableCapability;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;

class UDebugKillAllSickleEnemiesCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(CapabilityTags::Debug);

	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 1;

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"KillAllEnemies", "Kill All Sickle Enemies");
		Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadUp, n"GardenCombat");
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

	UFUNCTION(NotBlueprintCallable)
	void KillAllEnemies()
	{
		if(IsBlocked())
			return;
			
		if(PlayerOwner.HasControl())
		{
			NetKillAllEnemies();
		}	
	}

	UFUNCTION(NetFunction)
	void NetKillAllEnemies()
	{
		TArray<AActor> FoundActors;
		Gameplay::GetAllActorsOfClass(ASickleEnemy::StaticClass(), FoundActors);
		for(int i = 0; i < FoundActors.Num(); ++i)
		{
			auto Enemy = Cast<ASickleEnemy>(FoundActors[i]);
			Enemy.ManuallyKillEnemy();
		}
	}
};



