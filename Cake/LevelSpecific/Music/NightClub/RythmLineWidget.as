import Cake.LevelSpecific.Music.NightClub.RythmWidget;
import Cake.LevelSpecific.Music.NightClub.RythmTargetWidget;

class URythmLineWidget : UHazeUserWidget
{
	UPROPERTY()
	ERhythmButtonType ButtonType;

	UPROPERTY()
	TSubclassOf<URythmWidget> RythmWidgetClass;

	UPROPERTY()
	UCanvasPanel CanvasPanelNative;

	UPROPERTY()
	URythmTargetWidget RythmTarget = nullptr;

	TArray<URythmWidget> ActiveRythmWidgets;

	float Elapsed = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float DeltaTime)
	{
		if(RythmTarget == nullptr)
		{
			return;
		}

		for(int Index = ActiveRythmWidgets.Num() - 1; Index >= 0; --Index)
		{
			URythmWidget RythmWidget = ActiveRythmWidgets[Index];

			// arbitrary value for now
			if(RythmWidget.PanelSlot.Position.Y > 1500.0f)
			{
				RythmWidget.BP_OnFailure();
				ActiveRythmWidgets.RemoveAt(Index);
				RythmWidget.RemoveFromParent();
			}
		}
	}

	UFUNCTION()
	void RandomizeTime()
	{
		Elapsed = FMath::RandRange(0.5, 3.0f);
	}

	bool ButtonPressed()
	{
		for(int Index = ActiveRythmWidgets.Num() - 1; Index >= 0; --Index)
		{
			URythmWidget RythmWidget = ActiveRythmWidgets[Index];
			if(RythmWidget.IsOverlapping(RythmTarget))
			{
				RythmWidget.BP_OnHitSucess();
				ActiveRythmWidgets.RemoveAt(Index);
				RythmWidget.RemoveFromParent();
				RythmTarget.BP_OnRythmButtonPressed(ButtonType, true);
				return true;
			}
		}

		RythmTarget.BP_OnRythmButtonPressed(ButtonType, false);

		return false;
	}

	void PushRytmIcon()
	{
			URythmWidget NewRythmWidget = Cast<URythmWidget>(Widget::CreateWidget(this, RythmWidgetClass));
			UCanvasPanelSlot NewCanvasPanelSlot = CanvasPanelNative.AddChildToCanvas(NewRythmWidget);
			NewCanvasPanelSlot.SetAlignment(FVector2D(0.5f, 0.5f));
			NewCanvasPanelSlot.SetPosition(FVector2D(RythmTarget.PanelSlot.Position.X, 0.0f));
			NewCanvasPanelSlot.SetSize(FVector2D(128.0f, 128.0f));
			ActiveRythmWidgets.Add(NewRythmWidget);
	}

	UCanvasPanelSlot GetPanelSlot() const
	{
		return Cast<UCanvasPanelSlot>(Slot);
	}
}
