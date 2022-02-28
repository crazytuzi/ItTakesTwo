import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Cake.LevelSpecific.Tree.Wasps.Effects.WaspEffectsComponent;
import Cake.LevelSpecific.Tree.Wasps.Settings.WaspComposableSettings;

class UWaspEnemyIndicatorCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WaspEffects");
	default CapabilityTags.Add(n"WaspGUI");

	default TickGroup = ECapabilityTickGroups::PostWork;

	UWaspBehaviourComponent BehaviourComp;
	UWaspEffectsComponent EffectsComp;
	UWaspComposableSettings Settings;
	TMap<AHazePlayerCharacter, UEnemyIndicatorWidget> IndicatorWidgets;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComp = UWaspBehaviourComponent::Get(Owner);
		EffectsComp = UWaspEffectsComponent::Get(Owner);
		Settings = UWaspComposableSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// This capability runs locally.
		// To activate, we need a valid target and state
		if (!EffectsComp.IndicatorWidgetClass.IsValid())
			return EHazeNetworkActivation::DontActivate;
		if (BehaviourComp.State == EWaspState::Flee)
			return EHazeNetworkActivation::DontActivate;
		if (!BehaviourComp.HasValidTarget())
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// We do not deactivate due to lack of target, as we want wasps that have killed their target to keep the indicator. 
		// If we add some scenario where that is inappropriate then we can use a delay after having lost target instead.
		if (!EffectsComp.IndicatorWidgetClass.IsValid())
            return EHazeNetworkDeactivation::DeactivateLocal;
		if (BehaviourComp.State == EWaspState::Flee)
            return EHazeNetworkDeactivation::DeactivateLocal;

		// We do deactivate if both players are dead
		if (!BehaviourComp.IsValidTarget(Game::May) && !BehaviourComp.IsValidTarget(Game::Cody))
            return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		IndicatorWidgets.Add(Game::GetMay(), nullptr);
		IndicatorWidgets.Add(Game::GetCody(), nullptr);
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		HideEnemyIndicator(Game::GetMay());
		HideEnemyIndicator(Game::GetCody());
		IndicatorWidgets.Empty();
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		UpdateWidget(Game::GetMay());
		UpdateWidget(Game::GetCody());
	}

	void UpdateWidget(AHazePlayerCharacter Player)
	{
		UEnemyIndicatorWidget Widget = IndicatorWidgets[Player];
		if (Widget == nullptr)
		{
			// Should we show widget?
			if (Player.ActorLocation.IsNear(Owner.ActorLocation, Settings.EnemyIndicatorShowRange))
				Widget = ShowEnemyIndicator(Player);	
		}
		else
		{
			// Should we hide widget?
			if (!Player.ActorLocation.IsNear(Owner.ActorLocation, Settings.EnemyIndicatorHideRange))
				Widget = HideEnemyIndicator(Player);	
		}

		if (Widget == nullptr)
			return;

		if (EffectsComp.ShouldShowAttackEffect() && (Player == BehaviourComp.Target))
			Widget.Highlight(0.5f);

		// Settings might be changed in runtime
		Widget.SetWidgetRelativeAttachOffset(Settings.EnemyIndicatorGUIOffset);
		Widget.MinOpacity = Settings.EnemyIndicatorMinOpacity;
	}

	UEnemyIndicatorWidget ShowEnemyIndicator(AHazePlayerCharacter Player)
	{
		UEnemyIndicatorWidget Widget = nullptr;
		IndicatorWidgets.Find(Player, Widget);
		if (Widget == nullptr)
		{
			Widget = Cast<UEnemyIndicatorWidget>(Player.AddWidget(EffectsComp.IndicatorWidgetClass));

			USceneComponent AttachComp = USceneComponent::Get(Owner, Settings.EnemyIndicatorAttachComponent);
			if (AttachComp == nullptr)
				AttachComp = Owner.RootComponent;
			Widget.AttachWidgetToComponent(AttachComp, Settings.EnemyIndicatorAttachSocket);
			Widget.SetWidgetRelativeAttachOffset(Settings.EnemyIndicatorGUIOffset);
			Widget.MinOpacity = Settings.EnemyIndicatorMinOpacity;

			IndicatorWidgets.Add(Player, Widget);
		}
		return Widget;
	}

	UEnemyIndicatorWidget HideEnemyIndicator(AHazePlayerCharacter Player)
	{
		UEnemyIndicatorWidget Widget = nullptr;
		IndicatorWidgets.Find(Player, Widget);
		if (Widget != nullptr)
		{
			Player.RemoveWidget(Widget);
			IndicatorWidgets.Add(Player, nullptr);
		}
		return nullptr;
	}
};
