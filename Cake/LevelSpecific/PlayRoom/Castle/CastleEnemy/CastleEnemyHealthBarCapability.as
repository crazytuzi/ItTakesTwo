import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Peanuts.Health.HealthBarWidget;

class UCastlePlayerHealthBarsComponent : UActorComponent
{
    TArray<UHealthBarWidget> AvailablePool;

    UHealthBarWidget ShowHealthBar(TSubclassOf<UHealthBarWidget> WidgetClass)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
        UHealthBarWidget Widget;
        if (AvailablePool.Num() != 0)
        {
            for (auto ExistingWidget : AvailablePool)
            {
                if (ExistingWidget.Class == WidgetClass.Get())
                {
                    Widget = ExistingWidget;
                    break;
                }
            }

            if (Widget != nullptr)
            {
                AvailablePool.Remove(Widget);
                Player.AddExistingWidget(Widget);
            }
        }

        if (Widget == nullptr)
            Widget = Cast<UHealthBarWidget>(Player.AddWidget(WidgetClass.Get()));

        return Widget;
    }

    void HideHealthBar(UHealthBarWidget Widget)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
        Player.RemoveWidget(Widget);
        AvailablePool.Add(Widget);
    }
};

class UCastleEnemyHealthBarCapability : UHazeCapability
{
    ACastleEnemy Enemy;

	// Duration after being hit that an enemy shows their health bar
	UPROPERTY()
	float ShowHealthBarDuration = 3.f;

	// Class of health bar widget to show
	UPROPERTY()
	TSubclassOf<UHealthBarWidget> WidgetClass;
    TPerPlayer<UHealthBarWidget> Widgets;

	float ShowTimer = 0.f;

    // We save the health here, since this capability activates _after_ the health has changed
    //  and then we'll miss to show the lost health on the widget
    float PreviousHealth = 0.f;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
        Enemy.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
		Enemy.OnKilled.AddUFunction(this, n"OnKilled");
		Enemy.OnHealthChanged.AddUFunction(this, n"OnHealthChanged");

        PreviousHealth = Enemy.MaxHealth;
    }

    UFUNCTION()
    void OnTakeDamage(ACastleEnemy DamagedEnemy, FCastleEnemyDamageEvent Event)
    {
		ShowTimer = ShowHealthBarDuration;
    }

    UFUNCTION()
    void OnHealthChanged(ACastleEnemy DamagedEnemy)
    {
		ShowTimer = ShowHealthBarDuration;
    }

    UFUNCTION()
    void OnKilled(ACastleEnemy DamagedEnemy, bool bKilledByDamage)
    {
		ShowTimer = 0.f;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if (Enemy.Health <= 0.f || Enemy.bKilled)
			return EHazeNetworkActivation::DontActivate;

		if (Enemy.bUnhittable)
			return EHazeNetworkActivation::DontActivate;

		if (!Enemy.bShowHealthBar)
			return EHazeNetworkActivation::DontActivate;

		if (!Enemy.bAlwaysShowHealthBar && ShowTimer <= 0.f)
			return EHazeNetworkActivation::DontActivate;

		if (!Enemy.bShowHeathBarWhenEnemyNotRendered && !Enemy.WasRecentlyRendered(1.f))
			return EHazeNetworkActivation::DontActivate;

		if (Enemy.IsActorDisabled())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        if (Enemy.bCanDie && Enemy.Health <= 0.f || Enemy.bKilled)
            return EHazeNetworkDeactivation::DeactivateLocal;

        if (Enemy.bUnhittable)
            return EHazeNetworkDeactivation::DeactivateLocal;

		if (!Enemy.bAlwaysShowHealthBar && ShowTimer <= 0.f)
            return EHazeNetworkDeactivation::DeactivateLocal;

		if (!Enemy.bShowHeathBarWhenEnemyNotRendered && !Enemy.WasRecentlyRendered(1.f))
            return EHazeNetworkDeactivation::DeactivateLocal;

		if (Enemy.IsActorDisabled())
            return EHazeNetworkDeactivation::DeactivateLocal;

        return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		if (SceneView::IsFullScreen())
		{
			ShowWidgetForPlayer(SceneView::GetFullScreenPlayer());
		}
		else
		{
			for (auto Player : Game::GetPlayers())
				ShowWidgetForPlayer(Player);
		}
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
        for(auto Player : Game::Players)
        {
            auto Widget = Widgets[Player];
            if (Widget == nullptr)
                continue;

            auto Comp = UCastlePlayerHealthBarsComponent::GetOrCreate(Player);
            Comp.HideHealthBar(Widget);
        }
    }

	void ShowWidgetForPlayer(AHazePlayerCharacter Player)
	{
		auto Comp = UCastlePlayerHealthBarsComponent::GetOrCreate(Player);
		auto Widget = Comp.ShowHealthBar(WidgetClass);
		Widget.SetWidgetPersistent(true);
		Widget.AttachWidgetToComponent(Enemy.Mesh);
		Widget.SetWidgetRelativeAttachOffset(FVector(0.f, 0.f, Enemy.CapsuleComponent.ScaledCapsuleHalfHeight));
        Widget.InitHealthBar(Enemy.MaxHealth);
        Widget.SnapHealthTo(PreviousHealth);
        Widget.SetBarSize(Enemy.bSmallHealthBar ? EHealthBarSize::Small : EHealthBarSize::Normal);
		Widget.SetScreenSpaceOffset(Enemy.HealthBarScreenspaceOffset);
		Widgets[Player] = Widget;
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		ShowTimer -= DeltaTime;

		for (auto Widget : Widgets)
		{
            if (Widget == nullptr)
                continue;

            Widget.SetHealthAsDamage(Enemy.Health);
		}

        PreviousHealth = Enemy.Health;
    }
};