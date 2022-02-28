import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.PlayerHealth.PlayerRespawnComponent;
import Vino.PlayerHealth.PlayerHealthSettings;

class UPlayerTensionModeWidget : UHazeUserWidget
{
	UPROPERTY()
	UCurveFloat TensionCurve;

	UPROPERTY()
	float CurrentTensionPct = 0.f;
};

class UPlayerTensionModeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"TensionMode");
	default CapabilityDebugCategory = n"Health";

	AHazePlayerCharacter Player;
	UPlayerHealthComponent HealthComp;
	UPlayerRespawnComponent RespawnComp;
	UPlayerHealthSettings HealthSettings;

	UPlayerHealthComponent OtherPlayerHealthComp;
	UPlayerRespawnComponent OtherPlayerRespawnComp;

	UPlayerTensionModeWidget Widget;

	UCurveFloat TensionCurve;
	float TensionCurveDuration = 0.f;
	float TensionCurveTimer = 0.f;
	float TensionPct = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HealthComp = UPlayerHealthComponent::Get(Owner);
		RespawnComp = UPlayerRespawnComponent::Get(Owner);
		HealthSettings = UPlayerHealthSettings::GetSettings(Owner);

		OtherPlayerHealthComp = UPlayerHealthComponent::Get(Player.OtherPlayer);
		OtherPlayerRespawnComp = UPlayerRespawnComponent::Get(Player.OtherPlayer);
	}

	bool ShouldShowTensionMode() const
	{
		// Only go into tension mode if game over is a possibility
		if (!HealthSettings.bCanGameOver)
			return false;

		if (RespawnComp.bIsGameOver)
			return false;

		if (!SceneView::IsFullScreen())
		{
			// Don't go into tension mode if we are dead
			if (HealthComp.bIsDead)
				return false;

			// Go into tension mode while the other player is dead
			if (!OtherPlayerHealthComp.bIsDead)
				return false;

			return true;
		}
		else
		{
			// In full screen mode we go into tension mode if either
			// player is dead and we are the full screen view
			if (SceneView::GetFullScreenPlayer() == Player)
			{
				if (HealthComp.bIsDead || OtherPlayerHealthComp.bIsDead)
					return true;
			}
			return false;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// Only go into tension mode if game over is a possibility
		if (!ShouldShowTensionMode())
			return EHazeNetworkActivation::DontActivate;
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!ShouldShowTensionMode())
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UClass WidgetClass = RespawnComp.TensionModeWidget.Get();
		if (WidgetClass != nullptr && WidgetClass.IsChildOf(UPlayerTensionModeWidget::StaticClass()))
		{
			Widget = Cast<UPlayerTensionModeWidget>(Player.AddWidget(WidgetClass, EHazeWidgetLayer::PlayerHUD));
			TensionCurve = Widget.TensionCurve;
		}

		if (TensionCurve != nullptr)
		{
			TensionCurveTimer = 0.f;

			float MinTime = 0.f;
			float MaxTime = 0.f;
			TensionCurve.GetTimeRange(MinTime, MaxTime);
			TensionCurveDuration = MaxTime;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (Widget != nullptr)
		{
			Player.RemoveWidget(Widget);
			Widget = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (TensionCurve != nullptr)
		{
			TensionCurveTimer = (TensionCurveTimer + DeltaTime) % TensionCurveDuration;
			TensionPct = TensionCurve.GetFloatValue(TensionCurveTimer);
		}
		else
		{
			TensionPct = 1.f;
		}

		Widget.CurrentTensionPct = TensionPct;
	}
};