import Peanuts.Health.BossHealthBarWidget;

event void FGreenhouseOnDamageTakenEvent(float DamageTaken);

UCLASS(Abstract)
class AGreenhouseHealthManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent, Attach = "Billboard")
	UTextRenderComponent ManagerText;
	default ManagerText.SetRelativeLocation(FVector(0, 0, 50.f));
	default ManagerText.SetText(FText::FromString("Greenhouse Health Manager"));
	default ManagerText.SetHorizontalAlignment(EHorizTextAligment::EHTA_Center);
	default ManagerText.SetVerticalAlignment(EVerticalTextAligment::EVRTA_TextCenter);
	default ManagerText.SetHiddenInGame(true);
	default ManagerText.XScale = 5;
	default ManagerText.YScale = 5;

	UPROPERTY(Category = "Widget")
	TSubclassOf<UBossHealthBarWidget> BossHealthbarWidgetClass;

	UPROPERTY(EditDefaultsOnly, Category = "Health")
    UBossHealthBarWidget GreenhouseHPWidget;

	UPROPERTY(Category = "Events")
	FGreenhouseOnDamageTakenEvent OnDamageTaken;

	UPROPERTY()
	float MaxHealth;

	UPROPERTY()
	float CurrentHealth;

	UFUNCTION()
	void Setup()
	{
		CreateWidget();
		OnDamageTaken.AddUFunction(this, n"HandleDamageTaken");
	}

	UFUNCTION()
	void CreateWidget()
	{
		CurrentHealth = MaxHealth;

		GreenhouseHPWidget = Cast<UBossHealthBarWidget>(Widget::AddFullscreenWidget(BossHealthbarWidgetClass, EHazeWidgetLayer::Gameplay));
		GreenhouseHPWidget.InitBossHealthBar(FText::FromString("CHANGE TO REGULAR"), MaxHealth);
	}

	UFUNCTION(BlueprintCallable)
	void HandleDamageTaken(float DamageTaken)
	{
		CurrentHealth = GreenhouseHPWidget.Health;
		GreenhouseHPWidget.SetHealthAsDamage(CurrentHealth);
		CheckHealth();
	}

	UFUNCTION(BlueprintEvent)
	void CheckHealth()
	{

	}
}
