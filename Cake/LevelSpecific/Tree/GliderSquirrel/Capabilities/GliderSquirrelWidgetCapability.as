import Cake.LevelSpecific.Tree.GliderSquirrel.GliderSquirrel;

class UGliderSquirrelWidgetCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GliderSquirrel");
	default CapabilityTags.Add(n"GliderSquirrelWidget");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 55;

	AGliderSquirrel Squirrel;
	UHealthBarWidget Widget;

	float HitTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Squirrel = Cast<AGliderSquirrel>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Squirrel.IsDead())
			return EHazeNetworkActivation::DontActivate;

		if (Squirrel.Health == Squirrel.MaxHealth)
			return EHazeNetworkActivation::DontActivate;

		if (HitTimer < 0.f)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Squirrel.IsDead())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (HitTimer < 0.f)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		auto May = Game::GetMay();
		Widget = Cast<UHealthBarWidget>(May.AddWidget(Squirrel.WidgetClass));
		Widget.InitHealthBar(Squirrel.MaxHealth);
		Widget.SnapHealthTo(Squirrel.Health);

		Squirrel.OnTakeDamage.AddUFunction(this, n"HandleTakeDamage");

		HitTimer = 5.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		auto May = Game::GetMay();
		May.RemoveWidget(Widget);
		Widget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Widget.SetHealthAsDamage(Squirrel.Health);
		Widget.SetWidgetWorldPosition(Squirrel.GetActorLocation()+ FVector::UpVector * 500.f);

		HitTimer -= DeltaTime;
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleTakeDamage()
	{
		HitTimer = 5.f;
	}
}