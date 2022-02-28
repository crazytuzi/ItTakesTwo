import Peanuts.Health.HealthBarWidget;

class AFlyingBombCoreHitbox : AHazeActor
{
	UPROPERTY()
	TSubclassOf<UHealthBarWidget> WidgetType;

	UPROPERTY(Meta = (MakeEditWidget))
	FVector HealthBarPosition;

	UPROPERTY()
	float CoreMaxHealth = 2.f;

	bool bHitboxEnabled = false;
	bool bHealthBarsHidden = false;

	TPerPlayer<UHealthBarWidget> HealthBars;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION()
	void EnableCoreHitbox()
	{
		for (auto Player : Game::Players)
		{
			HealthBars[Player] = Cast<UHealthBarWidget>(Player.AddWidget(WidgetType));
			HealthBars[Player].AttachWidgetToActor(this);
			HealthBars[Player].SetWidgetRelativeAttachOffset(HealthBarPosition);
			HealthBars[Player].InitHealthBar(CoreMaxHealth);
		}

		BP_EnableCoreHitbox();
		bHitboxEnabled = true;
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintEvent)
	void BP_EnableCoreHitbox() {}

	UFUNCTION()
	void DisableCoreHitbox()
	{
		for (auto Player : Game::Players)
		{
			if (HealthBars[Player] != nullptr)
			{
				if (HealthBars[Player].bIsAdded)
					Player.RemoveWidget(HealthBars[Player]);
				HealthBars[Player] = nullptr;
			}
		}

		BP_DisableCoreHitbox();
		bHitboxEnabled = false;
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	void HideCoreHealthbars()
	{
		bHealthBarsHidden = true;
	}
	
	UFUNCTION()
	void UnhideCoreHealthbars()
	{
		bHealthBarsHidden = false;
	}


	UFUNCTION(BlueprintEvent)
	void BP_DisableCoreHitbox() {}

	UFUNCTION()
	void SetHealth(float Health)
	{
		for (auto Player : Game::Players)
		{
			if (HealthBars[Player] != nullptr)
				HealthBars[Player].SetHealthAsDamage(Health);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto Player : Game::Players)
		{
			auto HealthBar = HealthBars[Player];
			if (HealthBar == nullptr)
				continue;

			bool bShow = true;
			if (bHealthBarsHidden)
				bShow = false;
			else if (!Player.IsAnyCapabilityActive(n"ClockworkBirdMounted"))
				bShow = false;

			if (HealthBar.bIsAdded != bShow)
			{
				if (bShow)
				{
					Player.AddExistingWidget(HealthBars[Player]);
					HealthBars[Player].AttachWidgetToActor(this);
					HealthBars[Player].SetWidgetRelativeAttachOffset(HealthBarPosition);
				}
				else
				{
					Player.RemoveWidget(HealthBars[Player]);
				}
			}
		}
	}
};