import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.DrumMachine.DrumMachineButtonComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.DrumMachine.DrumMachineBeatIndicatorComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.DrumMachine.DrumMachineResetButtonComponent;
import Vino.ContextIcons.ContextStatics;

import void SetDrumMachineReference(AHazePlayerCharacter, AHazeActor) from "Cake.LevelSpecific.Music.LevelMechanics.Backstage.DrumMachine.PlayerDrumMachineComponent";
import Vino.Interactions.InteractionComponent;
import Peanuts.Triggers.PlayerTrigger;
import Vino.Camera.CameraStatics;
import Vino.Audio.Music.MusicCallbackSubscriberComponent;

event void FDrumMachineButtonToggled(ADrumMachine Machine, int RowIndex, int RowPressedButtons, int TotalPressedButtons);
event void FDrumMachineBeat(ADrumMachine Machine, int ColumnIndex, int ColumnPressedButtons);

struct FDrumMachineColumn
{
	UDrumMachineBeatIndicatorComponent BeatIndicator;
	TArray<UDrumMachineButtonComponent> Buttons;
	float ButtonsMin;
	float ButtonsMax;
}

UCLASS(Abstract)
class ADrumMachine : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UDrumMachineResetButtonComponent ResetButton;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent WidgetLocationComp;

	UPROPERTY(DefaultComponent)
	UGroundPoundedCallbackComponent GroundPoundDetector;

	UPROPERTY(DefaultComponent)
	UMusicCallbackSubscriberComponent MusicSubscriber;	

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UInteractionComponent CodyInteractComp;
	default CodyInteractComp.ExclusiveMode = EInteractionExclusiveMode::ExclusiveToCody;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UInteractionComponent MayInteractComp;
	default MayInteractComp.ExclusiveMode = EInteractionExclusiveMode::ExclusiveToMay;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UInteractionComponent CodyResetInteractComp;
	default CodyInteractComp.ExclusiveMode = EInteractionExclusiveMode::ExclusiveToCody;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UInteractionComponent MayResetInteractComp;
	default MayInteractComp.ExclusiveMode = EInteractionExclusiveMode::ExclusiveToMay;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UBoxComponent PlayerTriggerArea;
	default PlayerTriggerArea.CollisionProfileName = n"TriggerOnlyPlayer";
	default PlayerTriggerArea.RelativeLocation = FVector(-300.0f, 150.0f, 570.0f);
	default PlayerTriggerArea.BoxExtent = FVector(515.0f, 980.0f, 512.0f);

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UBoxComponent ResetButtonArea;
	default ResetButtonArea.CollisionProfileName = n"TriggerOnlyPlayer";
	default ResetButtonArea.RelativeLocation = FVector(730.0f, -600.0f, 200.0f);
	default ResetButtonArea.BoxExtent = FVector(100.0f, 180.0f, 230.0f);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PoiComp;

	// Keeps track on wether we should show interaction comp widget or not
	UPROPERTY()
	APlayerTrigger PlayerTrigger;

	bool bInteractionCompFollowCody = false;
	bool bInteractionCompFollowMay = false;

	// When a player presses a button for the first time, apply a POI
	bool bCodyHasPressedAButton = false;
	bool bMayHasPressedAButton = false;

	// If true the machine can play several sounds at the same time, i.e. in the same column. If false, only one button in each column will be active.
	UPROPERTY()
	bool bPolyphonic = true;

	UPROPERTY(meta = (NotBlueprintCallable))
	FDrumMachineButtonToggled OnButtonToggled;

	UPROPERTY(meta = (NotBlueprintCallable))
	FDrumMachineBeat OnBeat;

	UPROPERTY()
	TSubclassOf<UContextWidget> InteractWidget;

	int iBeatColumn = 0;

	TArray<FDrumMachineColumn> Columns;
	float SortingSlack = 20.f;
	float ButtonDetectionPadding = 25.f; 

	TArray<UContextWidget> WidgetArray;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerOverlap");
		PlayerTrigger.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
		

		MayInteractComp.DisableForPlayer(Game::GetCody(), n"MayOnly");
		CodyInteractComp.DisableForPlayer(Game::GetMay(), n"CodyOnly");
		MayResetInteractComp.DisableForPlayer(Game::GetCody(), n"MayOnly");
		CodyResetInteractComp.DisableForPlayer(Game::GetMay(), n"CodyOnly");

		// Sort all components by column left to right and row top to bottom
		TArray<UDrumMachineButtonComponent> Buttons; 
		GetComponentsByClass(Buttons);
		Sort(Buttons);
		TArray<UDrumMachineBeatIndicatorComponent> Indicators;
		GetComponentsByClass(Indicators);
		Sort(Indicators);

		// Bind toggle events to each button
		for (UDrumMachineButtonComponent Button : Buttons)
		{
			Button.OnToggled.AddUFunction(this, n"OnToggleButton");
		}	

		// Set up the columns. We assume the buttons will always form a filled grid.
		int NumColumns = Indicators.Num();
		int NumButtonRows = Buttons.Num() / NumColumns;
		if (!devEnsure(NumColumns * NumButtonRows == Buttons.Num(), "Drum machine must have one button in each row for each indicator."))
			return;
		Columns.SetNum(NumColumns);
		FTransform WorldToLocal = ActorTransform.Inverse();
		for (int iColumn = 0; iColumn < NumColumns; iColumn++)
		{
			Columns[iColumn].BeatIndicator = Indicators[iColumn];
			Columns[iColumn].Buttons.SetNum(NumButtonRows);
			for (int iRow = 0; iRow < NumButtonRows; iRow++)
			{
				Columns[iColumn].Buttons[iRow] = Buttons[iRow + iColumn * NumButtonRows];
				Columns[iColumn].Buttons[iRow].RowIndex = iRow;
				Columns[iColumn].Buttons[iRow].ColumnIndex = iColumn;
			}			

			// Set up bounds of buttons in column
			Columns[iColumn].ButtonsMax = -BIG_NUMBER;
			Columns[iColumn].ButtonsMin = BIG_NUMBER;
			for (UDrumMachineButtonComponent Button : Columns[iColumn].Buttons)
			{
				FVector LocalLoc = WorldToLocal.TransformPosition(Button.WorldLocation);
				FVector HalfSize = Button.GetDetectionSize() * 0.5f;
				Button.LocalMax.X = LocalLoc.X + HalfSize.X;
				Button.LocalMax.Y = LocalLoc.Y + HalfSize.Y;
				Button.LocalMin.X = LocalLoc.X - HalfSize.X;
				Button.LocalMin.Y = LocalLoc.Y - HalfSize.Y;
				Columns[iColumn].ButtonsMin = FMath::Min(Columns[iColumn].ButtonsMin, Button.LocalMin.Y);
				Columns[iColumn].ButtonsMax = FMath::Max(Columns[iColumn].ButtonsMax, Button.LocalMax.Y);
			}
		}

		ResetButton.OnPressed.AddUFunction(this, n"ResetButtons");
		FVector ResetButtonLocalLoc = WorldToLocal.TransformPosition(ResetButton.WorldLocation);
		FVector ResetButtonHalfSize = ResetButton.GetDetectionSize() * 0.5f;
		ResetButton.LocalMax.X = ResetButtonLocalLoc.X + ResetButtonHalfSize.X;
		ResetButton.LocalMax.Y = ResetButtonLocalLoc.Y + ResetButtonHalfSize.Y;
		ResetButton.LocalMin.X = ResetButtonLocalLoc.X - ResetButtonHalfSize.X;
		ResetButton.LocalMin.Y = ResetButtonLocalLoc.Y - ResetButtonHalfSize.Y;

		PlayerTriggerArea.OnComponentBeginOverlap.AddUFunction(this, n"PlayerTriggerOnBeginOverlap");
		PlayerTriggerArea.OnComponentEndOverlap.AddUFunction(this, n"PlayerTriggerOnEndOverlap");
		ResetButtonArea.OnComponentBeginOverlap.AddUFunction(this, n"PlayerTriggerOnBeginOverlap");
		ResetButtonArea.OnComponentEndOverlap.AddUFunction(this, n"PlayerTriggerOnEndOverlap");

		MusicSubscriber.OnMusicSyncGrid.AddUFunction(this, n"OnMusicBeat");
	}

	UFUNCTION(NotBlueprintCallable)
	void OnMusicBeat(FAkSegmentInfo SegmentInfo)
	{
		// Play all sounds in current column
		int NumPressedButtons = 0;
		for (UDrumMachineButtonComponent Button : Columns[iBeatColumn].Buttons)
		{
			Button.Beat();	
			if (Button.bButtonPressed)
				NumPressedButtons++;
		}

		for (UDrumMachineButtonComponent Button : Columns[(iBeatColumn == 0) ? Columns.Num() - 1 : iBeatColumn - 1].Buttons)
		{
			Button.BeatOver();
		}

		Columns[iBeatColumn].BeatIndicator.Beat();
		OnBeat.Broadcast(this, iBeatColumn, NumPressedButtons);

		// Advance countdown to next column
		iBeatColumn = (iBeatColumn + 1) % Columns.Num();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bInteractionCompFollowMay)
		{
			MayInteractComp.SetWorldLocation(Game::GetMay().GetActorLocation() + FVector(0.f, 0.f, -100.f));
		}

		if (bInteractionCompFollowCody)
		{
			CodyInteractComp.SetWorldLocation(Game::GetCody().GetActorLocation() + FVector(0.f, 0.f, -100.f));
		}

		//DebugDraw();
	}

	UFUNCTION()
	void SetContextWidgetEnabled(bool bEnabled)
	{
		TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
		
		if (bEnabled)
		{
			for (auto Player : Players)
				WidgetArray.AddUnique(CreateContextWidget(Player, InteractWidget, WidgetLocationComp));
		} else 
		{
			if (WidgetArray.Num() <= 0)
				return;

			for (auto Widget : WidgetArray)
				Widget.RemoveContextWidget();

			WidgetArray.Empty();
		}
	}

	void ToggleButton(AHazePlayerCharacter Player)
	{
		// This is broadcast on both control and remote side, but pass it on to the component we think was hit anyway to allow some effects to show.
		// Actual gameplay effect will be replicated separately by component.
		FVector LocalPoundLoc = ActorTransform.InverseTransformPosition(Player.ActorLocation);
		if ((LocalPoundLoc.X > ResetButton.LocalMin.X) && (LocalPoundLoc.X < ResetButton.LocalMax.X) &&
			(LocalPoundLoc.Y > ResetButton.LocalMin.Y) && (LocalPoundLoc.Y < ResetButton.LocalMax.Y))
		{
			ResetButton.OnGroundPounded(Player);
			return;
		}

		UDrumMachineButtonComponent PoundedButton = GetButtonAt2D(LocalPoundLoc);
		if (PoundedButton != nullptr)
		{
			PoundedButton.OnGroundPounded(Player);
			SetContextWidgetEnabled(false);

			if (Player == Game::GetCody() && !bCodyHasPressedAButton)
			{
				bCodyHasPressedAButton = true;
				FLookatFocusPointData Data;
				Data.Component = PoiComp;
				Data.FOV = 40.f;
				Data.ShowLetterbox = false;
				Data.POIBlendTime = 2.f;
				Data.Duration = 2.f;
				LookAtFocusPoint(Game::GetCody(), Data);
			}

			if (Player == Game::GetMay() && !bMayHasPressedAButton)
			{
				bMayHasPressedAButton = true;
				FLookatFocusPointData Data;
				Data.Component = PoiComp;
				Data.FOV = 40.f;
				Data.ShowLetterbox = false;
				Data.POIBlendTime = 2.f;
				Data.Duration = 2.f;
				LookAtFocusPoint(Game::GetMay(), Data);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnToggleButton(UDrumMachineButtonComponent ToggledButton)
	{
		if (!ensure(ToggledButton != nullptr))
			return;

		int RowIndex = ToggledButton.RowIndex;
		int RowPressedButtons = 0;
		int TotalPressedButtons = 0;
		for (const FDrumMachineColumn& Column : Columns)
		{
			int ColumnPressedButtons = 0;
			for (UDrumMachineButtonComponent Button : Column.Buttons)
			{
				if (ensure(Button != nullptr) && Button.bButtonPressed)
				{
					ColumnPressedButtons++;
					if (Button.RowIndex == RowIndex)
						RowPressedButtons++;
				}
			}
			if (!bPolyphonic && (ColumnPressedButtons > 1))
				ColumnPressedButtons = 1; // bever count as more than one button in a column, any extra will be released automatically.
			TotalPressedButtons += ColumnPressedButtons;
		}

		OnButtonToggled.Broadcast(this, RowIndex, RowPressedButtons, TotalPressedButtons);

		if (!bPolyphonic)
		{
			// Only one button in each column can be pressed at a time. 
			// Note that this can cause several additional OnToggleButton calls (all with !bButtonPressed though)
			if (ToggledButton.bButtonPressed && HasControl())
				NetMonophonicPress(ToggledButton);
		}
	}

	UFUNCTION(NetFunction)
	void NetMonophonicPress(UDrumMachineButtonComponent PressedButton)
	{
		if (!ensure(Columns.IsValidIndex(PressedButton.ColumnIndex)))
			return;

		// Release all other buttons in column
		for (UDrumMachineButtonComponent Button : Columns[PressedButton.ColumnIndex].Buttons)
		{
			if ((PressedButton != Button) && Button.bButtonPressed)
				Button.ReleaseButton();
		}
	}

	UDrumMachineButtonComponent GetButtonAt2D(const FVector& LocalPoundLoc)
	{
		for (FDrumMachineColumn Column : Columns)
		{
			// Columns are sorted from left to right, so if location is to the left (lower Y) we are outside or in between columns.
			if (LocalPoundLoc.Y < Column.ButtonsMin)
				return nullptr;

			// Check if to the right
			if (LocalPoundLoc.Y > Column.ButtonsMax)
				continue; // Your princess is in another column

			// Within column horizontal space, check vertical
			for (UDrumMachineButtonComponent Button : Column.Buttons)
			{
				if (LocalPoundLoc.X > Button.LocalMax.X)
					break; // Above, rows are sorted from top to bottom, so no need to check further
				
				if (LocalPoundLoc.X < Button.LocalMin.X)
					continue; // Below, try next row
			
				if ((LocalPoundLoc.Y < Button.LocalMin.Y) || (LocalPoundLoc.Y > Button.LocalMax.Y))
					break; // Beside button, no need to check further
	
				// On top of button!
				return Button;
			}	

			// Position was above, below or in between buttons. Assuming there is no significant overlap between columns we need not check further.
			return nullptr;		
		}
		// To the right of the columns
		return nullptr;
	}

	void Sort(TArray<UDrumMachineButtonComponent>& Buttons)
	{
		TArray<USceneComponent> Comps;
		int Num = Buttons.Num();
		Comps.SetNum(Num);
		for (int i = 0; i < Num; i++)
			Comps[i] = Buttons[i];
		QuickSort(Comps, 0, Num - 1);
		for (int i = 0; i < Num; i++)
			Buttons[i] = Cast<UDrumMachineButtonComponent>(Comps[i]);
	}

	void Sort(TArray<UDrumMachineBeatIndicatorComponent>& Indicators)
	{
		TArray<USceneComponent> Comps;
		int Num = Indicators.Num();
		Comps.SetNum(Num);
		for (int i = 0; i < Num; i++)
			Comps[i] = Indicators[i];
		QuickSort(Comps, 0, Num - 1);
		for (int i = 0; i < Num; i++)
			Indicators[i] = Cast<UDrumMachineBeatIndicatorComponent>(Comps[i]);
	}

	void QuickSort(TArray<USceneComponent>& Comps, int Start, int End)
    {
        if (End <= Start)
            return; // Single (or no) element 

		// Split the list on pivot value, then recursively sort the parts
		USceneComponent Pivot = Comps[End];
		int Left = Start;
		int Right = End - 1;
		while (true)
		{
			while ((Left < End) && SortBefore(Comps[Left], Pivot))
				Left++;
			while ((Right > 0) && SortBefore(Pivot, Comps[Right]))
				Right--;
			if (Left >= Right)
				break;
			Swap(Comps, Left, Right);
		}
		Swap(Comps, Left, End);
		
		QuickSort(Comps, Start, Left - 1);
		QuickSort(Comps, Left + 1, End);
    }	

	void Swap(TArray<USceneComponent>& Comps, int i, int j)
	{
		USceneComponent Temp = Comps[i];
		Comps[i] = Comps[j];
		Comps[j] = Temp;
	}

	bool SortBefore(USceneComponent Comp1, USceneComponent Comp2)
	{
		// Sort by column, then by row
		// Columns are sorted in ascending order on relative Y
		if (Comp1.RelativeLocation.Y > Comp2.RelativeLocation.Y + SortingSlack)
			return false; // Comp1 is in a rightmore column

		if (Comp1.RelativeLocation.Y < Comp2.RelativeLocation.Y - SortingSlack)
			return true; // Comp1 is in a leftmore column

		// Same column, rows are sorted in descending order on relative X
		if (Comp1.RelativeLocation.X > Comp2.RelativeLocation.X + SortingSlack)
			return true; // Comp1 is in a higher row
		return false;
	}

	UFUNCTION(NotBlueprintCallable)
	void ResetButtons()
	{
		// This is run locally for both sides, reset button handles networking
		for (FDrumMachineColumn Column : Columns)
		{
			for (UDrumMachineButtonComponent Button : Column.Buttons)
				Button.ReleaseButton(); // Local release
		}	
	}

	void DebugDraw()
	{
		FTransform Transform = ActorTransform;
		float Height = 200.f;
		for (FDrumMachineColumn Column : Columns)
		{
			System::DrawDebugLine(Column.BeatIndicator.WorldLocation, Column.BeatIndicator.WorldLocation + FVector::UpVector * Height, FLinearColor::Red, 0, 10);
			for (UDrumMachineButtonComponent Button : Column.Buttons)
				System::DrawDebugLine(Button.WorldLocation, Button.WorldLocation + FVector::UpVector * Height, FLinearColor::Yellow, 0, 10);
			Height += 100;

			int NumButtons = Column.Buttons.Num();
			if (NumButtons == 0)
				continue;

			float CenterY = (Column.ButtonsMax + Column.ButtonsMin) * 0.5f;
			float CenterX = (Column.Buttons[0].LocalMax.X + Column.Buttons[NumButtons - 1].LocalMin.X) * 0.5f;
			FVector WorldCenter = Transform.TransformPosition(FVector(CenterX, CenterY, Height * 0.25f));
			float HalfHeight = (Column.Buttons[0].LocalMax.X - Column.Buttons[NumButtons - 1].LocalMin.X) * 0.5f;
			float HalfWidth = (Column.ButtonsMax - Column.ButtonsMin) * 0.5f;
			System::DrawDebugBox(WorldCenter, FVector(HalfHeight, HalfWidth, 20), FLinearColor::Green, ActorRotation);
		}
	}

    UFUNCTION()
    void PlayerTriggerOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
       AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

	   if(Player == nullptr || (Player != nullptr && !Player.HasControl()))
		return;

		SetDrumMachineReference(Player, this);
    }

    UFUNCTION()
    void PlayerTriggerOnEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
       AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

	   if(Player == nullptr || (Player != nullptr && !Player.HasControl()))
		return;

		SetDrumMachineReference(Player, nullptr);
    }

	UFUNCTION()
	void OnPlayerOverlap(AHazePlayerCharacter Player)
	{
		if (Player == Game::GetCody())
			bInteractionCompFollowCody = true;
		else
			bInteractionCompFollowMay = true;
	}

	UFUNCTION()
	void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		if (Player == Game::GetCody())
			bInteractionCompFollowCody = false;
		else
			bInteractionCompFollowMay = false;
	}
}
