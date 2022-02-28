import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.CannonBallDamageableComponent;
import Peanuts.Health.HealthBarWidget;

class UPirateTowerHealthBarCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PirateTower");

	default CapabilityDebugCategory = n"GamePlay";

	AHazeActor Enemy;

	UCannonBallDamageableComponent CannonBallDamageableComponent;

	// Duration after being hit that an enemy shows their health bar
	UPROPERTY()
	float ShowHealthBarDuration = 7.f;

	// Offset relative to the enemy's actor location to show the health bar at
	UPROPERTY()
	FVector WidgetPositionOffset = FVector(0.f, 0.f, 310.f);

	TArray<UHealthBarWidget> Widgets;

	float ShowTimer = 0.f;

    // We save the health here, since this capability activates _after_ the health has changed
    //  and then we'll miss to show the lost health on the widget
    float PreviousHealth = 0.f;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<AHazeActor>(Owner);
		CannonBallDamageableComponent = UCannonBallDamageableComponent::Get(Owner);
       	CannonBallDamageableComponent.OnCannonBallHit.AddUFunction(this, n"OnTakeDamage");
		CannonBallDamageableComponent.OnExploded.AddUFunction(this, n"OnKilled");
		WidgetPositionOffset = CannonBallDamageableComponent.WidgetPositionOffset;

        PreviousHealth = CannonBallDamageableComponent.MaximumHealth;
    }

    UFUNCTION()
    void OnTakeDamage(FHitResult Hit)
    {
		ShowTimer = ShowHealthBarDuration;
    }

    UFUNCTION()
    void OnKilled()
    {
		ShowTimer = CannonBallDamageableComponent.HealthBarDisappearDelay;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (ShowTimer > 0.f)
            return EHazeNetworkActivation::ActivateLocal; 
        return EHazeNetworkActivation::DontActivate; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        if (ShowTimer <= 0.f)
            return EHazeNetworkDeactivation::DeactivateLocal; 
        return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		ShowWidgetForPlayer(SceneView::GetFullScreenPlayer());
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		for(auto Widget : Widgets)
        {
            auto Player = Widget.Player;
            auto Comp = UPirateShipPlayerHealthBarsComponent::GetOrCreate(Player);
            Comp.HideHealthBar(Widget);
        }

		Widgets.Empty();
    }

	void ShowWidgetForPlayer(AHazePlayerCharacter Player)
	{
		auto Comp = UPirateShipPlayerHealthBarsComponent::GetOrCreate(Player);
		auto Widget = Comp.ShowHealthBar(CannonBallDamageableComponent.HealthBarWidgetClass);
		Widget.AttachWidgetToComponent(Enemy.RootComponent);
		Widget.SetWidgetShowInFullscreen(true);
		Widget.SetWidgetRelativeAttachOffset(WidgetPositionOffset+FVector(0,0,100.0f));
        Widget.InitHealthBar(CannonBallDamageableComponent.MaximumHealth);
        Widget.SnapHealthTo(PreviousHealth);
		Widgets.Add(Widget);
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		ShowTimer -= DeltaTime;

		for (auto Widget : Widgets)
		{
            Widget.SetHealthAsDamage(CannonBallDamageableComponent.CurrentHealth);
            PreviousHealth = CannonBallDamageableComponent.CurrentHealth;
		}
    }
}