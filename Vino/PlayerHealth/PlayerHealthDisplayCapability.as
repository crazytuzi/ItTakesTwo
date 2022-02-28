import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.PlayerHealth.PlayerRespawnComponent;
import Vino.PlayerHealth.PlayerHealthSettings;
import Vino.PlayerHealth.PlayerHealthWheelWidget;

enum EPlayerHealthDisplayState
{
	Invisible,
	HealthBar,
	RespawnTimer,
};

class UPlayerHealthDisplayWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	float CurrentHealth = 0.f;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsDead = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsRespawning = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	UPlayerHealthSettings HealthSettings;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	EPlayerHealthDisplayState CurrentState = EPlayerHealthDisplayState::Invisible;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	EPlayerHealthDisplayPosition CurrentPosition = EPlayerHealthDisplayPosition::Default;

	bool ShouldShowHealthBar()
	{
		if (bIsDead)
			return false;
		if (!HealthSettings.bDisplayHealth)
			return false;
		return true;
	}

	bool ShouldShowRespawnTimer()
	{
		if (!bIsDead)
			return false;
		if (!bIsRespawning)
			return false;
		if (HealthSettings.RespawnTimer <= 0.f)
			return false;
		if (!SceneView::IsFullScreen())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float DeltaTime)
	{
		UpdateState();
		UpdatePosition();
	}

	void UpdatePosition(bool bForce = false)
	{
		// Update the place to position the UI at
		if (HealthSettings.HealthPosition != CurrentPosition || bForce)
		{
			CurrentPosition = HealthSettings.HealthPosition;
			BP_OnPositionChanged(CurrentPosition);
		}
	}

	void UpdateState()
	{
		// Update which state to show for the widget
		EPlayerHealthDisplayState NewState = EPlayerHealthDisplayState::Invisible;
		if (!bIsAdded)
			NewState = EPlayerHealthDisplayState::Invisible;
		else if (ShouldShowRespawnTimer())
			NewState = EPlayerHealthDisplayState::RespawnTimer;
		else if (ShouldShowHealthBar())
			NewState = EPlayerHealthDisplayState::HealthBar;

		if (NewState != CurrentState)
		{
			auto PrevState = CurrentState;
			CurrentState = NewState;
			BP_OnStateChanged(PrevState, NewState);
		}
	}

	UFUNCTION(BlueprintEvent)
	UPlayerHealthWheelWidget GetHealthWheel()
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnStateChanged(EPlayerHealthDisplayState OldState, EPlayerHealthDisplayState NewState)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnPositionChanged(EPlayerHealthDisplayPosition NewPosition)
	{
	}
};

class UPlayerHealthDisplayCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HealthDisplay");
	default CapabilityDebugCategory = n"Health";

	AHazePlayerCharacter Player;
	UPlayerHealthComponent HealthComp;
	UPlayerRespawnComponent RespawnComp;
	UPlayerHealthSettings HealthSettings;

	UPlayerHealthDisplayWidget Widget;	

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HealthComp = UPlayerHealthComponent::Get(Owner);
		RespawnComp = UPlayerRespawnComponent::Get(Owner);
		HealthSettings = UPlayerHealthSettings::GetSettings(Owner);		
	}

	bool ShouldShowHealthDisplay() const
	{
		// Don't display any health HUD when we are game over
		if (RespawnComp.bIsGameOver)
			return false;
		// We need the widget to display the health bar if we have one set 
		if (HealthSettings.bDisplayHealth)
			return true;
		// We need the widget to display the respawn timer if we are in fullscreen
		if (SceneView::IsFullScreen() && RespawnComp.bWaitingForRespawn)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!ShouldShowHealthDisplay())
			return EHazeNetworkActivation::DontActivate;
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!ShouldShowHealthDisplay())
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UClass WidgetClass = HealthComp.HealthDisplayWidget.Get();
		if (WidgetClass != nullptr && WidgetClass.IsChildOf(UPlayerHealthDisplayWidget::StaticClass()))
		{
			Widget = Cast<UPlayerHealthDisplayWidget>(Widget::CreateUserWidget(Player, WidgetClass));
			Widget::AddExistingFullscreenWidget(Widget, EHazeWidgetLayer::PlayerHUD);

			Widget.SetWidgetPersistent(true);
			Widget.HealthSettings = HealthSettings;
			Widget.OverrideWidgetPlayer(Player);
			Widget.UpdatePosition(bForce = true);
			Widget.UpdateState();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (Widget != nullptr)
		{
			Widget::RemoveFullscreenWidget(Widget);
			Widget = nullptr;		
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Widget != nullptr)
		{
			Widget.SetColorAndOpacity(FLinearColor(1.f, 1.f, 1.f, 1.f - Player.GetFadeOutPercentage()));
			Widget.CurrentHealth = HealthComp.CurrentHealth;
			Widget.bIsDead = HealthComp.bIsDead;
			Widget.bIsRespawning = RespawnComp.bWaitingForRespawn;

			auto HealthWheel = Widget.GetHealthWheel();
			HealthWheel.HealthChunks = HealthSettings.HealthChunks;
			HealthWheel.TotalHealth = HealthComp.CurrentHealth;
			HealthWheel.DamagedHealth = HealthComp.RecentlyLostHealth;
			HealthWheel.HealedHealth = HealthComp.RecentlyHealedHealth;
			HealthWheel.RegeneratedHealth = HealthComp.RecentlyRegeneratedHealth;			
		}
	}
};