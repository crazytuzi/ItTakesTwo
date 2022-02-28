import Peanuts.Objectives.ObjectivesData;

delegate void FOnObjectiveLineCompleted(UObjectiveLineWidget Widget);

struct FActiveObjective
{
	int Id;
	UObject Instigator;
	FObjectiveData Data;
};

struct FObjectiveSubWidget
{
	int Id;
	FObjectiveData Data;
	UObjectiveLineWidget Widget;
	bool bCompleted = false;
};

class UObjectiveLineWidget : UHazeUserWidget
{
	UPROPERTY()
	FObjectiveData Objective;
	UPROPERTY()
	bool bCompleted = false;

	FOnObjectiveLineCompleted OnCompleted;

	UFUNCTION(BlueprintEvent)
	void BP_Update() {}

	UFUNCTION(BlueprintEvent)
	void BP_Complete() {}

	UFUNCTION()
	void FinishCompletion()
	{
		OnCompleted.ExecuteIfBound(this);
	}
};

class UObjectivesWidget : UHazeUserWidget
{
	TArray<FObjectiveSubWidget> SubWidgets;
	FText HeaderText;

	UFUNCTION(BlueprintEvent)
	UObjectiveLineWidget BP_AddObjectiveLine(float DisplayOrder) { return nullptr; }
	UFUNCTION(BlueprintEvent)
	void BP_RemoveObjectiveLine(UObjectiveLineWidget Widget) {}

	UFUNCTION(BlueprintEvent)
	void BP_ShowObjectivesHeader(FText ObjectivesHeader) {}
	UFUNCTION(BlueprintEvent)
	void BP_HideObjectivesHeader() {}

	UFUNCTION(BlueprintPure)
	int GetInsertIndexForDisplayOrder(UVerticalBox Container, float DisplayOrder)
	{
		for (int i = 0, Count = Container.ChildrenCount; i < Count; ++i)
		{
			auto Child = Cast<UObjectiveLineWidget>(Container.GetChildAt(i));
			if (Child == nullptr)
				continue;

			if (Child.Objective.DisplayOrder > DisplayOrder)
				return i;
		}

		return Container.ChildrenCount;
	}

	void Complete(int Id)
	{
		for (auto& PresentWidget : SubWidgets)
		{
			if (PresentWidget.Id == Id)
			{
				PresentWidget.bCompleted = true;
				PresentWidget.Widget.OnCompleted.BindUFunction(this, n"OnLineCompleted");
				PresentWidget.Widget.BP_Complete();
			}
		}
	}

	UFUNCTION()
	void OnLineCompleted(UObjectiveLineWidget Widget)
	{
		for (int i = SubWidgets.Num() - 1; i >= 0; --i)
		{
			if (SubWidgets[i].Widget == Widget)
			{
				BP_RemoveObjectiveLine(Widget);
				SubWidgets.RemoveAt(i);
			}
		}
	}

	void Update(const TArray<FActiveObjective>& ActiveWidgets)
	{
		// Remove old subwidgets
		for (int i = SubWidgets.Num() - 1; i >= 0; --i)
		{
			if (SubWidgets[i].bCompleted)
				continue;

			bool bPresent = false;
			for (auto& ActiveWidget : ActiveWidgets)
			{
				if (ActiveWidget.Id == SubWidgets[i].Id)
				{
					bPresent = true;
					break;
				}
			}

			if (!bPresent)
			{
				BP_RemoveObjectiveLine(SubWidgets[i].Widget);
				SubWidgets.RemoveAt(i);
			}
		}

		// Add new subwidgets
		for (auto& ActiveWidget : ActiveWidgets)
		{
			bool bPresent = false;
			for (auto& PresentWidget : SubWidgets)
			{
				if (ActiveWidget.Id == PresentWidget.Id)
				{
					bPresent = true;
					break;
				}
			}

			if (bPresent)
				continue;

			auto NewWidget = BP_AddObjectiveLine(ActiveWidget.Data.DisplayOrder);
			FObjectiveSubWidget SubWidget;
			SubWidget.Data = ActiveWidget.Data;
			SubWidget.Id = ActiveWidget.Id;
			SubWidget.Widget = NewWidget;
			SubWidgets.Add(SubWidget);

			NewWidget.Objective = ActiveWidget.Data;
			NewWidget.BP_Update();
		}
	}
};

class UObjectivesComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UObjectivesWidget> WidgetType;

	private TArray<FActiveObjective> Objectives;
	private TArray<UObject> BlockInstigators;
	private int NextObjectiveId = 1;
	private UObjectivesWidget Widget;
	private FText HeaderText;

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		Objectives.Empty();
		BlockInstigators.Empty();
		HeaderText = FText();

		if (Widget != nullptr)
		{
			Cast<AHazePlayerCharacter>(Owner).RemoveWidgetFromHUD(Widget);
			Widget = nullptr;
		}
	}

	void Add(UObject Instigator, FObjectiveData Data)
	{
		FActiveObjective Objective;
		Objective.Id = NextObjectiveId++;
		Objective.Instigator = Instigator;
		Objective.Data = Data;
		Objectives.Add(Objective);

		UpdateWidget();
	}

	void Remove(UObject Instigator, EObjectiveStatus Status)
	{
		for (int i = Objectives.Num() - 1; i >= 0; --i)
		{
			if (Objectives[i].Instigator == Instigator)
			{
				if (Status == EObjectiveStatus::Completed && Widget != nullptr)
					Widget.Complete(Objectives[i].Id);
				Objectives.RemoveAt(i);
			}
		}

		UpdateWidget();
	}

	void UpdateWidget()
	{
		if (Widget != nullptr)
		{
			if ((Objectives.Num() == 0 && Widget.SubWidgets.Num() == 0 && HeaderText.IsEmpty())
				|| BlockInstigators.Num() != 0)
			{
				Cast<AHazePlayerCharacter>(Owner).RemoveWidgetFromHUD(Widget);
				Widget = nullptr;
			}
		}
		else
		{
			if ((Objectives.Num() != 0 || !HeaderText.IsEmpty()) && BlockInstigators.Num() == 0)
			{
				Widget = Cast<UObjectivesWidget>(Cast<AHazePlayerCharacter>(Owner).AddWidgetToHUDSlot(n"Objectives", WidgetType));
				Widget.SetWidgetPersistent(true);
			}
		}


		if (Widget != nullptr)
		{
			if (!HeaderText.IdenticalTo(Widget.HeaderText))
			{
				Widget.HeaderText = HeaderText;
				if (!HeaderText.IsEmpty())
					Widget.BP_ShowObjectivesHeader(HeaderText);
				else
					Widget.BP_HideObjectivesHeader();
			}

			Widget.Update(Objectives);
		}
	}

	void SetObjectivesHeader(FText Header)
	{
		HeaderText = Header;
		UpdateWidget();
	}

	void BlockHUD(UObject Instigator)
	{
		BlockInstigators.AddUnique(Instigator);
		UpdateWidget();
	}

	void UnblockHUD(UObject Instigator)
	{
		BlockInstigators.Remove(Instigator);
		UpdateWidget();
	}

	bool IsHUDBlocked()
	{
		return BlockInstigators.Num() != 0;
	}
};