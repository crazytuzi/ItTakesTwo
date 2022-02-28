import Vino.PointOfInterest.PointOfInterestMarkerWidget;
import Peanuts.Objectives.ObjectivesComponent;

UCLASS(Abstract)
class UPointOfInterestComponent : USceneComponent
{
	TPerPlayer<UHazeUserWidget> Widgets;
	TPerPlayer<bool> WidgetActive;

	UPROPERTY(Category = "Point Of Interest")
	EPointOfInterestMarkerWidgetVisType VisiblityType;

	// Whether the point of interest should start enabled by default
	UPROPERTY(Category = "Point Of Interest")
	bool bStartEnabled = false;

	// Players further away than this distance do not see the point of interest
	UPROPERTY(Category = "Point Of Interest", Meta = (InlineEditConditionToggle))
	bool bUseMaximumDistance = false;

	// Players further away than this distance do not see the point of interest
	UPROPERTY(Category = "Point Of Interest", Meta = (EditCondition = "bUseMaximumDistance"))
	float MaximumDistance = 1000.f;

	// Players closer than this distance do not see the point of interest
	UPROPERTY(Category = "Point Of Interest", Meta = (InlineEditConditionToggle))
	bool bUseMinimumDistance = false;

	// Players closer than this distance do not see the point of interest
	UPROPERTY(Category = "Point Of Interest", Meta = (EditCondition = "bUseMinimumDistance"))
	float MinimumDistance = 100.f;

	// Offset of the widget from the point of interest component
	UPROPERTY(Category = "Point Of Interest")
	FVector WidgetOffset;

	// Widget type to use for displaying this point of interest
	UPROPERTY(Category = "Point Of Interest")
	TSubclassOf<UHazeUserWidget> MarkerClass;

	private bool bWidgetsVisible = false;
	private UHazeLazyPlayerOverlapComponent OverlapComp;
	private TPerPlayer<UObjectivesComponent> ObjectivesComps;
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintPure)
	UHazeUserWidget GetCodysWidget() property
	{
		return Widgets[EHazePlayer::Cody];
	}

	UFUNCTION(BlueprintPure)
	UHazeUserWidget GetMaysWidget() property
	{
		return Widgets[EHazePlayer::May];
	}

	UFUNCTION(BlueprintPure)
	UHazeUserWidget GetWidgetForPlayer(AHazePlayerCharacter Player)
	{
		return Widgets[Player];
	}

	UFUNCTION()
	private void OnPlayerBeginOverlap(AHazePlayerCharacter Player)
	{
		SetComponentTickEnabled(true);
	}

	UFUNCTION()
	private void OnPlayerEndOverlap(AHazePlayerCharacter Player)
	{
		if (!OverlapComp.IsPlayerOverlapping(Player.OtherPlayer))
			SetComponentTickEnabled(false);
	}

	void UpdateWidgetDisplay(AHazePlayerCharacter Player)
	{
		auto Widget = Widgets[Player];
		if (Widget == nullptr)
			return;
		if (!WidgetActive[Player])
			return;
		
		float DistanceSQ = Player.ActorLocation.DistSquared(WorldLocation);
		bool bShouldAddWidget = true;
		if (bUseMinimumDistance && DistanceSQ < FMath::Square(MinimumDistance))
			bShouldAddWidget = false;
		if (bUseMaximumDistance && DistanceSQ > FMath::Square(MaximumDistance))
			bShouldAddWidget = false;

		auto ObjectivesComp = ObjectivesComps[Player];
		if (ObjectivesComp != nullptr && ObjectivesComp.IsHUDBlocked())
			bShouldAddWidget = false;

		if (bShouldAddWidget != Widget.bIsAdded)
		{
			if (bShouldAddWidget)
			{
				AddWidget(Player, Widget);
			}
			else
			{
				Player.RemoveWidget(Widget);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (auto Player : Game::Players)
			UpdateWidgetDisplay(Player);

#if !RELEASE
		ensure(!bUseMaximumDistance || OverlapComp.IsPlayerOverlapping(Game::Cody) || OverlapComp.IsPlayerOverlapping(Game::May));
#endif
	}

	private void AddWidget(AHazePlayerCharacter Player, UHazeUserWidget Widget)
	{
		Player.AddExistingWidget(Widget);
		Widget.AttachWidgetToComponent(this);
		Widget.SetWidgetPersistent(true);
		Widget.SetWidgetRelativeAttachOffset(WidgetOffset);
	}

	UFUNCTION()
	void SetPOIEnabled(AHazePlayerCharacter Player, bool bEnabled)
	{
#if TEST
		Log("" + Owner.GetName() + " | " + Player.GetName() + " Control: " + Player.HasControl() + " | SetPOIEnabled: " + bEnabled);
#endif

		SetWidgetVisible(Player, bEnabled);
	}

	UFUNCTION()
	protected void SetWidgetVisible(AHazePlayerCharacter Player, bool bNewVisible)
	{
		bool bWasVisible = WidgetActive[Player];
		if (bNewVisible == bWasVisible)
			return;

#if TEST
		Log("" + Owner.GetName() + " | " + Player.GetName() + " Control: " + Player.HasControl() + " | SetWidgetVisible: " + bNewVisible);
#endif

		if (bNewVisible)
		{
			WidgetActive[Player] = true;
			auto Widget = Widgets[Player];
			if (Widget == nullptr)
			{
				Widget = Widget::CreateUserWidget(Player, MarkerClass);
				Widgets[Player] = Widget;

				UPointOfInterestMarkerWidget MarkerWidget = Cast<UPointOfInterestMarkerWidget>(Widget);
				if (MarkerWidget != nullptr)
				{
					MarkerWidget.VisiblityType = VisiblityType;
					MarkerWidget.SetMarkerVisibility(VisiblityType);
				}
			}

			if (bUseMaximumDistance)
			{
				if (OverlapComp == nullptr)
				{
					OverlapComp = UHazeLazyPlayerOverlapComponent::Create(Owner);
					OverlapComp.AttachToComponent(this);
					OverlapComp.Shape.InitializeAsSphere(MaximumDistance + 500.f);
					OverlapComp.OnPlayerBeginOverlap.AddUFunction(this, n"OnPlayerBeginOverlap");
					OverlapComp.OnPlayerEndOverlap.AddUFunction(this, n"OnPlayerEndOverlap");
				}
				else
				{
					OverlapComp.SetLazyOverlapsEnabled(true);
					if (OverlapComp.IsPlayerOverlapping(Player))
						SetComponentTickEnabled(true);
				}
			}
			else
			{
				SetComponentTickEnabled(true);
			}
		}
		else
		{
			WidgetActive[Player] = false;

			auto Widget = Widgets[Player];
			if (Widget.bIsAdded)
				Player.RemoveWidget(Widget);

			if (!WidgetActive[Player.OtherPlayer])
			{
				if (OverlapComp != nullptr)
					OverlapComp.SetLazyOverlapsEnabled(false);
				SetComponentTickEnabled(false);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto Player : Game::Players)
			ObjectivesComps[Player] = UObjectivesComponent::Get(Player);

		if (bStartEnabled)
		{
			SetWidgetVisible(Game::Cody, true);
			SetWidgetVisible(Game::May, true);

			UPointOfInterestMarkerWidget CodysMarkerWidget = Cast<UPointOfInterestMarkerWidget>(CodysWidget);
			if(CodysMarkerWidget != nullptr)
			{
				CodysMarkerWidget.VisiblityType = VisiblityType;
				CodysMarkerWidget.SetMarkerVisibility(VisiblityType);
			}

			UPointOfInterestMarkerWidget MaysMarkerWidget = Cast<UPointOfInterestMarkerWidget>(MaysWidget);
			if(MaysMarkerWidget != nullptr)
			{
				MaysMarkerWidget.VisiblityType = VisiblityType;
				MaysMarkerWidget.SetMarkerVisibility(VisiblityType);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		SetWidgetVisible(Game::Cody, false);
		SetWidgetVisible(Game::May, false);
	}
}