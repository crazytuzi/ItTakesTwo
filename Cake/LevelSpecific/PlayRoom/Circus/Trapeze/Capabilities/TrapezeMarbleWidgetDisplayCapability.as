import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeComponent;
import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeTags;
import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeActor;

class UTrapezeMarbleWidgetDisplayCapability : UHazeCapability
{
	default CapabilityTags.Add(TrapezeTags::Trapeze);
	default CapabilityTags.Add(TrapezeTags::MarbleWidgetDisplay);

	default CapabilityDebugCategory = TrapezeTags::Trapeze;

	UPROPERTY(BlueprintReadOnly)
	TSubclassOf<UHazeInputButton> InputButtonWidgetClass;
	UHazeInputButton CatchButtonWidget;
	UHazeInputButton ThrowButtonWidget;

	AHazePlayerCharacter PlayerOwner;
	UTrapezeComponent TrapezeComponent;
	UTrapezeComponent OtherPlayerTrapezeComponent;

	ATrapezeActor Trapeze;
	ATrapezeMarbleActor Marble;

	const float CatchWidgetHeightOffset = 70.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		TrapezeComponent = UTrapezeComponent::Get(Owner);
		OtherPlayerTrapezeComponent = UTrapezeComponent::Get(PlayerOwner.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Trapeze = Cast<ATrapezeActor>(TrapezeComponent.TrapezeActor);
		Marble = Trapeze.Marble;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HandleCatchWidget();
		HandleThrowWidget();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate()	const
	{
		if(TrapezeComponent.IsSwinging())
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.RemoveWidget(CatchButtonWidget);
		CatchButtonWidget = nullptr;
		
		PlayerOwner.RemoveWidget(ThrowButtonWidget);
		ThrowButtonWidget = nullptr;

		Marble= nullptr;
		Trapeze = nullptr;
	}

	void HandleCatchWidget()
	{
		// Check if we should enable widget
		if(CatchButtonWidget == nullptr)
		{
			if(ShouldShowCatchWidget())
				AddCatchWidget();
		}
		// Check if we should disable widget
		else if(!ShouldShowCatchWidget())
		{
			PlayerOwner.RemoveWidget(CatchButtonWidget);
			CatchButtonWidget = nullptr;
		}
		else
		{
			// Add offset if catch wiget is active
			CatchButtonWidget.SetWidgetWorldPosition(Marble.ActorLocation + PlayerOwner.MovementWorldUp * CatchWidgetHeightOffset);
		}
	}

	bool ShouldShowCatchWidget()
	{
		if(!TrapezeComponent.IsSwinging())
			return false;

		if(TrapezeComponent.PlayerHasMarble())
			return false;

		if(PlayerOwner.IsAnyCapabilityActive(TrapezeTags::MarbleCatch))
			return false;

		if(TrapezeComponent.bJustThrewMarble)
			return false;

		if(TrapezeComponent.OtherPlayerTrapezeComponent.PlayerHasMarble())
			return false;

		if(Marble.IsFlyingTowardsDispenser())
			return false;

		if(!Marble.IsReadyForPickUp())
			return false;

		if(Marble.IsPickedUp())
			return false;

		if(Marble.IsAnyCapabilityActive(PickupTags::PickupSystem))
			return false;

		if(Marble.bEnteredReceptacle)
			return false;

		// - On throwing side (left trapeze): don't show after thrown
		// - On catching side (right trapeze): show only after thrown
		if(Marble.IsAirborne())
			return Trapeze.bIsCatchingEnd;
		else
			return !Trapeze.bIsCatchingEnd;
	}

	void HandleThrowWidget()
	{
		// Check if we should enable widget
		if(ThrowButtonWidget == nullptr)
		{
			if(ShouldShowThrowWidget())
				AddThrowWidget();
		}
		// Check if we should disable widget
		else if(!ShouldShowThrowWidget())
		{
			PlayerOwner.RemoveWidget(ThrowButtonWidget);
			ThrowButtonWidget = nullptr;
		}
	}

	bool ShouldShowThrowWidget()
	{
		if(!TrapezeComponent.PlayerCanThrowMarble())
			return false;

		if(TrapezeComponent.bJustCaughtMarble)
			return false;

		if(TrapezeComponent.bJustThrewMarble)
			return false;

		if(Trapeze.AnimationDataComponent.bIsThrowing)
			return false;

		return true;
	}

	void AddCatchWidget()
	{
		CatchButtonWidget = Cast<UHazeInputButton>(PlayerOwner.AddWidget(InputButtonWidgetClass));
		CatchButtonWidget.SetWidgetShowInFullscreen(true);
		CatchButtonWidget.ActionName = ActionNames::InteractionTrigger;

		CatchButtonWidget.AttachWidgetToComponent(Marble.Mesh);
		CatchButtonWidget.SetWidgetWorldPosition(Marble.ActorLocation + PlayerOwner.MovementWorldUp * CatchWidgetHeightOffset);
	}

	void AddThrowWidget()
	{
		ThrowButtonWidget = Cast<UHazeInputButton>(PlayerOwner.AddWidget(InputButtonWidgetClass));
		ThrowButtonWidget.SetWidgetShowInFullscreen(true);
		ThrowButtonWidget.ActionName = ActionNames::WeaponFire;

		ThrowButtonWidget.AttachWidgetToComponent(PlayerOwner.Mesh, n"RightAttach");
		ThrowButtonWidget.SetWidgetRelativeAttachOffset(FVector(0.f, 0.f, -40.f));
	}
}