import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.Control.DebugShortcutsEnableCapability;

class UDebugGodModeCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(n"Debug");
	default CapabilityDebugCategory = n"Debug";

	EGodMode CurrentValue = EGodMode::Mortal;

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"SetHealthMode", "Toggle God/Jesus Mode");
		Handler.AddAlwaysValidButton(EHazeDebugAlwaysValidButtonType::F7);
		Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, Handler.DefaultActiveCategory);
	}

	UFUNCTION()
	void SetHealthMode()
	{
		switch(GetValue())
		{
			case EGodMode::Mortal:
				SetValue(EGodMode::Jesus);
			break;
			case EGodMode::Jesus:
				SetValue(EGodMode::God);
			break;
			case EGodMode::God:
				SetValue(EGodMode::Mortal);
			break;
		}
	}

	// Enum values are stored in the CDO, so they persist through PIE sessions
	void SetValue(EGodMode NewValue)
	{
		auto CDO = Cast<UDebugGodModeCapability>(UDebugGodModeCapability::StaticClass().DefaultObject);
		CDO.CurrentValue = NewValue;

		for (auto Player : Game::GetPlayers())
		{
			auto HealthComp = UPlayerHealthComponent::Get(Player);
			HealthComp.GodMode = NewValue;
		}
	}

	EGodMode GetValue()
	{
		 auto CDO = Cast<UDebugGodModeCapability>(UDebugGodModeCapability::StaticClass().DefaultObject);
		 return CDO.CurrentValue;
	}

    UFUNCTION(BlueprintOverride)
    void PreTick(float DeltaTime)
	{
		auto HealthComp = UPlayerHealthComponent::Get(Owner);
		if (HealthComp == nullptr)
			return;

		auto GodModeValue = GetValue();
		HealthComp.GodMode = GodModeValue;

		// Display if we have a special godmode active
		if (Owner == Game::GetMay())
		{
			if (GodModeValue == EGodMode::God)
				PrintToScreen("GOD MODE", Color = FLinearColor::Green);
			else if (GodModeValue == EGodMode::Jesus)
				PrintToScreen("JESUS MODE", Color = FLinearColor::Yellow);
		}
	}
};