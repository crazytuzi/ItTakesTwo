import Cake.LevelSpecific.Tree.Queen.QueenArmorComponentHandler;

class UQueenHealthBarComponent : UActorComponent
{
	UQueenArmorComponentHandler ArmorHandler;
	UBossHealthBarWidget BossHealth;
	bool bDrawHealth;

	UFUNCTION()
	void Setup()
	{
		ArmorHandler = UQueenArmorComponentHandler::Get(Owner);
		CreateWidget();
	}

	UFUNCTION()
	void CreateWidget()
	{
		BossHealth = Cast<UBossHealthBarWidget>(Widget::AddFullscreenWidget(ArmorHandler.BossHealthbarWidgetClass, EHazeWidgetLayer::Gameplay));

		float Health = 0;
		float MaxHealth = 0;

		for (UQueenArmorComponent ArmorComp : ArmorHandler.TotalArmorComponents)
		{
			Health += ArmorComp.HP;
			MaxHealth += ArmorComp.MaxHealth;
		}

		BossHealth.InitBossHealthBar(NSLOCTEXT("BossHealthBarName", "WaspQueen", "Wasp Queen"), MaxHealth);
		BossHealth.SnapHealthTo(Health);
	}

	UFUNCTION()
	void SetHealthbarForPhase3()
	{
		
		float Health = 0;
		for (UQueenArmorComponent Armorcomp : ArmorHandler.TotalArmorComponents)
		{
			if(Armorcomp.bIsEndingArmor)
			{
				Health += Armorcomp.MaxHealth;
			}
		}

		bDrawHealth = true;
		BossHealth.Health = Health;
	}

	UFUNCTION()
	void HandleDamageTaken(
		FVector HitLocation,
		USceneComponent HitComponent,
		FName HitSocket,
        float DamageTaken)
	{
		BossHealth.TakeDamage(DamageTaken);

		float Health = 0;
		for (UQueenArmorComponent Armorcomp : ArmorHandler.TotalArmorComponents)
		{
			Health += Armorcomp.HP;
		}

		if(!ArmorHandler.HasControl())
		{
			Health = FMath::Clamp(Health, 1, 999999);
		}

		BossHealth.Health = Health;
	}
}