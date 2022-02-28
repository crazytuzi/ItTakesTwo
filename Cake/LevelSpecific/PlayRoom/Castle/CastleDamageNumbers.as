import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

class UCastleDamageNumberWidget : UHazeUserWidget
{
    UPROPERTY(BlueprintReadOnly, NotEditable)
    int DamageValue = 0;

    UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bIsCritical = false;

    UPROPERTY(BlueprintReadOnly, NotEditable)
    FVector DamageLocation;

    UPROPERTY(BlueprintReadOnly, NotEditable)
    FVector2D DamageLocationSpawnArea = FVector2D(80, 20);

    UPROPERTY(BlueprintReadOnly, NotEditable)
    FVector DamageDirection;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    float DamageSpeed;

    UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bDamagedPlayer = false;

	/* Which player is involved in the event (doing on taking damage) */
    UPROPERTY(BlueprintReadOnly, NotEditable)
	EHazePlayer InvolvedPlayer = EHazePlayer::MAX;

    /* Configured speed that the damage number should move sideways. */
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
    const float SidewaysSpeed = 200.f;

    /* Configured speed that the damage number should move up with initially. */
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
    const float UpwardsSpeed = 800.f;

	/* Configured speed that the damage number should move up with initially. */
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
    const float UpwardsSpeedCritical = 200.f;

    /* Configured downwards pull of gravity. */
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
    const float Gravity = 1500.f;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
    const float Drag = 3.f;

    /* Configured duration that the widget shows for. */
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
    const float Duration = 0.75f;

	const float AttributePercentageVariance = 0.2f;

    FVector CurrentPosition;
    FVector CurrentVelocity;

	UPROPERTY()
	float CriticalDuration = 2.f;
	UPROPERTY()
    float TimeRemaining = 0.f;

    UPROPERTY()
	float FadeOutTime = 0.1f;

    UCastlePlayerDamageNumberComponent NumberComp;

    void Start()
    {
        if (bIsCritical)
			TimeRemaining = CriticalDuration;
		else
			TimeRemaining = Duration;

        FVector CameraRight = Player.GetPlayerViewRotation().RotateVector(FVector::RightVector);
		FVector CameraUp = Player.GetPlayerViewRotation().RotateVector(FVector::UpVector);

		FVector DamageLocationRightOffset = CameraRight * FMath::RandRange(-DamageLocationSpawnArea.X * 0.5f, DamageLocationSpawnArea.X * 0.5f);
		FVector DamageLocationUpOffset = CameraUp * FMath::RandRange(-DamageLocationSpawnArea.Y * 0.5f, DamageLocationSpawnArea.Y * 0.5f);

        CurrentPosition = DamageLocation + DamageLocationRightOffset + DamageLocationUpOffset;
        SetWidgetWorldPosition(CurrentPosition);

        FVector LocalDirection = DamageDirection.GetSafeNormal();

        CurrentVelocity = FVector::ZeroVector;

		if (bIsCritical)
		{
			CurrentVelocity += LocalDirection * DamageSpeed * 0.05f;
			CurrentVelocity += FVector::UpVector * UpwardsSpeedCritical;
		}
		else
        {	
			CurrentVelocity += LocalDirection * DamageSpeed;
        	CurrentVelocity += FVector::UpVector * UpwardsSpeed;
		}

        BP_Start();
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Start"))
    void BP_Start() {}

    void Reset()
    {
        BP_Reset();
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Reset"))
    void BP_Reset() {}

    UFUNCTION(BlueprintPure)
    float GetPercentageDone()
    {
		if (bIsCritical)
        	return 1.f - (TimeRemaining / CriticalDuration);
		else
        	return 1.f - (TimeRemaining / Duration);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(FGeometry MyGeometry, float DeltaTime)
    {
		if (bIsCritical)
		{
        	CurrentPosition += CurrentVelocity * DeltaTime;
		}
		else
		{
        	CurrentPosition += CurrentVelocity * DeltaTime;
			CurrentVelocity -= CurrentVelocity * Drag * DeltaTime;
        	CurrentVelocity += FVector::UpVector * (Gravity * DeltaTime * -1.f);
		}

        SetWidgetWorldPosition(CurrentPosition);

        TimeRemaining -= DeltaTime;
        if (TimeRemaining < 0.f)
            WidgetFinished();
    }

    UFUNCTION()
    void WidgetFinished()
    {
        if (NumberComp != nullptr && NumberComp.AvailablePool.Num() < 20)
            NumberComp.AvailablePool.Add(this);
        Player.RemoveWidget(this);
    }
};



class UCastlePlayerDamageNumberComponent : UActorComponent
{
    TArray<UCastleDamageNumberWidget> AvailablePool;

    UCastleDamageNumberWidget AddDamageNumber(TSubclassOf<UCastleDamageNumberWidget> WidgetClass, int DamageValue, FVector DamageLocation, FVector DamageDirection, float DamageSpeed, bool bIsCritical, bool bDamagedPlayer, EHazePlayer InvolvedPlayer)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
        UCastleDamageNumberWidget Widget;
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
                Widget.Reset();
                Player.AddExistingWidget(Widget);
            }
        }

        if (Widget == nullptr)
            Widget = Cast<UCastleDamageNumberWidget>(Player.AddWidget(WidgetClass.Get()));

        Widget.NumberComp = this;
        Widget.DamageValue = DamageValue;
        Widget.DamageLocation = DamageLocation;
        Widget.DamageDirection = DamageDirection;
		Widget.DamageSpeed = DamageSpeed;
        Widget.bIsCritical = bIsCritical;
        Widget.bDamagedPlayer = bDamagedPlayer;
		Widget.InvolvedPlayer = InvolvedPlayer;
        Widget.Start();

        return Widget;
    }
};

UFUNCTION()
void ShowCastleDamageNumber(AHazePlayerCharacter ShowOnPlayer, TSubclassOf<UCastleDamageNumberWidget> WidgetClass, int DamageValue, FVector DamageLocation, FVector DamageDirection, float DamageSpeed, bool bIsCritical, bool bDamagedPlayer, EHazePlayer InvolvedPlayer)
{
	AHazePlayerCharacter Player = ShowOnPlayer;
	if (SceneView::IsFullScreen() || Player == nullptr)
		Player = Game::GetMay();

	auto Comp = UCastlePlayerDamageNumberComponent::GetOrCreate(Player);
	Comp.AddDamageNumber(WidgetClass, DamageValue, DamageLocation, DamageDirection, DamageSpeed, bIsCritical, bDamagedPlayer, InvolvedPlayer);
}