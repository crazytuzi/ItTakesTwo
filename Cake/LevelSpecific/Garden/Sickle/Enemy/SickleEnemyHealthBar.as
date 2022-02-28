import Peanuts.Health.HealthBarWidget;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;


class USickleEnemyCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HealthWidget");

	// Class of health bar widget to show
	UPROPERTY()
	TSubclassOf<UHealthBarWidget> WidgetClass;

	USickleCuttableHealthComponent HealthComponent;

	TPerPlayer<UHealthBarWidget> Widgets;
	ASickleEnemy EnemyOwner;

	UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
	 	EnemyOwner = Cast<ASickleEnemy>(Owner);

        HealthComponent = EnemyOwner.SickleCuttableComp;
   
	 	TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
 		for(auto Player : Players)
		{
			UHealthBarWidget Widget = Cast<UHealthBarWidget>(Widget::CreateWidget(nullptr, WidgetClass.Get()));
			Widget.InitHealthBar(HealthComponent.MaxHealth);
			Widgets[Player] = Widget;
		}
    }

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		for(auto Player : Game::Players)
        {
            Player.RemoveWidget(Widgets[Player]);
            Widgets[Player] = nullptr;
        }
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(HealthComponent == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {	
		for(auto Player : Game::Players)
		{
			auto Widget = Widgets[Player];
			Player.AddExistingWidget(Widget);
			Widget.SetWidgetPersistent(true);
			Widget.AttachWidgetToComponent(EnemyOwner.Mesh);
			Widget.SetWidgetRelativeAttachOffset(EnemyOwner.HealthBarPositionOffset);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		for(auto Player : Game::Players)
		{
			auto Widget = Widgets[Player];
			Player.RemoveWidget(Widget);
		}
	}  

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(auto Widget : Widgets)
		{
			const float CurrentHealth = HealthComponent.Health;
			const float MaxHealth = HealthComponent.MaxHealth;
			Widget.SetHealthAsDamage(CurrentHealth);
		}	
	}
}