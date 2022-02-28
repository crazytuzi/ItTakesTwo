
import Vino.Control.DebugShortcutsEnableCapability;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;

class UDebugShowCombatAreaInfo : UHazeDebugCapability
{
	default CapabilityTags.Add(CapabilityTags::Debug);

	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 1;

	AHazePlayerCharacter PlayerOwner;
	TArray<ASickleEnemyMovementArea> Areas;
	bool bWantToShowInfos = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"ShowCombatInfo", "Show the current combat info");
		Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"GardenCombat");
	}

	UFUNCTION(NotBlueprintCallable)
	void ShowCombatInfo()
	{
		bWantToShowInfos = !bWantToShowInfos;	
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(bWantToShowInfos)
			return EHazeNetworkActivation::ActivateLocal;
		
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bWantToShowInfos)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(Areas.Num() == 0)
		{
			GetAllActorsOfClass(Areas);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(auto Area : Areas)
		{
			if(Area == nullptr)
				continue;
			if(Area.PlayersInArea.Num() == 0)
				continue;
			Area.DrawDebug(true);
		}
	}

};